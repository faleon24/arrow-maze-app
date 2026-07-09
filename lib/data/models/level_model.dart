/// LevelModel — the data-layer representation of a level as returned by
/// the backend's GET /api/levels endpoint.
///
/// This is a MINIMAL first version: just the scalar fields, so we can
/// prove the app can talk to the backend and parse a response. The
/// board (rows, cols, cells) is added in the next step once the round
/// trip works.
///
/// `fromJson` is the standard Dart pattern for turning a decoded JSON
/// map into a typed object — the app-side mirror of the backend's
/// LevelResponseDto.from().
class LevelModel {
  final String id;
  final int index;
  final String difficulty;
  final int parTimeMs;
  final bool published;

  LevelModel({
    required this.id,
    required this.index,
    required this.difficulty,
    required this.parTimeMs,
    required this.published,
  });

  factory LevelModel.fromJson(Map<String, dynamic> json) {
    return LevelModel(
      id: json['id'] as String,
      index: json['index'] as int,
      difficulty: json['difficulty'] as String,
      parTimeMs: json['parTimeMs'] as int,
      published: json['published'] as bool,
    );
  }
}