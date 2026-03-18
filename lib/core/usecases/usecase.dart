import 'package:fpdart/fpdart.dart';
import 'package:infano_care_mobile/core/error/failures.dart';

abstract interface class UseCase<SuccessType, Params> {
  Future<Either<Failure, SuccessType>> call(Params params);
}

class NoParams {}
