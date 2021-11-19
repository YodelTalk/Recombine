import Combine

@dynamicMemberLookup
public class Store<Action, StoreState>: Recombine {
  @Published private(set) var state: StoreState

  private let reducers: [Reducer]
  private let middlewares: [Middleware]

  public init(initialState: StoreState, reducers: [Reducer], middlewares: [Middleware] = []) {
    self.state = initialState
    self.reducers = reducers
    self.middlewares = middlewares
  }

  public func dispatch(_ action: Action, completion: (() -> Void)? = {}) {
    let initialDispatch = { (_ action: Action) in
      self.state = self.reducers.reduce(self.state, { state, reducer in reducer(action, state) })
    }

    let finalDispatch = middlewares.reduce(
      initialDispatch, { dispatch, middleware in middleware(dispatch, self) }
    )

    finalDispatch(action)

    if let completion = completion {
      completion()
    }
  }

  public subscript<T>(dynamicMember keyPath: KeyPath<StoreState, T>) -> T {
    return state[keyPath: keyPath]
  }
}
