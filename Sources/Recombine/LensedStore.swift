import Combine

@dynamicMemberLookup
public class LensedStore<Action, StoreState, LensedStoreState>: ObservableObject, Recombine {
  public init(_ store: Store<Action, StoreState>, keyPath: KeyPath<StoreState, LensedStoreState>) {
    self.store = store
    self.state = store.state[keyPath: keyPath]

    self.cancellable = store.$state.sink {
      self.state = $0[keyPath: keyPath]
    }
  }

  public subscript<T>(dynamicMember keyPath: KeyPath<LensedStoreState, T>) -> T {
    return state[keyPath: keyPath]
  }

  public func dispatch(_ action: Action) {
    store.dispatch(action)
  }

  @Published private(set) var state: LensedStoreState

  private let store: Store<Action, StoreState>
  private var cancellable: AnyCancellable?
}
