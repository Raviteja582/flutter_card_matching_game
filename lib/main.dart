import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

void main() => runApp(const MemoryGame());

class MemoryGame extends StatelessWidget {
  const MemoryGame({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: GameScreen(),
    );
  }
}

class CardModel {
  final String frontAsset;
  final String backAsset;
  bool isFaceUp;
  bool isMatched;

  CardModel({
    required this.frontAsset,
    this.backAsset = 'assets/profile.jpeg',
    this.isFaceUp = false,
    this.isMatched = false,
  });

  resetCards() {
    isFaceUp = false;
    isMatched = false;
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  final int gridSize = 4;
  final List<CardModel> _cards = [];
  CardModel? _firstCard;
  CardModel? _secondCard;
  bool _isChecking = false;
  bool _isGameComplete = false;
  late AnimationController _controller;

  // Timer and scoring variables
  Timer? _timer;
  int _seconds = 0;
  int _score = 0;
  List<int> _topScores = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _initializeCards();
  }

  void _initializeCards() {
    List<String> cardImages = [
      'assets/christ.jpg',
      'assets/great_wall_china.jpg',
      'assets/pyramid.jpg',
      'assets/taj_mahal.jpg',
    ];

    cardImages = [...cardImages, ...cardImages];
    cardImages.shuffle(Random());

    _cards.clear();
    for (String asset in cardImages) {
      _cards.add(CardModel(frontAsset: asset));
    }

    _resetGame();
  }

  void _resetGame() {
    setState(() {
      _firstCard = null;
      _secondCard = null;
      _isChecking = false;
      _isGameComplete = false;

      for (int i = 0; i < _cards.length; i++) {
        _cards[i].resetCards();
      }

      _cards.shuffle(Random());

      _seconds = 0;
      _score = 0;
      _startTimer();
    });
  }

  void _onCardTap(int index) {
    if (_isChecking || _cards[index].isFaceUp || _cards[index].isMatched) {
      return;
    }

    setState(() {
      _cards[index].isFaceUp = true;
      if (_firstCard == null) {
        _firstCard = _cards[index];
      } else if (_secondCard == null) {
        _secondCard = _cards[index];
        _checkMatch();
      }
    });
  }

  void _checkMatch() {
    _isChecking = true;
    if (_firstCard!.frontAsset == _secondCard!.frontAsset) {
      setState(() {
        _firstCard!.isMatched = true;
        _secondCard!.isMatched = true;
        _firstCard = null;
        _secondCard = null;
        _isChecking = false;
        _score += 10;

        if (_cards.every((card) => card.isMatched)) {
          _completeGame();
        }
      });
    } else {
      Future.delayed(const Duration(seconds: 1), () {
        setState(() {
          _firstCard!.isFaceUp = false;
          _secondCard!.isFaceUp = false;
          _firstCard = null;
          _secondCard = null;
          _isChecking = false;
          _score -= 5; // Deduct points for a mismatch
        });
      });
    }
  }

  void _completeGame() {
    _isGameComplete = true;
    _timer?.cancel();
    _topScores.add(_seconds);
    _topScores.sort();
    if (_topScores.length > 10) _topScores = _topScores.sublist(0, 10);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Congratulations!"),
        content: Text("You completed the game in ${_seconds}s\nScore: $_score"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resetGame();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isGameComplete) {
        setState(() {
          _seconds++;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Memory Game'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetGame,
          ),
        ],
        backgroundColor: Colors.red,
      ),
      body: Container(
        color: Colors.red,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Timer: ${_seconds}s',
                    style: const TextStyle(fontSize: 24, color: Colors.white),
                  ),
                  Text(
                    'Score: $_score',
                    style: const TextStyle(fontSize: 24, color: Colors.white),
                  ),
                ],
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(8.0),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: gridSize,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: _cards.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () => _onCardTap(index),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      transitionBuilder:
                          (Widget child, Animation<double> animation) {
                        return RotationYTransition(
                          turns: animation,
                          child: child,
                        );
                      },
                      child: SizedBox(
                        width: 80,
                        height: 80,
                        child: _cards[index].isFaceUp || _cards[index].isMatched
                            ? Image.asset(_cards[index].frontAsset,
                                key: ValueKey(_cards[index].frontAsset))
                            : Image.asset(_cards[index].backAsset,
                                key: const ValueKey('back')),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  const Text(
                    'Top 10 Scores',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  for (var i = 0; i < _topScores.length; i++)
                    Text('${i + 1}. ${_topScores[i]}s',
                        style:
                            const TextStyle(fontSize: 16, color: Colors.white)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer?.cancel();
    super.dispose();
  }
}

class RotationYTransition extends AnimatedWidget {
  const RotationYTransition({
    super.key,
    required Animation<double> turns,
    this.alignment = Alignment.center,
    this.child,
  }) : super(listenable: turns);

  final Widget? child;
  final Alignment alignment;

  Animation<double> get turns => listenable as Animation<double>;

  @override
  Widget build(BuildContext context) {
    final double angle = turns.value * pi;
    return Transform(
      transform: Matrix4.rotationY(angle),
      alignment: alignment,
      child: child,
    );
  }
}
