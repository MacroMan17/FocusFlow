import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/category_local_datasource.dart';
import '../../data/datasources/settings_local_datasource.dart';
import '../../data/datasources/task_local_datasource.dart';
import '../../data/repositories/category_repository_impl.dart';
import '../../data/repositories/settings_repository_impl.dart';
import '../../data/repositories/task_repository_impl.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/entities/settings_entity.dart';
import '../../domain/entities/statistics_entity.dart';
import '../../domain/entities/task_entity.dart';
import '../../domain/repositories/category_repository.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../domain/repositories/task_repository.dart';
import '../../domain/usecases/category/create_category_use_case.dart';
import '../../domain/usecases/category/delete_category_use_case.dart';
import '../../domain/usecases/category/get_all_categories_use_case.dart';
import '../../domain/usecases/category/seed_default_categories_use_case.dart';
import '../../domain/usecases/category/update_category_use_case.dart';
import '../../domain/services/quote_service.dart';
import '../../domain/usecases/settings/get_settings_use_case.dart';
import '../../domain/usecases/settings/update_settings_use_case.dart';
import '../../domain/usecases/statistics/get_statistics_use_case.dart';
import '../../domain/usecases/task/complete_task_use_case.dart';
import '../../domain/usecases/task/create_task_use_case.dart';
import '../../domain/usecases/task/delete_task_use_case.dart';
import '../../domain/usecases/task/get_all_tasks_use_case.dart';
import '../../domain/usecases/task/get_filtered_tasks_use_case.dart';
import '../../domain/usecases/task/get_tasks_by_category_use_case.dart';
import '../../domain/usecases/task/get_tasks_by_date_use_case.dart';
import '../../domain/usecases/task/search_tasks_use_case.dart';
import '../../domain/usecases/task/update_task_use_case.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DATASOURCES
// ─────────────────────────────────────────────────────────────────────────────

final taskLocalDatasourceProvider = Provider<TaskLocalDatasource>(
  (_) => TaskLocalDatasource(),
);

final categoryLocalDatasourceProvider = Provider<CategoryLocalDatasource>(
  (_) => CategoryLocalDatasource(),
);

final settingsLocalDatasourceProvider = Provider<SettingsLocalDatasource>(
  (_) => SettingsLocalDatasource(),
);

// ─────────────────────────────────────────────────────────────────────────────
// REPOSITORIES
// ─────────────────────────────────────────────────────────────────────────────

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepositoryImpl(ref.watch(taskLocalDatasourceProvider));
});

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepositoryImpl(
    ref.watch(categoryLocalDatasourceProvider),
    ref.watch(taskLocalDatasourceProvider),
  );
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepositoryImpl(ref.watch(settingsLocalDatasourceProvider));
});

// ─────────────────────────────────────────────────────────────────────────────
// TASK USE CASES
// ─────────────────────────────────────────────────────────────────────────────

final createTaskUseCaseProvider = Provider<CreateTaskUseCase>(
  (ref) => CreateTaskUseCase(ref.watch(taskRepositoryProvider)),
);

final updateTaskUseCaseProvider = Provider<UpdateTaskUseCase>(
  (ref) => UpdateTaskUseCase(ref.watch(taskRepositoryProvider)),
);

final deleteTaskUseCaseProvider = Provider<DeleteTaskUseCase>(
  (ref) => DeleteTaskUseCase(ref.watch(taskRepositoryProvider)),
);

final completeTaskUseCaseProvider = Provider<CompleteTaskUseCase>(
  (ref) => CompleteTaskUseCase(ref.watch(taskRepositoryProvider)),
);

final uncompleteTaskUseCaseProvider = Provider<UncompleteTaskUseCase>(
  (ref) => UncompleteTaskUseCase(ref.watch(taskRepositoryProvider)),
);

final getAllTasksUseCaseProvider = Provider<GetAllTasksUseCase>(
  (ref) => GetAllTasksUseCase(ref.watch(taskRepositoryProvider)),
);

final getTodayTasksUseCaseProvider = Provider<GetTodayTasksUseCase>(
  (ref) => GetTodayTasksUseCase(ref.watch(taskRepositoryProvider)),
);

final getUpcomingTasksUseCaseProvider = Provider<GetUpcomingTasksUseCase>(
  (ref) => GetUpcomingTasksUseCase(ref.watch(taskRepositoryProvider)),
);

final getOverdueTasksUseCaseProvider = Provider<GetOverdueTasksUseCase>(
  (ref) => GetOverdueTasksUseCase(ref.watch(taskRepositoryProvider)),
);

final getCompletedTasksUseCaseProvider = Provider<GetCompletedTasksUseCase>(
  (ref) => GetCompletedTasksUseCase(ref.watch(taskRepositoryProvider)),
);

final getTaskByIdUseCaseProvider = Provider<GetTaskByIdUseCase>(
  (ref) => GetTaskByIdUseCase(ref.watch(taskRepositoryProvider)),
);

final getTasksByCategoryUseCaseProvider = Provider<GetTasksByCategoryUseCase>(
  (ref) => GetTasksByCategoryUseCase(ref.watch(taskRepositoryProvider)),
);

