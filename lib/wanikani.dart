import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';

final _rng = Random();

class WanikaniHandler {
  final String _token;
  final List<List<String>> _burns = [[]];
  bool _loadingBurns = false;
  bool _loadedBurns = false;

  WanikaniHandler(this._token);

  Future<List<dynamic>> _loadWKCollection(String apiURI) async {
    final headers = {
      'Wanikani-Revision': '20170710',
      'Authorization': 'Bearer $_token'
    };
    var results = [];
    String? currentPage = apiURI;
    while (currentPage != null) {
      final response = await http.get(Uri.parse(currentPage), headers: headers);
      if (response.statusCode != 200) {
        return results;
      }
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      results.addAll(jsonData['data']);
      currentPage = jsonData['pages']['next_url'];
    }
    return results;
  }

  Future<List<dynamic>> _loadSubjects(List<List<String>> chunks) async {
    var results = [];
    for (var j = 0; j < chunks.length; j++) {
      final currentChunk = chunks[j];
      final apiURL =
          'https://api.wanikani.com/v2/subjects?ids=${currentChunk.join(",")}';
      results.addAll(await _loadWKCollection(apiURL));
    }
    return results;
  }

  List<List<String>> get burns => _burns;
  bool get loadingBurns => _loadingBurns;
  bool get loadedBurns => _loadedBurns;
  void loadBurns() async {
    if (_loadingBurns) {
      return;
    }
    _loadingBurns = true;
    _loadedBurns = false;

    final assignments = await _loadWKCollection(
        'https://api.wanikani.com/v2/assignments?burned=true&hidden=false&subject_types=vocabulary');
    final subjectIDs = assignments
        .map<String>((e) => e['data']['subject_id'].toString())
        .toList();

    List<List<String>> chunkedSubjectIDs = [[]];
    const chunkSize = 100;
    for (var i = 0; i < subjectIDs.length; i += chunkSize) {
      var endPoint = (i + chunkSize) < subjectIDs.length
          ? i + chunkSize
          : subjectIDs.length;
      chunkedSubjectIDs.add(subjectIDs.sublist(i, endPoint));
    }

    final subjects = await _loadSubjects(chunkedSubjectIDs);
    _burns.clear();
    _burns.addAll(subjects.map<List<String>>((e) {
      final kanji = e['data']['characters'].toString();

      final primaryMeanings = e['data']['meanings']
          .where((item) => item['primary'] == true)
          .toList();
      final primaryReadings = e['data']['readings']
          .where((item) => item['primary'] == true)
          .toList();
      return [
        primaryReadings[_rng.nextInt(primaryReadings.length)]['reading'],
        primaryMeanings[_rng.nextInt(primaryMeanings.length)]['meaning'],
        kanji
      ];
    }).where((x) => x[0].length > 1));
    _loadingBurns = false;
    _loadedBurns = true;
  }
}
