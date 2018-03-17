public struct ReaderMonad<R, A> {
  let runReader: (R) -> A

  public init(_ runReader: @escaping (R) -> A) {
    self.runReader = runReader
  }
}

// MARK: - Functor

extension ReaderMonad {
  public func map<B>(_ f: @escaping (A) -> B) -> ReaderMonad<R, B> {
    return .init(self.runReader >>> f)
  }

  public static func <¢> <R, A, B> (f: @escaping (A) -> B, reader: ReaderMonad<R, A>) -> ReaderMonad<R, B> {
    return reader.map(f)
  }
}

// MARK: - Apply

extension ReaderMonad {
  public func apply<B>(_ f: ReaderMonad<R, (A) -> B>) -> ReaderMonad<R, B> {
    return .init { r in
      f.runReader(r) <| self.runReader(r)
    }
  }

  public static func <*> <R, A, B> (f: ReaderMonad<R, (A) -> B>, reader: ReaderMonad<R, A>) -> ReaderMonad<R, B> {
    return reader.apply(f)
  }
}

// MARK: - Applicative

public func pure<R, A>(_ a: A) -> ReaderMonad<R, A> {
  return .init(const(a))
}

// MARK: - Monad

extension ReaderMonad {

  public func flatMap<B>(_ f: @escaping (A) -> ReaderMonad<R, B>) -> ReaderMonad<R, B> {
    return .init { r in
      f(self.runReader(r)).runReader(r)
    }
  }

  public static func >>- <B>(f: @escaping (A) -> ReaderMonad<R, B>, reader: ReaderMonad<R, A>) -> ReaderMonad<R, B> {
    return reader.flatMap(f)
  }
}
