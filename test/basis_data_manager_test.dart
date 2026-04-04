import 'package:flutter_test/flutter_test.dart';
import 'package:hypertrack/data/basis_data_manager.dart';

void main() {
  group('BasisDataManager.shouldImportAsset', () {
    test('imports on first run with versionless asset when no data exists', () {
      final shouldImport = BasisDataManager.shouldImportAsset(
        forceImport: false,
        assetVersion: '0',
        installedVersion: '0',
        hasExistingDataForVersionlessAsset: false,
      );

      expect(shouldImport, isTrue);
    });

    test('skips re-import for versionless asset when data already exists', () {
      final shouldImport = BasisDataManager.shouldImportAsset(
        forceImport: false,
        assetVersion: '0',
        installedVersion: '0',
        hasExistingDataForVersionlessAsset: true,
      );

      expect(shouldImport, isFalse);
    });

    test('imports when asset version is newer than installed version', () {
      final shouldImport = BasisDataManager.shouldImportAsset(
        forceImport: false,
        assetVersion: '202601010001',
        installedVersion: '202501010001',
        hasExistingDataForVersionlessAsset: true,
      );

      expect(shouldImport, isTrue);
    });

    test('force import always imports', () {
      final shouldImport = BasisDataManager.shouldImportAsset(
        forceImport: true,
        assetVersion: '0',
        installedVersion: '000000000001',
        hasExistingDataForVersionlessAsset: true,
      );

      expect(shouldImport, isTrue);
    });
  });

  group('BasisDataManager.storedVersionAfterImport', () {
    test('stores fallback version for versionless assets', () {
      final stored = BasisDataManager.storedVersionAfterImport(
        assetVersion: '0',
      );
      expect(stored, '000000000001');
    });

    test('stores actual version when provided', () {
      final stored = BasisDataManager.storedVersionAfterImport(
        assetVersion: '202601010001',
      );
      expect(stored, '202601010001');
    });
  });
}
