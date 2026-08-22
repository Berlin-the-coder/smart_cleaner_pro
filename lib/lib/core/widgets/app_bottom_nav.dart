import 'package:flutter/material.dart';

// Tab index constants — use these everywhere so they never go out of sync.
class AppTabs {
  static const int home    = 0;
  static const int files   = 1;
  static const int apps    = 2;
  static const int battery = 3;
}

/// Shared bottom navigation bar used across all feature screens.
///
/// [currentIndex] highlights the active tab.
/// On tap, pops everything back to root and the root (dashboard) handles
/// switching to the correct tab via its own state.
class AppBottomNav extends StatelessWidget {
  final int currentIndex;

  const AppBottomNav({super.key, required this.currentIndex});

  static const _items = [
    (Icons.home_rounded,           Icons.home_outlined,           'Home'),
    (Icons.folder_rounded,         Icons.folder_outlined,         'Files'),
    (Icons.apps_rounded,           Icons.apps_outlined,           'Apps'),
    (Icons.battery_full_rounded,   Icons.battery_full_outlined,   'Battery'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_items.length, (i) {
              final isActive = i == currentIndex;
              final item     = _items[i];
              return GestureDetector(
                onTap: () => _navigate(context, i),
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  width: 64,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isActive ? item.$1 : item.$2,
                        color: isActive
                            ? _activeColor(i)
                            : Colors.black38,
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.$3,
                        style: TextStyle(
                          fontSize: 11,
                          color: isActive
                              ? _activeColor(i)
                              : Colors.black38,
                          fontWeight: isActive
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  void _navigate(BuildContext context, int targetIndex) {
    // Already on this tab — do nothing.
    if (targetIndex == currentIndex) return;

    // Pop everything back to the root (dashboard) in one go,
    // then tell the dashboard which tab to show.
    Navigator.of(context).popUntil((route) => route.isFirst);

    // After popping, the dashboard is on top. We send it the
    // desired tab index via its global key / route arguments.
    // The simplest approach that works without restructuring:
    // push a replacement with the tab index as an argument.
    //
    // If your dashboard accepts a tab index, use pushReplacement.
    // Otherwise just popping to root is enough if the dashboard
    // remembers its selected index in its own State.
    //
    // We'll use a named route with arguments if you have them set up,
    // or a direct approach via a global key below.
    _DashboardNavBridge.navigateTo(context, targetIndex);
  }

  Color _activeColor(int index) {
    switch (index) {
      case AppTabs.files:   return const Color(0xFF2F6BFF);
      case AppTabs.apps:    return const Color(0xFF6C63FF);
      case AppTabs.battery: return const Color(0xFF00C2A8);
      default:              return const Color(0xFF2F6BFF); // home
    }
  }
}

/// Bridge that lets feature-screen bottom navs trigger tab switches
/// on the dashboard without needing a full state-management solution.
///
/// The dashboard registers itself; feature screens call [navigateTo].
class _DashboardNavBridge {
  static void Function(int)? _handler;

  static void register(void Function(int index) handler) {
    _handler = handler;
  }

  static void unregister() => _handler = null;

  static void navigateTo(BuildContext context, int index) {
    if (_handler != null) {
      _handler!(index);
    }
  }
}

/// Mixin for the dashboard State — call [registerNavBridge] in initState
/// and [unregisterNavBridge] in dispose.
mixin DashboardNavMixin<T extends StatefulWidget> on State<T> {
  void registerNavBridge(void Function(int) onNavigate) {
    _DashboardNavBridge.register(onNavigate);
  }

  void unregisterNavBridge() {
    _DashboardNavBridge.unregister();
  }
}