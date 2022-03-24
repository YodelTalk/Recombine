import Combine

public class LensedStore<Action, StoreState, LensedStoreState>: ObservableObject, Recombine {
  public init(_ store: Store<Action, StoreState>, keyPath: KeyPath<StoreState, LensedStoreState>) {
    self.store = store
    self.value = store.state[keyPath: keyPath]

    self.cancellable = store.$state.sink {
      self.value = $0[keyPath: keyPath]
    }
  }

  public subscript<T>(dynamicMember keyPath: KeyPath<LensedStoreState, T>) -> T {
    return value[keyPath: keyPath]
  }

  public func dispatch(_ action: Action) {
    store.dispatch(action)
  }

  @Published private(set) var value: LensedStoreState

  private let store: Store<Action, StoreState>
  private var cancellable: AnyCancellable?
}
