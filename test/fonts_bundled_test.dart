import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// `GoogleFonts.config.allowRuntimeFetching` is disabled in main.dart, so every
/// font variant used via `GoogleFonts.plusJakartaSans()` /
/// `GoogleFonts.jetBrainsMono()` must be bundled under the Google Fonts API
/// file name - i.e. the asset path has to END WITH
/// "FamilyNoSpaces-Variant.ttf" (e.g. "JetBrainsMono-Bold.ttf").
/// Files with spaces ("JetBrains Mono-Bold.ttf") are silently not matched and
/// cause the runtime exception:
///   "GoogleFonts.config.allowRuntimeFetching is false but font ... not found"
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Only these two families are used in lib/ (weights w400..w800, normal).
  const expectedApiFileNames = <String>[
    'PlusJakartaSans-Regular',
    'PlusJakartaSans-Medium',
    'PlusJakartaSans-SemiBold',
    'PlusJakartaSans-Bold',
    'PlusJakartaSans-ExtraBold',
    'JetBrainsMono-Regular',
    'JetBrainsMono-Medium',
    'JetBrainsMono-SemiBold',
    'JetBrainsMono-Bold',
    'JetBrainsMono-ExtraBold',
  ];

  test(
    'every GoogleFonts variant resolves to a bundled asset',
    () async {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final assets = manifest.listAssets();

      expect(
        assets,
        isNotEmpty,
        reason: 'Asset manifest unavailable in the test environment',
      );

      for (final apiFileName in expectedApiFileNames) {
        final resolved = assets.any(
          (path) =>
              path.endsWith('$apiFileName.ttf') ||
              path.endsWith('$apiFileName.otf'),
        );
        expect(
          resolved,
          isTrue,
          reason:
              'Missing bundled font "$apiFileName.ttf". GoogleFonts looks it '
              'up by asset path suffix, so a space-named file such as '
              '"JetBrains Mono-Bold.ttf" will NOT be found (and runtime '
              'fetching is disabled). Assets found: $assets',
        );
      }
    },
  );

  test('no bundled font file name contains spaces', () async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final fontAssets = manifest
        .listAssets()
        .where((path) => path.endsWith('.ttf') || path.endsWith('.otf'))
        .toList();

    expect(fontAssets, isNotEmpty);
    for (final path in fontAssets) {
      expect(
        path.contains(' '),
        isFalse,
        reason: 'Font asset path contains a space: "$path"',
      );
    }
  });
}
