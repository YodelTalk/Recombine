public protocol Changeable {}

public extension Changeable {
  func changed<T>(_ path: WritableKeyPath<Self, T>, to value: T) -> Self {
    var clone = self
    clone.change(path, to: value)
    return clone
  }

  mutating func change<T>(_ path: WritableKeyPath<Self, T>, to value: T) {
    self[keyPath: path] = value
  }
}
