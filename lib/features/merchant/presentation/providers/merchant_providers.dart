import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:wain_app/features/merchant/data/repositories/merchant_repository.dart';

part 'merchant_providers.g.dart';

@riverpod
MerchantRepository merchantRepository(Ref ref) {
  return MerchantRepository();
}
