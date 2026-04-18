import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../shared/habits_data.dart';

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});
  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen>
    with SingleTickerProviderStateMixin {
  int         _selectedCategory = 0;
  final Set<int> _checked = {};
  late AnimationController _headerAnim;
  late Animation<double>   _headerFade;

  @override
  void initState() {
    super.initState();
    _headerAnim = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 700));
    _headerFade = CurvedAnimation(
      parent: _headerAnim, curve: Curves.easeOut);
    _headerAnim.forward();
  }

  @override
  void dispose() { _headerAnim.dispose(); super.dispose(); }

  List<HabitItem> get _filtered {
    if (_selectedCategory == 0) return kHabits;
    final cat = kHabitCategories[_selectedCategory];
    return kHabits.where((h) => h.category == cat).toList();
  }

  @override
  Widget build(BuildContext context) {
    final done  = _checked.length;
    final total = kHabits.length;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: CustomScrollView(
          slivers: [

            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _headerFade,
                child: _HabitsHero(done: done, total: total),
              ),
            ),

            // ── Filtres catégories ────────────────────────────
            SliverToBoxAdapter(
              child: SizedBox(
                height: 44,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 4),
                  scrollDirection: Axis.horizontal,
                  itemCount: kHabitCategories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final selected = i == _selectedCategory;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedCategory = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: selected
                            ? AppColors.primary : AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: selected
                              ? AppColors.primary : AppColors.cardBorder),
                          boxShadow: selected ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.25),
                              blurRadius: 8, offset: const Offset(0, 3)),
                          ] : [],
                        ),
                        child: Text(kHabitCategories[i],
                          style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600,
                            color: selected
                              ? Colors.white : AppColors.textSecondary)),
                      ),
                    );
                  },
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // ── Liste habitudes ───────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              sliver: SliverList.separated(
                itemCount: _filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) {
                  final habit     = _filtered[i];
                  final globalIdx = kHabits.indexOf(habit);
                  return HabitCard(
                    habit: habit,
                    isChecked: _checked.contains(globalIdx),
                    onToggle: () => setState(() {
                      _checked.contains(globalIdx)
                        ? _checked.remove(globalIdx)
                        : _checked.add(globalIdx);
                    }),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Hero patient ─────────────────────────────────────────────
class _HabitsHero extends StatelessWidget {
  final int done, total;
  const _HabitsHero({required this.done, required this.total});

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : done / total;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF3DADA0), Color(0xFF5EC5B8), Color(0xFF8DD9D1)]),
        borderRadius: BorderRadius.only(
          bottomLeft:  Radius.circular(32),
          bottomRight: Radius.circular(32)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2))),
                    child: const Icon(Icons.arrow_back_rounded,
                      color: Colors.white, size: 20)),
                ),
                const SizedBox(width: 14),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Bonnes Habitudes',
                    style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800,
                      color: Colors.white, fontFamily: 'Inter')),
                  Text('Style de vie épilepsie-friendly',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.72))),
                ]),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20)),
                  child: Text('$done/$total',
                    style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w800,
                      color: Colors.white))),
              ]),
              const SizedBox(height: 24),
              Text(
                done == 0
                  ? 'Commencez votre journée saine !'
                  : done == total
                    ? 'Bravo ! Toutes les habitudes cochées !'
                    : '$done habitude${done > 1 ? 's' : ''} accomplie${done > 1 ? 's' : ''} aujourd\'hui',
                style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700,
                  color: Colors.white)),
              const SizedBox(height: 14),
              Stack(children: [
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(4))),
                AnimatedFractionallySizedBox(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOut,
                  widthFactor: progress,
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.greenAccent, Color(0xFF10B981)]),
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.greenAccent.withValues(alpha: 0.5),
                          blurRadius: 8),
                      ])),
                ),
              ]),
              const SizedBox(height: 8),
              Text('${(progress * 100).toInt()}% complété',
                style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.7))),
            ],
          ),
        ),
      ),
    );
  }
}
