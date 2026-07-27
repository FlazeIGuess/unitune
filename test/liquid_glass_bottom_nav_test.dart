import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unitune/core/widgets/liquid_glass_bottom_nav.dart';

const _items = [
  BottomNavItem(
    icon: Icons.home_outlined,
    activeIcon: Icons.home,
    label: 'Home',
  ),
  BottomNavItem(
    icon: Icons.history_outlined,
    activeIcon: Icons.history,
    label: 'History',
  ),
  BottomNavItem(
    icon: Icons.queue_music_outlined,
    activeIcon: Icons.queue_music,
    label: 'Playlists',
  ),
  BottomNavItem(
    icon: Icons.settings_outlined,
    activeIcon: Icons.settings,
    label: 'Settings',
  ),
];

/// Hosts the nav and keeps the selected index, mirroring MainShell.
class _Host extends StatefulWidget {
  final void Function(int)? onChanged;
  const _Host({this.onChanged});

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  int index = 0;

  /// Selects an item the way the rest of the app does — without the test
  /// reaching into the protected `setState`.
  void select(int value) => setState(() => index = value);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.bottomCenter,
          child: LiquidGlassBottomNav(
            items: _items,
            currentIndex: index,
            onTap: (i) {
              setState(() => index = i);
              widget.onChanged?.call(i);
            },
          ),
        ),
      ),
    );
  }
}

void main() {
  // The collapsed slot width the widget uses internally: icon 22 + 2 * 16.
  const collapsedWidth = 54.0;

  Future<void> settle(WidgetTester tester) async {
    await tester.pumpAndSettle(const Duration(milliseconds: 50));
  }

  testWidgets('tapping an item still selects it', (tester) async {
    final selections = <int>[];
    await tester.pumpWidget(_Host(onChanged: selections.add));
    await settle(tester);

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await settle(tester);

    expect(selections, [3]);
  });

  testWidgets('dragging the pill far enough selects the next item', (
    tester,
  ) async {
    final selections = <int>[];
    await tester.pumpWidget(_Host(onChanged: selections.add));
    await settle(tester);

    // Drag right by one full slot: the pill should settle on index 1.
    await tester.drag(
      find.byType(LiquidGlassBottomNav),
      const Offset(collapsedWidth, 0),
    );
    await settle(tester);

    expect(selections, [1]);
  });

  testWidgets(
    'a drag shorter than half a slot snaps back and selects nothing',
    (tester) async {
      final selections = <int>[];
      await tester.pumpWidget(_Host(onChanged: selections.add));
      await settle(tester);

      // Well under half a slot, and slow enough not to register as a flick.
      await tester.timedDrag(
        find.byType(LiquidGlassBottomNav),
        const Offset(collapsedWidth * 0.2, 0),
        const Duration(milliseconds: 400),
      );
      await settle(tester);

      expect(selections, isEmpty);
    },
  );

  testWidgets('dragging across several slots selects the far item', (
    tester,
  ) async {
    final selections = <int>[];
    await tester.pumpWidget(_Host(onChanged: selections.add));
    await settle(tester);

    await tester.timedDrag(
      find.byType(LiquidGlassBottomNav),
      const Offset(collapsedWidth * 3, 0),
      const Duration(milliseconds: 600),
    );
    await settle(tester);

    expect(selections.last, 3);
  });

  testWidgets('the pill cannot be dragged past the ends', (tester) async {
    final selections = <int>[];
    await tester.pumpWidget(_Host(onChanged: selections.add));
    await settle(tester);

    // Already at index 0; dragging further left must not select anything.
    await tester.timedDrag(
      find.byType(LiquidGlassBottomNav),
      const Offset(-collapsedWidth * 3, 0),
      const Duration(milliseconds: 600),
    );
    await settle(tester);

    expect(selections, isEmpty);
  });

  testWidgets('an externally changed index moves the pill', (tester) async {
    await tester.pumpWidget(const _Host());
    await settle(tester);

    tester.state<_HostState>(find.byType(_Host)).select(2);
    await settle(tester);

    // The active icon variant is only shown once the pill has arrived.
    expect(find.byIcon(Icons.queue_music), findsOneWidget);
  });

  testWidgets('total width stays constant while the pill moves', (
    tester,
  ) async {
    await tester.pumpWidget(const _Host());
    await settle(tester);

    final before = tester.getSize(find.byType(LiquidGlassBottomNav)).width;

    // Stop mid-drag, where the expansion budget is split between two items.
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(LiquidGlassBottomNav)),
    );
    await gesture.moveBy(const Offset(collapsedWidth * 0.5, 0));
    await tester.pump();

    expect(tester.getSize(find.byType(LiquidGlassBottomNav)).width, before);

    await gesture.up();
    await settle(tester);
  });
}
