
import 'package:flutter/material.dart';

import '../models/bottle.dart';
import '../services/bottle_repository.dart';

class HistoryScreen extends StatefulWidget {
  final BottleRepository bottleRepository;
  final String childId;

  const HistoryScreen({
    super.key,
    required this.bottleRepository,
    required this.childId,
  });

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<Bottle>> _bottlesFuture;

  @override
  void initState() {
    super.initState();
    _loadBottles();
  }

  void _loadBottles() {
    _bottlesFuture = widget.bottleRepository.getByChildId(
      widget.childId,
    );
  }

  Future<void> _refresh() async {
    setState(() {
      _loadBottles();
    });

    await _bottlesFuture;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Bottle>>(
      future: _bottlesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return _buildError(snapshot.error);
        }

        final bottles = snapshot.data ?? [];

        if (bottles.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: bottles.length,
            separatorBuilder: (_, __) {
              return const SizedBox(height: 8);
            },
            itemBuilder: (context, index) {
              return _BottleHistoryItem(
                bottle: bottles[index],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(
            height: 200,
          ),
          Icon(
            Icons.history,
            size: 48,
          ),
          SizedBox(height: 16),
          Center(
            child: Text(
              'Aucun biberon enregistré',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SizedBox(height: 8),
          Center(
            child: Text(
              'Les biberons terminés apparaîtront ici.',
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(Object? error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
            ),
            const SizedBox(height: 16),
            const Text(
              'Impossible de charger l\'historique.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '$error',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                setState(_loadBottles);
              },
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottleHistoryItem extends StatelessWidget {
  final Bottle bottle;

  const _BottleHistoryItem({
    required this.bottle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Heure
            SizedBox(
              width: 64,
              child: Text(
                _formatTime(bottle.feedingStartedAt),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(width: 16),

            // Informations
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Biberon',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Durée : ${_formatDuration(bottle.feedingDuration)}',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Quantité
            if (bottle.volume != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatVolume(bottle),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'pris',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) {
      return '--';
    }

    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;

    if (minutes == 0) {
      return '${seconds}s';
    }

    return '${minutes}min ${seconds.toString().padLeft(2, '0')}s';
  }

  String _formatVolume(Bottle bottle) {
    final volume = bottle.volume!;

    final formattedVolume = volume % 1 == 0
        ? volume.toInt().toString()
        : volume.toStringAsFixed(1);

    final unit = switch (bottle.volumeUnit) {
      VolumeUnit.ml => 'ml',
      VolumeUnit.oz => 'oz',
      null => '',
    };

    return '$formattedVolume $unit';
  }
}
