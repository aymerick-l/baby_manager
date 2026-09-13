import 'package:flutter/material.dart';

import '../models/bottle.dart';
import '../services/bottle_repository.dart';
import '../widgets/bottle_timeline_chart.dart';
import '../widgets/date_selector.dart';
import '../widgets/last_bottle_card.dart';

class StatisticsScreen extends StatefulWidget {
  final BottleRepository bottleRepository;
  final String childId;

  const StatisticsScreen({
    super.key,
    required this.bottleRepository,
    required this.childId,
  });

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  late Future<List<Bottle>> _bottlesFuture;

  late DateTime _startDate;
  late DateTime _endDate;

  @override
  void initState() {
    super.initState();

    _initializeDateRange();
    _loadBottles();
  }

  void _initializeDateRange() {
    final now = DateTime.now();

    _startDate = DateTime(
      now.year,
      now.month,
      now.day,
    );

    _endDate = _startDate.add(
      const Duration(days: 1),
    );
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

  List<Bottle> _filterBottles(List<Bottle> bottles) {
    final filtered = bottles.where((bottle) {
      return !bottle.feedingStartedAt.isBefore(_startDate) &&
          bottle.feedingStartedAt.isBefore(_endDate);
    }).toList();

    // Sécurité : on s'assure que le plus récent est en premier.
    filtered.sort(
      (a, b) => b.feedingStartedAt.compareTo(
        a.feedingStartedAt,
      ),
    );

    return filtered;
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
        final filteredBottles = _filterBottles(bottles);

        return RefreshIndicator(
          onRefresh: _refresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverToBoxAdapter(
                  child: _buildContent(filteredBottles),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContent(List<Bottle> bottles) {
    //TODO: Get last bottle from repository instead of getting all
    final lastBottle = bottles.isEmpty ? null : bottles.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DateSelector(
          startDate: _startDate,
          endDate: _endDate,
          onChanged: (start, end) {
            setState(() {
              _startDate = start;
              _endDate = end;
            });
          },
        ),

        const SizedBox(height: 16),

        LastBottleCard(
          bottle: lastBottle,
        ),

        const SizedBox(height: 24),

        if (bottles.isEmpty)
          _buildEmptyState()
        else ...[
          _buildSummarySection(bottles),

          const SizedBox(height: 24),

          _buildTimelineSection(bottles),
        ],
      ],
    );
  }

  Widget _buildSummarySection(List<Bottle> bottles) {
    final bottleCount = bottles.length;
    final totalVolume = _calculateTotalVolume(bottles);
    final totalFeedingDuration =
        _calculateTotalFeedingDuration(bottles);
    final totalBurpingDuration =
        _calculateTotalBurpingDuration(bottles);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Résumé',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),

        const SizedBox(height: 12),

        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 600;

            if (isWide) {
              return Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.local_drink_outlined,
                      title: 'Biberons',
                      value: '$bottleCount',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.water_drop_outlined,
                      title: 'Volume',
                      value: _formatVolume(totalVolume),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.timer_outlined,
                      title: 'Prise',
                      value: _formatDuration(
                        totalFeedingDuration,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.air_outlined,
                      title: 'Rot',
                      value: _formatDuration(
                        totalBurpingDuration,
                      ),
                    ),
                  ),
                ],
              );
            }

            return Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.local_drink_outlined,
                        title: 'Biberons',
                        value: '$bottleCount',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.water_drop_outlined,
                        title: 'Volume',
                        value: _formatVolume(totalVolume),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.timer_outlined,
                        title: 'Prise',
                        value: _formatDuration(
                          totalFeedingDuration,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.air_outlined,
                        title: 'Rot',
                        value: _formatDuration(
                          totalBurpingDuration,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildTimelineSection(List<Bottle> bottles) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Timeline',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),

        const SizedBox(height: 4),

        Text(
          'Déroulement des biberons sur la période',
          style: Theme.of(context).textTheme.bodyMedium,
        ),

        const SizedBox(height: 12),

        Card(
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            height: 400,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: BottleTimelineChart(
                bottles: bottles,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return SizedBox(
      width: double.infinity,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 48,
          ),
          child: Column(
            children: [
              Icon(
                Icons.bar_chart_outlined,
                size: 56,
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant,
              ),

              const SizedBox(height: 16),

              Text(
                'Aucun biberon',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),

              const SizedBox(height: 8),

              Text(
                'Aucun biberon enregistré sur cette période.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
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
              'Impossible de charger les statistiques.',
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

  double _calculateTotalVolume(List<Bottle> bottles) {
    double total = 0;

    for (final bottle in bottles) {
      if (bottle.volume == null) {
        continue;
      }

      // Pour l'instant, seules les valeurs en ml sont
      // additionnées afin de ne pas mélanger ml et oz.
      if (bottle.volumeUnit == VolumeUnit.ml) {
        total += bottle.volume!;
      }
    }

    return total;
  }

  Duration _calculateTotalFeedingDuration(
    List<Bottle> bottles,
  ) {
    var total = Duration.zero;

    for (final bottle in bottles) {
      final duration = bottle.feedingDuration;

      if (duration != null) {
        total += duration;
      }
    }

    return total;
  }

  Duration _calculateTotalBurpingDuration(
    List<Bottle> bottles,
  ) {
    var total = Duration.zero;

    for (final bottle in bottles) {
      final duration = bottle.burpingDuration;

      if (duration != null) {
        total += duration;
      }
    }

    return total;
  }

  String _formatVolume(double volume) {
    if (volume == 0) {
      return '0 ml';
    }

    final formatted = volume % 1 == 0
        ? volume.toInt().toString()
        : volume.toStringAsFixed(1);

    return '$formatted ml';
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    if (hours > 0) {
      return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
    }

    if (minutes > 0) {
      return '${minutes}min';
    }

    if (duration.inSeconds > 0) {
      return '${duration.inSeconds}s';
    }

    return '0min';
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodySmall,
                  ),

                  const SizedBox(height: 4),

                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
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
}