import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

const _kTeal = Color(0xFF00695C);
const _kTeal400 = Color(0xFF26A69A);

class MainShell extends StatefulWidget {
  final StatefulNavigationShell navigationShell;
  const MainShell({super.key, required this.navigationShell});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell>
    with SingleTickerProviderStateMixin {
  static const _tabs = [
    _TabItem(
        icon: Icons.home_outlined,
        selectedIcon: Icons.home_rounded,
        label: 'Home'),
    _TabItem(
        icon: Icons.calendar_month_outlined,
        selectedIcon: Icons.calendar_month_rounded,
        label: 'Calendar'),
    _TabItem(
        icon: Icons.bar_chart_outlined,
        selectedIcon: Icons.bar_chart_rounded,
        label: 'Statistics'),
    _TabItem(
        icon: Icons.settings_outlined,
        selectedIcon: Icons.settings_rounded,
        label: 'Settings'),
  ];

  late final AnimationController _indicatorCtrl;
  late int _previousIndex;

  @override
  void initState() {
    super.initState();
    _previousIndex = widget.navigationShell.currentIndex;
    _indicatorCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _indicatorCtrl.dispose();
    super.dispose();
  }

  void _onTap(int index) {
    if (index != widget.navigationShell.currentIndex) {
      setState(() => _previousIndex = widget.navigationShell.currentIndex);
      _indicatorCtrl.forward(from: 0.0);
    }
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final current = widget.navigationShell.currentIndex;
    final tabCount = _tabs.length;
    const navHeight = 64.0;
    final screenWidth = MediaQuery.of(context).size.width;
    final tabWidth = screenWidth / tabCount;

    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: SizedBox(
        height: navHeight + MediaQuery.of(context).padding.bottom,
        child: Material(
          color: cs.surfaceContainerLow,
          elevation: 0,
          child: Stack(
            children: [
              // ── Top divider ───────────────────────────────────
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                    height: 1, color: cs.outlineVariant.withValues(alpha: 0.4)),
              ),

              // ── Sliding teal pill indicator ───────────────────
              AnimatedBuilder(
                animation: _indicatorCtrl,
                builder: (_, __) {
                  final t =
                      Curves.easeInOutCubic.transform(_indicatorCtrl.value);
                  final prevX = _previousIndex * tabWidth + tabWidth / 2;
                  final currX = current * tabWidth + tabWidth / 2;
                  final x = lerpDouble(prevX, currX, t)! - 28;

                  return Positioned(
                    top: 8,
                    left: x,
                    child: Container(
                      width: 56,
                      height: 28,
                      decoration: BoxDecoration(
                        color: _kTeal.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _kTeal400.withValues(alpha: 0.25),
                        ),
                      ),
                    ),
                  );
                },
              ),

              // ── Tab items ─────────────────────────────────────
              Row(
                children: List.generate(tabCount, (i) {
                  final selected = i == current;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => _onTap(i),
                      behavior: HitTestBehavior.opaque,
                      child: SizedBox(
                        height: navHeight,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: Icon(
                                selected
                                    ? _tabs[i].selectedIcon
                                    : _tabs[i].icon,
                                key: ValueKey('$i-$selected'),
                                color:
                                    selected ? _kTeal400 : cs.onSurfaceVariant,
                                size: 22,
                              ),
                            ),
                            const SizedBox(height: 2),
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 200),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color:
                                    selected ? _kTeal400 : cs.onSurfaceVariant,
                                fontFamily: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.fontFamily,
                              ),
                              child: Text(_tabs[i].label),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

double? lerpDouble(double a, double b, double t) => a + (b - a) * t;

class _TabItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  const _TabItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}
