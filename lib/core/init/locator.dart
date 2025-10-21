import 'package:base/service/social/social_service.dart';
import 'package:get_it/get_it.dart';

// Services
import '../../service/auth/auth_service.dart';
import '../../service/habit/habit_service.dart';
import '../../service/profile/profile_service.dart';
import '../../service/settings/settings_service.dart';
import '../../service/task/task_service.dart';
import '../../service/note/note_service.dart';
import '../../service/budget/budget_service.dart';
import '../../service/expense/expense_service.dart';
import '../../service/subscription/subscription_service.dart';
import '../../service/diary/diary_service.dart';
import '../../service/gamification/gamification_service.dart';
import '../../service/notification/notification_service.dart';
import '../../service/utility/utility_feedback_service.dart';

final GetIt locator = GetIt.instance;

void setupLocator() {
  // Auth & Profile Services
  locator.registerLazySingleton<IAuthService>(() => AuthService());
  locator.registerLazySingleton<IProfileService>(() => ProfileService());
  locator.registerLazySingleton<ISocialService>(() => SocialService());
  locator.registerLazySingleton<ISettingsService>(() => SettingsService());

  // Content Services
  locator.registerLazySingleton<IHabitService>(() => HabitService());
  locator.registerLazySingleton<ITaskService>(() => TaskService());
  locator.registerLazySingleton<INoteService>(() => NoteService());
  locator.registerLazySingleton<IDiaryService>(() => DiaryService());

  // Finance Services
  locator.registerLazySingleton<IBudgetService>(() => BudgetService());
  locator.registerLazySingleton<IExpenseService>(() => ExpenseService());
  locator.registerLazySingleton<ISubscriptionService>(() => SubscriptionService());

  // Gamification & Social Services
  locator.registerLazySingleton<IGamificationService>(() => GamificationService());
  locator.registerLazySingleton<INotificationService>(() => NotificationService());

  // Utility Services
  locator.registerLazySingleton<IUtilityService>(() => UtilityService());
  locator.registerLazySingleton<IFeedbackService>(() => FeedbackService());
}

// Helper getters for easy access (optional)
IAuthService get authService => locator<IAuthService>();
IProfileService get profileService => locator<IProfileService>();
ISocialService get socialService => locator<ISocialService>();
ISettingsService get settingsService => locator<ISettingsService>();
IHabitService get habitService => locator<IHabitService>();
ITaskService get taskService => locator<ITaskService>();
INoteService get noteService => locator<INoteService>();
IDiaryService get diaryService => locator<IDiaryService>();
IBudgetService get budgetService => locator<IBudgetService>();
IExpenseService get expenseService => locator<IExpenseService>();
ISubscriptionService get subscriptionService => locator<ISubscriptionService>();
IGamificationService get gamificationService => locator<IGamificationService>();
INotificationService get notificationService => locator<INotificationService>();
IUtilityService get utilityService => locator<IUtilityService>();
IFeedbackService get feedbackService => locator<IFeedbackService>();