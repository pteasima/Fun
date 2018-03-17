public struct StateMonad<S, A> {
  public let run: (S) -> (result: A, finalState: S)

  public init(run: @escaping (S) -> (result: A, finalState: S)) {
    self.run = run
  }

  public func eval(_ state: S) -> A {
    return self.run(state).result
  }

  public func exec(_ state: S) -> S {
    return self.run(state).finalState
  }

  public func with(_ modification: @escaping (S) -> S) -> StateMonad<S, A> {
    return StateMonad(run: self.run <<< modification)
  }
}

extension StateMonad {
  public static var get: StateMonad<S, S> {
    return .init { ($0, $0) }
  }

  public static func gets(_ f: @escaping (S) -> A) -> StateMonad<S, A> {
    return .init { (f($0), $0) }
  }

  public static func put(_ state: S) -> StateMonad<S, Unit> {
    return .init { _ in (unit, state) }
  }

  public static func modify(_ f: @escaping (S) -> S) -> StateMonad<S, Unit> {
    return .init { (unit, f($0)) }
  }
}

// MARK: - Functor

extension StateMonad {
  public func map<B>(_ a2b: @escaping (A) -> B) -> StateMonad<S, B> {
    return StateMonad<S, B> { state in
      let (result, finalState) = self.run(state)
      return (a2b(result), finalState)
    }
  }

  public static func <¢> <B>(a2b: @escaping (A) -> B, sa: StateMonad<S, A>) -> StateMonad<S, B> {
    return sa.map(a2b)
  }
}

// MARK: - Apply

extension StateMonad {
  public func apply<B>(_ sa2b: StateMonad<S, (A) -> B>) -> StateMonad<S, B> {
    return sa2b.flatMap { a2b in self.map(a2b) }
  }

  public static func <*> <B>(sa2b: StateMonad<S, (A) -> B>, sa: StateMonad) -> StateMonad<S, B> {
    return sa.apply(sa2b)
  }
}

// MARK: - Applicative

public func pure<S, A>(_ a: A) -> StateMonad<S, A> {
  return .init { (a, $0) }
}

// MARK: - Bind/Monad

extension StateMonad {
  public func flatMap<B>(_ a2sb: @escaping (A) -> StateMonad<S, B>) -> StateMonad<S, B> {
    return StateMonad<S, B> { state in
      let (result, nextState) = self.run(state)
      return a2sb(result).run(nextState)
    }
  }

  public static func >>- <B>(sa: StateMonad<S, A>, a2sb: @escaping (A) -> StateMonad<S, B>) -> StateMonad<S, B> {
    return sa.flatMap(a2sb)
  }
}
