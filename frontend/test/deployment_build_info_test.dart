import 'package:flutter_test/flutter_test.dart';
import 'package:plant_it/deployment_build_info.dart';

void main() {
  group('DeploymentBuildInfo', () {
    test('detects different comparable revisions', () {
      const info = DeploymentBuildInfo(
        version: '0.16.0',
        revision: 'aaaaaaaaaaaaaaaa',
      );

      expect(info.differsFrom('bbbbbbbbbbbbbbbb'), isTrue);
      expect(info.differsFrom('aaaaaaaaaaaaaaaa'), isFalse);
      expect(info.differsFrom('aaaaaaaa'), isFalse);
    });

    test('ignores local placeholder revisions', () {
      const info = DeploymentBuildInfo(
        version: '0.16.0',
        revision: 'development',
      );

      expect(info.differsFrom('bbbbbbbbbbbbbbbb'), isFalse);
      expect(
        const DeploymentBuildInfo(
          version: '0.16.0',
          revision: 'aaaaaaaaaaaaaaaa',
        ).differsFrom('development'),
        isFalse,
      );
    });

    test('uses a readable abbreviated revision', () {
      expect(
        DeploymentBuildInfo.displayRevision('1234567890abcdef'),
        '1234567890ab',
      );
      expect(DeploymentBuildInfo.displayRevision(''), 'unknown');
    });
  });
}
