import 'dart:async';

import 'package:baby_manager/models/bottle.dart';
import 'package:flutter/material.dart';


enum FeedingTimerStep {
  idle,
  feeding,
  quantity,
  burping,
  completed,
}

class FeedingTimer extends StatefulWidget {
  /// Id of the child receiving the bottle.
  final String? childId;

  /// Called when the bottle is completed and ready to be persisted.
  final Future<void> Function(Bottle bottle)? onBottleCompleted;

  const FeedingTimer({
    super.key,
    this.childId,
    this.onBottleCompleted,
  });

  @override
  State<FeedingTimer> createState() => _FeedingTimerState();
}

class _FeedingTimerState extends State<FeedingTimer> {
  FeedingTimerStep _step = FeedingTimerStep.idle;

  Timer? _timer;

  DateTime? _feedingStartedAt;
  DateTime? _feedingEndedAt;

  DateTime? _burpingStartedAt;
  DateTime? _burpingEndedAt;

  Duration _elapsed = Duration.zero;

  double? _volume;
  VolumeUnit _volumeUnit = VolumeUnit.ml;

  BottleType? _bottleType;

  final TextEditingController _volumeController = TextEditingController();

  Bottle? _completedBottle;

  @override
  void dispose() {
    _timer?.cancel();
    _volumeController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Feeding
  // ---------------------------------------------------------------------------

  void _startFeeding() {
    final now = DateTime.now();

    setState(() {
      _feedingStartedAt = now;
      _feedingEndedAt = null;

      _burpingStartedAt = null;
      _burpingEndedAt = null;

      _volume = null;
      _completedBottle = null;

      _elapsed = Duration.zero;
      _step = FeedingTimerStep.feeding;
    });

    _startTimer();
  }

  void _endFeeding() {
    _timer?.cancel();

    final now = DateTime.now();

    setState(() {
      _feedingEndedAt = now;
      _elapsed = now.difference(_feedingStartedAt!);
      _step = FeedingTimerStep.quantity;
    });
  }

  // ---------------------------------------------------------------------------
  // Quantity
  // ---------------------------------------------------------------------------

  void _validateQuantity() {
    final volume = double.tryParse(
      _volumeController.text.replaceAll(',', '.'),
    );

    if (volume == null || volume <= 0) {
      return;
    }

    setState(() {
      _volume = volume;
      _step = FeedingTimerStep.burping;
    });
  }

  // ---------------------------------------------------------------------------
  // Burping
  // ---------------------------------------------------------------------------

  void _startBurping() {
    final now = DateTime.now();

    setState(() {
      _burpingStartedAt = now;
      _burpingEndedAt = null;

      _elapsed = Duration.zero;
      _step = FeedingTimerStep.burping;
    });

    _startTimer();
  }

  void _endBurping() {
    _timer?.cancel();

    final now = DateTime.now();

    setState(() {
      _burpingEndedAt = now;
      _elapsed = now.difference(_burpingStartedAt!);

      _step = FeedingTimerStep.completed;
    });

    _saveBottle();
  }

  // ---------------------------------------------------------------------------
  // Timer
  // ---------------------------------------------------------------------------

  void _startTimer() {
    _timer?.cancel();

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (!mounted) return;

        final now = DateTime.now();

        setState(() {
          if (_step == FeedingTimerStep.feeding &&
              _feedingStartedAt != null) {
            _elapsed = now.difference(_feedingStartedAt!);
          }

          if (_step == FeedingTimerStep.burping &&
              _burpingStartedAt != null) {
            _elapsed = now.difference(_burpingStartedAt!);
          }
        });
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Persistence
  // ---------------------------------------------------------------------------

  Future<void> _saveBottle() async {
    final feedingStartedAt = _feedingStartedAt;
    final feedingEndedAt = _feedingEndedAt;
    final burpingStartedAt = _burpingStartedAt;
    final burpingEndedAt = _burpingEndedAt;
    final volume = _volume;

    if (feedingStartedAt == null ||
        feedingEndedAt == null ||
        volume == null) {
      return;
    }

    final bottle = Bottle(
      childId: widget.childId,
      feedingStartedAt: feedingStartedAt,
      feedingEndedAt: feedingEndedAt,
      burpingStartedAt: burpingStartedAt,
      burpingEndedAt: burpingEndedAt,
      volume: volume,
      volumeUnit: _volumeUnit,
      type: _bottleType,
      source: BottleSource.tracked,
    );

    setState(() {
      _completedBottle = bottle;
    });

    await widget.onBottleCompleted?.call(bottle);
  }

  // ---------------------------------------------------------------------------
  // Reset
  // ---------------------------------------------------------------------------

  void _reset() {
    _timer?.cancel();

    setState(() {
      _step = FeedingTimerStep.idle;

      _feedingStartedAt = null;
      _feedingEndedAt = null;

      _burpingStartedAt = null;
      _burpingEndedAt = null;

      _elapsed = Duration.zero;

      _volume = null;
      _bottleType = null;

      _volumeController.clear();

      _completedBottle = null;
    });
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: _buildCurrentStep(),
    );
  }

  Widget _buildCurrentStep() {
    switch (_step) {
      case FeedingTimerStep.idle:
        return _buildIdle();

      case FeedingTimerStep.feeding:
        return _buildFeeding();

      case FeedingTimerStep.quantity:
        return _buildQuantity();

      case FeedingTimerStep.burping:
        return _buildBurping();

      case FeedingTimerStep.completed:
        return _buildCompleted();
    }
  }

  // ---------------------------------------------------------------------------
  // Idle
  // ---------------------------------------------------------------------------

  Widget _buildIdle() {
    return Column(
      key: const ValueKey('idle'),
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.local_drink_outlined,
          size: 64,
        ),

        const SizedBox(height: 16),

        const Text(
          'Prêt pour un biberon ?',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _startFeeding,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Lancer le biberon'),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Feeding
  // ---------------------------------------------------------------------------

  Widget _buildFeeding() {
    return Column(
      key: const ValueKey('feeding'),
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.local_drink,
          size: 64,
        ),

        const SizedBox(height: 16),

        const Text(
          'Biberon en cours',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 24),

        _buildTimer(),

        const SizedBox(height: 32),

        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _endFeeding,
            icon: const Icon(Icons.stop),
            label: const Text('Fin du biberon'),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Quantity
  // ---------------------------------------------------------------------------

  Widget _buildQuantity() {
    return Column(
      key: const ValueKey('quantity'),
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.local_drink_outlined,
          size: 64,
        ),

        const SizedBox(height: 16),

        const Text(
          'Combien a-t-il bu ?',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 24),

        TextField(
          controller: _volumeController,
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
          ),
          textAlign: TextAlign.center,
          autofocus: true,
          decoration: InputDecoration(
            hintText: '180',
            suffixText: _volumeUnit == VolumeUnit.ml ? 'ml' : 'oz',
            border: const OutlineInputBorder(),
          ),
        ),

        const SizedBox(height: 16),

        SegmentedButton<VolumeUnit>(
          segments: const [
            ButtonSegment(
              value: VolumeUnit.ml,
              label: Text('ml'),
            ),
            ButtonSegment(
              value: VolumeUnit.oz,
              label: Text('oz'),
            ),
          ],
          selected: {_volumeUnit},
          onSelectionChanged: (value) {
            setState(() {
              _volumeUnit = value.first;
            });
          },
        ),

        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _validateQuantity,
            child: const Text('Continuer'),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Burping
  // ---------------------------------------------------------------------------

  Widget _buildBurping() {
    final hasStarted = _burpingStartedAt != null;

    return Column(
      key: const ValueKey('burping'),
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.child_care,
          size: 64,
        ),

        const SizedBox(height: 16),

        Text(
          hasStarted ? 'Rot en cours' : 'Faire le rot',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 24),

        if (hasStarted) ...[
          _buildTimer(),

          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _endBurping,
              icon: const Icon(Icons.stop),
              label: const Text('Fin du rot'),
            ),
          ),
        ] else ...[
          Text(
            '${_volume!.toStringAsFixed(0)} ${_volumeUnit == VolumeUnit.ml ? 'ml' : 'oz'}',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _startBurping,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Commencer le rot'),
            ),
          ),

          const SizedBox(height: 8),

          TextButton(
            onPressed: _endBurping,
            child: const Text('Pas de rot'),
          ),
        ],
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Completed
  // ---------------------------------------------------------------------------

  Widget _buildCompleted() {
    final bottle = _completedBottle;

    return Column(
      key: const ValueKey('completed'),
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.check_circle_outline,
          size: 64,
        ),

        const SizedBox(height: 16),

        const Text(
          'Biberon terminé',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 24),

        if (bottle != null) ...[
          _buildSummaryRow(
            'Quantité',
            '${bottle.volume!.toStringAsFixed(0)} '
                '${bottle.volumeUnit == VolumeUnit.ml ? 'ml' : 'oz'}',
          ),

          _buildSummaryRow(
            'Biberon',
            _formatDuration(bottle.feedingDuration!),
          ),

          if (bottle.burpingDuration != null)
            _buildSummaryRow(
              'Rot',
              _formatDuration(bottle.burpingDuration!),
            ),

          _buildSummaryRow(
            'Total',
            _formatDuration(bottle.totalDuration!),
          ),
        ],

        const SizedBox(height: 32),

        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _reset,
            child: const Text('Nouveau biberon'),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Components
  // ---------------------------------------------------------------------------

  Widget _buildTimer() {
    return Text(
      _formatDuration(_elapsed),
      style: const TextStyle(
        fontSize: 56,
        fontWeight: FontWeight.w600,
        fontFeatures: [
          FontFeature.tabularFigures(),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }

    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }
}