public enum NearSemiringValidation<E, A> {
  case valid(A)
  case invalid(E)
}

public extension NearSemiringValidation {
  public func validate<B>(_ e2b: (E) -> B, _ a2b: (A) -> B) -> B {
    switch self {
    case let .valid(a):
      return a2b(a)
    case let .invalid(e):
      return e2b(e)
    }
  }

  public var isValid: Bool {
    return validate(const(false), const(true))
  }
}

public func validate<A, B, C>(_ a2c: @escaping (A) -> C) -> (@escaping (B) -> C) -> (NearSemiringValidation<A, B>) -> C {
  return { b2c in
    { ab in
      ab.validate(a2c, b2c)
    }
  }
}

// MARK: - Functor

extension NearSemiringValidation {
  public func map<B>(_ a2b: (A) -> B) -> NearSemiringValidation<E, B> {
    switch self {
    case let .valid(a):
      return .valid(a2b(a))
    case let .invalid(e):
      return .invalid(e)
    }
  }

  public static func <¢> <B>(a2b: (A) -> B, a: NearSemiringValidation) -> NearSemiringValidation<E, B> {
    return a.map(a2b)
  }
}

public func map<A, B, C>(_ b2c: @escaping (B) -> C)
  -> (NearSemiringValidation<A, B>)
  -> NearSemiringValidation<A, C> {
    return { ab in
      b2c <¢> ab
    }
}

// MARK: - Bifunctor

extension NearSemiringValidation {
  public func bimap<B, C>(_ e2b: (E) -> B, _ a2c: (A) -> C) -> NearSemiringValidation<B, C> {
    switch self {
    case let .valid(a):
      return .valid(a2c(a))
    case let .invalid(e):
      return .invalid(e2b(e))
    }
  }
}

public func bimap<A, B, C, D>(_ a2c: @escaping (A) -> C)
  -> (@escaping (B) -> D)
  -> (NearSemiringValidation<A, B>)
  -> NearSemiringValidation<C, D> {
    return { b2d in
      { ab in
        ab.bimap(a2c, b2d)
      }
    }
}

// MARK: - Apply

extension NearSemiringValidation where E: NearSemiring {
  public func apply<B>(_ a2b: NearSemiringValidation<E, (A) -> B>) -> NearSemiringValidation<E, B> {
    switch (a2b, self) {
    case let (.valid(f), _):
      return self.map(f)
    case let (.invalid(e), .valid):
      return .invalid(e)
    case let (.invalid(e1), .invalid(e2)):
      return .invalid(e1 * e2)
    }
  }

  public static func <*> <B>(a2b: NearSemiringValidation<E, (A) -> B>, a: NearSemiringValidation) -> NearSemiringValidation<E, B> {
    return a.apply(a2b)
  }
}

public func apply<A: NearSemiring, B, C>(_ b2c: NearSemiringValidation<A, (B) -> C>)
  -> (NearSemiringValidation<A, B>)
  -> NearSemiringValidation<A, C> {
    return { ab in
      b2c <*> ab
    }
}

// MARK: - Applicative

public func pure<E, A>(_ a: A) -> NearSemiringValidation<E, A> {
  return .valid(a)
}

// MARK: - Alt

extension NearSemiringValidation: Alt where E: NearSemiring {
  public static func <|> (lhs: NearSemiringValidation, rhs: @autoclosure @escaping () -> NearSemiringValidation) -> NearSemiringValidation {
    let rhs = rhs()
    switch (lhs, rhs) {
    case (.invalid, .valid):
      return rhs
    case let (.invalid(e1), .invalid(e2)):
      return .invalid(e1 + e2)
    default:
      return lhs
    }
  }
}

// MARK: - Eq/Equatable

extension NearSemiringValidation: Equatable where E: Equatable, A: Equatable {
  public static func == (lhs: NearSemiringValidation, rhs: NearSemiringValidation) -> Bool {
    switch (lhs, rhs) {
    case let (.invalid(e1), .invalid(e2)):
      return e1 == e2
    case let (.valid(a1), .valid(a2)):
      return a1 == a2
    default:
      return false
    }
  }
}

// MARK: - Ord/Comparable

extension NearSemiringValidation: Comparable where E: Comparable, A: Comparable {
  public static func < (lhs: NearSemiringValidation, rhs: NearSemiringValidation) -> Bool {
    switch (lhs, rhs) {
    case let (.invalid(e1), .invalid(e2)):
      return e1 < e2
    case let (.valid(a1), .valid(a2)):
      return a1 < a2
    case (.invalid, .valid):
      return true
    case (.valid, .invalid):
      return false
    }
  }
}

// MARK: - Semigroup

extension NearSemiringValidation: Semigroup where E: Semiring, A: Semigroup {
  public static func <>(lhs: NearSemiringValidation, rhs: NearSemiringValidation) -> NearSemiringValidation {
    return curry(<>) <¢> lhs <*> rhs
  }
}
