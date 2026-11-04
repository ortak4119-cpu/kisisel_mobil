import 'dart:io';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:image_picker/image_picker.dart';
import 'package:auto_route/auto_route.dart';
import '../../../core/route/app_router.gr.dart';
import '../../../core/init/locator.dart';
import '../../../models/settings/settings_models.dart';
import '../../../models/social/social_model.dart';
import '../../../service/profile/profile_service.dart';
import '../../../service/social/social_service.dart';
import '../../../service/gamification/gamification_service.dart';
import '../../../service/auth/auth_service.dart';
import '../../../models/auth/auth_models.dart';
import '../../../models/gamification/gamification_models.dart';
import '../../../core/utils/custom_snackbar.dart';
import '../../common/sent_animation.dart';

class ProfileViewModel extends ChangeNotifier {
  final IProfileService _profileService = locator.get<IProfileService>();
  final ISocialService _socialService = locator.get<ISocialService>();
  final IGamificationService _gamificationService = locator.get<IGamificationService>();
  final IAuthService _authService = locator.get<IAuthService>();
  final ImagePicker _imagePicker = ImagePicker();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isUploadingAvatar = false;
  bool get isUploadingAvatar => _isUploadingAvatar;

  bool _isUploadingCover = false;
  bool get isUploadingCover => _isUploadingCover;

  // Current User
  User? _currentUser;
  User? get currentUser => _currentUser;

  // Profil verisinin en son başarıyla senkronlandığı an ("Son senkron" göstergesi).
  DateTime? _lastSyncedAt;
  DateTime? get lastSyncedAt => _lastSyncedAt;

  bool _isUserLoaded = false;
  bool get isUserLoaded => _isUserLoaded;

  // Profile Stats
  ProfileStats? _profileStats;
  ProfileStats? get profileStats => _profileStats;

  // Social
  List<Friend> _friends = [];
  List<Friend> get friends => _friends;

  List<FriendRequest> _friendRequests = [];
  List<FriendRequest> get friendRequests => _friendRequests;

  List<UserSearchResult> _searchResults = [];
  List<UserSearchResult> get searchResults => _searchResults;

  // Takip edilen kullanıcı id'leri (follow durumunu UI'da göstermek için).
  final Set<int> _following = {};
  bool isFollowingUser(int userId) => _following.contains(userId);

  // Achievements
  List<Achievement> _achievements = [];
  List<Achievement> get achievements => _achievements;

  // Level info (gerçek XP ilerlemesi)
  LevelInfo? _levelInfo;
  LevelInfo? get levelInfo => _levelInfo;

