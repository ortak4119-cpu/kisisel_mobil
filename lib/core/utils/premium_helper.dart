import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../models/auth/auth_models.dart';
import '../route/app_router.gr.dart';

class PremiumHelper {
  // Premium limit değerleri
  static const int FREE_NOTE_LIMIT = 2;
  static const int FREE_HABIT_LIMIT = 1;
  static const int FREE_TASK_LIMIT = 2;
  static const int FREE_SUBSCRIPTION_LIMIT = 2;
  static const int FREE_EXPENSE_LIMIT = 2;

  /// Kullanıcının premium olup olmadığını kontrol eder
  static bool isPremiumUser(User? user) {
    if (user == null) return false;

    // Guest kullanıcılar premium olamaz
    if (user.isGuest) return false;

    // Subscription durumunu kontrol et
    final subscriptionStatus = user.subscriptionStatus;
    final subscriptionType = user.subscriptionType;

    // Aktif subscription var mı?
    if (subscriptionStatus == 'active' || subscriptionStatus == 'trialing') {
      // Subscription type kontrolü (free değilse premium)
      if (subscriptionType != null && subscriptionType != 'free') {
        return true;
      }
    }

    return false;
  }

  // NOT: Ücretsiz sürüm limitleri kaldırıldı. Aşağıdaki ekleme kontrolleri
  // artık her zaman izin verir; ücretsiz hesaplar da not/alışkanlık/görev/
  // abonelik/harcamayı sınırsız ekleyebilir. (Limit sabitleri ve paywall
  // ileride tekrar etkinleştirilebilmek için kasıtlı olarak korunuyor.)

  /// Not ekleme limiti — kaldırıldı, her zaman izin verir.
  static Future<bool> checkNoteLimit({
    required BuildContext context,
    required User? user,
    required int currentNoteCount,
  }) async {
    return true;
  }

  /// Alışkanlık ekleme limiti — kaldırıldı, her zaman izin verir.
  static Future<bool> checkHabitLimit({
    required BuildContext context,
    required User? user,
    required int currentHabitCount,
  }) async {
    return true;
  }

  /// Görev ekleme limiti — kaldırıldı, her zaman izin verir.
  static Future<bool> checkTaskLimit({
    required BuildContext context,
    required User? user,
    required int currentTaskCount,
  }) async {
    return true;
  }

  /// Abonelik ekleme limiti — kaldırıldı, her zaman izin verir.
  static Future<bool> checkSubscriptionLimit({
    required BuildContext context,
    required User? user,
    required int currentSubscriptionCount,
  }) async {
    return true;
  }

  /// Harcama ekleme limiti — kaldırıldı, her zaman izin verir.
  static Future<bool> checkExpenseLimit({
    required BuildContext context,
    required User? user,
    required int currentExpenseCount,
  }) async {
    return true;
  }

  /// Paywall ekranını gösterir
  /// Satın alma başarılı olursa true döner
  static Future<bool> _showPremiumPaywall(BuildContext context) async {
    if (!context.mounted) return false;

    final result = await context.router.push(const PaywallRoute());

    // Paywall'dan döndükten sonra result true ise premium satın alındı
    if (result == true && context.mounted) {
      debugPrint('✅ Premium satın alındı!');
      return true;
    }
    return false;
  }

  /// Premium özellik bilgisi gösterir (isteğe bağlı, daha soft bir yaklaşım)
  static void showPremiumFeatureDialog({
    required BuildContext context,
    required String featureName,
    required int currentCount,
    required int limit,
  }) {
    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.workspace_premium, color: Colors.amber),
            const SizedBox(width: 8),
            Text('premium.featureTitle'.tr()),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'premium.limitInfo'.tr(
                namedArgs: {'feature': featureName, 'limit': '$limit'},
              ),
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            Text(
              'premium.currentUsage'.tr(
                namedArgs: {'current': '$currentCount', 'limit': '$limit'},
              ),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'premium.unlockCta'.tr(),
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('common.cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showPremiumPaywall(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
            ),
            child: Text('premium.goCta'.tr()),
          ),
        ],
      ),
    );
  }
}
