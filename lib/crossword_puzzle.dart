import 'dart:collection';
import 'flow_direction.dart';
import 'dart:math';

final _rng = Random();

class CrosswordPuzzle {
  final int _sideLength;
  late List<List<String>> _squares;
  final SplayTreeMap<int, String> _downClues = SplayTreeMap();
  final SplayTreeMap<int, String> _acrossClues = SplayTreeMap();
  var _score = 0;

  String _getSquareValue(int x, int y) {
    // out of bounds
    if (x < 0 || x >= _sideLength || y < 0 || y >= _sideLength) {
      return '.';
    }
    return _squares[y][x];
  }

  bool _isSquareEmpty(int x, int y) {
    final value = _getSquareValue(x, y);
    return (value == '' || value == '.');
  }

  List<List<int>> _findLetter(String needle) {
    List<List<int>> result = [];
    for (var y = 0; y < _sideLength; y++) {
      for (var x = 0; x < _sideLength; x++) {
        if (_getSquareValue(x, y) == needle) {
          result.add([x, y]);
        }
      }
    }
    return result;
  }

  List<dynamic> _findStart(String needle) {
    var result = [];
    for (var i = 0; i < needle.length; i++) {
      final huntLetter = needle[i];
      final letterInstances = _findLetter(huntLetter);
      // test if these are legal
      for (var j = 0; j < letterInstances.length; j++) {
        final proposedX = letterInstances[j][0];
        final proposedY = letterInstances[j][1];

        // could this be done left to right?
        final rScore =
            _tryWord(proposedX - i, proposedY, needle, FlowDirection.right);
        final dScore =
            _tryWord(proposedX, proposedY - i, needle, FlowDirection.down);
        if (rScore > 0) {
          result.add([proposedX - i, proposedY, FlowDirection.right, rScore]);
        }
        if (dScore > 0) {
          result.add([proposedX, proposedY - i, FlowDirection.down, dScore]);
        }
      }
    }
    if (result.isEmpty) {
      return [];
    }
    // return our best one
    result.shuffle();
    result.sort((a, b) => b[3].compareTo(a[3]));
    return result[0];
  }

  void _setSquareValue(int x, int y, String value) {
    if (x < 0 || x >= _sideLength || y < 0 || y >= _sideLength) {
      // pass;
    } else {
      _squares[y][x] = value;
    }
  }

  void _writeWord(int x, int y, String value, FlowDirection orientation) {
    final deltaX = orientation == FlowDirection.down ? 0 : 1;
    final deltaY = orientation == FlowDirection.down ? 1 : 0;
    for (var i = 0; i < value.length; i++) {
      _setSquareValue(x + deltaX * i, y + deltaY * i, value[i]);
    }
  }

  int _tryWord(
      int startX, int startY, String value, FlowDirection orientation) {
    var moveScore = 1;
    var legalMove = true;

    final terminatedValue = ".$value.";

    if (orientation == FlowDirection.right) {
      startX -= 1;
    } else {
      startY -= 1;
    }

    final deltaX = orientation == FlowDirection.right ? 1 : 0;
    final deltaY = orientation == FlowDirection.right ? 0 : 1;

    for (var step = 0; step < terminatedValue.length; step++) {
      final targetX = startX + deltaX * step;
      final targetY = startY + deltaY * step;
      final targetSquare = _getSquareValue(targetX, targetY);

      if (targetSquare == terminatedValue[step]) {
        // an intersection, a legal move
        // potentially grants bonus score if this isn't the trailing square
        if (targetSquare != '.') {
          moveScore += 1;
        }
      } else if (targetSquare == '') {
        // an empty space - potentially legal
        // depending on what borders it
        if (orientation == FlowDirection.down) {
          // positions to left and right must be clear
          legalMove = legalMove &&
              (_isSquareEmpty(targetX - 1, targetY) &&
                  _isSquareEmpty(targetX + 1, targetY));
        } else {
          // positions up and down must be clear
          legalMove = legalMove &&
              (_isSquareEmpty(targetX, targetY - 1) &&
                  _isSquareEmpty(targetX, targetY + 1));
        }
      } else {
        // anything else if forbidden
        legalMove = false;
      }
    }

    if (legalMove == false) {
      moveScore = -1;
    }

    return moveScore;
  }

  List<dynamic> _randomPlacement(String word) {
    final flowDirection =
        _rng.nextBool() ? FlowDirection.down : FlowDirection.right;
    final startP = _rng.nextInt(_sideLength - word.length + 1);
    final startS = _rng.nextInt(_sideLength);

    if (flowDirection == FlowDirection.down) {
      return ([startS, startP, flowDirection]);
    } else {
      return ([startP, startS, flowDirection]);
    }
  }

  CrosswordPuzzle(List<List<String>> inputs, this._sideLength, maxItems) {
    _squares = List.generate(_sideLength, (_) => List.filled(_sideLength, ''));

    inputs.sort((a, b) => b[1].length.compareTo(a[1].length));
    var placed = 0;

    for (var i = 0; i < inputs.length; i++) {
      // add a '.' to provide a terminating black space
      var currentAnswer = inputs[i][1];
      var currentAnswerTerminated = "${inputs[i][1]}.";
      var moveScore = 0;

      late int startX;
      late int startY;
      late FlowDirection flowDirection;

      final possibleStart = _findStart(currentAnswer);
      if (possibleStart.isEmpty) {
        // dire - nothing overlapping
        // let's try some randoms
        moveScore = -1;
        for (var j = 0; j < 100; j++) {
          final randomParameters = _randomPlacement(currentAnswer);
          startX = randomParameters[0];
          startY = randomParameters[1];
          flowDirection = randomParameters[2];
          moveScore = _tryWord(startX, startY, currentAnswer, flowDirection);
          // we're not going to get overlaps (by definition) so any positive
          // score will be sufficient
          if (moveScore > 0) {
            break;
          }
        }
        // if we still don't have a legal move, give up
        if (moveScore < 0) {
          continue;
        }
      } else {
        startX = possibleStart[0];
        startY = possibleStart[1];
        flowDirection = possibleStart[2];
        moveScore = possibleStart[3];
      }

      // success!
      final startOffset = (startX + 1) + (startY * _sideLength);
      if (flowDirection == FlowDirection.down) {
        _downClues[startOffset] = inputs[i][0];
      } else {
        _acrossClues[startOffset] = inputs[i][0];
      }
      _writeWord(startX, startY, currentAnswerTerminated, flowDirection);
      _score += moveScore + 1;
      if (++placed >= maxItems) {
        break;
      }
    }
  }

  SplayTreeMap<int, String> get downClues => _downClues;
  SplayTreeMap<int, String> get acrossClues => _acrossClues;

  int get score => _score;
  int get size => _sideLength;

  List<String> get tiles =>
      _squares.expand((i) => i.map((x) => x == '.' ? '' : x)).toList();
}
