import Combine

@dynamicMemberLookup
public class LensedStore<Action, StoreState, LensedStoreState>: ObservableObject, Recombine {
  public init(_ store: Store<Action, StoreState>, keyPath: KeyPath<StoreState, LensedStoreState>) {
    self.store = store
    value = store.state[keyPath: keyPath]

    cancellable = store.$state.sink {
      self.value = $0[keyPath: keyPath]
    }
  }

  @Published public private(set) var value: LensedStoreState

  public subscript<T>(dynamicMember keyPath: KeyPath<LensedStoreState, T>) -> T {
    return value[keyPath: keyPath]
  }

  public func dispatch(_ action: Action) {
    store.dispatch(action)
  }

  private let store: Store<Action, StoreState>
  private var cancellable: AnyCancellable?
}
