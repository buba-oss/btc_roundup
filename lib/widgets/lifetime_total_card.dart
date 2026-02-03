import 'package:flutter/material.dart';
import '../utils/formatters.dart';

class LifetimeTotalCard extends StatefulWidget {
  final double euroTotal;
  final int satsTotal;

  const LifetimeTotalCard({
    super.key,
    required this.euroTotal,
    required this.satsTotal,
  });

  @override
  State<LifetimeTotalCard> createState() => _LifetimeTotalCardState();
}

class _LifetimeTotalCardState extends State<LifetimeTotalCard> {
  double _prevEuro = 0;
  int _prevSats = 0;

  bool _flashEuro = false;
  bool _flashSats = false;

  @override
  @override
  void didUpdateWidget(covariant LifetimeTotalCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    // EURO
    if (widget.euroTotal != _prevEuro) {
      _flashEuro = true;
      _resetFlash(() => _flashEuro = false);
    }

    // SATS
    if (widget.satsTotal != _prevSats) {
      _flashSats = true;
      _resetFlash(() => _flashSats = false);
    }

    _prevEuro = widget.euroTotal;
    _prevSats = widget.satsTotal;
  }

  void _resetFlash(VoidCallback reset) {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(reset);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Lifetime Round-Ups',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),

            // 💶 EURO ANIMATION
            TweenAnimationBuilder<double>(
              tween: Tween(
                begin: _prevEuro,
                end: widget.euroTotal,
              ),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                final isDown = widget.euroTotal < _prevEuro;

                return AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 300),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _flashEuro
                        ? (isDown ? Colors.red : Colors.green)
                        : Colors.black,
                  ),
                  child: Text(Formatters.formatEuro(value)),
                );
              },
            ),

            const SizedBox(height: 6),

            // ₿ SATS ANIMATION
            TweenAnimationBuilder<double>(
              tween: Tween(
                begin: _prevSats.toDouble(),
                end: widget.satsTotal.toDouble(),
              ),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                final isDown = widget.satsTotal < _prevSats;

                return AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 300),
                  style: TextStyle(
                    fontSize: 16,
                    color: _flashSats
                        ? (isDown ? Colors.red : Colors.green)
                        : Colors.grey,
                  ),
                  child: Text(Formatters.formatSats(value.round())),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
