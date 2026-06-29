import 'package:dartz/dartz.dart';
import '../../core/utils/failure.dart';

/// Base contract for all use cases that take a single [Params] argument.
abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

/// Base contract for use cases that require no parameters.
abstract class NoParamsUseCase<Type> {
  Future<Either<Failure, Type>> call();
}

/// Sentinel type used when a use case takes no parameters.
class NoParams {
  const NoParams();
}
