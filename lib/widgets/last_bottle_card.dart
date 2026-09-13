import 'package:flutter/material.dart';

import '../models/bottle.dart';

class LastBottleCard extends StatelessWidget {
  final Bottle? bottle;

  const LastBottleCard({
    super.key,
    required this.bottle,
  });

  @override
  Widget build(BuildContext context) {
    if (bottle == null) {
      return _buildEmptyCard(context);
    }

    return _buildBottleCard(context, bottle!);
  }

  Widget _buildBottleCard(
    BuildContext context,
    Bottle bottle,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _buildIcon(
              context,
              Icons.local_drink_outlined,
            ),

            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dernier biberon',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    _formatTime(bottle.feedingStartedAt),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 2),

                  Text(
                    _formatElapsedTime(bottle.feedingStartedAt),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            if (bottle.volume != null)
              _buildVolume(
                context,
                bottle,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCard(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _buildIcon(
              context,
              Icons.local_drink_outlined,
            ),

            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dernier biberon',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    'Aucun biberon',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 2),

                  Text(
                    'Aucun biberon enregistré pour le moment.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(
    BuildContext context,
    IconData icon,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        icon,
        color: colorScheme.onPrimaryContainer,
      ),
    );
  }

  Widget _buildVolume(
    BuildContext context,
    Bottle bottle,
  ) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          _formatVolume(bottle),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 2),

        Text(
          'pris',
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  String _formatElapsedTime(DateTime dateTime) {
    final now = DateTime.now();

    final difference = now.difference(dateTime);

    if (difference.isNegative) {
      return 'à venir';
    }

    final days = difference.inDays;
    final hours = difference.inHours % 24;
    final minutes = difference.inMinutes % 60;

    if (days > 0) {
      if (days == 1) {
        return 'Il y a 1 jour';
      }

      return 'Il y a $days jours';
    }

    if (hours > 0) {
      if (minutes > 0) {
        return 'Il y a ${hours}h${minutes.toString().padLeft(2, '0')}';
      }

      return 'Il y a ${hours}h';
    }

    if (minutes > 0) {
      return 'Il y a ${minutes} min';
    }

    return 'À l’instant';
  }

  String _formatVolume(Bottle bottle) {
    final volume = bottle.volume;

    if (volume == null) {
      return '';
    }

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