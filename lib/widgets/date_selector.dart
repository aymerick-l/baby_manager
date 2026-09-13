
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateSelector extends StatelessWidget {
  /// Date de début incluse dans la période.
  final DateTime startDate;

  /// Date de fin exclusive.
  ///
  /// Exemple :
  /// startDate = 2026-09-05 00:00
  /// endDate   = 2026-09-06 00:00
  ///
  /// => affiche tous les biberons du 5 septembre.
  final DateTime endDate;

  /// Appelé lorsque la période est modifiée.
  ///
  /// [start] est inclusif.
  /// [end] est exclusif.
  final void Function(DateTime start, DateTime end) onChanged;

  const DateSelector({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openDateRangePicker(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          child: Row(
            children: [
              Icon(
                Icons.calendar_month_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Période',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatDateRange(),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openDateRangePicker(BuildContext context) async {
    // showDateRangePicker travaille avec des dates, pas avec des heures.
    // On retire donc l'heure pour initialiser correctement le picker.
    final initialStart = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
    );

    // endDate est exclusive dans notre composant.
    // Le picker attend une date inclusive, donc on retire un jour.
    final initialEnd = DateTime(
      endDate.year,
      endDate.month,
      endDate.day,
    ).subtract(const Duration(days: 1));

    final firstDate = DateTime(
      2020,
      1,
      1,
    );

    final lastDate = DateTime(
      2100,
      12,
      31,
    );

    final picked = await showDateRangePicker(
      context: context,
      firstDate: firstDate,
      lastDate: lastDate,
      initialDateRange: DateTimeRange(
        start: initialStart,
        end: initialEnd.isBefore(initialStart)
            ? initialStart
            : initialEnd,
      ),
      helpText: 'Sélectionner une période',
      cancelText: 'Annuler',
      confirmText: 'Valider',
      saveText: 'Valider',
      fieldStartLabelText: 'Début',
      fieldEndLabelText: 'Fin',
      fieldStartHintText: 'Date de début',
      fieldEndHintText: 'Date de fin',
    );

    if (picked == null) {
      return;
    }

    // Le DateRangePicker considère la date de fin comme incluse.
    //
    // Notre application utilise une période semi-ouverte :
    // [start, end)
    //
    // Donc pour afficher :
    // 05/09 uniquement
    //
    // on utilise :
    // start = 05/09 00:00
    // end   = 06/09 00:00
    final start = DateTime(
      picked.start.year,
      picked.start.month,
      picked.start.day,
    );

    final end = DateTime(
      picked.end.year,
      picked.end.month,
      picked.end.day,
    ).add(const Duration(days: 1));

    onChanged(start, end);
  }

  String _formatDateRange() {
    final formatter = DateFormat('d MMM yyyy', 'fr_FR');

    final start = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
    );

    // endDate est exclusive, donc la dernière journée affichée
    // correspond à endDate - 1 jour.
    final lastDay = DateTime(
      endDate.year,
      endDate.month,
      endDate.day,
    ).subtract(const Duration(days: 1));

    // Une seule journée.
    if (start.year == lastDay.year &&
        start.month == lastDay.month &&
        start.day == lastDay.day) {
      return formatter.format(start);
    }

    // Même année : on évite de répéter l'année.
    if (start.year == lastDay.year) {
      final startFormatter = DateFormat('d MMM', 'fr_FR');

      return '${startFormatter.format(start)} → ${formatter.format(lastDay)}';
    }

    return '${formatter.format(start)} → ${formatter.format(lastDay)}';
  }
}
