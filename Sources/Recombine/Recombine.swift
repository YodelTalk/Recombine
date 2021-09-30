import Combine

public protocol Recombine: ObservableObject {
  associatedtype Action
  associatedtype StoreState

  typealias Reducer = (Action, StoreState) -> StoreState
  typealias Dispatch = (Action) -> Void
  typealias Middleware = (@escaping Dispatch) -> Dispatch

  func dispatch(_ action: Action)
  func getState() -> StoreState
}
