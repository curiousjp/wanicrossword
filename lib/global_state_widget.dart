import 'package:flutter/material.dart';

import 'crossword_controller.dart';

typedef ScoringCallback = int Function();
typedef FocusingCallback = void Function(String);

class GlobalStateWidget extends InheritedWidget {
  final Map<String, FocusingCallback> focusCallbackMap = {};
  final List<ScoringCallback> scoringCallbacks = [];
  final crosswordController = CrosswordController();

  GlobalStateWidget({Key? key, required Widget child})
      : super(key: key, child: child);

  static GlobalStateWidget? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<GlobalStateWidget>();
  }

  @override
  bool updateShouldNotify(GlobalStateWidget oldWidget) =>
      focusCallbackMap != oldWidget.focusCallbackMap ||
      crosswordController != oldWidget.crosswordController;
}
