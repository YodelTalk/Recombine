import Combine

public protocol Recombine: ObservableObject {
  associatedtype Action
  associatedtype StoreState

  typealias Reducer = (Action, StoreState) -> StoreState
  typealias Dispatch = (Action) -> Void
  typealias Middleware = (@escaping Dispatch, Store<Action, StoreState>) -> Dispatch

  func dispatch(_ action: Action)
  subscript<T>(dynamicMember _: KeyPath<StoreState, T>) -> T { get }
}
