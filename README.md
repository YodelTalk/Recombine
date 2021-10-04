# Recombine ![test](https://github.com/yodeltalk/recombine/actions/workflows/test.yml/badge.svg)

Our take on a [Redux](https://github.com/reduxjs/redux)-inspired state managment for Swift.

## Usage

```swift
struct State: Changeable {
  var counter = 0
}

enum Action {
  case increase
  case decrease
}

typealias AppStore = Store<Action, State>

func counterReducer(action: Action, state: State) -> State {
  switch action {
  case .increase:
    return state.change(path: \.counter, to: state.counter + 1)
  case .decrease:
    return state.change(path: \.counter, to: state.counter - 1)
  }
}

let logger = { (dispatch: @escaping AppStore.Dispatch, store: AppStore) in
  return { (action: Action) in
    print("Handling action: \(action)")
    dispatch(action)
    print("New state: \(store.counter)")
  }
}

let store = AppStore(
  initialState: State(),
  reducers: [counterReducer],
  middlewares: [logger]
)

store.dispatch(.increase)
store.dispatch(.decrease)
store.dispatch(.decrease)

store.counter // -1
```

## Inspiration

- https://elm-lang.org
- https://github.com/reduxjs/redux
- https://github.com/ReSwift/ReSwift
- https://github.com/ReSwift/Recombine (yes, I stole the name)

## License

[The MIT License](./LICENSE)
