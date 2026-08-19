import 'package:injectable/injectable.dart';
import 'package:flutter_template/features/user/domain/repository/subscription_repository.dart';
import 'package:flutter_template/core/generated/base_use_case.dart';

@singleton
class SetSubscriptionStatusUseCase with BaseUseCaseWithParams<void, bool> {
  SetSubscriptionStatusUseCase(this._subscriptionRepository);

  final SubscriptionRepository _subscriptionRepository;

  @override
  Future<void> execute(bool params) =>
      _subscriptionRepository.setSubscriptionStatus(params);
}
