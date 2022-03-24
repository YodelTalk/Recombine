public protocol Changeable {}

public extension Changeable {
  func change<T>(_ path: WritableKeyPath<Self, T>, to value: T) -> Self {
    var clone = self
    clone[keyPath: path] = value
    return clone
  }
}
