import 'package:flutter/material.dart';

import 'global_state_widget.dart';
import 'crossword_cell_widget.dart';
import 'flow_direction.dart';

// note to self:
// git push -u origin main
// flutter pub global run peanut --extra-args "--base-href=/wanicrossword/"
// git push origin --set-upstream gh-pages

const version = '0.01';

void main() {
  runApp(GlobalStateWidget(child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WaniCrossword - $version',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'WaniCrossword'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    final globalState = GlobalStateWidget.of(context)!;

    // make the tiles
    final currentPuzzle = globalState.crosswordController.getPuzzle();
    final tiles = currentPuzzle.tiles;
    final width = currentPuzzle.size;

    final cells = tiles.asMap().entries.map((entry) {
      final squareNumber = entry.key + 1;
      final coords = globalState.indexToCartesian(squareNumber);
      final startsAnswer =
          (currentPuzzle.acrossClues.containsKey(squareNumber) ||
              currentPuzzle.downClues.containsKey(squareNumber));
      final currentValue =
          globalState.cellCurrentValues.get(coords[0], coords[1]) ?? "";

      return CrosswordCell(
          character: entry.value,
          xPosition: coords[0],
          yPosition: coords[1],
          startValue: currentValue,
          note: startsAnswer ? squareNumber.toString() : null);
    }).toList();

    final gridView = GridView.count(
      crossAxisCount: width,
      childAspectRatio: 1,
      primary: false,
      children: cells,
    );

    ListView genClues(Map<int, String> input, FlowDirection orient) => ListView(
        shrinkWrap: true,
        primary: false,
        children: input.entries
            .map((entry) => ListTile(
                leading: Text(entry.key.toString()),
                title: Text(entry.value),
                onTap: () {
                  final coords = globalState.indexToCartesian(entry.key);
                  final fCallback =
                      globalState.focusCallbackMap.get(coords[0], coords[1]);
                  if (fCallback != null) {
                    globalState.crosswordController.flowDirection = orient;
                    fCallback('', false);
                  }
                }))
            .toList());

    final acrossList = genClues(currentPuzzle.acrossClues, FlowDirection.right);
    final downList = genClues(currentPuzzle.downClues, FlowDirection.down);

    return Scaffold(
        appBar: AppBar(title: Text(widget.title), actions: [
          IconButton(
            icon: const Icon(Icons.scoreboard),
            tooltip: 'Score',
            onPressed: () {
              setState(() {
                final scoreTuple = globalState.scorePlaystate();
                final score = scoreTuple[0];
                final maxScore = scoreTuple[1];
                showDialog<String>(
                    context: context,
                    builder: (BuildContext context) => AlertDialog(
                            title: const Text('Scoring'),
                            content:
                                Text('Your score is $score out of $maxScore.'),
                            actions: <Widget>[
                              TextButton(
                                  onPressed: () => Navigator.pop(context, 'OK'),
                                  child: const Text('OK')),
                            ]));
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.autorenew),
            tooltip: 'Layout Puzzle',
            onPressed: () {
              setState(() {
                globalState.resetPlaystate();
                globalState.crosswordController.layoutPuzzle();
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.question_mark),
            tooltip: 'Show Hints',
            onPressed: () {
              final hintMode = globalState.crosswordController.showHints;
              setState(() {
                globalState.crosswordController.showHints = !hintMode;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.key),
            tooltip: 'Login',
            onPressed: () async {
              final popupKeyController = TextEditingController(text: '');
              final popupScaleController = TextEditingController(text: '20');
              final popupValues = await showDialog<List<dynamic>>(
                  context: context,
                  builder: (BuildContext context) => AlertDialog(
                          title: const Text('Please enter your API key'),
                          content:
                              Column(mainAxisSize: MainAxisSize.min, children: [
                            TextField(
                              autocorrect: false,
                              obscureText: true,
                              obscuringCharacter: '•',
                              controller: popupKeyController,
                              decoration:
                                  const InputDecoration(helperText: 'API Key'),
                            ),
                            TextField(
                              autocorrect: false,
                              keyboardType: TextInputType.number,
                              controller: popupScaleController,
                              decoration: const InputDecoration(
                                  helperText: 'Puzzle Scale'),
                            ),
                          ]),
                          actions: <Widget>[
                            TextButton(
                                onPressed: () => Navigator.pop(context, [
                                      popupKeyController.text,
                                      int.tryParse(popupScaleController.text)
                                    ]),
                                child: const Text('OK')),
                            TextButton(
                                onPressed: () =>
                                    Navigator.pop(context, ['', 0]),
                                child: const Text('Cancel'))
                          ]));

              popupKeyController.dispose();
              popupScaleController.dispose();

              if (popupValues == null) {
                return;
              }

              final enteredToken = popupValues[0];
              final enteredScale = popupValues[1] ?? 50;

              if (enteredToken != null) {
                setState(() {
                  globalState.resetPlaystate();
                  globalState.crosswordController
                    ..createWKHandler(enteredToken.trim(), enteredScale)
                    ..layoutPuzzle();
                });
              }
            },
          ),
        ]),
        body: Row(children: [
          Expanded(child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
            var ratio = 1.0;
            if (constraints.maxWidth > constraints.maxHeight) {
              ratio = constraints.maxHeight / constraints.maxWidth;
            }
            return FractionallySizedBox(widthFactor: ratio, child: gridView);
          })),
          const VerticalDivider(),
          Expanded(
              child: Row(children: [
            Expanded(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                  Container(
                      padding: const EdgeInsets.all(4.0),
                      child:
                          const Text('Across', style: TextStyle(fontSize: 18))),
                  Expanded(child: acrossList)
                ])),
            const VerticalDivider(),
            Expanded(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                  Container(
                      padding: const EdgeInsets.all(4.0),
                      child:
                          const Text('Down', style: TextStyle(fontSize: 18))),
                  Expanded(child: downList)
                ])),
          ]))
        ]));
  }
}
