import 'position.dart';

/// Collectible — a pickup that sits on one board cell and is gathered
/// when an arrow's ray passes over it. Value object: immutable, equality
/// by (position, kind).
///
/// [kind] is a whitelisted string (project constraint: no enums). The
/// backend seeds only 'STAR' today; adding a new kind is a one-line
/// change to [knownKinds]. Unknown kinds are rejected fast so a stale
/// fixture cannot silently drop a bogus pickup on the board.
class Collectible {
  static const Set<String> knownKinds = {'STAR'};

  final Position position;
  final String kind;

  Collectible({required this.position, required this.kind}) {
    if (!knownKinds.contains(kind)) {
      throw FormatException('Unknown collectible kind: "$kind"');
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Collectible &&
          position == other.position &&
          kind == other.kind);

  @override
  int get hashCode => Object.hash(position, kind);
}