  Future<void> loadLevelInfo() async {
    try {
      final response = await _gamificationService.getLevelInfo();
      if (response.isSuccess && response.data != null) {
        _levelInfo = response.data!;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading level info: $e');
    }
  }

  // ==================== PROFILE ====================

  Future<void> loadProfile() async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await _profileService.getProfile();

      if (response.isSuccess && response.data != null) {
        _currentUser = response.data!;
      }
      _isUserLoaded = true;

      // Load stats, friends, and achievements in parallel
      await Future.wait([
        loadProfileStats(),
        loadFriends(),
        loadFriendRequests(),
        loadAchievements(),
        loadLevelInfo(),
        loadFollowing(),
      ]);
    } catch (e) {
      debugPrint('Error loading profile: $e');
      _isUserLoaded = true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadProfileStats() async {
    try {
      debugPrint('📊 [ViewModel] loadProfileStats() called');

      final response = await _profileService.getStats();

      debugPrint('📊 [ViewModel] Service response received');
      debugPrint('   - isSuccess: ${response.isSuccess}');
      debugPrint('   - data is null: ${response.data == null}');

      if (response.isSuccess && response.data != null) {
        _profileStats = response.data!;
        debugPrint('✅ [ViewModel] Stats assigned to _profileStats');
        notifyListeners();
        debugPrint('✅ [ViewModel] notifyListeners() called');
      } else {
        debugPrint('❌ [ViewModel] Stats load failed: ${response.errorMessage}');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [ViewModel] Error loading profile stats: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  /// Profil alanlarını günceller (ad/kullanıcı adı/bio + gizlilik/dil).
  /// Başarıyı bool döner; hata mesajını (ör. kullanıcı adı çakışması) gösterir.
  Future<bool> updateProfile({
    String? username,
    String? displayName,
    String? bio,
    String? preferredLanguage,
    String? profileVisibility,
    bool? showLevel,
    bool? showAchievements,
    bool? showHabits,
    BuildContext? context,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final request = ProfileUpdateRequest(
        username: username,
        displayName: displayName,
        bio: bio,
        preferredLanguage: preferredLanguage,
        profileVisibility: profileVisibility,
        showLevel: showLevel,
        showAchievements: showAchievements,
        showHabits: showHabits,
      );

      final response = await _profileService.updateProfile(request);

      if (response.isSuccess && response.data != null) {
        _currentUser = response.data!;
        return true;
      }
      if (context != null && context.mounted) {
        CustomSnackBar.showError(
            context, response.errorMessage);
      }
      return false;
    } catch (e) {
      debugPrint('Error updating profile: $e');
      if (context != null && context.mounted) {
        CustomSnackBar.showError(context, 'errors.general'.tr());
      }
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Oturumu kapatır ve splash'a döner (settings ile aynı akış).
  Future<void> logout(BuildContext context) async {
    try {
      await _authService.logout();
    } catch (e) {
      debugPrint('Error logging out: $e');
    }
    if (context.mounted) {
      context.router.replaceAll([const SplashRoute()]);
    }
  }

  // ==================== IMAGE UPLOAD ====================

  Future<void> updateProfilePicture(BuildContext context, ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) return;

      _isUploadingAvatar = true;
      notifyListeners();

      final file = File(image.path);
      final response = await _profileService.updateAvatar(file);

      if (response.isSuccess && response.data != null) {
        // Update current user profile picture
        _currentUser = _currentUser?.copyWith(profilePictureUrl: response.data!);

        if (context.mounted) {
          CustomSnackBar.showSuccess(context, 'profile.success.profilePictureUpdated'.tr());
        }
      } else {
        if (context.mounted) {
          CustomSnackBar.showError(
            context,
            response.errorMessage,
          );
        }
      }
    } catch (e) {
      debugPrint('Error updating profile picture: $e');
      if (context.mounted) {
        CustomSnackBar.showError(context, 'profile.errors.imageUploadError'.tr());
      }
    } finally {
      _isUploadingAvatar = false;
      notifyListeners();
    }
  }

  Future<void> updateCoverImage(BuildContext context, ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image == null) return;

      _isUploadingCover = true;
      notifyListeners();

      final file = File(image.path);
      final response = await _profileService.updateCover(file);

      if (response.isSuccess && response.data != null) {
        // Update current user cover image
        _currentUser = _currentUser?.copyWith(coverImageUrl: response.data!);

        if (context.mounted) {
          CustomSnackBar.showSuccess(context, 'profile.success.coverImageUpdated'.tr());
        }
      } else {
        if (context.mounted) {
          CustomSnackBar.showError(
            context,
            response.errorMessage,
          );
        }
      }
    } catch (e) {
      debugPrint('Error updating cover image: $e');
      if (context.mounted) {
        CustomSnackBar.showError(context, 'profile.errors.imageUploadError'.tr());
      }
    } finally {
      _isUploadingCover = false;
      notifyListeners();
    }
  }

  // ==================== SOCIAL ====================

  Future<void> loadFriends() async {
    try {
      final response = await _socialService.getFriends();

      if (response.isSuccess && response.data != null) {
        _friends = response.data!;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading friends: $e');
    }
  }

  Future<void> loadFriendRequests() async {
    try {
      final response = await _socialService.getFriendRequests();

      if (response.isSuccess && response.data != null) {
        _friendRequests = response.data!;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading friend requests: $e');
    }
  }

  Future<void> searchUsers(String query) async {
    debugPrint('🔍 [ViewModel] searchUsers() called with query: "$query"');

    if (query.length < 2) {
      debugPrint('⚠️ [ViewModel] Query too short (${query.length} chars), clearing results');
      _searchResults = [];
      notifyListeners();
      return;
    }

    try {
      debugPrint('🔍 [ViewModel] Calling social service...');

      final response = await _socialService.searchUsers(query);

      debugPrint('🔍 [ViewModel] Response received');
      debugPrint('   - isSuccess: ${response.isSuccess}');
      debugPrint('   - statusCode: ${response.statusCode}');
      debugPrint('   - message: ${response.message}');

      if (response.isSuccess && response.data != null) {
        _searchResults = response.data!;
        debugPrint('✅ [ViewModel] Found ${_searchResults.length} users');

        // İlk 3 sonucu logla
        if (_searchResults.isNotEmpty) {
          for (var i = 0; i < (_searchResults.length > 3 ? 3 : _searchResults.length); i++) {
            debugPrint('   User $i: ${_searchResults[i].displayName} (@${_searchResults[i].username})');
          }
        }

        notifyListeners();
      } else {
        debugPrint('❌ [ViewModel] Search failed: ${response.errorMessage}');
        _searchResults = [];
        notifyListeners();
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [ViewModel] Error searching users: $e');
      debugPrint('Stack trace: $stackTrace');
      _searchResults = [];
      notifyListeners();
    }
  }

  Future<bool> sendFriendRequest(int userId, BuildContext context) async {
    try {
      debugPrint('🤝 Sending friend request to user $userId');
      final response = await _socialService.sendFriendRequest(userId);

      debugPrint('🤝 Response: ${response.isSuccess}');

      if (response.isSuccess) {
        if (context.mounted) {
          // Düz snackbar yerine ortada animasyonlu "Gönderildi" rozeti.
          showSentAnimation(context, 'profile.friends.requestSent'.tr());
        }
        return true;
      } else {
        if (context.mounted) {
          CustomSnackBar.showError(
            context,
            response.errorMessage,
          );
        }
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error sending friend request: $e');
      if (context.mounted) {
        CustomSnackBar.showError(context, 'errors.general'.tr());
      }
      return false;
    }
  }

  Future<void> acceptFriendRequest(int requestId, BuildContext context) async {
    try {
      final response = await _socialService.acceptFriendRequest(requestId);

      if (response.isSuccess) {
        _friendRequests.removeWhere((r) => r.id == requestId);
        await loadFriends();
        if (context.mounted) {
          CustomSnackBar.showSuccess(context, 'profile.friends.requestAccepted'.tr());
        }
      } else {
        if (context.mounted) {
          CustomSnackBar.showError(
            context,
            response.errorMessage,
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        CustomSnackBar.showError(context, 'errors.general'.tr());
      }
      debugPrint('Error accepting friend request: $e');
    }
  }

  Future<void> rejectFriendRequest(int requestId, BuildContext context) async {
    try {
      final response = await _socialService.rejectFriendRequest(requestId);

      if (response.isSuccess) {
        _friendRequests.removeWhere((r) => r.id == requestId);
        notifyListeners();
        if (context.mounted) {
          CustomSnackBar.showInfo(context, 'profile.friends.requestRejected'.tr());
        }
      } else {
        if (context.mounted) {
          CustomSnackBar.showError(
            context,
            response.errorMessage,
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        CustomSnackBar.showError(context, 'errors.general'.tr());
      }
      debugPrint('Error rejecting friend request: $e');
    }
  }

  Future<void> unfriend(int userId, BuildContext context) async {
    try {
      final response = await _socialService.unfriend(userId);

      if (response.isSuccess) {
        _friends.removeWhere((f) => f.id == userId);
        notifyListeners();
        if (context.mounted) {
          CustomSnackBar.showInfo(context, 'profile.friends.unfriended'.tr());
        }
      } else {
        if (context.mounted) {
          CustomSnackBar.showError(
            context,
            response.errorMessage,
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        CustomSnackBar.showError(context, 'errors.general'.tr());
      }
      debugPrint('Error unfriending: $e');
    }
  }

  /// Takip edilenleri yükle (follow durumu için id kümesi).
  Future<void> loadFollowing() async {
    try {
      final response = await _socialService.getFollowing();
      if (response.isSuccess && response.data != null) {
        _following
          ..clear()
          ..addAll(response.data!.map((f) => f.id));
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading following: $e');
    }
  }

  Future<void> follow(int userId, BuildContext context) async {
    try {
      final response = await _socialService.follow(userId);
      if (response.isSuccess) {
        _following.add(userId);
        notifyListeners();
        if (context.mounted) {
          CustomSnackBar.showSuccess(context, 'profile.friends.followed'.tr());
        }
      } else if (context.mounted) {
        CustomSnackBar.showError(
            context, response.errorMessage);
      }
    } catch (e) {
      debugPrint('Error following user: $e');
      if (context.mounted) {
        CustomSnackBar.showError(context, 'errors.general'.tr());
      }
    }
  }

  Future<void> unfollow(int userId, BuildContext context) async {
    try {
      final response = await _socialService.unfollow(userId);
      if (response.isSuccess) {
        _following.remove(userId);
        notifyListeners();
        if (context.mounted) {
          CustomSnackBar.showInfo(context, 'profile.friends.unfollowed'.tr());
        }
      } else if (context.mounted) {
        CustomSnackBar.showError(
            context, response.errorMessage);
      }
    } catch (e) {
      debugPrint('Error unfollowing user: $e');
      if (context.mounted) {
        CustomSnackBar.showError(context, 'errors.general'.tr());
      }
    }
  }

  Future<UserProfile?> loadUserProfile(int userId) async {
    try {
      debugPrint('👤 Loading user profile for userId: $userId');

      final response = await _socialService.getUserProfile(userId);

      if (response.isSuccess && response.data != null) {
        debugPrint('✅ User profile loaded');
        return response.data!;
      } else {
        debugPrint('❌ Failed to load user profile: ${response.errorMessage}');
      }
    } catch (e) {
      debugPrint('❌ Error loading user profile: $e');
    }
    return null;
  }

  bool isFriend(int userId) {
    return _friends.any((friend) => friend.id == userId);
  }

  // ==================== ACHIEVEMENTS ====================

  Future<void> loadAchievements() async {
    try {
      debugPrint('🏆 [ViewModel] Loading ALL achievements (completed + locked)...');

      // ✅ completed parametresini kaldır - tüm başarımları getir
      final response = await _gamificationService.getAchievements();

      if (response.isSuccess && response.data != null) {
        _achievements = response.data!;

        final completed = _achievements.where((a) => a.isCompleted).length;
        final inProgress = _achievements.where((a) => !a.isCompleted && a.currentProgress > 0).length;
        final locked = _achievements.where((a) => !a.isCompleted && a.currentProgress == 0).length;

        debugPrint('✅ [ViewModel] Achievements loaded:');
        debugPrint('   Total: ${_achievements.length}');
        debugPrint('   Completed: $completed');
        debugPrint('   In Progress: $inProgress');
        debugPrint('   Locked: $locked');

        notifyListeners();
      } else {
        debugPrint('❌ [ViewModel] Failed to load achievements: ${response.errorMessage}');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [ViewModel] Error loading achievements: $e');
      debugPrint('Stack: $stackTrace');
    }
  }

  // ==================== REFRESH ====================

  Future<void> refreshAll() async {
    await Future.wait([
      loadProfile(),
      loadProfileStats(),
      loadFriends(),
      loadFriendRequests(),
      loadAchievements(),
      loadLevelInfo(),
    ]);
    _lastSyncedAt = DateTime.now();
    notifyListeners();
  }
}