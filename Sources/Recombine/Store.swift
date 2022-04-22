import Combine

@dynamicMemberLookup
public class Store<Action, StoreState>: Recombine {
  public init(initialState: StoreState, reducers: [Reducer], middlewares: [Middleware] = []) {
    self.state = initialState
    self.reducers = reducers
    self.middlewares = middlewares
  }

  @Published public private(set) var state: StoreState

  public func dispatch(_ action: Action) {
    let initialDispatch = { (_ action: Action) in
      self.state = self.reducers.reduce(self.state) { state, reducer in reducer(action, state) }
    }

    let finalDispatch = middlewares.reduce(
      initialDispatch, { dispatch, middleware in middleware(dispatch, self) }
    )

    finalDispatch(action)
  }

  public func lense<T>(_ keyPath: KeyPath<StoreState, T>) -> LensedStore<Action, StoreState, T> {
    return LensedStore<Action, StoreState, T>(self, keyPath: keyPath)
  }

  public subscript<T>(dynamicMember keyPath: KeyPath<StoreState, T>) -> T {
    return state[keyPath: keyPath]
  }

  private let reducers: [Reducer]
  private let middlewares: [Middleware]
}
