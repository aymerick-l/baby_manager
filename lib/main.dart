import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'models/bottle.dart';
import 'services/bottle_repository.dart';
import 'screens/history_screen.dart';
import 'screens/statistics_screen.dart';
import 'widgets/feeding_timer.dart';
import 'widgets/last_bottle_card.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('fr_FR');

  runApp(const BabyManagerApp());
}

class BabyManagerApp extends StatelessWidget {
  const BabyManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final bottleRepository = BottleRepository();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Baby Manager',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
        ),
        useMaterial3: true,
      ),
      home: HomeScreen(
        bottleRepository: bottleRepository,
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final BottleRepository bottleRepository;

  const HomeScreen({
    super.key,
    required this.bottleRepository,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static const String _childId = 'baby-1';

  late Future<List<Bottle>> _bottlesFuture;

  @override
  void initState() {
    super.initState();

    _loadBottles();
  }

  void _loadBottles() {
    _bottlesFuture = widget.bottleRepository.getByChildId(
      _childId,
    );
  }

  Future<void> _refreshBottles() async {
    setState(() {
      _loadBottles();
    });

    await _bottlesFuture;
  }

  Bottle? _getLastBottle(List<Bottle> bottles) {
    if (bottles.isEmpty) {
      return null;
    }

    // getByChildId() retourne déjà les biberons avec
    // le plus récent en premier.
    return bottles.first;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildHome(),

          HistoryScreen(
            bottleRepository: widget.bottleRepository,
            childId: _childId,
          ),

          StatisticsScreen(
            bottleRepository: widget.bottleRepository,
            childId: _childId,
          ),
        ],
      ),

      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.local_drink_outlined),
            selectedIcon: Icon(Icons.local_drink),
            label: 'Biberon',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'Historique',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Stats',
          ),
        ],
      ),
    );
  }

  Widget _buildHome() {
    return FutureBuilder<List<Bottle>>(
      future: _bottlesFuture,
      builder: (context, snapshot) {
        // Pendant le chargement initial.
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        // En cas d'erreur.
        if (snapshot.hasError) {
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
                    'Impossible de charger les biberons.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _refreshBottles,
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            ),
          );
        }

        final bottles = snapshot.data ?? [];
        final lastBottle = _getLastBottle(bottles);

        return Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 500,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FeedingTimer(
                    childId: _childId,
                    onBottleCompleted: (bottle) async {
                      // Enregistrement du nouveau biberon.
                      await widget.bottleRepository.create(
                        bottle,
                      );

                      // On recharge le dernier biberon.
                      await _refreshBottles();
                    },
                  ),

                  const SizedBox(height: 24),

                  LastBottleCard(
                    bottle: lastBottle,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}