final getTasksByDateUseCaseProvider = Provider<GetTasksByDateUseCase>(
  (ref) => GetTasksByDateUseCase(ref.watch(taskRepositoryProvider)),
);

final searchTasksUseCaseProvider = Provider<SearchTasksUseCase>(
  (ref) => SearchTasksUseCase(ref.watch(taskRepositoryProvider)),
);

// ─────────────────────────────────────────────────────────────────────────────
// CATEGORY USE CASES
// ─────────────────────────────────────────────────────────────────────────────

final createCategoryUseCaseProvider = Provider<CreateCategoryUseCase>(
  (ref) => CreateCategoryUseCase(ref.watch(categoryRepositoryProvider)),
);

final updateCategoryUseCaseProvider = Provider<UpdateCategoryUseCase>(
  (ref) => UpdateCategoryUseCase(ref.watch(categoryRepositoryProvider)),
);

final deleteCategoryUseCaseProvider = Provider<DeleteCategoryUseCase>(
  (ref) => DeleteCategoryUseCase(ref.watch(categoryRepositoryProvider)),
);

final getAllCategoriesUseCaseProvider = Provider<GetAllCategoriesUseCase>(
  (ref) => GetAllCategoriesUseCase(ref.watch(categoryRepositoryProvider)),
);

final seedDefaultCategoriesUseCaseProvider =
    Provider<SeedDefaultCategoriesUseCase>(
  (ref) => SeedDefaultCategoriesUseCase(ref.watch(categoryRepositoryProvider)),
);

// ─────────────────────────────────────────────────────────────────────────────
// SETTINGS USE CASES
// ─────────────────────────────────────────────────────────────────────────────

final getSettingsUseCaseProvider = Provider<GetSettingsUseCase>(
  (ref) => GetSettingsUseCase(ref.watch(settingsRepositoryProvider)),
);

final updateSettingsUseCaseProvider = Provider<UpdateSettingsUseCase>(
  (ref) => UpdateSettingsUseCase(ref.watch(settingsRepositoryProvider)),
);

final updateThemeModeUseCaseProvider = Provider<UpdateThemeModeUseCase>(
  (ref) => UpdateThemeModeUseCase(ref.watch(settingsRepositoryProvider)),
);

final updateAccentColorUseCaseProvider = Provider<UpdateAccentColorUseCase>(
  (ref) => UpdateAccentColorUseCase(ref.watch(settingsRepositoryProvider)),
);

final completeOnboardingUseCaseProvider = Provider<CompleteOnboardingUseCase>(
  (ref) => CompleteOnboardingUseCase(ref.watch(settingsRepositoryProvider)),
);

final resetSettingsUseCaseProvider = Provider<ResetSettingsUseCase>(
  (ref) => ResetSettingsUseCase(ref.watch(settingsRepositoryProvider)),
);

// ─────────────────────────────────────────────────────────────────────────────
// STATISTICS USE CASE
// ─────────────────────────────────────────────────────────────────────────────

final getStatisticsUseCaseProvider = Provider<GetStatisticsUseCase>(
  (ref) => GetStatisticsUseCase(ref.watch(taskRepositoryProvider)),
);

final statisticsProvider = FutureProvider((ref) async {
  ref.watch(taskListNotifierProvider);
  final result = await ref.read(getStatisticsUseCaseProvider)();
  return result.fold((_) => StatisticsEntity.empty, (s) => s);
});

// ─────────────────────────────────────────────────────────────────────────────
// QUOTE SERVICE
// ─────────────────────────────────────────────────────────────────────────────

final quoteServiceProvider = Provider<QuoteService>(
  (ref) => QuoteService(ref.watch(settingsRepositoryProvider)),
);

final dailyQuoteProvider = FutureProvider<String>((ref) async {
  return ref.read(quoteServiceProvider).getTodayQuote();
});

// ─────────────────────────────────────────────────────────────────────────────
// SETTINGS NOTIFIER
// ─────────────────────────────────────────────────────────────────────────────

class SettingsNotifier extends StateNotifier<AsyncValue<SettingsEntity>> {
  final GetSettingsUseCase _getSettings;
  final UpdateSettingsUseCase _updateSettings;

  SettingsNotifier(this._getSettings, this._updateSettings)
      : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    final result = await _getSettings();
    result.fold(
      (f) => state = AsyncValue.error(f.message, StackTrace.current),
      (s) => state = AsyncValue.data(s),
    );
  }

  Future<void> update(SettingsEntity settings) async {
    final result = await _updateSettings(settings);
    result.fold(
      (f) => state = AsyncValue.error(f.message, StackTrace.current),
      (s) => state = AsyncValue.data(s),
    );
  }

  SettingsEntity get current =>
      state.maybeWhen(data: (s) => s, orElse: SettingsEntity.defaults);
}

final settingsNotifierProvider =
    StateNotifierProvider<SettingsNotifier, AsyncValue<SettingsEntity>>((ref) {
  return SettingsNotifier(
    ref.watch(getSettingsUseCaseProvider),
    ref.watch(updateSettingsUseCaseProvider),
  );
});

