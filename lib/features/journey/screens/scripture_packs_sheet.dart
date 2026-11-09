import 'package:flutter/material.dart';
import '../../../core/design/components.dart';
import '../../../core/design/organic.dart';
import '../../../core/services/audio_service.dart';
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
      barrierColor: OC.n900.withValues(alpha: 0.45),
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
        SnackBar(content: Text('${pack.title} is ready offline.')),
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
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.88),
      padding: EdgeInsets.fromLTRB(22, 12, 22, MediaQuery.of(context).viewInsets.bottom + 30),
      decoration: const BoxDecoration(
        color: OC.bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
      ),
      child: FutureBuilder<List<ScripturePack>>(
        future: _packsFuture,
        builder: (context, snapshot) {
          final packs = snapshot.data ?? [];
          final storage = packs.where((p) => p.isDownloaded).fold<double>(0, (a, p) => a + p.sizeMb);
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(color: OC.n400, borderRadius: BorderRadius.circular(3)),
                ),
              ),
              Text('Offline Scripture Packs', style: OT.h3()),
              const SizedBox(height: 4),
              Text('Seasons of weeks, ready without signal · ${storage.toStringAsFixed(1)} MB on this phone', style: OT.small()),
              const SizedBox(height: 16),
              if (snapshot.connectionState != ConnectionState.done)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator(color: OC.accent)),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: packs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _packCard(packs[i]),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _packCard(ScripturePack pack) {
    final progress = _downloadingProgress[pack.id];
    final Widget action;
    if (pack.isBuiltIn) {
      action = const OTag('Built-In Core ✓', bg: OC.s200, fg: OC.s900);
    } else if (progress != null) {
      action = SizedBox(
        width: 88,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(value: progress, minHeight: 6, color: OC.accent, backgroundColor: OC.a200),
        ),
      );
    } else if (pack.isDownloaded) {
      action = OButton('Remove', style: OButtonStyle.outline, expand: false, height: 38, onPressed: () => _handleDelete(pack));
    } else {
      action = OButton('Download', expand: false, height: 38, onPressed: () => _handleDownload(pack));
    }
    return OCard(
      radius: 24,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: pack.isDownloaded ? OC.s500 : OC.a200, shape: BoxShape.circle),
            child: Center(
              child: Text('${pack.weekStart}', style: OT.display(18, color: pack.isDownloaded ? OC.n100 : OC.a800)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pack.title, style: OT.display(18)),
                const SizedBox(height: 2),
                Text('Weeks ${pack.weekStart}–${pack.weekEnd} · ${pack.season} · ${pack.sizeMb.toStringAsFixed(1)} MB',
                    style: OT.small(alpha: 0.7)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          action,
        ],
      ),
    );
  }
}
