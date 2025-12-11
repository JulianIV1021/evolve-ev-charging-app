import 'package:flutter_map_training/network/network.dart';

import '../../../common/utils/logger.dart';
import '../model/wallet_model.dart';

abstract class WalletService {
  final ApiClient apiClient;

  const WalletService(this.apiClient);

  Future<Wallet> getWalletInfo();
}

class WalletServiceImpl implements WalletService {
  @override
  final ApiClient apiClient;

  const WalletServiceImpl(this.apiClient);

  @override
  Future<Wallet> getWalletInfo() async {
    try {
      final walletResponse = await apiClient.get('wallet-info.json');
      if (walletResponse == null) {
        throw const FormatException('Wallet response was empty');
      }
      return Wallet.fromJson(walletResponse as Map<String, dynamic>);
    } catch (e) {
      log.severe('_fetchWalletInfo error: $e');
      rethrow;
    }
  }
}
