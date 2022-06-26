import 'package:flutter/material.dart';

import 'package:kana_kit/kana_kit.dart';

import 'flow_direction.dart';
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
      required this.startValue,
      this.note,
      this.right,
      this.down})
      : super(key: key);

  final String character;
  final String startValue;
  final String identifier;
  final String? note;

  final String? right;
  final String? down;

  @override
  State<CrosswordCell> createState() => _CrosswordCellState();
}

class _CrosswordCellState extends State<CrosswordCell> {
  final _focusNode = FocusNode();
  late TextEditingController _textController;
  Color _fillColor = Colors.transparent;
  TextEditingValue _previousTCV = const TextEditingValue();

  GlobalStateWidget? _globalState;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.startValue);
    _previousTCV = _textController.value;
    _textController.addListener(_handleTextEvents);
    _focusNode.addListener(_handleFocusEvents);
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _focusCallback(String spill, bool changedDirection) {
    _focusNode.requestFocus();
    // typing through
    if (changedDirection == false || spill.isNotEmpty) {
      _textController.text = spill;
      _handleTextEvents();
    }
  }

  int _handleScoreEvents() {
    if (_textController.text == widget.character) {
      return 1;
    } else {
      if (_textController.text.isNotEmpty) {
        setState(() {
          _fillColor = Colors.pink;
        });
      }
      return 0;
    }
  }

  void _handleFocusEvents() {
    if (_focusNode.hasFocus) {
      setState(() {
        _fillColor = Colors.amber;
      });
    } else {
      setState(() {
        _fillColor = Colors.transparent;
      });
    }
  }

  void _handleResetEvents() {
    _fillColor = Colors.transparent;
    _textController.text = '';
  }

  void _handleTextEvents() {
    String text = _textController.text;

    // This is getting triggered by selection change events too
    if (text == _previousTCV.text) {
      return;
    }
    if (text.isEmpty) {
      _previousTCV = _textController.value;
      if (_globalState != null) {
        _globalState!.cellValues[widget.identifier] = '';
      }
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
        textType = newTextType;
        text = newText;
        // This will trigger _handleTextEvents once more
        // unless we disable the handler first...
        _textController.removeListener(_handleTextEvents);
        _textController.value = _textController.value.copyWith(
            text: text,
            selection: TextSelection(
                baseOffset: text.length, extentOffset: text.length),
            composing: TextRange.empty);
        _textController.addListener(_handleTextEvents);
      }
    }

    _previousTCV = _textController.value;
    _globalState!.cellValues[widget.identifier] = text;

    // navigation
    if (textType == targetType && _globalState != null) {
      final flowDirection = _globalState!.crosswordController.flowDirection;
      FocusingCallback? nextDown = _globalState!.focusCallbackMap[widget.down];
      FocusingCallback? nextRight =
          _globalState!.focusCallbackMap[widget.right];

      if ((nextRight ?? nextDown) != null) {
        final nextPick = (flowDirection == FlowDirection.right)
            ? (nextRight ?? nextDown)
            : (nextDown ?? nextRight);

        bool changedDirection = false;
        if (nextPick == nextDown && flowDirection != FlowDirection.down) {
          _globalState!.crosswordController.flowDirection = FlowDirection.down;
          changedDirection = true;
        } else if (nextPick == nextRight &&
            flowDirection != FlowDirection.right) {
          _globalState!.crosswordController.flowDirection = FlowDirection.right;
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

    _globalState = GlobalStateWidget.of(context)!;
    _globalState!.scoringCallbacks.add(_handleScoreEvents);
    _globalState!.resetCallbacks.add(_handleResetEvents);
    _globalState!.focusCallbackMap[widget.identifier] = _focusCallback;

    return Container(
        decoration: BoxDecoration(
          color: _fillColor,
          border: Border.all(color: Colors.blueAccent),
        ),
        child: Stack(children: <Widget>[
          widget.note == null
              ? const SizedBox.shrink()
              : Align(
                  alignment: Alignment.topLeft,
                  child: Text(widget.note!, textAlign: TextAlign.left)),
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
              decoration: InputDecoration(
                counterText: '',
                border: InputBorder.none,
                helperText: _globalState!.crosswordController.showHints
                    ? widget.character
                    : null,
              ),
            ),
          )
        ]));
  }
}
