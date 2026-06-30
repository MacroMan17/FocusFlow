import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MainShell — custom bottom nav with animated pill indicator
// Spec: height 78dp, corner radius 28dp, selected 28dp / unselected 24dp icons
// ─────────────────────────────────────────────────────────────────────────────

class MainShell extends StatefulWidget {
  final StatefulNavigationShell navigationShell;
  const MainShell({super.key, required this.navigationShell});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell>
    with SingleTickerProviderStateMixin {
  static const _tabs = [
    _Tab(icon: Icons.home_outlined, sel: Icons.home_rounded, label: 'Home'),
    _Tab(
        icon: Icons.calendar_month_outlined,
        sel: Icons.calendar_month_rounded,
        label: 'Calendar'),
    _Tab(
        icon: Icons.bar_chart_outlined,
        sel: Icons.bar_chart_rounded,
        label: 'Statistics'),
    _Tab(
        icon: Icons.settings_outlined,
        sel: Icons.settings_rounded,
        label: 'Settings'),
  ];

  late final AnimationController _pillCtrl;
  late int _prev;

  @override
  void initState() {
    super.initState();
    _prev = widget.navigationShell.currentIndex;
    _pillCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _pillCtrl.dispose();
    super.dispose();
  }

  void _onTap(int i) {
    if (i != widget.navigationShell.currentIndex) {
      setState(() => _prev = widget.navigationShell.currentIndex);
      _pillCtrl.forward(from: 0.0);
    }
    widget.navigationShell.goBranch(
      i,
      initialLocation: i == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cur = widget.navigationShell.currentIndex;
    final bottom = MediaQuery.of(context).padding.bottom;
    const h = 78.0;
    final w = MediaQuery.of(context).size.width;
    final tabW = w / _tabs.length;

    return Scaffold(
      body: widget.navigationShell,
      backgroundColor: kBg,
      bottomNavigationBar: Container(
        height: h + bottom,
        decoration: BoxDecoration(
          color: kBg2,
          border: const Border(
            top: BorderSide(color: kDivider, width: 1),
          ),
        ),
        child: Stack(
          children: [
            // ── Animated pill ────────────────────────────────────
            AnimatedBuilder(
              animation: _pillCtrl,
              builder: (_, __) {
                final t = Curves.easeInOutCubic.transform(_pillCtrl.value);
                final px = _prev * tabW + tabW / 2;
                final cx = cur * tabW + tabW / 2;
                final x = px + (cx - px) * t - 28;
                return Positioned(
                  top: 10,
                  left: x,
                  child: Container(
                    width: 56,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0x556C63FF),
                          Color(0x3300E5FF),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(kNavRadius),
                      border: Border.all(
                        color: const Color(0x556C63FF),
                        width: 1,
                      ),
                    ),
                  ),
                );
              },
            ),

            // ── Tab items ────────────────────────────────────────
            Row(
              children: List.generate(_tabs.length, (i) {
                final sel = i == cur;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => _onTap(i),
                    behavior: HitTestBehavior.opaque,
                    child: SizedBox(
                      height: h,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Icon with animated size
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            child: Icon(
                              sel ? _tabs[i].sel : _tabs[i].icon,
                              key: ValueKey('$i$sel'),
                              size: sel ? 28 : 24,
                              color: sel ? kPrimary : kTextSec,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Label 13sp Medium
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 250),
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              fontWeight:
                                  sel ? FontWeight.w600 : FontWeight.w500,
                              color: sel ? kPrimary : kTextSec,
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
    );
  }
}

class _Tab {
  final IconData icon, sel;
  final String label;
  const _Tab({required this.icon, required this.sel, required this.label});
}
