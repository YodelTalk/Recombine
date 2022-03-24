import Combine
import XCTest

@testable import Recombine

class RecombineTests: XCTestCase {
  func testInitialState() {
    let store = AppStore(
      initialState: State(),
      reducers: []
    )

    XCTAssertEqual(store.counter, 0)
    XCTAssertFalse(store.flag)
    XCTAssertEqual(store.user, User(username: "Alice"))
    XCTAssertEqual(store.user.username, "Alice")
  }

  func testReducers() {
    let store = AppStore(
      initialState: State(),
      reducers: [reducer]
    )

    store.dispatch(.increase)
    store.dispatch(.decrease)
    store.dispatch(.decrease)
    store.dispatch(.rename("Bob"))

    XCTAssertEqual(store.counter, -1)
    XCTAssertFalse(store.flag)
    XCTAssertEqual(store.user.username, "Bob")

    store.dispatch(.toggle)

    XCTAssertEqual(store.counter, -1)
    XCTAssertTrue(store.flag)
    XCTAssertEqual(store.user.username, "Bob")
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
      initialState: State(),
      reducers: [reducer],
      middlewares: [asyncMiddleware, syncMiddleware]
    )

    store.dispatch(.increase)
    store.dispatch(.decrease)
    store.dispatch(.decrease)

    waitForExpectations(timeout: 1)

    XCTAssertEqual(store.counter, -3)
    XCTAssertFalse(store.flag)
    XCTAssertEqual(store.user.username, "Bob")

    store.dispatch(.toggle)

    XCTAssertEqual(store.counter, -3)
    XCTAssertTrue(store.flag)
    XCTAssertEqual(store.user.username, "Bob")
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
      initialState: State(),
      reducers: [reducer],
      middlewares: [dispatchingMiddleware]
    )

    store.dispatch(.increase)

    waitForExpectations(timeout: 1)

    XCTAssertEqual(store.counter, 0)
  }

  func testSubStateLensing() {
    let store = AppStore(
      initialState: State(),
      reducers: [reducer]
    )

    XCTAssertEqual(store.counter, 0)
    XCTAssertFalse(store.flag)

    let counterLense = store.lense(\.counter)
    let flagLense = store.lense(\.flag)
    let usernameLense = store.lense(\.user.username)

    XCTAssertEqual(counterLense.value, 0)
    XCTAssertFalse(flagLense.value)
    XCTAssertEqual(usernameLense.value, "Alice")

    store.dispatch(.increase)
    store.dispatch(.toggle)
    store.dispatch(.rename("Bob"))

    XCTAssertEqual(counterLense.value, 1)
    XCTAssertTrue(flagLense.value)
    XCTAssertEqual(usernameLense.value, "Bob")

    XCTAssertEqual(store.counter, counterLense.value)
    XCTAssertEqual(store.flag, flagLense.value)
    XCTAssertEqual(store.user.username, usernameLense.value)
  }
}

extension RecombineTests {
  struct State: Changeable {
    var counter = 0
    var flag = false
    var user = User(username: "Alice")
  }

  struct User: Equatable {
    var username: String
  }

  enum Action {
    case increase
    case decrease
    case toggle
    case rename(String)
  }

  typealias AppStore = Store<Action, State>

  func reducer(action: Action, state: State) -> State {
    switch action {
    case .increase:
      return state.change(\.counter, to: state.counter + 1)
    case .decrease:
      return state.change(\.counter, to: state.counter - 1)
    case .toggle:
      return state.change(\.flag, to: !state.flag)
    case let .rename(username):
      var user = state.user
      user.username = username
      return state.change(\.user, to: user)
    }
  }
}
