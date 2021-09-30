import Combine

protocol Recombine: ObservableObject {
  associatedtype Action
  associatedtype StoreState

  typealias Reducer = (Action, StoreState) -> StoreState
  typealias Dispatch = (Action) -> Void
  typealias Middleware = (@escaping Dispatch) -> Dispatch

  func dispatch(_ action: Action)
  func getState() -> StoreState
}

protocol Changeable {}

extension Changeable {
  func change<T>(path: WritableKeyPath<Self, T>, to value: T) -> Self {
    var clone = self
    clone[keyPath: path] = value
    return clone
  }
}

class Store<Action, StoreState>: Recombine {
  @Published private(set) var state: StoreState

  private let reducers: [Reducer]
  private let middlewares: [Middleware]

  init(initialState: StoreState, reducers: [Reducer], middlewares: [Middleware] = []) {
    self.state = initialState
    self.reducers = reducers
    self.middlewares = middlewares
  }

  func dispatch(_ action: Action) {
    let initialDispatch = { (_ action: Action) in
      self.state = self.reducers.reduce(self.state, { state, reducer in reducer(action, state) })
    }

    let finalDispatch = middlewares.reduce(
      initialDispatch, { dispatch, middleware in middleware(dispatch) }
    )

    finalDispatch(action)
  }

  func getState() -> StoreState {
    return state
  }
}
