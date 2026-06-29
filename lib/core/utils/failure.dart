import 'package:equatable/equatable.dart';

/// Base failure class used across the domain layer.
abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

/// Failure originating from local Hive storage operations.
class StorageFailure extends Failure {
  const StorageFailure(super.message);
}

/// Failure when a requested entity is not found.
class NotFoundFailure extends Failure {
  const NotFoundFailure(super.message);
}

/// Failure due to invalid input or validation error.
class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

/// Unexpected or unknown failure.
class UnexpectedFailure extends Failure {
  const UnexpectedFailure(super.message);
}
