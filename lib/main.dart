import 'dart:async';
import 'package:flutter/material.dart';

void main() {
  runApp(const DigitalPetApp());
}

class DigitalPetApp extends StatelessWidget {
  const DigitalPetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Digital Pet',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const DigitalPetPage(),
    );
  }
}

class DigitalPetPage extends StatefulWidget {
  const DigitalPetPage({super.key});

  @override
  State<DigitalPetPage> createState() => _DigitalPetPageState();
}

class _DigitalPetPageState extends State<DigitalPetPage> {
  // ------------------------------------------------------------
  // Initial values
  // ------------------------------------------------------------

  static const int _initialHappiness = 50;
  static const int _initialHunger = 50;

  int _happiness = _initialHappiness;
  int _hunger = _initialHunger;

  String _petName = 'Pip';
  String _lastAction = 'Choose an action to care for your pet.';

  bool _gameOver = false;
  bool _hasWon = false;

  Timer? _hungerTimer;
  Timer? _highMoodTimer;

  final TextEditingController _nameController = TextEditingController(
    text: 'Pip',
  );

  // ------------------------------------------------------------
  // Lifecycle
  // ------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _startHungerTimer();
  }

  @override
  void dispose() {
    _hungerTimer?.cancel();
    _highMoodTimer?.cancel();
    _nameController.dispose();

    super.dispose();
  }

  // ------------------------------------------------------------
  // Helpers
  // ------------------------------------------------------------

  int _clampMeter(int value) {
    return value.clamp(0, 100);
  }

  bool get _finished => _gameOver || _hasWon;

  String get _moodLabel {
    if (_happiness > 70) {
      return 'Happy';
    }

    if (_happiness >= 30) {
      return 'Neutral';
    }

    return 'Unhappy';
  }

  Color get _moodColor {
    if (_happiness > 70) {
      return Colors.green;
    }

    if (_happiness >= 30) {
      return Colors.yellow;
    }

    return Colors.red;
  }

  // ------------------------------------------------------------
  // Hunger timer
  // Hunger increases by 5 every 30 seconds.
  //
  // Assignment overflow rule:
  // 95 -> 100 = no happiness penalty.
  // Another tick while hunger is already 100 reduces happiness by 20.
  // ------------------------------------------------------------

  void _startHungerTimer() {
    _hungerTimer?.cancel();

    _hungerTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_finished) {
        timer.cancel();
        return;
      }

      final int attemptedHunger = _hunger + 5;

      setState(() {
        if (attemptedHunger > 100) {
          _hunger = 100;
          _happiness = _clampMeter(_happiness - 20);
          _lastAction = '$_petName is starving! Happiness decreased.';
        } else {
          _hunger = attemptedHunger;
          _lastAction = '$_petName is getting hungry.';
        }
      });

      _updateOutcome();
    });
  }

  // ------------------------------------------------------------
  // Feed
  //
  // Hunger -10.
  // If resulting hunger is below 30, happiness -20.
  // Otherwise happiness +10.
  // ------------------------------------------------------------

  void _feedPet() {
    if (_finished) return;

    final int nextHunger = _clampMeter(_hunger - 10);

    final int happinessChange = nextHunger < 30 ? -20 : 10;

    final int nextHappiness = _clampMeter(_happiness + happinessChange);

    setState(() {
      _hunger = nextHunger;
      _happiness = nextHappiness;

      if (happinessChange < 0) {
        _lastAction = '$_petName is too full. Happiness decreased.';
      } else {
        _lastAction = 'You fed $_petName. Hunger decreased!';
      }
    });

    _updateOutcome();
  }

  // ------------------------------------------------------------
  // Play
  //
  // Team rule used here:
  // Happiness +15
  // Hunger +5
  // ------------------------------------------------------------

  void _playWithPet() {
    if (_finished) return;

    final int nextHappiness = _clampMeter(_happiness + 15);

    final int nextHunger = _clampMeter(_hunger + 5);

    setState(() {
      _happiness = nextHappiness;
      _hunger = nextHunger;
      _lastAction = 'You played with $_petName. Happiness increased!';
    });

    _updateOutcome();
  }

  // ------------------------------------------------------------
  // Win / Loss
  //
  // Win:
  // Happiness must stay STRICTLY above 80 for 3 continuous minutes.
  //
  // Loss:
  // Hunger == 100 AND Happiness <= 10.
  // ------------------------------------------------------------

  void _updateOutcome() {
    if (_finished) return;

    // Loss
    if (_hunger == 100 && _happiness <= 10) {
      _highMoodTimer?.cancel();
      _highMoodTimer = null;

      _hungerTimer?.cancel();

      setState(() {
        _gameOver = true;
        _lastAction = 'Game Over! $_petName is too hungry and unhappy.';
      });

      return;
    }

    // Happiness dropped back to 80 or below.
    // Cancel the pending win timer.
    if (_happiness <= 80) {
      _highMoodTimer?.cancel();
      _highMoodTimer = null;
      return;
    }

    // Happiness is above 80.
    // Start the timer only if one is not already running.
    _highMoodTimer ??= Timer(const Duration(minutes: 3), () {
      _highMoodTimer = null;

      if (!mounted) return;
      if (_gameOver) return;

      if (_happiness > 80) {
        _hungerTimer?.cancel();

        setState(() {
          _hasWon = true;
          _lastAction = 'You win! $_petName stayed happy for 3 minutes!';
        });
      }
    });
  }

  // ------------------------------------------------------------
  // Reset
  // Core requirement.
  //
  // This is NOT the advanced Pause/Resume Session Control feature.
  // ------------------------------------------------------------

  void _resetGame() {
    _highMoodTimer?.cancel();
    _highMoodTimer = null;

    setState(() {
      _happiness = _initialHappiness;
      _hunger = _initialHunger;

      _gameOver = false;
      _hasWon = false;

      _lastAction = 'Game reset. Take care of $_petName!';
    });

    _startHungerTimer();
  }

  // ------------------------------------------------------------
  // Pet name
  // ------------------------------------------------------------

  void _confirmName() {
    final String newName = _nameController.text.trim();

    if (newName.isEmpty) return;

    setState(() {
      _petName = newName;
      _lastAction = 'Your pet is now named $_petName!';
    });
  }

  // ------------------------------------------------------------
  // UI
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Digital Pet'), centerTitle: true),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // --------------------------------------------------
            // Pet name
            // --------------------------------------------------
            Text('Pet Name', style: Theme.of(context).textTheme.titleMedium),

            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Enter pet name',
                    ),
                    onSubmitted: (_) => _confirmName(),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _confirmName,
                  child: const Text('Confirm'),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // --------------------------------------------------
            // Pet
            // --------------------------------------------------
            Center(
              child: Column(
                children: [
                  ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      _moodColor,
                      BlendMode.modulate,
                    ),
                    child: Image.asset(
                      'assets/pet.png',
                      width: 160,
                      height: 160,
                      fit: BoxFit.contain,

                      // Allows the program to still run
                      // before pet.png is added.
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.pets,
                          size: 130,
                          color: Colors.white,
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    _petName,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),

                  const SizedBox(height: 6),

                  Text(
                    'Mood: $_moodLabel',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // --------------------------------------------------
            // Happiness
            // --------------------------------------------------
            _buildMeter(title: 'Happiness', value: _happiness),

            const SizedBox(height: 20),

            // --------------------------------------------------
            // Hunger
            // --------------------------------------------------
            _buildMeter(title: 'Hunger', value: _hunger),

            const SizedBox(height: 30),

            // --------------------------------------------------
            // Game status
            // --------------------------------------------------
            if (_hasWon)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    '🏆 YOU WIN!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

            if (_gameOver)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    '💀 GAME OVER',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

            // --------------------------------------------------
            // Action buttons
            // --------------------------------------------------
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _finished ? null : _feedPet,
                    icon: const Icon(Icons.restaurant),
                    label: const Text('Feed'),
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _finished ? null : _playWithPet,
                    icon: const Icon(Icons.sports_esports),
                    label: const Text('Play'),
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _resetGame,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reset'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // --------------------------------------------------
            // Last action / feedback
            // --------------------------------------------------
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _lastAction,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Goal: Keep happiness above 80 continuously for 3 minutes.',
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 6),

            const Text(
              'Game Over: Hunger reaches 100 while happiness is 10 or lower.',
              textAlign: TextAlign.center,
            ),

            // ==================================================
            // YOU TODO
            // ==================================================
            //
            // 1. Session Controls
            //    - Pause
            //    - Resume
            //
            // 2. Visual Polish
            //    - Animation / bounce
            //    - Animated meters
            //    - Expression/message animation
            //    - Reduced-motion support
            //
            // These are intentionally NOT implemented here.
            // ==================================================
          ],
        ),
      ),
    );
  }

  Widget _buildMeter({required String title, required int value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
            Text('$value / 100'),
          ],
        ),

        const SizedBox(height: 8),

        LinearProgressIndicator(value: value / 100, minHeight: 12),
      ],
    );
  }
}
