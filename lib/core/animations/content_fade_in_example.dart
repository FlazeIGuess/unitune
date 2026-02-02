import 'package:flutter/material.dart';
import 'content_fade_in.dart';

/// Example usage of ContentFadeIn animations
///
/// This file demonstrates various ways to use the fade-in animation helpers
/// for dynamic content loading scenarios.

// Example 1: Simple fade-in for a single widget
class SimpleFadeInExample extends StatelessWidget {
  const SimpleFadeInExample({super.key});

  @override
  Widget build(BuildContext context) {
    return ContentFadeIn(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('This card fades in smoothly'),
        ),
      ),
    );
  }
}

// Example 2: Staggered fade-in for a list of items
class StaggeredListExample extends StatelessWidget {
  const StaggeredListExample({super.key});

  @override
  Widget build(BuildContext context) {
    final items = List.generate(5, (index) => 'Item ${index + 1}');

    return Column(
      children: createStaggeredFadeIns(
        children: items
            .map(
              (item) =>
                  ListTile(leading: Icon(Icons.music_note), title: Text(item)),
            )
            .toList(),
        staggerDelay: Duration(milliseconds: 50),
      ),
    );
  }
}

// Example 3: Conditional fade-in based on data loading
class ConditionalFadeInExample extends StatefulWidget {
  const ConditionalFadeInExample({super.key});

  @override
  State<ConditionalFadeInExample> createState() =>
      _ConditionalFadeInExampleState();
}

class _ConditionalFadeInExampleState extends State<ConditionalFadeInExample> {
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    // Simulate data loading
    Future.delayed(Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _isLoaded = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ConditionalFadeIn(
      condition: _isLoaded,
      placeholder: Center(child: CircularProgressIndicator()),
      child: Column(
        children: [
          Text('Data loaded successfully!'),
          Text('This content faded in after loading.'),
        ],
      ),
    );
  }
}

// Example 4: Using the extension method
class ExtensionMethodExample extends StatelessWidget {
  const ExtensionMethodExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Simple fade-in
        Text('Fade in immediately').withFadeIn(),

        SizedBox(height: 16),

        // Fade-in with delay
        Text(
          'Fade in after 100ms',
        ).withFadeIn(delay: Duration(milliseconds: 100)),

        SizedBox(height: 16),

        // Fade-in with custom duration
        Text(
          'Fade in slowly',
        ).withFadeIn(duration: Duration(milliseconds: 500)),
      ],
    );
  }
}

// Example 5: Service buttons with staggered fade-in (real-world scenario)
class ServiceButtonsExample extends StatelessWidget {
  const ServiceButtonsExample({super.key});

  @override
  Widget build(BuildContext context) {
    final services = [
      {'name': 'Spotify', 'icon': Icons.music_note, 'color': Colors.green},
      {'name': 'Apple Music', 'icon': Icons.music_note, 'color': Colors.red},
      {'name': 'Tidal', 'icon': Icons.music_note, 'color': Colors.white},
      {'name': 'YouTube Music', 'icon': Icons.music_note, 'color': Colors.red},
    ];

    return Column(
      children: createStaggeredFadeIns(
        children: services
            .map(
              (service) => ListTile(
                leading: Icon(
                  service['icon'] as IconData,
                  color: service['color'] as Color,
                ),
                title: Text(service['name'] as String),
                trailing: ElevatedButton(onPressed: () {}, child: Text('Play')),
              ),
            )
            .toList(),
        staggerDelay: Duration(milliseconds: 75),
      ),
    );
  }
}

// Example 6: Dynamic content with fade-in
class DynamicContentExample extends StatefulWidget {
  const DynamicContentExample({super.key});

  @override
  State<DynamicContentExample> createState() => _DynamicContentExampleState();
}

class _DynamicContentExampleState extends State<DynamicContentExample> {
  final List<String> _items = [];

  void _addItem() {
    setState(() {
      _items.add('Item ${_items.length + 1}');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(onPressed: _addItem, child: Text('Add Item')),
        SizedBox(height: 16),
        ...createStaggeredFadeIns(
          children: _items
              .map((item) => Card(child: ListTile(title: Text(item))))
              .toList(),
          staggerDelay: Duration(milliseconds: 50),
        ),
      ],
    );
  }
}
