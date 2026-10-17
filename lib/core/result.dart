/// Outcome of a tool operation. Tools return errors as values instead of
/// throwing, so the UI only has to switch on [Ok] or [Err].
sealed class Result<T, E> {
  const Result();
}

final class Ok<T, E> extends Result<T, E> {
  const Ok(this.value);

  final T value;
}

final class Err<T, E> extends Result<T, E> {
  const Err(this.error);

  final E error;
}
