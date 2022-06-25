import 'package:flutter/material.dart';

import 'package:kana_kit/kana_kit.dart';

import 'flow_direction.dart';
import 'crossword_controller.dart';
import 'global_state_widget.dart';

// Some kanaKit helpers I didn't want to put anywhere else
enum KanaKitType { r, k, h, m, n }

KanaKitType detectKanaKitType(String input) {
  if (input.isEmpty) {
    return KanaKitType.n;
  }
  const kanaKit = KanaKit();
  if (kanaKit.isHiragana(input)) {
    return KanaKitType.h;
  }
  if (kanaKit.isKatakana(input)) {
    return KanaKitType.k;
  }
  if (kanaKit.isRomaji(input)) {
    return KanaKitType.r;
  }
  return KanaKitType.m;
}

String convertKanaKitType(String input, KanaKitType kkt) {
  if (input.isEmpty) {
    return input;
  }
  const kanaKit = KanaKit();
  if (kkt == KanaKitType.r) {
    return kanaKit.toRomaji(input);
  }
  if (kkt == KanaKitType.h) {
    return kanaKit.toHiragana(input);
  }
  if (kkt == KanaKitType.k) {
    return kanaKit.toKatakana(input);
  }
  return input;
}

class CrosswordCell extends StatefulWidget {
  const CrosswordCell(
      {Key? key,
      required this.character,
      required this.identifier,
      this.note,
      this.right,
      this.down})
      : super(key: key);

  final String character;
  final String identifier;
  final String? note;

  final String? right;
  final String? down;

  @override
  State<CrosswordCell> createState() => _CrosswordCellState();
}

class _CrosswordCellState extends State<CrosswordCell> {
  final _focusNode = FocusNode();
  final _textController = TextEditingController(text: '');
  TextEditingValue _previousTCV = const TextEditingValue();

  Map<String, FocusingCallback>? _globalFocusCallbackMap;
  CrosswordController? _globalCrosswordController;

  @override
  void initState() {
    super.initState();
    _textController.addListener(_handleTextEvents);
  }

  @override
  void dispose() {
    if (_globalFocusCallbackMap != null) {
      _globalFocusCallbackMap!.remove(_focusCallback);
    }
    _focusNode.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _focusCallback(String spill, bool changedDirection) {
    _focusNode.requestFocus();
    // typing through
    if (changedDirection == false) {
      _textController.text = spill;
      _handleTextEvents();
    }
  }

  int _score() {
    if (_textController.text == widget.character) {
      return 1;
    } else {
      _textController.text = '';
      return 0;
    }
  }

  void _handleTextEvents() {
    String text = _textController.text;

    // This is getting triggered by selection change events too
    if (text == _previousTCV.text) {
      return;
    }
    _previousTCV = _textController.value;
    if (text.isEmpty) {
      return;
    }

    final targetType = detectKanaKitType(widget.character);
    var textType = detectKanaKitType(text);
    var spill = '';

    // There is one exception to coercion - do not coerce 'n' when the target
    // type is katakana or hiragana - this is to stop it from getting turned
    // into ん and blocking kana like の / ノ.
    final blockConversion = (text == 'n' &&
        (targetType == KanaKitType.h || targetType == KanaKitType.k));

    // Let's attempt coercion.
    if (targetType != textType && blockConversion == false) {
      // restore the 'n' workaround
      if (text == 'nn') {
        text = 'n';
      }

      var newText = convertKanaKitType(text, targetType);
      final newTextType = detectKanaKitType(newText);
      // Success?
      if (newTextType == targetType) {
        if (newText.length > 1) {
          spill = newText.substring(1);
          newText = newText.substring(0, 1);
        }
        // This will trigger _handleTextEvents once more
        _textController.value = _textController.value.copyWith(
            text: newText,
            selection: TextSelection(
                baseOffset: newText.length, extentOffset: newText.length),
            composing: TextRange.empty);
        return;
      }
    }

    // navigation
    if (textType == targetType &&
        _globalCrosswordController != null &&
        _globalFocusCallbackMap != null) {
      final flowDirection = _globalCrosswordController!.flowDirection;
      FocusingCallback? nextDown = _globalFocusCallbackMap![widget.down];
      FocusingCallback? nextRight = _globalFocusCallbackMap![widget.right];

      if ((nextRight ?? nextDown) != null) {
        final nextPick = (flowDirection == FlowDirection.right)
            ? (nextRight ?? nextDown)
            : (nextDown ?? nextRight);

        bool changedDirection = false;
        if (nextPick == nextDown &&
            _globalCrosswordController!.flowDirection != FlowDirection.down) {
          _globalCrosswordController!.flowDirection = FlowDirection.down;
          changedDirection = true;
        } else if (nextPick == nextRight &&
            _globalCrosswordController!.flowDirection != FlowDirection.right) {
          _globalCrosswordController!.flowDirection = FlowDirection.right;
          changedDirection = true;
        }
        nextPick!(spill, changedDirection);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.character.isEmpty) {
      return Container(
          decoration: BoxDecoration(
              color: Colors.black,
              border: Border.all(color: Colors.blueAccent)));
    }

    _globalFocusCallbackMap = GlobalStateWidget.of(context)!.focusCallbackMap;
    _globalCrosswordController =
        GlobalStateWidget.of(context)!.crosswordController;
    GlobalStateWidget.of(context)!.scoringCallbacks.add(_score);
    _globalFocusCallbackMap![widget.identifier] = _focusCallback;
    _textController.clear();

    final numberIndicator = widget.note == null
        ? const SizedBox.shrink()
        : Align(
            alignment: Alignment.topLeft,
            child: Text(widget.note!, textAlign: TextAlign.left));

    return Container(
        decoration: BoxDecoration(border: Border.all(color: Colors.blueAccent)),
        child: Stack(children: <Widget>[
          numberIndicator,
          Align(
            alignment: Alignment.center,
            child: TextField(
              maxLength: 3,
              enabled: true,
              textAlignVertical: TextAlignVertical.center,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black),
              focusNode: _focusNode,
              controller: _textController,
              decoration: const InputDecoration(
                counterText: '',
                border: InputBorder.none,
                //helperText: widget.character,
              ),
            ),
          )
        ]));
  }
}
