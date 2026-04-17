# GetX Feature — Detailed Implementation Guide

## Complete File Templates

### lib/controllers/<feature>_controller.dart
```dart
import 'package:get/get.dart';
import '../core/base/base_controller.dart';
import '../features/<feature>/repositories/<feature>_repository.dart';

class <Feature>Controller extends BaseController {
  final <Feature>Repository _repo = Get.find();

  // ── Reactive State ─────────────────────────────────────────────
  final items = <ItemModel>[].obs;
  final selectedItem = Rxn<ItemModel>();

  // ── Lifecycle ──────────────────────────────────────────────────
  @override
  void onInit() {
    super.onInit();
    fetchItems();
  }

  // ── Actions ───────────────────────────────────────────────────
  Future<void> fetchItems() async {
    setLoading(true);
    final result = await _repo.getItems();
    result.fold(
      (failure) => setError(failure.message),
      (data) => items.assignAll(data),
    );
    setLoading(false);
  }
}
```

### lib/core/base/base_controller.dart
```dart
import 'package:get/get.dart';

abstract class BaseController extends GetxController {
  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final hasError = false.obs;

  void setLoading(bool value) => isLoading.value = value;

  void setError(String message) {
    errorMessage.value = message;
    hasError.value = true;
  }

  void clearError() {
    errorMessage.value = '';
    hasError.value = false;
  }
}
```

### lib/features/<feature>/views/<feature>_view.dart
```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/<feature>_controller.dart';
import '../../../core/theme/e_colors.dart';
import '../../../core/theme/e_spacing.dart';

class <Feature>View extends GetView<<Feature>Controller> {
  const <Feature>View({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EColors.background,
      appBar: AppBar(title: const Text('<Feature>')),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.hasError.value) {
          return Center(child: Text(controller.errorMessage.value));
        }
        return _Body();
      }),
    );
  }
}

class _Body extends GetView<<Feature>Controller> {
  const _Body();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.all(ESpacing.md),
      itemCount: controller.items.length,
      itemBuilder: (_, i) => _ItemCard(item: controller.items[i]),
    );
  }
}
```

### lib/features/<feature>/repositories/<feature>_repository.dart
```dart
import 'package:dartz/dartz.dart';
import 'package:get/get.dart';
import '../../../core/base/base_repository.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../models/<feature>_model.dart';

class <Feature>Repository extends BaseRepository {
  final ApiClient _client = Get.find();

  Future<Either<Failure, List<<Feature>Model>>> getItems() async {
    try {
      final res = await _client.get(ApiEndpoints.<feature>);
      final list = (res.data as List)
          .map((e) => <Feature>Model.fromJson(e))
          .toList();
      return Right(list);
    } on DioException catch (e) {
      return Left(ApiFailure.fromDioError(e));
    }
  }
}
```

### lib/features/<feature>/models/<feature>_model.dart
```dart
import 'package:json_annotation/json_annotation.dart';
part '<feature>_model.g.dart';

@JsonSerializable()
class <Feature>Model {
  final String id;
  final String name;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  const <Feature>Model({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  factory <Feature>Model.fromJson(Map<String, dynamic> json) =>
      _$<Feature>ModelFromJson(json);

  Map<String, dynamic> toJson() => _$<Feature>ModelToJson(this);
}
```

### lib/features/<feature>/<feature>.dart (barrel)
```dart
// Views
export 'views/<feature>_view.dart';

// Models
export 'models/<feature>_model.dart';

// Repository (only export if other features need it — typically don't)
// export 'repositories/<feature>_repository.dart';
```

### lib/bindings/route_bindings/<feature>_binding.dart
```dart
import 'package:get/get.dart';
import '../../controllers/<feature>_controller.dart';
import '../../features/<feature>/repositories/<feature>_repository.dart';

class <Feature>Binding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<<Feature>Repository>(() => <Feature>Repository());
    Get.lazyPut<<Feature>Controller>(() => <Feature>Controller());
  }
}
```

### lib/routes/routes.dart (add entry)
```dart
abstract class Routes {
  static const splash    = '/';
  static const login     = '/login';
  static const dashboard = '/dashboard';
  static const <feature> = '/<feature>';  // ← add this
}
```

### lib/routes/app_pages.dart (add GetPage)
```dart
GetPage(
  name: Routes.<feature>,
  page: () => const <Feature>View(),
  binding: <Feature>Binding(),
  transition: Transition.fadeIn,
),
```

## Registering Always-On Controllers in AppBindings
For controllers that are needed globally (e.g., AuthController):

```dart
// lib/bindings/app_bindings.dart
class AppBindings extends Bindings {
  @override
  void dependencies() {
    // Services (permanent)
    Get.put<ApiClient>(ApiClient(), permanent: true);
    Get.put<StorageService>(StorageService(), permanent: true);

    // Global controllers (fenix: recreated if destroyed)
    Get.lazyPut<AuthController>(() => AuthController(), fenix: true);
  }
}
```

## Testing a GetX Controller
```dart
// test/controllers/<feature>_controller_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([<Feature>Repository])
void main() {
  late <Feature>Controller controller;
  late Mock<Feature>Repository mockRepo;

  setUp(() {
    Get.testMode = true;
    mockRepo = Mock<Feature>Repository();
    Get.put<<Feature>Repository>(mockRepo);
    controller = Get.put(<Feature>Controller());
  });

  tearDown(() => Get.reset());

  test('fetchItems populates items on success', () async {
    when(mockRepo.getItems()).thenAnswer(
      (_) async => Right([<Feature>Model(id: '1', name: 'Test', createdAt: DateTime.now())]),
    );
    await controller.fetchItems();
    expect(controller.items.length, 1);
    expect(controller.hasError.value, false);
  });
}
```
