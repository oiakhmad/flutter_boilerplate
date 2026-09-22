import 'package:flutter_clean_boilerplate/core/result/result.dart';
import 'package:flutter_clean_boilerplate/features/app_lock/domain/repositories/app_lock_repository.dart';
import 'package:flutter_clean_boilerplate/features/app_lock/domain/usecases/pin_verifier.dart';

/// Verifies the PIN to unlock the app (the Lock Screen's submit action).
///
/// A thin, clearly-named use case over the shared [PinVerifier] pipeline -
/// the controller talks only to use cases, never to domain helpers, so the
/// lockout and attempt-counter rules still live entirely in the domain
/// layer.
class VerifyPinUseCase {
  VerifyPinUseCase(AppLockRepository repository)
      : _verifier = PinVerifier(repository);

  final PinVerifier _verifier;

  Future<Result<void>> call(String pin) => _verifier(pin);
}