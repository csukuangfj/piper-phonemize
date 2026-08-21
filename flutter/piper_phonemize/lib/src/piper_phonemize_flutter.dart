// Copyright (c) 2026 piper-phonemize contributors
//
// Flutter-specific helper for extracting espeak-ng-data from assets.
// This file uses Flutter-only APIs (rootBundle, path_provider).

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

// Known espeak-ng-data files. AssetManifest doesn't list plugin assets,
// so we enumerate them explicitly. This includes all files from
// swift-api-examples/espeak-ng-data/ (voices/, lang/, dict files, etc.).
const _espeakNgDataFiles = [
  'phontab', 'phondata', 'phonindex', 'intonations', 'phondata-manifest',
  'af_dict', 'am_dict', 'an_dict', 'ar_dict', 'as_dict', 'az_dict',
  'ba_dict', 'be_dict', 'bg_dict', 'bn_dict', 'bpy_dict', 'bs_dict',
  'ca_dict', 'chr_dict', 'cmn_dict', 'cs_dict', 'cv_dict', 'cy_dict',
  'da_dict', 'de_dict', 'el_dict', 'en_dict', 'eo_dict', 'es_dict',
  'et_dict', 'eu_dict', 'fa_dict', 'fi_dict', 'fr_dict', 'ga_dict',
  'gd_dict', 'gn_dict', 'grc_dict', 'gu_dict', 'hak_dict', 'haw_dict',
  'he_dict', 'hi_dict', 'hr_dict', 'ht_dict', 'hu_dict', 'hy_dict',
  'ia_dict', 'id_dict', 'io_dict', 'is_dict', 'it_dict', 'ja_dict',
  'jbo_dict', 'ka_dict', 'kk_dict', 'kl_dict', 'kn_dict', 'ko_dict',
  'kok_dict', 'ku_dict', 'ky_dict', 'la_dict', 'lb_dict', 'lfn_dict',
  'lt_dict', 'lv_dict', 'mi_dict', 'mk_dict', 'ml_dict', 'mr_dict',
  'ms_dict', 'mt_dict', 'mto_dict', 'my_dict', 'nci_dict', 'ne_dict',
  'nl_dict', 'no_dict', 'nog_dict', 'om_dict', 'or_dict', 'pa_dict',
  'pap_dict', 'piqd_dict', 'pl_dict', 'pt_dict', 'py_dict', 'qdb_dict',
  'qu_dict', 'quc_dict', 'qya_dict', 'ro_dict', 'ru_dict', 'sd_dict',
  'shn_dict', 'si_dict', 'sjn_dict', 'sk_dict', 'sl_dict', 'smj_dict',
  'sq_dict', 'sr_dict', 'sv_dict', 'sw_dict', 'ta_dict', 'te_dict',
  'th_dict', 'tk_dict', 'tn_dict', 'tr_dict', 'tt_dict', 'ug_dict',
  'uk_dict', 'ur_dict', 'uz_dict', 'vi_dict', 'yue_dict',
  // lang/ subdirectory
  'lang/aav/vi', 'lang/aav/vi-VN-x-central', 'lang/aav/vi-VN-x-south',
  'lang/art/eo', 'lang/art/ia', 'lang/art/io', 'lang/art/jbo',
  'lang/art/lfn', 'lang/art/piqd', 'lang/art/py', 'lang/art/qdb',
  'lang/art/qya', 'lang/art/sjn', 'lang/azc/nci', 'lang/bat/lt',
  'lang/bat/ltg', 'lang/bat/lv', 'lang/bnt/sw', 'lang/bnt/tn',
  'lang/ccs/ka', 'lang/cel/cy', 'lang/cel/ga', 'lang/cel/gd',
  'lang/cus/om', 'lang/dra/kn', 'lang/dra/ml', 'lang/dra/ta',
  'lang/dra/te', 'lang/esx/kl', 'lang/eu', 'lang/gmq/da',
  'lang/gmq/is', 'lang/gmq/nb', 'lang/gmq/sv', 'lang/gmw/af',
  'lang/gmw/de', 'lang/gmw/en', 'lang/gmw/en-029',
  'lang/gmw/en-GB-scotland', 'lang/gmw/en-GB-x-gbclan',
  'lang/gmw/en-GB-x-gbcwmd', 'lang/gmw/en-GB-x-rp', 'lang/gmw/en-US',
  'lang/gmw/en-US-nyc', 'lang/gmw/lb', 'lang/gmw/nl', 'lang/grk/el',
  'lang/grk/grc', 'lang/inc/as', 'lang/inc/bn', 'lang/inc/bpy',
  'lang/inc/gu', 'lang/inc/hi', 'lang/inc/kok', 'lang/inc/mr',
  'lang/inc/ne', 'lang/inc/or', 'lang/inc/pa', 'lang/inc/sd',
  'lang/inc/si', 'lang/inc/ur', 'lang/ine/hy', 'lang/ine/hyw',
  'lang/ine/sq', 'lang/ira/fa', 'lang/ira/fa-Latn', 'lang/ira/ku',
  'lang/iro/chr', 'lang/itc/la', 'lang/jpx/ja', 'lang/ko',
  'lang/map/haw', 'lang/miz/mto', 'lang/myn/quc', 'lang/poz/id',
  'lang/poz/mi', 'lang/poz/ms', 'lang/qu', 'lang/roa/an',
  'lang/roa/ca', 'lang/roa/es', 'lang/roa/es-419', 'lang/roa/fr',
  'lang/roa/fr-BE', 'lang/roa/fr-CH', 'lang/roa/ht', 'lang/roa/it',
  'lang/roa/pap', 'lang/roa/pt', 'lang/roa/pt-BR', 'lang/roa/ro',
  'lang/sai/gn', 'lang/sem/am', 'lang/sem/ar', 'lang/sem/he',
  'lang/sem/mt', 'lang/sit/cmn', 'lang/sit/cmn-Latn-pinyin',
  'lang/sit/hak', 'lang/sit/my', 'lang/sit/yue',
  'lang/sit/yue-Latn-jyutping', 'lang/tai/shn', 'lang/tai/th',
  'lang/trk/az', 'lang/trk/ba', 'lang/trk/cv', 'lang/trk/kk',
  'lang/trk/ky', 'lang/trk/nog', 'lang/trk/tk', 'lang/trk/tr',
  'lang/trk/tt', 'lang/trk/ug', 'lang/trk/uz', 'lang/urj/et',
  'lang/urj/fi', 'lang/urj/hu', 'lang/urj/smj', 'lang/zle/be',
  'lang/zle/ru', 'lang/zle/ru-cl', 'lang/zle/ru-LV', 'lang/zle/uk',
  'lang/zls/bg', 'lang/zls/bs', 'lang/zls/hr', 'lang/zls/mk',
  'lang/zls/sl', 'lang/zls/sr', 'lang/zlw/cs', 'lang/zlw/pl',
  'lang/zlw/sk',
  // voices/ subdirectory
  'voices/!v/adam', 'voices/!v/Alex', 'voices/!v/Alicia',
  'voices/!v/Andrea', 'voices/!v/Andy', 'voices/!v/anika',
  'voices/!v/anikaRobot', 'voices/!v/Annie', 'voices/!v/announcer',
  'voices/!v/antonio', 'voices/!v/AnxiousAndy', 'voices/!v/aunty',
  'voices/!v/belinda', 'voices/!v/benjamin', 'voices/!v/boris',
  'voices/!v/caleb', 'voices/!v/croak', 'voices/!v/david',
  'voices/!v/Demonic', 'voices/!v/Denis', 'voices/!v/Diogo',
  'voices/!v/ed', 'voices/!v/edward', 'voices/!v/edward2',
  'voices/!v/f1', 'voices/!v/f2', 'voices/!v/f3', 'voices/!v/f4',
  'voices/!v/f5', 'voices/!v/fast', 'voices/!v/Gene', 'voices/!v/Gene2',
  'voices/!v/grandma', 'voices/!v/grandpa', 'voices/!v/gustave',
  'voices/!v/Henrique', 'voices/!v/Hugo', 'voices/!v/ian',
  'voices/!v/iven', 'voices/!v/iven2', 'voices/!v/iven3',
  'voices/!v/iven4', 'voices/!v/Jacky', 'voices/!v/john',
  'voices/!v/kaukovalta', 'voices/!v/klatt', 'voices/!v/klatt2',
  'voices/!v/klatt3', 'voices/!v/klatt4', 'voices/!v/klatt5',
  'voices/!v/klatt6', 'voices/!v/Lee', 'voices/!v/linda',
  'voices/!v/m1', 'voices/!v/m2', 'voices/!v/m3', 'voices/!v/m4',
  'voices/!v/m5', 'voices/!v/m6', 'voices/!v/m7', 'voices/!v/m8',
  'voices/!v/marcelo', 'voices/!v/Marco', 'voices/!v/Mario',
  'voices/!v/max', 'voices/!v/Michael', 'voices/!v/michel',
  'voices/!v/miguel', 'voices/!v/Mike', 'voices/!v/mike2',
  'voices/!v/Mr serious', 'voices/!v/Nguyen', 'voices/!v/norbert',
  'voices/!v/pablo', 'voices/!v/paul', 'voices/!v/pedro',
  'voices/!v/quincy', 'voices/!v/Reed', 'voices/!v/RicishayMax',
  'voices/!v/RicishayMax2', 'voices/!v/RicishayMax3', 'voices/!v/rob',
  'voices/!v/robert', 'voices/!v/robosoft', 'voices/!v/robosoft2',
  'voices/!v/robosoft3', 'voices/!v/robosoft4', 'voices/!v/robosoft5',
  'voices/!v/robosoft6', 'voices/!v/robosoft7', 'voices/!v/robosoft8',
  'voices/!v/sandro', 'voices/!v/shelby', 'voices/!v/steph',
  'voices/!v/steph2', 'voices/!v/steph3', 'voices/!v/Storm',
  'voices/!v/travis', 'voices/!v/Tweaky', 'voices/!v/UniRobot',
  'voices/!v/victor', 'voices/!v/whisper', 'voices/!v/whisperf',
  'voices/!v/zac',
];

/// Extract espeak-ng-data from Flutter assets to a filesystem directory.
///
/// Returns the absolute path to the extracted directory.
/// Skips extraction if already done (cached).
///
/// This is needed because espeak-ng's `PiperPhonemizeInitialize` requires
/// a filesystem directory path, but Flutter assets are only accessible
/// via [rootBundle].
///
/// Usage (Flutter only):
/// ```dart
/// final dataDir = await extractEspeakNgData();
/// PiperPhonemize.initialize(dataDir);
/// ```
Future<String> extractEspeakNgData() async {
  final appDir = await getApplicationSupportDirectory();
  final targetDir = '${appDir.path}/espeak-ng-data';
  final targetDirectory = Directory(targetDir);

  // Skip if already extracted
  if (await targetDirectory.exists()) {
    return targetDir;
  }

  await targetDirectory.create(recursive: true);

  for (final fileName in _espeakNgDataFiles) {
    try {
      final data = await rootBundle
          .load('packages/piper_phonemize/espeak-ng-data/$fileName');
      final bytes =
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      // Create parent directories for nested files (lang/, voices/)
      final file = File('$targetDir/$fileName');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes);
    } catch (_) {
      // File not in bundle — skip
    }
  }

  return targetDir;
}
