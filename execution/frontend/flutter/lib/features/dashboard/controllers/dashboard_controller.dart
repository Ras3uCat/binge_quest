import 'package:get/get.dart';

class DashboardController extends GetxController {
  static DashboardController get to => Get.find();

  final selectedIndex = 0.obs;
  final libraryTabIndex = 0.obs;

  void navigateToTab(int index, {int libraryTab = 0}) {
    if (index == 1) libraryTabIndex.value = libraryTab;
    selectedIndex.value = index;
  }
}
