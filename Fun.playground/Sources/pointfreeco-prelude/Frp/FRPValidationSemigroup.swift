public func <*> <A, B, E: Semigroup>(a2b: Event<SemigroupValidation<E, (A) -> B>>, a: Event<SemigroupValidation<E, A>>)
  -> Event<SemigroupValidation<E, B>> {

    return (<*>) <¢> (curry({ ($0, $1) }) <¢> a2b <*> a)
}

public func pure<E, A>(_ a: A) -> Event<SemigroupValidation<E, A>> {
  return pure <<< pure <| a
}
