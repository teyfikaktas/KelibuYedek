import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter/physics.dart';

typedef SwipingCardDeck = SwipingDeck<Card>;

/// A deck of [Widget] objects that can be swiped to the left or right
/// using a gesture or a button.
// ignore: must_be_immutable
class SwipingDeck<T extends Widget> extends StatelessWidget {
  SwipingDeck(
      {Key? key,
        required this.cardDeck,
        required this.onLeftSwipe,
        required this.onRightSwipe,
        required this.onDeckEmpty,
        required this.cardWidth,
        this.minimumVelocity = 1000,
        this.rotationFactor = .8 / 3.14,
        this.swipeThreshold,
        this.swipeAnimationDuration = const Duration(milliseconds: 500),
        this.disableDragging = false})
      : super(key: key) {
    cardDeck = cardDeck.reversed.toList();
  }

  /// The list of [Widget] objects to be swiped.
  List<T> cardDeck;

  /// Callback function ran when a [Widget] is swiped left.
  final Function(T) onLeftSwipe;

  /// Callback function ran when a [Widget] is swiped right.
  final Function(T) onRightSwipe;

  /// Callback function when the last [Widget] in the [cardDeck] is swiped.
  final Function() onDeckEmpty;

  /// The minimum horizontal velocity required to trigger a swipe.
  final double minimumVelocity;

  /// The amount each [Widget] rotates as it is swiped.
  final double rotationFactor;

  /// The width of all [Widget] objects in the [cardDeck].
  final double cardWidth;

  /// The [Duration] of the swiping [AnimationController].
  final Duration swipeAnimationDuration;

  /// Disable swiping cards using the dragging gesture.
  final bool disableDragging;

  /// The distance in pixels that a [Widget] must be dragged before it is swiped.
  late final double? swipeThreshold;

  /// The [SwipingGestureDetector] used to control swipe animations.
  late final SwipingGestureDetector swipeDetector;

  /// The [Size] of the screen.
  late final Size screenSize;

  bool animationActive = false;
  static const String left = "left";
  static const String right = "right";

  @override
  Widget build(BuildContext context) {
    screenSize = MediaQuery.of(context).size;
    swipeDetector = SwipingGestureDetector(
      cardDeck: cardDeck,
      swipeLeft: swipeLeft,
      swipeRight: swipeRight,
      swipeBack: swipeBack,
      swipeThreshold: swipeThreshold ?? screenSize.width / 4,
      cardWidth: cardWidth,
      rotationFactor: rotationFactor,
      minimumVelocity: minimumVelocity,
      swipeAnimationDuration: swipeAnimationDuration,
      disableDragging: disableDragging,
    );
    return SizedBox(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          SizedBox(
            width: MediaQuery.of(context).size.width,
            child: swipeDetector,
          ),
        ],
      ),
    );
  }

  Future<void> swipeLeft() async {
    if (animationActive || cardDeck.isEmpty) return;
    await _swipeCard(left, screenSize);
    onLeftSwipe(cardDeck.last);
    cardDeck.removeLast();
    if (cardDeck.isEmpty) onDeckEmpty();
  }

  Future<void> swipeRight() async {
    if (animationActive || cardDeck.isEmpty) return;
    await _swipeCard(right, screenSize);
    onRightSwipe(cardDeck.last);
    cardDeck.removeLast();
    if (cardDeck.isEmpty) onDeckEmpty();
  }

  Future<void> swipeBack() async {
    if (animationActive || cardDeck.isEmpty) return;
    T lastCard = cardDeck.removeLast();
    cardDeck.insert(0, lastCard);
    onLeftSwipe(cardDeck.first); // Call function when going back
  }

  Future<void> _swipeCard(String direction, Size screenSize) async {
    double swipeEnd = screenSize.width / 2 + cardWidth;
    swipeDetector.swipe = AlignmentTween(
      begin: swipeDetector.dragAlignment,
      end: Alignment(direction == left ? -swipeEnd : swipeEnd,
          swipeDetector.dragAlignment.x),
    ).animate(
      CurvedAnimation(
        parent: swipeDetector.swipeController,
        curve: Curves.ease,
      ),
    );
    animationActive = true;
    await swipeDetector.swipeController.forward();
    swipeDetector.swipeController.reset();
    animationActive = false;
  }
}

class SwipingGestureDetector<T> extends StatefulWidget {
  SwipingGestureDetector({
    Key? key,
    required this.cardDeck,
    required this.swipeLeft,
    required this.swipeRight,
    required this.swipeBack, // Add swipeBack callback
    required this.cardWidth,
    this.minimumVelocity = 1000,
    this.rotationFactor = .8 / 3.14,
    this.swipeAnimationDuration = const Duration(milliseconds: 500),
    required this.swipeThreshold,
    this.disableDragging = false,
  }) : super(key: key);

