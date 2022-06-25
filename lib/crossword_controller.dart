import 'flow_direction.dart';
import 'crossword_puzzle.dart';
import 'wanikani.dart';

import 'dart:math';

final _rng = Random();

class CrosswordController {
  WanikaniHandler? _wanikaniController;
  CrosswordPuzzle? _currentPuzzle;

  FlowDirection flowDirection = FlowDirection.down;
  bool showHints = true;

  CrosswordController();

  CrosswordPuzzle getPuzzle() {
    _currentPuzzle ??= layoutPuzzle();
    return _currentPuzzle!;
  }

  void createWKHandler(String token) {
    _wanikaniController = WanikaniHandler(token);
  }

  bool get hasHandler => _wanikaniController != null;

  CrosswordPuzzle layoutPuzzle() {
    int width = 8;
    List<List<String>> clues = [];

    if (_wanikaniController == null) {
      clues = [
        ['please', 'please'],
        ['add', 'add'],
        ['your', 'your'],
        ['readonly', 'readonly'],
        ['api', 'api'],
        ['key', 'key']
      ];
    } else if (_wanikaniController!.loadingBurns) {
      clues = [
        ['still', 'still'],
        ['loading', 'loading'],
        ['your', 'your'],
        ['burned', 'burned'],
        ['items', 'items'],
      ];
    } else if (_wanikaniController!.loadedBurns == false) {
      _wanikaniController!.loadBurns();
      clues = [
        ['requesting', 'requesting'],
        ['your', 'your'],
        ['burned', 'burned'],
        ['items', 'items'],
      ];
    } else {
      final burns = _wanikaniController!.burns;
      clues = burns
          .map<List<String>>((e) => [_rng.nextBool() ? e[1] : e[2], e[0]])
          .toList();
      if (clues.isEmpty) {
        clues = [
          ['something', 'something'],
          ['wrong', 'wrong'],
          ['with', 'with'],
          ['api', 'api'],
          ['retrieval', 'retrieval'],
        ];
      }
    }

    if (clues.isEmpty) {
      clues = [
        ['clues', 'clues'],
        ['were', 'were'],
        ['unretrievable', 'unretrievable'],
      ];
    }

    // sort by length
    clues.shuffle();
    if (clues.length > 250) {
      clues = clues.sublist(0, 250);
    }
    width = clues.map<int>((e) => e[1].length).reduce(max) * 2 + 1;

    Stopwatch s = Stopwatch();

    CrosswordPuzzle bestSolution = CrosswordPuzzle(clues, width);

    s.start();
    //var bestTime = 0;
    while (s.elapsedMilliseconds < 700) {
      var newPuzzle = CrosswordPuzzle(clues, width);
      if (newPuzzle.score > bestSolution.score) {
        bestSolution = newPuzzle;
        //bestTime = s.elapsedMilliseconds;
      }
    }
    s.stop();
    _currentPuzzle = bestSolution;
    return _currentPuzzle!;
  }
}
