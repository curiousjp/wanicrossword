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

  void _focusCallback(String spill) {
    _focusNode.requestFocus();
    _textController.text = spill;
    if (spill.isNotEmpty) {
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

    if (text.isEmpty) {
      return;
    }

    final clueType = detectKanaKitType(widget.character);
    var textType = detectKanaKitType(text);
    var spill = '';

    // There is one exception to coercion - do not coerce 'n' when the target
    // type is katakana or hiragana - this is to stop it from getting turned
    // into ん and blocking kana like の / ノ.
    final blockConversion = (text == 'n' &&
        (clueType == KanaKitType.h || clueType == KanaKitType.k));

    // Let's attempt coercion.
    if (clueType != textType && blockConversion == false) {
      // restore the 'n' workaround
      if (text == 'nn') {
        text = 'n';
      }

      var newText = convertKanaKitType(text, clueType);
      final newTextType = detectKanaKitType(newText);
      // Success
      if (newTextType == clueType) {
        if (newText.length > 1) {
          spill = newText.substring(1);
          newText = newText.substring(0, 1);
        }
        _textController.value = _textController.value.copyWith(
            text: newText,
            selection: TextSelection(
                baseOffset: newText.length, extentOffset: newText.length),
            composing: TextRange.empty);
        text = newText;
        textType = newTextType;
      }
    }

    // navigation
    if (textType == clueType &&
        _globalCrosswordController != null &&
        _globalFocusCallbackMap != null) {
      final flowDirection = _globalCrosswordController!.flowDirection;
      FocusingCallback? nextDown = _globalFocusCallbackMap![widget.down];
      FocusingCallback? nextRight = _globalFocusCallbackMap![widget.right];

      if ((nextRight ?? nextDown) != null) {
        final nextPick = (flowDirection == FlowDirection.right)
            ? (nextRight ?? nextDown)
            : (nextDown ?? nextRight);

        if (nextPick == nextDown) {
          _globalCrosswordController!.flowDirection = FlowDirection.down;
        } else {
          _globalCrosswordController!.flowDirection = FlowDirection.right;
        }
        nextPick!(spill);
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
