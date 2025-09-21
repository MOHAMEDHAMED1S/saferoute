import 'package:flutter/material.dart';
import 'dart:math' as math;

// Custom Page Route with enhanced transitions
class EnhancedPageRoute<T> extends PageRouteBuilder<T> {
  final Widget child;
  final PageTransitionType transitionType;
  final Duration duration;
  final Curve curve;
  final Alignment? alignment;

  EnhancedPageRoute({
    required this.child,
    this.transitionType = PageTransitionType.slideFromRight,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
    this.alignment,
    RouteSettings? settings,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          settings: settings,
        );

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    switch (transitionType) {
      case PageTransitionType.slideFromRight:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: curve,
          )),
          child: child,
        );
      case PageTransitionType.slideFromLeft:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(-1.0, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: curve,
          )),
          child: child,
        );
      case PageTransitionType.slideFromTop:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, -1.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: curve,
          )),
          child: child,
        );
      case PageTransitionType.slideFromBottom:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, 1.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: curve,
          )),
          child: child,
        );
      case PageTransitionType.fade:
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      case PageTransitionType.scale:
        return ScaleTransition(
          scale: Tween<double>(
            begin: 0.0,
            end: 1.0,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: curve,
          )),
          alignment: alignment ?? Alignment.center,
          child: child,
        );
      case PageTransitionType.rotation:
        return RotationTransition(
          turns: Tween<double>(
            begin: 0.0,
            end: 1.0,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: curve,
          )),
          child: child,
        );
      case PageTransitionType.size:
        return SizeTransition(
          sizeFactor: animation,
          child: child,
        );
      case PageTransitionType.fadeScale:
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(
              begin: 0.8,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: curve,
            )),
            child: child,
          ),
        );
      case PageTransitionType.slideRotate:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: curve,
          )),
          child: RotationTransition(
            turns: Tween<double>(
              begin: 0.1,
              end: 0.0,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: curve,
            )),
            child: child,
          ),
        );
      case PageTransitionType.custom:
        return _buildCustomTransition(animation, secondaryAnimation, child);
    }
  }

  Widget _buildCustomTransition(
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // Custom 3D flip transition
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final rotateY = (1.0 - animation.value) * math.pi / 2;
        if (rotateY >= math.pi / 2) {
          return Container();
        }
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(rotateY),
          child: child,
        );
      },
      child: child,
    );
  }
}

enum PageTransitionType {
  slideFromRight,
  slideFromLeft,
  slideFromTop,
  slideFromBottom,
  fade,
  scale,
  rotation,
  size,
  fadeScale,
  slideRotate,
  custom,
}

// Hero Animation Widget
class EnhancedHero extends StatelessWidget {
  final String tag;
  final Widget child;
  final Duration? flightShuttleBuilder;
  final HeroFlightShuttleBuilder? customFlightShuttleBuilder;

  const EnhancedHero({
    Key? key,
    required this.tag,
    required this.child,
    this.flightShuttleBuilder,
    this.customFlightShuttleBuilder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: tag,
      flightShuttleBuilder: customFlightShuttleBuilder ??
          (flightContext, animation, flightDirection, fromHeroContext, toHeroContext) {
            return ScaleTransition(
              scale: animation.drive(
                Tween<double>(begin: 0.0, end: 1.0).chain(
                  CurveTween(curve: Curves.fastOutSlowIn),
                ),
              ),
              child: flightDirection == HeroFlightDirection.push
                  ? toHeroContext.widget
                  : fromHeroContext.widget,
            );
          },
      child: child,
    );
  }
}

// Animated List Item
class AnimatedListItem extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration delay;
  final Duration duration;
  final Curve curve;
  final AnimationType animationType;
  final double? slideDistance;
  final Axis? slideDirection;

  const AnimatedListItem({
    Key? key,
    required this.child,
    required this.index,
    this.delay = const Duration(milliseconds: 100),
    this.duration = const Duration(milliseconds: 500),
    this.curve = Curves.easeOutBack,
    this.animationType = AnimationType.slideUp,
    this.slideDistance,
    this.slideDirection,
  }) : super(key: key);

  @override
  State<AnimatedListItem> createState() => _AnimatedListItemState();
}

class _AnimatedListItemState extends State<AnimatedListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    );

    _slideAnimation = Tween<Offset>(
      begin: _getSlideBeginOffset(),
      end: Offset.zero,
    ).animate(_animation);

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_animation);

    _rotationAnimation = Tween<double>(
      begin: 0.5,
      end: 0.0,
    ).animate(_animation);

    // Start animation with delay
    Future.delayed(
      Duration(milliseconds: widget.delay.inMilliseconds * widget.index),
      () {
        if (mounted) {
          _controller.forward();
        }
      },
    );
  }

  Offset _getSlideBeginOffset() {
    final distance = widget.slideDistance ?? 50.0;
    switch (widget.animationType) {
      case AnimationType.slideUp:
        return Offset(0, distance / 100);
      case AnimationType.slideDown:
        return Offset(0, -distance / 100);
      case AnimationType.slideLeft:
        return Offset(distance / 100, 0);
      case AnimationType.slideRight:
        return Offset(-distance / 100, 0);
      default:
        return Offset(0, distance / 100);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.animationType) {
      case AnimationType.slideUp:
      case AnimationType.slideDown:
      case AnimationType.slideLeft:
      case AnimationType.slideRight:
        return SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _animation,
            child: widget.child,
          ),
        );
      case AnimationType.scale:
        return ScaleTransition(
          scale: _scaleAnimation,
          child: FadeTransition(
            opacity: _animation,
            child: widget.child,
          ),
        );
      case AnimationType.rotation:
        return RotationTransition(
          turns: _rotationAnimation,
          child: FadeTransition(
            opacity: _animation,
            child: widget.child,
          ),
        );
      case AnimationType.fade:
        return FadeTransition(
          opacity: _animation,
          child: widget.child,
        );
      case AnimationType.slideScale:
        return SlideTransition(
          position: _slideAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: FadeTransition(
              opacity: _animation,
              child: widget.child,
            ),
          ),
        );
    }
  }
}

