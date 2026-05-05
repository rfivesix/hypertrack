import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/config/app_data_sources.dart';

void main() {
  test('runtime data-source config uses Train Libre DB filenames by default',
      () {
    expect(AppDataSources.trainingDbFileName, 'train_libre_training.db');
    expect(
      AppDataSources.trainingAssetDbPath,
      'assets/db/train_libre_training.db',
    );
    expect(AppDataSources.baseFoodsDbFileName, 'train_libre_base_foods.db');
    expect(AppDataSources.exerciseCatalog.defaultDbPath,
        'train_libre_training.db');
    expect(AppDataSources.exerciseCatalog.localCacheDbFileName,
        'train_libre_training_remote.db');

    final us = AppDataSources.offCatalogForCountry(OffCatalogCountry.us);
    expect(us.defaultDbPath, 'train_libre_off_us.db');
    expect(us.bundledAssetDbPath, 'assets/db/train_libre_prep_us.db');
    expect(us.localCacheDbFileName, 'train_libre_off_us_remote.db');
  });

  test('legacy Hypertrack DB filenames remain explicit fallbacks', () {
    expect(AppDataSources.legacyTrainingDbFileName, 'hypertrack_training.db');
    expect(
      AppDataSources.legacyBaseFoodsDbFileName,
      'hypertrack_base_foods.db',
    );
    expect(
      AppDataSources.exerciseCatalog.legacyDefaultDbPath,
      'hypertrack_training.db',
    );

    final de = AppDataSources.offCatalogForCountry(OffCatalogCountry.de);
    expect(de.legacyDefaultDbPath, 'hypertrack_off_de.db');
    expect(de.legacyBundledAssetDbPath, 'assets/db/hypertrack_prep_de.db');
    expect(de.legacyLocalCacheDbFileName, 'hypertrack_off_de_remote.db');
  });
}
