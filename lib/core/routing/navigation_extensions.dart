import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

extension NavigationContextX on BuildContext {
  void popOrGo(String fallbackRoute) {
    if (canPop()) {
      pop();
      return;
    }
    go(fallbackRoute);
  }
}
