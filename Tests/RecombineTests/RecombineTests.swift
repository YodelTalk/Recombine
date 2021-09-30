import Combine
import XCTest

@testable import Recombine

class RecombineTests: XCTestCase {
  struct State: Changeable {
    var counter = 0
    var flag: Bool
  }

  enum Action {
    case increase
    case decrease
  }

  typealias AppStore = Store<Action, State>

  func counterReducer(action: Action, state: State) -> State {
    switch action {
    case .increase:
      return state.change(path: \.counter, to: state.counter + 1)
    case .decrease:
      return state.change(path: \.counter, to: state.counter - 1)
    }
  }

  func testInitialState() {
    let store = AppStore(
      initialState: State(flag: false),
      reducers: []
    )

    XCTAssertEqual(store.getState().counter, 0)
  }

  func testReducers() {
    let store = AppStore(
      initialState: State(flag: false),
      reducers: [counterReducer]
    )

    store.dispatch(.increase)
    store.dispatch(.decrease)
    store.dispatch(.decrease)

    XCTAssertEqual(store.getState().counter, -1)
  }

  func testMiddlewares() {
    let expectation = self.expectation(description: "asyncMiddleware")

    let asyncMiddleware = {
      (dispatch: @escaping AppStore.Dispatch) in
      return { (action: Action) in
        switch action {
        case .increase:
          DispatchQueue.main.async {
            dispatch(action)
            expectation.fulfill()
          }
        case .decrease:
          dispatch(action)
        }
      }
    }

    let syncMiddleware = {
      (dispatch: @escaping AppStore.Dispatch) in
      return { (action: Action) in
        switch action {
        case .increase:
          dispatch(action)
        case .decrease:
          dispatch(action)
          dispatch(action)
        }
      }
    }

    let store = AppStore(
      initialState: State(flag: true),
      reducers: [counterReducer],
      middlewares: [asyncMiddleware, syncMiddleware]
    )

    store.dispatch(.increase)
    store.dispatch(.decrease)
    store.dispatch(.decrease)

    waitForExpectations(timeout: 1)

    XCTAssertEqual(store.getState().counter, -3)
  }

}
