import 'package:uuid/uuid.dart';

class Bottle {
  final String id;

  /// Id of the child
  final String? childId;

  /// Temporal datas
  final DateTime feedingStartedAt;
  final DateTime? feedingEndedAt;

  final DateTime? burpingStartedAt;
  final DateTime? burpingEndedAt;

  /// volume of the bottle, in the unit specified by [volumeUnit].
  final double? volume;

  /// Volume unit of the bottle, either milliliters (ml) or ounces (oz).
  final VolumeUnit? volumeUnit;

  /// Type of the bottle.
  final BottleType? type;

  /// Free notes if needed
  final String? notes;

  /// Source of the bottle, either tracked automatically or entered manually.
  final BottleSource source;

  /// Creation date of the bottle.
  final DateTime createdAt;

  /// Modification date of the bottle.
  final DateTime updatedAt;

  Bottle({
    String? id,
    this.childId,
    required this.feedingStartedAt,
    this.feedingEndedAt,
    this.burpingStartedAt,
    this.burpingEndedAt,
    this.volume,
    this.volumeUnit,
    this.type,
    this.notes,
    this.source = BottleSource.tracked,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  /// Duration of the bottle.
  Duration? get feedingDuration {
    if (feedingEndedAt == null) return null;

    return feedingEndedAt!.difference(feedingStartedAt);
  }

  /// Duration of the burping.
  Duration? get burpingDuration {
    if (burpingStartedAt == null || burpingEndedAt == null) {
      return null;
    }

    return burpingEndedAt!.difference(burpingStartedAt!);
  }

  /// Total duration of the bottle.
  Duration? get totalDuration {
    final feeding = feedingDuration;
    final burping = burpingDuration;

    if (feeding == null) return null;

    return feeding + (burping ?? Duration.zero);
  }

  BottleStatus get status {
    if (feedingEndedAt == null) {
      return BottleStatus.feeding;
    }

    if (burpingEndedAt == null) {
      return BottleStatus.burping;
    }

    return BottleStatus.completed;
  }

  Bottle copyWith({
    String? childId,
    DateTime? feedingStartedAt,
    DateTime? feedingEndedAt,
    DateTime? burpingStartedAt,
    DateTime? burpingEndedAt,
    double? volume,
    VolumeUnit? volumeUnit,
    BottleType? type,
    String? notes,
    BottleSource? source,
    DateTime? updatedAt,
  }) {
    return Bottle(
      id: id,
      childId: childId ?? this.childId,
      feedingStartedAt: feedingStartedAt ?? this.feedingStartedAt,
      feedingEndedAt: feedingEndedAt ?? this.feedingEndedAt,
      burpingStartedAt: burpingStartedAt ?? this.burpingStartedAt,
      burpingEndedAt: burpingEndedAt ?? this.burpingEndedAt,
      volume: volume ?? this.volume,
      volumeUnit: volumeUnit ?? this.volumeUnit,
      type: type ?? this.type,
      notes: notes ?? this.notes,
      source: source ?? this.source,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'child_id': childId,

      'feeding_started_at': feedingStartedAt.toIso8601String(),
      'feeding_ended_at': feedingEndedAt?.toIso8601String(),

      'burping_started_at': burpingStartedAt?.toIso8601String(),
      'burping_ended_at': burpingEndedAt?.toIso8601String(),

      'volume': volume,
      'volume_unit': volumeUnit?.name,

      'type': type?.name,

      'notes': notes,

      'source': source.name,

      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Bottle.fromMap(Map<String, dynamic> map) {
    return Bottle(
      id: map['id'] as String,

      childId: map['child_id'] as String?,

      feedingStartedAt: DateTime.parse(map['feeding_started_at'] as String),

      feedingEndedAt: map['feeding_ended_at'] != null
          ? DateTime.parse(map['feeding_ended_at'] as String)
          : null,

      burpingStartedAt: map['burping_started_at'] != null
          ? DateTime.parse(map['burping_started_at'] as String)
          : null,

      burpingEndedAt: map['burping_ended_at'] != null
          ? DateTime.parse(map['burping_ended_at'] as String)
          : null,

      volume: map['volume'] != null ? (map['volume'] as num).toDouble() : null,

      volumeUnit: map['volume_unit'] != null
          ? VolumeUnit.values.byName(map['volume_unit'] as String)
          : null,

      type: map['type'] != null
          ? BottleType.values.byName(map['type'] as String)
          : null,

      notes: map['notes'] as String?,

      source: BottleSource.values.byName(map['source'] as String),

      createdAt: DateTime.parse(map['created_at'] as String),

      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}

enum BottleType { breastMilk, formula, other }

enum VolumeUnit { ml, oz }

enum BottleSource { tracked, manual }

enum BottleStatus { feeding, burping, completed }
