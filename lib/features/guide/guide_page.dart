import 'package:alburdat_dashboard/core/theme/app_theme.dart';
import 'package:alburdat_dashboard/features/guide/guide_content.dart';
import 'package:alburdat_dashboard/widgets/app_bars.dart';
import 'package:alburdat_dashboard/widgets/app_card.dart';
import 'package:alburdat_dashboard/widgets/status_widgets.dart';
import 'package:flutter/material.dart';

/// Membuka panduan, opsional langsung ke [topic].
Future<void> openGuide(BuildContext context, [GuideTopic? topic]) {
  return Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => GuidePage(initialTopic: topic)),
  );
}

/// Tombol "?" kontekstual untuk header halaman.
class HelpButton extends StatelessWidget {
  const HelpButton({super.key, required this.topic});

  final GuideTopic topic;

  @override
  Widget build(BuildContext context) {
    return SquareIconButton(
      icon: Icons.help_outline_rounded,
      tooltip: 'Panduan',
      onPressed: () => openGuide(context, topic),
    );
  }
}

class GuidePage extends StatefulWidget {
  const GuidePage({super.key, this.initialTopic});

  final GuideTopic? initialTopic;

  @override
  State<GuidePage> createState() => _GuidePageState();
}

class _GuidePageState extends State<GuidePage> {
  final _search = TextEditingController();
  final Map<GuideTopic, GlobalKey> _keys = {for (final s in guideSections) s.topic: GlobalKey()};
  String _query = '';

  @override
  void initState() {
    super.initState();
    final topic = widget.initialTopic;
    if (topic != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = _keys[topic]?.currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 300), alignment: 0.05);
        }
      });
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _matches(GuideSection s) => _query.isEmpty || s.searchText.contains(_query);

  @override
  Widget build(BuildContext context) {
    final sections = guideSections.where(_matches).toList();
    final faqs = faqItems
        .where((f) => _query.isEmpty || '${f.question} ${f.answer}'.toLowerCase().contains(_query))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Panduan')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          // Bukan ListView lazy: semua bagian harus ter-build agar
          // ensureVisible bisa melompat ke topik mana pun.
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.sm, Gap.lg, Gap.xxl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
              TextField(
                controller: _search,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Cari panduan, mis. "WiFi" atau "HST"',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Hapus',
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => setState(() {
                            _search.clear();
                            _query = '';
                          }),
                        ),
                ),
                onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
              ),
              const SizedBox(height: Gap.lg),
              if (sections.isEmpty && faqs.isEmpty)
                const EmptyState(
                  icon: Icons.search_off_rounded,
                  title: 'Tidak ditemukan',
                  message: 'Coba kata kunci lain.',
                ),
              for (final s in sections)
                if (s.topic != GuideTopic.troubleshooting)
                  Padding(
                    key: _keys[s.topic],
                    padding: const EdgeInsets.only(bottom: Gap.md),
                    child: _SectionCard(
                      section: s,
                      initiallyExpanded: s.topic == widget.initialTopic || _query.isNotEmpty,
                    ),
                  ),
              if (faqs.isNotEmpty) ...[
                Padding(
                  key: _keys[GuideTopic.troubleshooting],
                  padding: const EdgeInsets.only(top: Gap.sm, bottom: Gap.md),
                  child: const SectionHeader(
                    title: 'Pemecahan masalah',
                    subtitle: 'Pertanyaan yang sering muncul',
                  ),
                ),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (var i = 0; i < faqs.length; i++) ...[
                        if (i > 0) const Divider(indent: Gap.lg, endIndent: Gap.lg),
                        ExpansionTile(
                          initiallyExpanded: _query.isNotEmpty ||
                              (widget.initialTopic == GuideTopic.troubleshooting && i == 0),
                          title: Text(faqs[i].question, style: Theme.of(context).textTheme.titleMedium),
                          childrenPadding: const EdgeInsets.fromLTRB(Gap.lg, 0, Gap.lg, Gap.lg),
                          expandedAlignment: Alignment.centerLeft,
                          children: [Text(faqs[i].answer, style: Theme.of(context).textTheme.bodyMedium)],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.section, required this.initiallyExpanded});

  final GuideSection section;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return AppCard(
      padding: EdgeInsets.zero,
      child: ExpansionTile(
        // Key bergantung pada status awal supaya hasil pencarian ikut terbuka.
        key: PageStorageKey('${section.topic}-$initiallyExpanded'),
        initiallyExpanded: initiallyExpanded,
        leading: Container(
          padding: const EdgeInsets.all(Gap.sm),
          decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(Radii.sm)),
          child: Icon(section.icon, color: AppColors.primary, size: 20),
        ),
        title: Text(section.title, style: t.titleMedium),
        subtitle: Text(section.summary, style: t.bodySmall),
        childrenPadding: const EdgeInsets.fromLTRB(Gap.lg, 0, Gap.lg, Gap.lg),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < section.steps.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: Gap.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(color: AppColors.navActive, shape: BoxShape.circle),
                    child: Text('${i + 1}', style: t.labelSmall?.copyWith(color: Colors.white)),
                  ),
                  const SizedBox(width: Gap.md),
                  Expanded(child: Text(section.steps[i], style: t.bodyMedium)),
                ],
              ),
            ),
          if (section.warning != null) ...[
            const SizedBox(height: Gap.xs),
            InfoBanner(message: section.warning!, tone: Tone.warning),
          ],
          for (final tip in section.tips) ...[
            const SizedBox(height: Gap.sm),
            InfoBanner(message: tip, tone: Tone.info, icon: Icons.lightbulb_outline_rounded),
          ],
        ],
      ),
    );
  }
}
