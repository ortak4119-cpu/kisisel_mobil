import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import '../../models/auth/auth_models.dart';
import '../../core/route/app_router.dart';
import '../route/app_router.gr.dart';

class PremiumHelper {
  // Premium limit değerleri
  static const int FREE_NOTE_LIMIT = 5;
  static const int FREE_HABIT_LIMIT = 2;
  static const int FREE_TASK_LIMIT = 3;

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

  /// Not ekleme limitini kontrol eder ve gerekirse paywall gösterir
  /// Returns: true ise devam edebilir, false ise limit aşılmış
  static Future<bool> checkNoteLimit({
    required BuildContext context,
    required User? user,
    required int currentNoteCount,
  }) async {
    // Premium kullanıcı ise sınır yok
    if (isPremiumUser(user)) return true;

    // Limit kontrolü
    if (currentNoteCount >= FREE_NOTE_LIMIT) {
      await _showPremiumPaywall(context);
      return false;
    }

    return true;
  }

  /// Alışkanlık ekleme limitini kontrol eder ve gerekirse paywall gösterir
  /// Returns: true ise devam edebilir, false ise limit aşılmış
  static Future<bool> checkHabitLimit({
    required BuildContext context,
    required User? user,
    required int currentHabitCount,
  }) async {
    // Premium kullanıcı ise sınır yok
    if (isPremiumUser(user)) return true;

    // Limit kontrolü
    if (currentHabitCount >= FREE_HABIT_LIMIT) {
      await _showPremiumPaywall(context);
      return false;
    }

    return true;
  }

  /// Görev ekleme limitini kontrol eder ve gerekirse paywall gösterir
  /// Returns: true ise devam edebilir, false ise limit aşılmış
  static Future<bool> checkTaskLimit({
    required BuildContext context,
    required User? user,
    required int currentTaskCount,
  }) async {
    // Premium kullanıcı ise sınır yok
    if (isPremiumUser(user)) return true;

    // Limit kontrolü
    if (currentTaskCount >= FREE_TASK_LIMIT) {
      await _showPremiumPaywall(context);
      return false;
    }

    return true;
  }

  /// Paywall ekranını gösterir
  static Future<void> _showPremiumPaywall(BuildContext context) async {
    if (!context.mounted) return;

    final result = await context.router.push(const PaywallRoute());

    // Paywall'dan döndükten sonra result true ise premium satın alındı
    if (result == true && context.mounted) {
      // Kullanıcı bilgilerini yenilemeyi tetikleyebilirsiniz
      debugPrint('✅ Premium satın alındı!');
    }
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
        title: const Row(
          children: [
            Icon(Icons.workspace_premium, color: Colors.amber),
            SizedBox(width: 8),
            Text('Premium Özellik'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ücretsiz sürümde $featureName için $limit adet limit vardır.',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            Text(
              'Şu an $currentCount/$limit kullanıyorsunuz.',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Sınırsız kullanım için Premium\'a geçin!',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showPremiumPaywall(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
            ),
            child: const Text('Premium\'a Geç'),
          ),
        ],
      ),
    );
  }
}
