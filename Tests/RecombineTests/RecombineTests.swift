import Combine
import XCTest

@testable import Recombine

class RecombineTests: XCTestCase {
  func testInitialState() {
    let store = AppStore(
      initialState: State(flag: false),
      reducers: []
    )

    XCTAssertEqual(store.counter, 0)
    XCTAssertFalse(store.flag)
  }

  func testReducers() {
    let store = AppStore(
      initialState: State(flag: false),
      reducers: [counterReducer]
    )

    store.dispatch(.increase)
    store.dispatch(.decrease)
    store.dispatch(.decrease)

    XCTAssertEqual(store.counter, -1)
    XCTAssertFalse(store.flag)

    store.dispatch(.toggle)

    XCTAssertEqual(store.counter, -1)
    XCTAssertTrue(store.flag)
  }

  func testMiddlewares() {
    let expectation = self.expectation(description: "asyncMiddleware")

    let asyncMiddleware = {
      (dispatch: @escaping AppStore.Dispatch, _: AppStore) in
        { (action: Action) in
          switch action {
          case .increase:
            DispatchQueue.main.async {
              dispatch(action)
              expectation.fulfill()
            }

          default:
            dispatch(action)
          }
        }
    }

    let syncMiddleware = {
      (dispatch: @escaping AppStore.Dispatch, _: AppStore) in
        { (action: Action) in
          switch action {
          case .decrease:
            dispatch(action)
            dispatch(action)

          default:
            dispatch(action)
          }
        }
    }

    let store = AppStore(
      initialState: State(flag: false),
      reducers: [counterReducer],
      middlewares: [asyncMiddleware, syncMiddleware]
    )

    store.dispatch(.increase)
    store.dispatch(.decrease)
    store.dispatch(.decrease)

    waitForExpectations(timeout: 1)

    XCTAssertEqual(store.counter, -3)
    XCTAssertFalse(store.flag)

    store.dispatch(.toggle)

    XCTAssertEqual(store.counter, -3)
    XCTAssertTrue(store.flag)
  }

  func testDispatchingMiddlewares() {
    let expectation = self.expectation(description: "dispatchedAction")

    let dispatchingMiddleware = {
      (dispatch: @escaping AppStore.Dispatch, store: AppStore) in
        { (action: Action) in
          switch action {
          case .increase:
            dispatch(action)
            store.dispatch(.decrease)

          case .decrease:
            dispatch(action)
            expectation.fulfill()

          default:
            dispatch(action)
          }
        }
    }

    let store = AppStore(
      initialState: State(flag: false),
      reducers: [counterReducer],
      middlewares: [dispatchingMiddleware]
    )

    store.dispatch(.increase)

    waitForExpectations(timeout: 1)

    XCTAssertEqual(store.counter, 0)
  }
}

extension RecombineTests {
  struct State: Changeable {
    var counter = 0
    var flag: Bool
  }

  enum Action {
    case increase
    case decrease
    case toggle
  }

  typealias AppStore = Store<Action, State>

  func counterReducer(action: Action, state: State) -> State {
    switch action {
    case .increase:
      return state.change(\.counter, to: state.counter + 1)
    case .decrease:
      return state.change(\.counter, to: state.counter - 1)
    case .toggle:
      return state.change(\.flag, to: !state.flag)
    }
  }
}
