import 'package:crossword/flow_direction.dart';
import 'package:flutter/material.dart';

import 'global_state_widget.dart';
import 'crossword_cell_widget.dart';

void main() {
  runApp(GlobalStateWidget(child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WaniCrossword',
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
    // burn the old focus map
    GlobalStateWidget.of(context)!.focusCallbackMap.clear();
    // burn the old scoring callbacks
    GlobalStateWidget.of(context)!.scoringCallbacks.clear();

    // make the tiles
    final currentPuzzle =
        GlobalStateWidget.of(context)!.crosswordController.getPuzzle();
    final tiles = currentPuzzle.tiles;
    final width = currentPuzzle.size;
    final height = (tiles.length / width).ceil();

    final cells = tiles.asMap().entries.map((entry) {
      final xPosition = (entry.key % width);
      final yPosition = (entry.key ~/ width);
      final offset = entry.key + 1;
      return CrosswordCell(
          character: entry.value,
          identifier: entry.key.toString(),
          note: (currentPuzzle.acrossClues.containsKey(offset) ||
                  currentPuzzle.downClues.containsKey(offset))
              ? offset.toString()
              : null,
          right: xPosition < (width - 1) ? (entry.key + 1).toString() : null,
          down:
              yPosition < (height - 1) ? (entry.key + width).toString() : null);
    }).toList();

    final acrossList = ListView(
        shrinkWrap: true,
        primary: false,
        children: currentPuzzle.acrossClues.entries
            .map((entry) => ListTile(
                leading: Text(entry.key.toString()),
                title: Text(entry.value),
                onTap: () {
                  final fCallback = GlobalStateWidget.of(context)!
                      .focusCallbackMap[(entry.key - 1).toString()];
                  if (fCallback != null) {
                    GlobalStateWidget.of(context)!
                        .crosswordController
                        .flowDirection = FlowDirection.right;
                    fCallback('');
                  }
                }))
            .toList());

    final downList = ListView(
        shrinkWrap: true,
        primary: false,
        children: currentPuzzle.downClues.entries
            .map((entry) => ListTile(
                leading: Text(entry.key.toString()),
                title: Text(entry.value),
                onTap: () {
                  final fCallback = GlobalStateWidget.of(context)!
                      .focusCallbackMap[(entry.key - 1).toString()];
                  if (fCallback != null) {
                    GlobalStateWidget.of(context)!
                        .crosswordController
                        .flowDirection = FlowDirection.down;
                    fCallback('');
                  }
                }))
            .toList());

    return Scaffold(
        appBar: AppBar(title: Text(widget.title), actions: [
          IconButton(
              onPressed: () {
                final callbacks =
                    GlobalStateWidget.of(context)!.scoringCallbacks;
                final scores = callbacks.map((f) => f()).toList();
                final score = scores.reduce((a, b) => a + b);
                showDialog<String>(
                    context: context,
                    builder: (BuildContext context) => AlertDialog(
                            title: const Text('Scoring'),
                            content: Text(
                                'Your score is $score out of ${scores.length}.'),
                            actions: <Widget>[
                              TextButton(
                                  onPressed: () => Navigator.pop(context, 'OK'),
                                  child: const Text('OK')),
                            ]));
              },
              icon: const Icon(Icons.scoreboard),
              tooltip: 'Score'),
          IconButton(
              onPressed: () {
                setState(() {
                  GlobalStateWidget.of(context)!
                      .crosswordController
                      .layoutPuzzle();
                });
              },
              icon: const Icon(Icons.autorenew),
              tooltip: 'Layout Puzzle'),
          IconButton(
              onPressed: () async {
                final popupController = TextEditingController(text: '');
                final enteredToken = await showDialog<String>(
                    context: context,
                    builder: (BuildContext context) => AlertDialog(
                            title: const Text('Please enter your API key'),
                            content: TextField(
                                autocorrect: false,
                                obscureText: true,
                                obscuringCharacter: '🐊',
                                controller: popupController),
                            actions: <Widget>[
                              TextButton(
                                  onPressed: () => Navigator.pop(
                                      context, popupController.text),
                                  child: const Text('OK')),
                              TextButton(
                                  onPressed: () => Navigator.pop(context, ''),
                                  child: const Text('Cancel'))
                            ]));
                // d276a05c-ab0f-4724-b9e5-38787c25bf39
                popupController.dispose();
                if (enteredToken != null) {
                  setState(() {
                    GlobalStateWidget.of(context)!.crosswordController
                      ..createWKHandler(enteredToken.trim())
                      ..layoutPuzzle();
                  });
                }
              },
              icon: const Icon(Icons.key),
              tooltip: 'Login'),
        ]),
        body: Row(children: [
          Expanded(
              child: GridView.count(
            crossAxisCount: width,
            primary: false,
            shrinkWrap: true,
            children: cells,
          )),
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
