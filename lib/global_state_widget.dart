import 'dart:collection';

import 'package:flutter/material.dart';

import 'crossword_controller.dart';

typedef FocusingCallback = void Function(String, bool);

class CartesianMap<T> {
  final _innerMap = LinkedHashMap<List<int>, T>(
      equals: (list1, list2) {
        if (list1.length != 2 || list2.length != 2) {
          return false;
        }
        if (list1[0] != list2[0] || list1[1] != list2[1]) {
          return false;
        }
        return true;
      },
      hashCode: Object.hashAll);

  CartesianMap() : super();

  T? get(int x, int y) => _innerMap[[x, y]];
  void set(int x, int y, T value) {
    _innerMap[[x, y]] = value;
  }

  Iterable<MapEntry<List<int>, T>> get entries => _innerMap.entries;

  void remove(int x, int y) {
    _innerMap.remove([x, y]);
  }

  void clear() {
    _innerMap.clear();
  }
}

class CartesianMapDefault<T> extends CartesianMap<T> {
  final T _default;
  CartesianMapDefault(this._default) : super();
  @override
  T? get(int x, int y) => _innerMap[[x, y]] ?? _default;
}

class GlobalStateWidget extends InheritedWidget {
  final focusCallbackMap = CartesianMap<FocusingCallback>();

  final cellCurrentValues = CartesianMap<String>();
  final cellColourValues = CartesianMapDefault<Color>(Colors.transparent);

  final crosswordController = CrosswordController();

  GlobalStateWidget({Key? key, required Widget child})
      : super(key: key, child: child);

  static GlobalStateWidget? of(BuildContext context) {
    var state = context.dependOnInheritedWidgetOfExactType<GlobalStateWidget>();
    assert(state != null, "Failed to retrieve the Global State Widget");
    return state;
  }

  int cartesianToIndex(int x, int y) =>
      crosswordController.getPuzzle().size * (y - 1) + (x - 1) + 1;
  List<int> indexToCartesian(int i) {
    final zeroIndex = i - 1;
    final width = crosswordController.getPuzzle().size;
    return [(zeroIndex % width) + 1, (zeroIndex ~/ width) + 1];
  }

  void resetPlaystate() {
    cellColourValues.clear();
    cellCurrentValues.clear();
  }

  List<int> scorePlaystate() {
    final targets = crosswordController.getPuzzle().tiles;
    var maximumScore = 0;
    var score = 0;
    for (var offset = 0; offset < targets.length; offset++) {
      if (targets[offset] != '') {
        final coords = indexToCartesian(offset + 1);
        final currentValue = cellCurrentValues.get(coords[0], coords[1]) ?? "";
        if (targets[offset] == currentValue) {
          score++;
        } else if (currentValue.isNotEmpty) {
          cellColourValues.set(coords[0], coords[1], Colors.pink);
        }
        maximumScore++;
      }
    }
    return [score, maximumScore];
  }

  @override
  bool updateShouldNotify(GlobalStateWidget oldWidget) =>
      focusCallbackMap != oldWidget.focusCallbackMap ||
      crosswordController != oldWidget.crosswordController ||
      cellCurrentValues != oldWidget.cellCurrentValues ||
      cellColourValues != oldWidget.cellColourValues;
}
