import 'package:flutter/material.dart';
import 'dart:math';

void main() => runApp(const MemoryGame());

class MemoryGame extends StatelessWidget {
  const MemoryGame({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
}

class GameScreen extends StatefulWidget {
  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  final int gridSize = 4;
  final List<CardModel> _cards = [];
  CardModel? _firstCard;
  CardModel? _secondCard;
  bool _isChecking = false;
  late AnimationController _controller;

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
  }

  void _resetCards() {
    setState(() {
      _initializeCards();
      _firstCard = null;
      _secondCard = null;
      _isChecking = false;
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
      });
    } else {
      Future.delayed(const Duration(seconds: 1), () {
        setState(() {
          _firstCard!.isFaceUp = false;
          _secondCard!.isFaceUp = false;
          _firstCard = null;
          _secondCard = null;
          _isChecking = false;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Memory Game'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetCards,
          )
        ],
      ),
      body: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: gridSize,
        ),
        itemCount: _cards.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => _onCardTap(index),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return RotationYTransition(
                  turns: animation,
                  child: child,
                );
              },
              child: _cards[index].isFaceUp || _cards[index].isMatched
                  ? Image.asset(_cards[index].frontAsset,
                      key: ValueKey(_cards[index].frontAsset))
                  : Image.asset(_cards[index].backAsset,
                      key: const ValueKey('back')),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
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
