import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
      required this.xPosition,
      required this.yPosition,
      required this.startValue,
      this.note})
      : super(key: key);

  final int xPosition;
  final int yPosition;

  final String character;
  final String startValue;
  final String? note;

  @override
  State<CrosswordCell> createState() => _CrosswordCellState();
}

class _CrosswordCellState extends State<CrosswordCell> {
  final _focusNode = FocusNode();
  final _keyEventFocusNode = FocusNode();
  late TextEditingController _textController;
  late GlobalStateWidget _globalState;
  bool _textEventHappened = false;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.startValue);
    _textController.addListener(_handleTextEvents);
    _focusNode.addListener(_handleFocusEvents);
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _keyEventFocusNode.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(CrosswordCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_textController.text != widget.startValue) {
      _textController.text = widget.startValue;
    }
  }

  void _focusCallback(String spill, bool changedDirection) {
    _focusNode.requestFocus();
    if (spill.isNotEmpty) {
      _textController.value = TextEditingValue(
          text: spill,
          selection: TextSelection(baseOffset: 0, extentOffset: spill.length));
    } else {
      _textController.value = _textController.value.copyWith(
          selection: TextSelection(
              baseOffset: 0, extentOffset: _textController.text.length));
    }
  }

  void _handleFocusEvents() {
    if (_focusNode.hasFocus) {
      setState(() {
        // try to have a legal traversal direction set
        if (_globalState.crosswordController.flowDirection ==
            FlowDirection.right) {
          if (_globalState.focusCallbackMap
                  .get(widget.xPosition + 1, widget.yPosition) ==
              null) {
            _globalState.crosswordController.flowDirection ==
                FlowDirection.down;
          }
        } else if (_globalState.crosswordController.flowDirection ==
            FlowDirection.down) {
          if (_globalState.focusCallbackMap
                  .get(widget.xPosition, widget.yPosition + 1) ==
              null) {
            _globalState.crosswordController.flowDirection ==
                FlowDirection.right;
          }
        }
        // set highlight colour
        _globalState.cellColourValues
            .set(widget.xPosition, widget.yPosition, Colors.amber);
      });
    } else {
      setState(() {
        _globalState.cellColourValues
            .remove(widget.xPosition, widget.yPosition);
      });
    }
  }

  void _handleTextEvents() {
    String text = _textController.text;
    final oldText =
        _globalState.cellCurrentValues.get(widget.xPosition, widget.yPosition);

    _textEventHappened = true;

    if (text.isEmpty) {
      _globalState.cellCurrentValues
          .set(widget.xPosition, widget.yPosition, '');
      return;
    }

    if (text == oldText) {
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
        // only spill sutegana / stopped consonants
        // uう -> うう : should not spill
        // kyo -> きょ : should spill
        // ddo -> っど : should spill
        final hasSutegana =
            RegExp(r'^.?[ゃゅょぁぃぅぇぉっゎァィゥェォヵㇰヶㇱㇲッㇳㇴㇵㇶㇷㇷ゚ㇸㇹㇺャュョㇻㇼㇽㇾㇿヮ]+.*$');
        if (newText.length > 1 && hasSutegana.hasMatch(newText)) {
          // This is a very silly workaround, but here's why it happens:
          //   as you've noticed upstream, at the moment we return early when
          //   the string being set is the same as the string already
          //   registered as in this cell... this is a workaround for some
          //   annoying behaviour with selections. Doing this conversion
          //   ensures that it will be different to whatever is there already,
          //   allowing it to pass through (assuming the puzzle is homogenous).
          spill = convertKanaKitType(newText.substring(1), KanaKitType.k);
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

    _globalState.cellCurrentValues
        .set(widget.xPosition, widget.yPosition, text);

    // don't autoadvance the cell if there's the wrong number of chars in it
    if (text.length != widget.character.length) {
      return;
    }

    // navigation
    if (textType == targetType) {
      final flowDirection = _globalState.crosswordController.flowDirection;

      FocusingCallback? nextDown = _globalState.focusCallbackMap
          .get(widget.xPosition, widget.yPosition + 1);
      FocusingCallback? nextRight = _globalState.focusCallbackMap
          .get(widget.xPosition + 1, widget.yPosition);

      if ((nextRight ?? nextDown) != null) {
        final nextPick = (flowDirection == FlowDirection.right)
            ? (nextRight ?? nextDown)
            : (nextDown ?? nextRight);

        bool changedDirection = false;
        if (nextPick == nextDown && flowDirection != FlowDirection.down) {
          _globalState.crosswordController.flowDirection = FlowDirection.down;
          changedDirection = true;
        } else if (nextPick == nextRight &&
            flowDirection != FlowDirection.right) {
          _globalState.crosswordController.flowDirection = FlowDirection.right;
          changedDirection = true;
        }
        nextPick!(spill, changedDirection);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    _globalState = GlobalStateWidget.of(context)!;

    if (widget.character.isEmpty) {
      _globalState.focusCallbackMap.remove(widget.xPosition, widget.yPosition);
      return Container(
          decoration: BoxDecoration(
              color: Colors.black87,
              border: Border.all(color: Colors.blueAccent)));
    }

    _globalState.focusCallbackMap
        .set(widget.xPosition, widget.yPosition, _focusCallback);

    return Container(
        decoration: BoxDecoration(
          color: _globalState.cellColourValues
              .get(widget.xPosition, widget.yPosition),
          border: Border.all(color: Colors.blueAccent),
        ),
        child: Stack(children: <Widget>[
          widget.note == null
              ? const SizedBox.shrink()
              : Align(
                  alignment: Alignment.topLeft,
                  child: Text(widget.note!,
                      style: DefaultTextStyle.of(context)
                          .style
                          .apply(fontSizeFactor: 0.75),
                      textAlign: TextAlign.left)),
          Align(
            alignment: Alignment.center,
            child: KeyboardListener(
              focusNode: _keyEventFocusNode,
              onKeyEvent: (ke) {
                if (ke.runtimeType == KeyUpEvent ||
                    ke.runtimeType == KeyRepeatEvent) {
                  FocusingCallback? traverseTarget;

                  if (ke.logicalKey.keyLabel == 'Backspace' &&
                      _textController.text.isEmpty) {
                    if (_textEventHappened) {
                      // this backspace was actually used to change the text object
                      // let's wait for the next one
                      _textEventHappened = false;
                      return;
                    } else {
                      if (_globalState.crosswordController.flowDirection ==
                          FlowDirection.right) {
                        traverseTarget = _globalState.focusCallbackMap
                            .get(widget.xPosition - 1, widget.yPosition);
                      }
                      if (_globalState.crosswordController.flowDirection ==
                          FlowDirection.down) {
                        traverseTarget = _globalState.focusCallbackMap
                            .get(widget.xPosition, widget.yPosition - 1);
                      }
                    }
                  }

                  if (ke.logicalKey.keyLabel == 'Arrow Left') {
                    traverseTarget = _globalState.focusCallbackMap
                        .get(widget.xPosition - 1, widget.yPosition);
                  }

                  if (ke.logicalKey.keyLabel == 'Arrow Right') {
                    traverseTarget = _globalState.focusCallbackMap
                        .get(widget.xPosition + 1, widget.yPosition);
                  }

                  if (ke.logicalKey.keyLabel == 'Arrow Up') {
                    // try to move up
                    traverseTarget = _globalState.focusCallbackMap
                        .get(widget.xPosition, widget.yPosition - 1);
                  }

                  if (ke.logicalKey.keyLabel == 'Arrow Down') {
                    // try to move down
                    traverseTarget = _globalState.focusCallbackMap
                        .get(widget.xPosition, widget.yPosition + 1);
                  }

                  if (traverseTarget != null) {
                    traverseTarget('', true);
                  }
                }
              },
              child: TextField(
                maxLength: 3,
                focusNode: _focusNode,
                enabled: true,
                textAlignVertical: TextAlignVertical.center,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black),
                controller: _textController,
                decoration: InputDecoration(
                  counterText: '',
                  border: InputBorder.none,
                  helperText: _globalState.crosswordController.showHints
                      ? widget.character
                      : null,
                ),
              ),
            ),
          )
        ]));
  }
}
