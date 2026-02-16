import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unitune/features/settings/preferences_manager.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('playlist share tip preference persists', () async {
    final prefs = await SharedPreferences.getInstance();
    final manager = PreferencesManager(prefs);

    expect(manager.isPlaylistShareTipDismissed, false);

    await manager.setPlaylistShareTipDismissed(true);

    expect(manager.isPlaylistShareTipDismissed, true);
  });
}
