import 'package:eschool_saas_staff/data/models/auth/permissionDetails.dart';
import 'package:eschool_saas_staff/ui/widgets/system/permissionDetailsContainer.dart';
import 'package:flutter/material.dart';

class StackedPermissionSwiper extends StatefulWidget {
  final List<PermissionDetails> permissions;
  final VoidCallback? onPermissionUpdated;
  const StackedPermissionSwiper({
    super.key,
    required this.permissions,
    this.onPermissionUpdated,
  });

  @override
  State<StackedPermissionSwiper> createState() => _StackedPermissionSwiperState();
}

class _StackedPermissionSwiperState extends State<StackedPermissionSwiper>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  double _dragOffset = 0.0;
  late AnimationController _animController;
  late Animation<double> _slideAnimation;
  bool _isAnimating = false;

  bool _isSettlingLeftCard = false;
  bool _isSettlingRightCard = false;
  double _leftCardSettleOffset = 0.0;
  double _rightCardSettleOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _animController.addListener(() {
      setState(() {
        if (_isSettlingLeftCard) {
          _leftCardSettleOffset = _slideAnimation.value;
        } else if (_isSettlingRightCard) {
          _rightCardSettleOffset = _slideAnimation.value;
        } else {
          _dragOffset = _slideAnimation.value;
        }
      });
    });
  }

  @override
  void didUpdateWidget(covariant StackedPermissionSwiper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_currentIndex >= widget.permissions.length) {
      _currentIndex = widget.permissions.isNotEmpty ? widget.permissions.length - 1 : 0;
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (_isAnimating) return;
    double delta = details.primaryDelta ?? 0.0;

    final cardWidth = MediaQuery.of(context).size.width * 0.82;
    final peekOffset = cardWidth - 12.0;

    final isLastCard = _currentIndex == widget.permissions.length - 1;
    final isFirstCard = _currentIndex == 0;

    setState(() {
      if (isLastCard && (_dragOffset + delta) < 0) {
        // Rubber-band resistance dragging left past the last card
        _dragOffset += delta * 0.35;
      } else if (isFirstCard && (_dragOffset + delta) > 0) {
        // Rubber-band resistance dragging right past the first card
        _dragOffset += delta * 0.35;
      } else {
        _dragOffset += delta;
      }

      // Clamp dragOffset to not exceed boundaries too far
      if (!isLastCard && _dragOffset < -peekOffset - 20) {
        _dragOffset = -peekOffset - 20;
      }
      if (!isFirstCard && _dragOffset > peekOffset + 20) {
        _dragOffset = peekOffset + 20;
      }
    });
  }

  void _onDragEnd(DragEndDetails details) {
    if (_isAnimating) return;
    final cardWidth = MediaQuery.of(context).size.width * 0.82;
    final peekOffset = cardWidth - 12.0;
    final velocity = details.velocity.pixelsPerSecond.dx;

    final isLastCard = _currentIndex == widget.permissions.length - 1;
    final isFirstCard = _currentIndex == 0;

    // Swipe left threshold (only if not the last card)
    if ((_dragOffset < -80 || velocity < -400) && !isLastCard) {
      _swipeLeft(peekOffset);
    }
    // Swipe right threshold (go back to previous card, only if not the first card)
    else if ((_dragOffset > 80 || velocity > 400) && !isFirstCard && _currentIndex > 0) {
      _swipeRight(peekOffset);
    }
    // Reset position
    else {
      _resetPosition();
    }
  }

  void _swipeLeft(double peekOffset) {
    _isAnimating = true;
    _animController.duration = const Duration(milliseconds: 200);
    _slideAnimation = Tween<double>(
      begin: _dragOffset,
      end: -peekOffset,
    ).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );

    _animController.forward(from: 0.0).then((_) {
      setState(() {
        _currentIndex++;
        _dragOffset = 0.0;
        _isSettlingLeftCard = true;
      });

      _animController.duration = const Duration(milliseconds: 200);
      _slideAnimation = Tween<double>(
        begin: -peekOffset + 16.0,
        end: 0.0,
      ).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
      );

      _animController.forward(from: 0.0).then((_) {
        setState(() {
          _isSettlingLeftCard = false;
          _isAnimating = false;
        });
      });
    });
  }

  void _swipeRight(double peekOffset) {
    _isAnimating = true;
    _animController.duration = const Duration(milliseconds: 200);
    _slideAnimation = Tween<double>(
      begin: _dragOffset,
      end: peekOffset,
    ).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );

    _animController.forward(from: 0.0).then((_) {
      setState(() {
        _currentIndex--;
        _dragOffset = 0.0;
        _isSettlingRightCard = true;
      });

      _animController.duration = const Duration(milliseconds: 200);
      _slideAnimation = Tween<double>(
        begin: peekOffset - 16.0,
        end: 0.0,
      ).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
      );

      _animController.forward(from: 0.0).then((_) {
        setState(() {
          _isSettlingRightCard = false;
          _isAnimating = false;
        });
      });
    });
  }

  void _resetPosition() {
    _isAnimating = true;
    _animController.duration = const Duration(milliseconds: 200);
    _slideAnimation = Tween<double>(
      begin: _dragOffset,
      end: 0.0,
    ).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );

    _animController.forward(from: 0.0).then((_) {
      setState(() {
        _isAnimating = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.permissions.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = MediaQuery.of(context).size.width * 0.82;
        final screenWidth = MediaQuery.of(context).size.width;
        final peekOffset = cardWidth - 12.0;

        List<Widget> cards = [];

        // 1. Previous Card (rendered on the left side)
        if (_currentIndex > 0) {
          cards.addAll([
            _buildCardItem(
              permission: widget.permissions[_currentIndex - 1],
              cardWidth: cardWidth,
              screenWidth: screenWidth,
              peekOffset: peekOffset,
              positionIndex: -1,
              key: ValueKey(widget.permissions[_currentIndex - 1].id ?? (_currentIndex - 1).toString()),
            )
          ]);
        }

        // 2. Next Card (rendered behind the center card, showing slightly to the right)
        if (_currentIndex + 1 < widget.permissions.length) {
          cards.add(_buildCardItem(
            permission: widget.permissions[_currentIndex + 1],
            cardWidth: cardWidth,
            screenWidth: screenWidth,
            peekOffset: peekOffset,
            positionIndex: 1,
            key: ValueKey(widget.permissions[_currentIndex + 1].id ?? (_currentIndex + 1).toString()),
          ));
        }

        // 3. Active Card (center card, handles dragging - always rendered on top)
        if (_currentIndex < widget.permissions.length) {
          cards.add(_buildCardItem(
            permission: widget.permissions[_currentIndex],
            cardWidth: cardWidth,
            screenWidth: screenWidth,
            peekOffset: peekOffset,
            positionIndex: 0,
            key: ValueKey(widget.permissions[_currentIndex].id ?? _currentIndex.toString()),
          ));
        }

        return Stack(
          clipBehavior: Clip.none,
          children: cards,
        );
      },
    );
  }

  Widget _buildCardItem({
    required PermissionDetails permission,
    required double cardWidth,
    required double screenWidth,
    required double peekOffset,
    required int positionIndex,
    required Key key,
  }) {
    double translateX = 0.0;
    double translateY = 0.0;
    double scale = 1.0;
    double opacity = 1.0;
    double rotation = 0.0;

    final isActive = positionIndex == 0;

    if (positionIndex == 0) {
      // Center Card (Active)
      double dragRatio = (_dragOffset / screenWidth).clamp(-1.0, 1.0);
      rotation = dragRatio * 0.15;

      if (_dragOffset < 0.0) {
        // Dragging left (dismiss to left peek)
        translateX = _dragOffset;
        scale = 1.0 - (dragRatio.abs() * 0.06);
        opacity = 1.0 - (dragRatio.abs() * 0.45);
      } else {
        // Dragging right (yielding to left card, stacking behind)
        double ratio = (_dragOffset / peekOffset).clamp(0.0, 1.0);
        translateX = _dragOffset;
        translateY = ratio * 8.0;
        scale = 1.0 - (ratio * 0.04);
        opacity = 1.0 - (ratio * 0.45);
      }
    } else if (positionIndex == -1) {
      // Left Card (Previous)
      double settleOffset = _isSettlingLeftCard ? _leftCardSettleOffset : 0.0;
      translateX = -16.0 + settleOffset;
      translateY = 8.0;
      scale = 0.96;
      opacity = 0.55;

      if (_isSettlingLeftCard) {
        double ratio = (settleOffset.abs() / (peekOffset - 16.0)).clamp(0.0, 1.0);
        scale = 0.96 - (ratio * 0.02);
      } else {
        if (_dragOffset > 0.0) {
          // Pulling left card to center
          double ratio = (_dragOffset / peekOffset).clamp(0.0, 1.0);
          translateX = -16.0 + (ratio * 16.0);
          translateY = 8.0 - (ratio * 8.0);
          scale = 0.96 + (ratio * 0.04);
          opacity = 0.55 + (ratio * 0.45);
        } else if (_dragOffset < 0.0) {
          // Active card moves further left, push left card out of screen
          double ratio = (_dragOffset.abs() / peekOffset).clamp(0.0, 1.0);
          translateX = -16.0 - (ratio * (peekOffset - 16.0));
          scale = 0.96 - (ratio * 0.02);
          opacity = (0.55 - (ratio * 0.55)).clamp(0.0, 0.55);
        }
      }
    } else if (positionIndex == 1) {
      // Right Card (Next)
      double settleOffset = _isSettlingRightCard ? _rightCardSettleOffset : 0.0;
      translateX = 16.0 + settleOffset;
      translateY = 8.0;
      scale = 0.96;
      opacity = 0.55;

      if (_isSettlingRightCard) {
        double ratio = (settleOffset.abs() / (peekOffset - 16.0)).clamp(0.0, 1.0);
        scale = 0.96 - (ratio * 0.02);
      } else {
        if (_dragOffset < 0.0) {
          // Pulling right card to center
          double ratio = (_dragOffset.abs() / peekOffset).clamp(0.0, 1.0);
          translateX = 16.0 - (ratio * 16.0);
          translateY = 8.0 - (ratio * 8.0);
          scale = 0.96 + (ratio * 0.04);
          opacity = 0.55 + (ratio * 0.45);
        } else if (_dragOffset > 0.0) {
          // Active card moves to right, fade out right card
          double ratio = (_dragOffset / peekOffset).clamp(0.0, 1.0);
          translateX = 16.0 + (ratio * (peekOffset - 16.0));
          scale = 0.96 - (ratio * 0.02);
          opacity = (0.55 - (ratio * 0.55)).clamp(0.0, 0.55);
        }
      }
    }

    return GestureDetector(
      key: key,
      behavior: isActive ? HitTestBehavior.deferToChild : HitTestBehavior.translucent,
      onHorizontalDragUpdate: isActive ? _onDragUpdate : null,
      onHorizontalDragEnd: isActive ? _onDragEnd : null,
      child: Transform.translate(
        offset: Offset(translateX, translateY),
        child: Transform.scale(
          scale: scale,
          child: Transform.rotate(
            angle: rotation,
            child: Opacity(
              opacity: opacity.clamp(0.0, 1.0),
              child: Center(
                child: SizedBox(
                  width: cardWidth,
                  child: RepaintBoundary(
                    child: PermissionDetailsContainer(
                      permissionDetails: permission,
                      isCompact: true,
                      onPermissionUpdated: widget.onPermissionUpdated,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