  final List<T> cardDeck;
  final Function() swipeLeft, swipeRight, swipeBack;
  final double minimumVelocity;
  final double rotationFactor;
  final double swipeThreshold;
  final double cardWidth;
  final Duration swipeAnimationDuration;
  final bool disableDragging;
  Alignment dragAlignment = Alignment.center;
  late AnimationController swipeController;
  late Animation<Alignment> swipe;

  @override
  State<StatefulWidget> createState() => _SwipingGestureDetector();
}

class _SwipingGestureDetector extends State<SwipingGestureDetector>
    with TickerProviderStateMixin {
  bool animationActive = false;
  late final AnimationController springController;
  late Animation<Alignment> spring;

  @override
  void initState() {
    super.initState();
    springController = AnimationController(vsync: this);
    springController.addListener(() {
      setState(() {
        widget.dragAlignment = spring.value;
      });
    });

    widget.swipeController = AnimationController(
        vsync: this, duration: widget.swipeAnimationDuration);
    widget.swipeController.addListener(() {
      setState(() {
        widget.dragAlignment = widget.swipe.value;
      });
    });
  }

  @override
  void dispose() {
    springController.dispose();
    widget.swipeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    return GestureDetector(
      onPanUpdate: !widget.disableDragging ? _onPanUpdate : (_) {},
      onPanStart: !widget.disableDragging ? _onPanStart : (_) {},
      onPanEnd: !widget.disableDragging
          ? (details) => _onPanEnd(details, screenSize)
          : (_) {},
      child: Stack(
        alignment: Alignment.center,
        children: topTwoCards(),
      ),
    );
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      widget.dragAlignment += Alignment(details.delta.dx, details.delta.dy);
    });
  }

  void _onPanStart(DragStartDetails details) async {
    if (animationActive) {
      springController.stop();
    }
  }

  void _onPanEnd(DragEndDetails details, Size screenSize) async {
    double vx = details.velocity.pixelsPerSecond.dx;
    if (vx >= widget.minimumVelocity ||
        widget.dragAlignment.x >= widget.swipeThreshold) {
      await widget.swipeRight();
    } else if (vx <= -widget.minimumVelocity ||
        widget.dragAlignment.x <= -widget.swipeThreshold) {
      if (widget.dragAlignment.x <= -widget.swipeThreshold) {
        await widget.swipeBack();
      } else {
        await widget.swipeLeft();
      }
    } else {
      animateBackToDeck(details.velocity.pixelsPerSecond, screenSize);
    }
    setState(() {
      widget.dragAlignment = Alignment.center;
    });
  }

  List<Widget> topTwoCards() {
    if (widget.cardDeck.isEmpty) {
      return [
        const SizedBox(
          height: 0,
          width: 0,
        )
      ];
    }
    List<Widget> cardDeck = [];
    int deckLength = widget.cardDeck.length;
    for (int i = max(deckLength - 2, 0); i < deckLength; ++i) {
      cardDeck.add(widget.cardDeck[i]);
    }
    Widget topCard = cardDeck.last;
    cardDeck.removeLast();
    cardDeck.add(
      Align(
          alignment: Alignment(getCardXPosition(), 0),
          child: Transform.rotate(
            angle: getCardAngle(),
            child: topCard,
          )),
    );
    return cardDeck;
  }

  double getCardAngle() {
    final double screenWidth = MediaQuery.of(context).size.width;
    return widget.rotationFactor * (widget.dragAlignment.x / screenWidth);
  }

  double getCardXPosition() {
    final double screenWidth = MediaQuery.of(context).size.width;
    return widget.dragAlignment.x / ((screenWidth - widget.cardWidth) / 2);
  }

  void animateBackToDeck(Offset pixelsPerSecond, Size size) async {
    spring = springController.drive(
      AlignmentTween(
        begin: widget.dragAlignment,
        end: Alignment.center,
      ),
    );

    final unitsPerSecondX = pixelsPerSecond.dx / size.width;
    final unitsPerSecondY = pixelsPerSecond.dy / size.height;
    final unitsPerSecond = Offset(unitsPerSecondX, unitsPerSecondY);
    final unitVelocity = unitsPerSecond.distance;

    const springProps = SpringDescription(
      mass: 30,
      stiffness: 1,
      damping: 1,
    );

    final simulation = SpringSimulation(springProps, 0, 1, -unitVelocity);
    animationActive = true;
    await springController.animateWith(simulation);
    animationActive = false;
  }
}
