import 'package:flutter/material.dart';
import 'unitune_logo.dart';

/// Standard Header for UniTune Screens
///
/// Ensures consistent spacing and design across Home, History, and Settings.
/// Displays the [UniTuneLogo] on the left and an optional [action] widget on the right.
class UniTuneHeader extends StatelessWidget {
  final Widget? action;

  const UniTuneHeader({super.key, this.action});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const UniTuneLogo(size: 40), // Standard size from Home screen
        if (action != null)
          action!
        else
          const SizedBox(
            width: 24,
          ), // Placeholder to balance if needed, or just empty
      ],
    );
  }
}
