import Combine

@dynamicMemberLookup
public class LensedStore<Action, StoreState, LensedStoreState: Equatable>: Recombine {
  public init(_ store: Store<Action, StoreState>, keyPath: KeyPath<StoreState, LensedStoreState>) {
    self.store = store
    self.state = store.state[keyPath: keyPath]

    cancellable = store.$state.sink {
      let newState = $0[keyPath: keyPath]

      if self.state != newState {
        self.objectWillChange.send()
        self.state = newState
      }
    }
  }

  public private(set) var state: LensedStoreState

  public subscript<T>(dynamicMember keyPath: KeyPath<LensedStoreState, T>) -> T {
    return state[keyPath: keyPath]
  }

  public func dispatch(_ action: Action) {
    store.dispatch(action)
  }

  private let store: Store<Action, StoreState>
  private var cancellable: AnyCancellable?
}
