import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/audio_service.dart';
import '../../../core/theme/logos_theme.dart';
import '../../../core/theme/logos_icons.dart';
import '../../../core/theme/logos_typography.dart';
import '../data/scripture_pack_repository.dart';
import '../models/scripture_pack.dart';

/// Modal bottom sheet allowing pilgrims to download and manage 52-week offline Scripture packs.
class ScripturePacksSheet extends StatefulWidget {
  final ScripturePackRepository repository;

  const ScripturePacksSheet({
    super.key,
    required this.repository,
  });

  static Future<void> show(BuildContext context, {ScripturePackRepository? repository}) {
    AudioService().selectionTick();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ScripturePacksSheet(
        repository: repository ?? ScripturePackRepository(),
      ),
    );
  }

  @override
  State<ScripturePacksSheet> createState() => _ScripturePacksSheetState();
}

class _ScripturePacksSheetState extends State<ScripturePacksSheet> {
  late Future<List<ScripturePack>> _packsFuture;
  final Map<String, double> _downloadingProgress = {};

  @override
  void initState() {
    super.initState();
    _loadPacks();
  }

  void _loadPacks() {
    _packsFuture = widget.repository.fetchPacks();
  }

  Future<void> _handleDownload(ScripturePack pack) async {
    AudioService().selectionTick();
    setState(() {
      _downloadingProgress[pack.id] = 0.05;
    });

    await widget.repository.downloadPack(
      pack.id,
      onProgress: (p) {
        if (mounted) {
          setState(() {
            _downloadingProgress[pack.id] = p;
          });
        }
      },
    );

    AudioService().sacredCelebrationHaptic();
    if (mounted) {
      setState(() {
        _downloadingProgress.remove(pack.id);
        _loadPacks();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF10B981),
          content: Text('${pack.title} downloaded for offline contemplation!'),
        ),
      );
    }
  }

  Future<void> _handleDelete(ScripturePack pack) async {
    AudioService().selectionTick();
    await widget.repository.deletePack(pack.id);
    if (mounted) {
      setState(() => _loadPacks());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Removed ${pack.title} from offline storage.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? LogosColors.examenSurface : Colors.white;
    final ink = isDark ? LogosColors.examenInk : LogosColors.ink;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 18, 24, MediaQuery.of(context).viewInsets.bottom + 34),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: LogosColors.taupe),
        boxShadow: LogosColors.softShadow,
      ),
      child: FutureBuilder<List<ScripturePack>>(
        future: _packsFuture,
        builder: (context, snapshot) {
          final packs = snapshot.data ?? [];
          final totalStorageMb = packs
              .where((p) => p.isDownloaded)
              .fold<double>(0.0, (acc, p) => acc + p.sizeMb);

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: ink.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: LogosColors.coral.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const AppIcon(LogosIcons.autoStories, color: LogosColors.coral, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Offline Scripture Packs',
                                style: LogosTypography.headline(color: ink).copyWith(fontSize: 16),
                              ),
                              Text(
                                'Full 52-Week Lexicons & Contemplative Stems',
                                style: LogosTypography.caption(color: ink.withValues(alpha: 0.6)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      '${totalStorageMb.toStringAsFixed(1)} MB',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F5132),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  itemCount: packs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (ctx, index) {
                    final pack = packs[index];
                    final isDownloading = _downloadingProgress.containsKey(pack.id);
                    final progress = _downloadingProgress[pack.id] ?? 0.0;

                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: ink.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: pack.isDownloaded
                              ? const Color(0xFF10B981).withValues(alpha: 0.3)
                              : LogosColors.taupe,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: LogosColors.coral.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'WEEKS ${pack.weekStart}–${pack.weekEnd}',
                                  style: GoogleFonts.inter(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    color: LogosColors.coral,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${pack.sizeMb} MB · ${pack.season}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 10.5,
                                    color: ink.withValues(alpha: 0.6),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (pack.isBuiltIn)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Built-In Core ✓',
                                    style: GoogleFonts.inter(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF0F5132),
                                    ),
                                  ),
                                )
                              else if (pack.isDownloaded)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const AppIcon(LogosIcons.checkCircleRounded, color: Color(0xFF10B981), size: 18),
                                    IconButton(
                                      icon: const AppIcon(LogosIcons.autoDeleteOutlined, size: 16, color: Colors.grey),
                                      tooltip: 'Delete to free storage',
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                      onPressed: () => _handleDelete(pack),
                                    ),
                                  ],
                                )
                              else if (isDownloading)
                                SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    value: progress,
                                    strokeWidth: 2.2,
                                    color: LogosColors.coral,
                                  ),
                                )
                              else
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: LogosColors.coral,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  icon: const AppIcon(LogosIcons.arrowDown, size: 12),
                                  label: Text(
                                    'Download',
                                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700),
                                  ),
                                  onPressed: () => _handleDownload(pack),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            pack.title,
                            style: GoogleFonts.inter(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: ink,
                            ),
                          ),
                          Text(
                            pack.subtitle,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: ink.withValues(alpha: 0.65),
                            ),
                          ),
                          if (isDownloading) ...[
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 4,
                                backgroundColor: LogosColors.taupe,
                                valueColor: const AlwaysStoppedAnimation(LogosColors.coral),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
