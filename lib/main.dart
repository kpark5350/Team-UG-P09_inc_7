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
  // Restore these production values before the release build.
  static const Duration _hungerInterval = Duration(seconds: 30);
  static const Duration _winDuration = Duration(minutes: 3);

  static const int _initialHappiness = 50;
  static const int _initialHunger = 50;

  int _happiness = _initialHappiness;
  int _hunger = _initialHunger;

  String _petName = 'Pip';
  String _lastAction = 'Choose an action to care for your pet.';

  bool _gameOver = false;
  bool _hasWon = false;
  bool _paused = false;

  Timer? _hungerTimer;
  Timer? _highMoodTimer;

  // Win countdown bookkeeping so pause/resume keeps the remaining time.
  Duration _winRemaining = _winDuration;
  DateTime? _winStartedAt;

  // Short-lived animation state only.
  Timer? _bounceTimer;
  bool _bouncing = false;

  final TextEditingController _nameController =
      TextEditingController(text: 'Pip');

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
    _bounceTimer?.cancel();
    _nameController.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------
  // Helpers
  // ------------------------------------------------------------

  int _clampMeter(int value) => value.clamp(0, 100).toInt();

  bool get _finished => _gameOver || _hasWon;

  // Care actions are blocked after an outcome or while paused.
  bool get _locked => _finished || _paused;

  String get _moodLabel {
    if (_happiness > 70) return 'Happy';
    if (_happiness >= 30) return 'Neutral';
    return 'Unhappy';
  }

  Color get _moodColor {
    if (_happiness > 70) return Colors.green;
    if (_happiness >= 30) return Colors.yellow;
    return Colors.red;
  }

  // Restrained size change from the same happiness bands.
  double get _petScale {
    if (_happiness > 70) return 1.06;
    if (_happiness < 30) return 0.94;
    return 1.0;
  }

  // Derived speech so it can never drift out of sync with state.
  String get _petMessage {
    if (_gameOver) return 'I need a rest.';
    if (_hasWon) return 'Best day ever!';
    if (_paused) return 'Taking a break...';
    if (_hunger > 80) return "I'm starving!";
    if (_happiness <= 30) return 'Play with me?';
    return "Hi, I'm $_petName!";
  }

  bool get _reduceMotion => MediaQuery.of(context).disableAnimations;

  Duration _dur(int ms) =>
      _reduceMotion ? Duration.zero : Duration(milliseconds: ms);

  // ------------------------------------------------------------
  // Bounce (guarded, newer bounce replaces older reset)
  // ------------------------------------------------------------

  void _bounce() {
    _bounceTimer?.cancel();
    setState(() => _bouncing = true);
    _bounceTimer = Timer(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      setState(() => _bouncing = false);
    });
  }

  // ------------------------------------------------------------
  // Hunger timer
  // 95 -> 100 = no penalty. A tick that would exceed 100 clamps
  // hunger and reduces happiness by 20.
  // ------------------------------------------------------------

  void _startHungerTimer() {
    _hungerTimer?.cancel();

    _hungerTimer = Timer.periodic(_hungerInterval, (timer) {
      if (!mounted || _locked) {
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
  // Feed / Play
  // ------------------------------------------------------------

  void _feedPet() {
    if (_locked) return;

    final int nextHunger = _clampMeter(_hunger - 10);
    final int happinessChange = nextHunger < 30 ? -20 : 10;
    final int nextHappiness = _clampMeter(_happiness + happinessChange);

    setState(() {
      _hunger = nextHunger;
      _happiness = nextHappiness;
      _lastAction = happinessChange < 0
          ? '$_petName is too full. Happiness decreased.'
          : 'You fed $_petName. Hunger decreased!';
    });

    _bounce();
    _updateOutcome();
  }

  void _playWithPet() {
    if (_locked) return;

    final int nextHappiness = _clampMeter(_happiness + 15);
    final int nextHunger = _clampMeter(_hunger + 5);

    setState(() {
      _happiness = nextHappiness;
      _hunger = nextHunger;
      _lastAction = 'You played with $_petName. Happiness increased!';
    });

    _bounce();
    _updateOutcome();
  }

  // ------------------------------------------------------------
  // Win timer helpers
  // ------------------------------------------------------------

  /// Cancel the win countdown. Restores the full duration when
  /// [resetRemaining] is true (happiness dropped, loss, or reset).
  void _cancelWinTimer({required bool resetRemaining}) {
    _highMoodTimer?.cancel();
    _highMoodTimer = null;
    _winStartedAt = null;
    if (resetRemaining) _winRemaining = _winDuration;
  }

  void _startWinTimer() {
    _winStartedAt = DateTime.now();
    _highMoodTimer = Timer(_winRemaining, () {
      _highMoodTimer = null;
      _winStartedAt = null;

      if (!mounted || _gameOver || _paused) return;

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
  // Win / Loss
  // ------------------------------------------------------------

  void _updateOutcome() {
    if (_finished || _paused) return;

    // Loss
    if (_hunger == 100 && _happiness <= 10) {
      _cancelWinTimer(resetRemaining: true);
      _hungerTimer?.cancel();

      setState(() {
        _gameOver = true;
        _lastAction = 'Game Over! $_petName is too hungry and unhappy.';
      });
      return;
    }

    // Dropped to 80 or below: cancel and clear the pending win.
    if (_happiness <= 80) {
      _cancelWinTimer(resetRemaining: true);
      return;
    }

    // Above 80: start only if one is not already running.
    if (_highMoodTimer == null) _startWinTimer();
  }

  // ------------------------------------------------------------
  // Pause / Resume (Session Controls)
  // ------------------------------------------------------------

  void _pauseGame() {
    if (_finished || _paused) return;

    // Freeze the win countdown and remember the time left.
    if (_highMoodTimer != null && _winStartedAt != null) {
      final elapsed = DateTime.now().difference(_winStartedAt!);
      final left = _winRemaining - elapsed;
      _winRemaining = left.isNegative ? Duration.zero : left;
    }
    _cancelWinTimer(resetRemaining: false);
    _hungerTimer?.cancel();

    setState(() {
      _paused = true;
      _lastAction = 'Game paused.';
    });
  }

  void _resumeGame() {
    if (_finished || !_paused) return;

    setState(() {
      _paused = false;
      _lastAction = 'Game resumed. Take care of $_petName!';
    });

    _startHungerTimer();
    _updateOutcome(); // restarts the win timer with the time left
  }

  // ------------------------------------------------------------
  // Reset (core requirement)
  // ------------------------------------------------------------

  void _resetGame() {
    _cancelWinTimer(resetRemaining: true);

    setState(() {
      _happiness = _initialHappiness;
      _hunger = _initialHunger;
      _gameOver = false;
      _hasWon = false;
      _paused = false;
      _lastAction = 'Game reset. Take care of $_petName!';
    });

    _startHungerTimer(); // cancels the old one first
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

            // Pet
            Center(
              child: Column(
                children: [
                  AnimatedScale(
                    scale: _petScale * (_bouncing ? 1.15 : 1.0),
                    duration: _dur(180),
                    curve: Curves.easeOutBack,
                    child: ColorFiltered(
                      colorFilter:
                          ColorFilter.mode(_moodColor, BlendMode.modulate),
                      child: Image.asset(
                        'assets/pet.png',
                        width: 160,
                        height: 160,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.pets,
                              size: 130, color: Colors.white);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(_petName,
                      style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 6),
                  Text('Mood: $_moodLabel',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 10),

                  // Expression / speech bubble cross-fade
                  AnimatedSwitcher(
                    duration: _dur(300),
                    child: Container(
                      key: ValueKey(_petMessage),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .secondaryContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(_petMessage),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            _buildMeter(title: 'Happiness', value: _happiness),
            const SizedBox(height: 20),
            _buildMeter(title: 'Hunger', value: _hunger),
            const SizedBox(height: 30),

            if (_paused)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    '⏸ PAUSED',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

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

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _locked ? null : _feedPet,
                    icon: const Icon(Icons.restaurant),
                    label: const Text('Feed'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _locked ? null : _playWithPet,
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
            const SizedBox(height: 10),

            // Session controls
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _finished
                    ? null
                    : (_paused ? _resumeGame : _pauseGame),
                icon: Icon(_paused ? Icons.play_arrow : Icons.pause),
                label: Text(_paused ? 'Resume' : 'Pause'),
              ),
            ),
            const SizedBox(height: 20),

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
          ],
        ),
      ),
    );
  }

  Widget _buildMeter({required String title, required int value}) {
    return Semantics(
      label: '$title $value out of 100',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 17)),
              Text('$value / 100'),
            ],
          ),
          const SizedBox(height: 8),
          // Living meter: glides to the current state value.
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: value / 100),
            duration: _dur(400),
            curve: Curves.easeOut,
            builder: (context, v, _) =>
                LinearProgressIndicator(value: v, minHeight: 12),
          ),
        ],
      ),
    );
  }
}