// ─────────────────────────────────────────────────────────────────────────────
// TASK LIST NOTIFIER
// ─────────────────────────────────────────────────────────────────────────────

enum TaskFilter { all, today, upcoming, overdue, completed }

enum TaskSort { createdAt, dueDate, priority, title }

class TaskListState {
  final List<TaskEntity> tasks;
  final TaskFilter filter;
  final TaskSort sort;
  final String? categoryFilter;
  final bool isLoading;
  final String? error;

  const TaskListState({
    this.tasks = const [],
    this.filter = TaskFilter.all,
    this.sort = TaskSort.createdAt,
    this.categoryFilter,
    this.isLoading = false,
    this.error,
  });

  TaskListState copyWith({
    List<TaskEntity>? tasks,
    TaskFilter? filter,
    TaskSort? sort,
    String? categoryFilter,
    bool clearCategoryFilter = false,
    bool? isLoading,
    String? error,
  }) {
    return TaskListState(
      tasks: tasks ?? this.tasks,
      filter: filter ?? this.filter,
      sort: sort ?? this.sort,
      categoryFilter:
          clearCategoryFilter ? null : categoryFilter ?? this.categoryFilter,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  List<TaskEntity> get filteredAndSorted {
    var list = List<TaskEntity>.from(tasks);

    // Apply category filter
    if (categoryFilter != null) {
      list = list.where((t) => t.categoryId == categoryFilter).toList();
    }

    // Apply filter tab
    switch (filter) {
      case TaskFilter.all:
        list = list.where((t) => !t.isCompleted).toList();
        break;
      case TaskFilter.today:
        list = list.where((t) => t.isDueToday && !t.isCompleted).toList();
        break;
      case TaskFilter.upcoming:
        list = list.where((t) => t.isUpcoming && !t.isCompleted).toList();
        break;
      case TaskFilter.overdue:
        list = list.where((t) => t.isOverdue).toList();
        break;
      case TaskFilter.completed:
        list = list.where((t) => t.isCompleted).toList();
        break;
    }

    // Apply sort
    switch (sort) {
      case TaskSort.createdAt:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case TaskSort.dueDate:
        list.sort((a, b) {
          if (a.dueDate == null && b.dueDate == null) return 0;
          if (a.dueDate == null) return 1;
          if (b.dueDate == null) return -1;
          return a.dueDate!.compareTo(b.dueDate!);
        });
        break;
      case TaskSort.priority:
        list.sort((a, b) => b.priority.value.compareTo(a.priority.value));
        break;
      case TaskSort.title:
        list.sort((a, b) => a.title.compareTo(b.title));
        break;
    }

    return list;
  }
}

class TaskListNotifier extends StateNotifier<TaskListState> {
  final GetAllTasksUseCase _getAllTasks;
  final Ref _ref;

  TaskListNotifier(this._getAllTasks, this._ref) : super(const TaskListState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    final result = await _getAllTasks();
    result.fold(
      (f) => state = state.copyWith(isLoading: false, error: f.message),
      (tasks) => state = state.copyWith(tasks: tasks, isLoading: false),
    );
  }

  void setFilter(TaskFilter filter) {
    state = state.copyWith(filter: filter);
  }

  void setSort(TaskSort sort) {
    state = state.copyWith(sort: sort);
  }

  void setCategoryFilter(String? categoryId) {
    if (categoryId == null) {
      state = state.copyWith(clearCategoryFilter: true);
    } else {
      state = state.copyWith(categoryFilter: categoryId);
    }
  }

  Future<void> toggleComplete(String taskId, bool currentlyComplete) async {
    if (currentlyComplete) {
      await _ref.read(uncompleteTaskUseCaseProvider)(taskId);
    } else {
      await _ref.read(completeTaskUseCaseProvider)(taskId);
    }
    await load();
  }

  Future<void> deleteTask(String taskId) async {
    await _ref.read(deleteTaskUseCaseProvider)(taskId);
    await load();
  }
}

final taskListNotifierProvider =
    StateNotifierProvider<TaskListNotifier, TaskListState>((ref) {
  return TaskListNotifier(ref.watch(getAllTasksUseCaseProvider), ref);
});

// ─────────────────────────────────────────────────────────────────────────────
// CATEGORY LIST NOTIFIER
// ─────────────────────────────────────────────────────────────────────────────

class CategoryListNotifier
    extends StateNotifier<AsyncValue<List<CategoryEntity>>> {
  final GetAllCategoriesUseCase _getAll;
  final SeedDefaultCategoriesUseCase _seed;

  CategoryListNotifier(this._getAll, this._seed)
      : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    await _seed();
    await load();
  }

  Future<void> load() async {
    final result = await _getAll();
    result.fold(
      (f) => state = AsyncValue.error(f.message, StackTrace.current),
      (cats) => state = AsyncValue.data(cats),
    );
  }
}

final categoryListNotifierProvider = StateNotifierProvider<CategoryListNotifier,
    AsyncValue<List<CategoryEntity>>>((ref) {
  return CategoryListNotifier(
    ref.watch(getAllCategoriesUseCaseProvider),
    ref.watch(seedDefaultCategoriesUseCaseProvider),
  );
});
