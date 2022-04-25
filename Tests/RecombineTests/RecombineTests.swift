import Combine
import Recombine
import XCTest

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
    store.dispatch(.rename("Bob"))

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

    XCTAssertEqual(counterLense.state, 0)
    XCTAssertFalse(flagLense.state)
    XCTAssertEqual(usernameLense.state, "Alice")

    store.dispatch(.increase)
    store.dispatch(.toggle)
    store.dispatch(.rename("Bob"))

    XCTAssertEqual(counterLense.state, 1)
    XCTAssertTrue(flagLense.state)
    XCTAssertEqual(usernameLense.state, "Bob")

    XCTAssertEqual(store.counter, counterLense.state)
    XCTAssertEqual(store.flag, flagLense.state)
    XCTAssertEqual(store.user.username, usernameLense.state)
  }

  func testPublishers() {
    let store = AppStore(
      initialState: State(),
      reducers: [reducer]
    )

    let counterLense = store.lense(\.counter)
    let flagLense = store.lense(\.flag)
    let usernameLense = store.lense(\.user.username)

    let counterLenseChange = expectChange(of: counterLense.$state, count: 2)
    let flagLenseChange = expectChange(of: flagLense.$state, count: 1)
    let usernameLenseNoChange = expectNoChange(of: usernameLense.$state)
    let usernameLenseChange = expectChange(of: usernameLense.$state, count: 1)

    store.dispatch(.increase)
    store.dispatch(.toggle)
    store.dispatch(.increase)

    wait(for: [counterLenseChange.expectation], timeout: 1)
    wait(for: [flagLenseChange.expectation], timeout: 1)
    wait(for: [usernameLenseNoChange.expectation], timeout: 1)

    store.dispatch(.rename("Bob"))

    wait(for: [usernameLenseChange.expectation], timeout: 1)
  }

  func testStateChanges() {
    var mutableState = State()
    mutableState.change(\.user.username, to: "Bob")
    XCTAssertEqual(mutableState.user.username, "Bob")

    let immutableState = State()
    let changedStare = immutableState.changed(\.user.username, to: "Bob")
    XCTAssertEqual(changedStare.user.username, "Bob")
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
      return state.changed(\.counter, to: state.counter + 1)
    case .decrease:
      return state.changed(\.counter, to: state.counter - 1)
    case .toggle:
      return state.changed(\.flag, to: !state.flag)
    case let .rename(username):
      var user = state.user
      user.username = username
      return state.changed(\.user, to: user)
    }
  }
}

extension RecombineTests {
  typealias PublisherExpectation = (expectation: XCTestExpectation, cancellable: AnyCancellable)

  func expectChange<T: Publisher>(
    of publisher: T,
    file _: StaticString = #file,
    line _: UInt = #line,
    count expectedCount: Int
  ) -> PublisherExpectation where T.Failure == Never {
    var count = 0
    let expectation = expectation(description: "Publisher received \(expectedCount) of values")

    let cancellable = publisher
      .dropFirst()
      .sink(
        receiveValue: { _ in
          count += 1
          if count == expectedCount {
            expectation.fulfill()
          }
        }
      )

    return (expectation, cancellable)
  }

  func expectNoChange<T: Publisher>(
    of publisher: T,
    file _: StaticString = #file,
    line _: UInt = #line
  ) -> PublisherExpectation where T.Failure == Never {
    let expectation = expectation(description: "Publisher received values without expecting any")
    expectation.isInverted = true

    let cancellable = publisher
      .dropFirst()
      .sink(
        receiveValue: { _ in
          expectation.fulfill()
        }
      )

    return (expectation, cancellable)
  }
}
