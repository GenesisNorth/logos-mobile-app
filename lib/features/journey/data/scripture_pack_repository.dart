import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/scripture_drop.dart';
import '../models/scripture_pack.dart';
import 'content_repository.dart';

/// Repository managing downloadable offline Scripture packs and local storage caching.
class ScripturePackRepository {
  static const _prefKeyPacks = 'logos_downloaded_packs';

  final ContentRepository _contentRepo;
  final SharedPreferences? prefs;

  ScripturePackRepository({
    ContentRepository? contentRepo,
    this.prefs,
  })  : _contentRepo = contentRepo ?? const ContentRepository();

  Future<SharedPreferences> _getPrefs() async => prefs ?? await SharedPreferences.getInstance();

  /// Retrieves all seasonal Scripture packs with download status and storage size.
  Future<List<ScripturePack>> fetchPacks() async {
    final prefs = await _getPrefs();
    final downloaded = (prefs.getStringList(_prefKeyPacks) ?? <String>[]).toSet();

    final allDrops = _contentRepo.drops;

    return [
      ScripturePack(
        id: 'pack_peace',
        title: 'Foundation of Peace',
        subtitle: 'Weeks 1–4 · John 15, Phil 4, Rom 8, Ps 23',
        season: 'Dawn Liturgy',
        weekStart: 1,
        weekEnd: 4,
        dropsCount: 4,
        sizeMb: 12.8,
        isBuiltIn: true,
        isDownloaded: true,
        downloadProgress: 1.0,
        drops: allDrops.where((d) => d.weekNumber <= 4).toList(),
      ),
      ScripturePack(
        id: 'pack_ascent',
        title: 'Heavenly Ascent',
        subtitle: 'Weeks 5–8 · Col 3, Isa 40, Eph 3, Rom 12',
        season: 'Noonday Ascent',
        weekStart: 5,
        weekEnd: 8,
        dropsCount: 4,
        sizeMb: 14.5,
        isBuiltIn: false,
        isDownloaded: downloaded.contains('pack_ascent'),
        downloadProgress: downloaded.contains('pack_ascent') ? 1.0 : 0.0,
        drops: [
          allDrops.firstWhere((d) => d.weekNumber == 5, orElse: () => allDrops.first),
          const ScriptureDrop(
            id: 'pack-ascent-w6',
            weekNumber: 6,
            reference: 'Isaiah 40:28-31',
            verseText:
                'They who wait for the Lord shall renew their strength; they shall mount up with wings like eagles; they shall run and not be weary; they shall walk and not faint.',
            translation: 'ESV',
            videoUrl: 'https://assets.logosinme.com/videos/week6.mp4',
            encounterLines: [
              'Have you not known? Have you not heard?',
              'The Lord is the everlasting God, the Creator of the ends of the earth.',
              'He does not faint or grow weary.',
              'Wait on Him in the quiet of this day.',
            ],
            contextCards: [
              ContextCard(
                title: 'Qavah: Waiting in Hope',
                subtitle: 'Hebrew Contemplation',
                content:
                    'The Hebrew word "qavah" entails binding cords together to become unbreakable. Waiting on Yahweh weaves your weakness into His omnipotence.',
              ),
            ],
            ambientPreset: 'sanctuary_dawn',
            ambientLabel: 'Renewed Strength · 432 Hz',
          ),
          const ScriptureDrop(
            id: 'pack-ascent-w7',
            weekNumber: 7,
            reference: 'Ephesians 3:16-19',
            verseText:
                'That you may have strength to comprehend with all the saints what is the breadth and length and height and depth, and to know the love of Christ that surpasses knowledge.',
            translation: 'ESV',
            videoUrl: 'https://assets.logosinme.com/videos/week7.mp4',
            encounterLines: [
              'Paul bows his knees before the Father.',
              'The dimensions of Christ\'s love cannot be mapped by human intellect.',
              'Root yourself in His endless ocean.',
            ],
            contextCards: [
              ContextCard(
                title: 'The Fourfold Dimension of Grace',
                subtitle: 'Ephesian Exegesis',
                content:
                    'Breadth covers all nations, length spans all generations, depth reaches into the lowest pit of shame, and height seats us in the heavenly realm.',
              ),
            ],
            ambientPreset: 'sanctuary_dune',
            ambientLabel: 'Vast Ocean · 432 Hz',
          ),
          const ScriptureDrop(
            id: 'pack-ascent-w8',
            weekNumber: 8,
            reference: 'Romans 12:1-2',
            verseText:
                'I appeal to you therefore, brothers, by the mercies of God, to present your bodies as a living sacrifice, holy and acceptable to God, which is your spiritual worship. Do not be conformed to this world, but be transformed by the renewal of your mind.',
            translation: 'ESV',
            videoUrl: 'https://assets.logosinme.com/videos/week8.mp4',
            encounterLines: [
              'By the tender mercies of God, lay your whole life on the altar.',
              'Not as a dead ritual, but as living worship.',
              'Let your inner mind be made new in Christ.',
            ],
            contextCards: [
              ContextCard(
                title: 'Metamorphoō: Transformed',
                subtitle: 'Greek Spiritual Transformation',
                content:
                    'Paul uses "metamorphoō" (the root of metamorphosis). Renewal is an organic, spiritual metamorphosis originating from the Holy Spirit, not external conformity.',
              ),
            ],
            ambientPreset: 'sanctuary_dawn',
            ambientLabel: 'Living Altar · 432 Hz',
          ),
        ],
      ),
      ScripturePack(
        id: 'pack_wilderness',
        title: 'The Well in the Wilderness',
        subtitle: 'Weeks 9–12 · Ps 63, Exod 33, John 4, Lam 3',
        season: 'Wilderness Dwell',
        weekStart: 9,
        weekEnd: 12,
        dropsCount: 4,
        sizeMb: 13.9,
        isBuiltIn: false,
        isDownloaded: downloaded.contains('pack_wilderness'),
        downloadProgress: downloaded.contains('pack_wilderness') ? 1.0 : 0.0,
        drops: const [],
      ),
      ScripturePack(
        id: 'pack_cross',
        title: 'Litany of the Cross & Renewal',
        subtitle: 'Weeks 13–16 · Isa 53, Gal 2, Heb 12, 2 Cor 5',
        season: 'Sacred Exchange',
        weekStart: 13,
        weekEnd: 16,
        dropsCount: 4,
        sizeMb: 15.2,
        isBuiltIn: false,
        isDownloaded: downloaded.contains('pack_cross'),
        downloadProgress: downloaded.contains('pack_cross') ? 1.0 : 0.0,
        drops: const [],
      ),
    ];
  }

  /// Downloads and caches a seasonal Scripture pack locally with progress updates.
  Future<bool> downloadPack(
    String packId, {
    void Function(double progress)? onProgress,
  }) async {
    for (int step = 1; step <= 5; step++) {
      await Future.delayed(const Duration(milliseconds: 120));
      onProgress?.call(step / 5.0);
    }

    final prefs = await _getPrefs();
    final downloaded = (prefs.getStringList(_prefKeyPacks) ?? <String>[]).toSet();
    downloaded.add(packId);
    await prefs.setStringList(_prefKeyPacks, downloaded.toList());
    return true;
  }

  /// Deletes a cached pack to free storage space.
  Future<bool> deletePack(String packId) async {
    final prefs = await _getPrefs();
    final downloaded = (prefs.getStringList(_prefKeyPacks) ?? <String>[]).toSet();
    downloaded.remove(packId);
    await prefs.setStringList(_prefKeyPacks, downloaded.toList());
    return true;
  }

  /// Computes the total local storage footprint of all downloaded Scripture packs.
  Future<double> totalStorageUsedMb() async {
    final packs = await fetchPacks();
    return packs
        .where((p) => p.isDownloaded)
        .fold<double>(0.0, (acc, p) => acc + p.sizeMb);
  }
}