enum AnimationType {
  slideUp,
  slideDown,
  slideLeft,
  slideRight,
  scale,
  rotation,
  fade,
  slideScale,
}

// Staggered Animation Widget
class StaggeredAnimationWidget extends StatefulWidget {
  final List<Widget> children;
  final Duration delay;
  final Duration duration;
  final Curve curve;
  final AnimationType animationType;
  final Axis direction;

  const StaggeredAnimationWidget({
    Key? key,
    required this.children,
    this.delay = const Duration(milliseconds: 100),
    this.duration = const Duration(milliseconds: 500),
    this.curve = Curves.easeOutBack,
    this.animationType = AnimationType.slideUp,
    this.direction = Axis.vertical,
  }) : super(key: key);

  @override
  State<StaggeredAnimationWidget> createState() => _StaggeredAnimationWidgetState();
}

class _StaggeredAnimationWidgetState extends State<StaggeredAnimationWidget> {
  @override
  Widget build(BuildContext context) {
    return widget.direction == Axis.vertical
        ? Column(
            children: widget.children
                .asMap()
                .entries
                .map(
                  (entry) => AnimatedListItem(
                    index: entry.key,
                    delay: widget.delay,
                    duration: widget.duration,
                    curve: widget.curve,
                    animationType: widget.animationType,
                    child: entry.value,
                  ),
                )
                .toList(),
          )
        : Row(
            children: widget.children
                .asMap()
                .entries
                .map(
                  (entry) => AnimatedListItem(
                    index: entry.key,
                    delay: widget.delay,
                    duration: widget.duration,
                    curve: widget.curve,
                    animationType: widget.animationType,
                    child: entry.value,
                  ),
                )
                .toList(),
          );
  }
}

// Parallax Effect Widget
class ParallaxWidget extends StatefulWidget {
  final Widget child;
  final double speed;
  final Axis direction;

  const ParallaxWidget({
    Key? key,
    required this.child,
    this.speed = 0.5,
    this.direction = Axis.vertical,
  }) : super(key: key);

  @override
  State<ParallaxWidget> createState() => _ParallaxWidgetState();
}

class _ParallaxWidgetState extends State<ParallaxWidget> {
  late ScrollController _scrollController;
  double _offset = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_updateOffset);
  }

  void _updateOffset() {
    setState(() {
      _offset = _scrollController.offset * widget.speed;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: widget.direction == Axis.vertical
          ? Offset(0, _offset)
          : Offset(_offset, 0),
      child: widget.child,
    );
  }
}

// Morphing Container
class MorphingContainer extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;
  final Color? fromColor;
  final Color? toColor;
  final BorderRadius? fromBorderRadius;
  final BorderRadius? toBorderRadius;
  final EdgeInsetsGeometry? fromPadding;
  final EdgeInsetsGeometry? toPadding;
  final bool isExpanded;

  const MorphingContainer({
    Key? key,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
    this.fromColor,
    this.toColor,
    this.fromBorderRadius,
    this.toBorderRadius,
    this.fromPadding,
    this.toPadding,
    required this.isExpanded,
  }) : super(key: key);

  @override
  State<MorphingContainer> createState() => _MorphingContainerState();
}

class _MorphingContainerState extends State<MorphingContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _colorAnimation;
  late Animation<BorderRadius?> _borderRadiusAnimation;
  late Animation<EdgeInsetsGeometry?> _paddingAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _colorAnimation = ColorTween(
      begin: widget.fromColor,
      end: widget.toColor,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    _borderRadiusAnimation = BorderRadiusTween(
      begin: widget.fromBorderRadius,
      end: widget.toBorderRadius,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    _paddingAnimation = EdgeInsetsGeometryTween(
      begin: widget.fromPadding,
      end: widget.toPadding,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    if (widget.isExpanded) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(MorphingContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExpanded != oldWidget.isExpanded) {
      if (widget.isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            color: _colorAnimation.value,
            borderRadius: _borderRadiusAnimation.value,
          ),
          padding: _paddingAnimation.value,
          child: widget.child,
        );
      },
    );
  }
}

// Floating Action Button with animations
class AnimatedFloatingActionButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final Color? backgroundColor;
  final double? elevation;
  final ShapeBorder? shape;
  final bool isVisible;
  final Duration animationDuration;

  const AnimatedFloatingActionButton({
    Key? key,
    this.onPressed,
    required this.child,
    this.backgroundColor,
    this.elevation,
    this.shape,
    this.isVisible = true,
    this.animationDuration = const Duration(milliseconds: 300),
  }) : super(key: key);

  @override
  State<AnimatedFloatingActionButton> createState() => _AnimatedFloatingActionButtonState();
}

class _AnimatedFloatingActionButtonState extends State<AnimatedFloatingActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    if (widget.isVisible) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(AnimatedFloatingActionButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.rotate(
            angle: _rotationAnimation.value * 2 * math.pi,
            child: FloatingActionButton(
              onPressed: widget.onPressed,
              backgroundColor: widget.backgroundColor,
              elevation: widget.elevation,
              shape: widget.shape,
              child: widget.child,
            ),
          ),
        );
      },
    );
  }
}