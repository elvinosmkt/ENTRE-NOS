import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../subscription/data/subscription_provider.dart';

class PremiumScreen extends ConsumerWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(subscriptionProvider).value ?? false;
    final selectedPlan = ValueNotifier<int>(1); // 0 = monthly, 1 = annual

    return Scaffold(
      backgroundColor: context.surfaceColor,
      body: SafeArea(
        bottom: false,
        child: isPremium 
          ? _buildPremiumActive(context)
          : _buildPremiumOffer(context, ref, selectedPlan),
      ),
    );
  }

  Widget _buildPremiumActive(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.workspace_premium_rounded, size: 64, color: AppColors.warning),
          ),
          const SizedBox(height: 24),
          Text(
            'Premium Ativo! ✨',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: context.textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Você tem acesso ilimitado a todos os recursos.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: context.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumOffer(BuildContext context, WidgetRef ref, ValueNotifier<int> selectedPlan) {
    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.workspace_premium_rounded, size: 48, color: AppColors.primary),
              ),
              const SizedBox(height: 24),
              Text(
                'Desbloqueie tudo',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: context.textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Envie carinhos ilimitados.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  color: context.textSecondary,
                ),
              ),
            ],
          ),
        ),

        // Benefits
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 5)),
              ],
            ),
            child: Column(
              children: [
                _BenefitItem(icon: Icons.brush_rounded, text: 'Cores e pincéis exclusivos', textColor: context.textColor, secondaryColor: context.textSecondary),
                const SizedBox(height: 16),
                _BenefitItem(icon: Icons.all_inclusive, text: 'Carinhos ilimitados por dia', textColor: context.textColor, secondaryColor: context.textSecondary),
                const SizedBox(height: 16),
                _BenefitItem(icon: Icons.widgets_rounded, text: 'Widgets personalizáveis', textColor: context.textColor, secondaryColor: context.textSecondary),
                const SizedBox(height: 16),
                _BenefitItem(icon: Icons.photo_library_rounded, text: 'Fundos e stickers especiais', textColor: context.textColor, secondaryColor: context.textSecondary),
              ],
            ),
          ),
        ),

        const Spacer(),

        // Plans
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ValueListenableBuilder<int>(
            valueListenable: selectedPlan,
            builder: (context, selected, _) {
              return Row(
                children: [
                  Expanded(
                    child: _PlanCard(
                      title: 'Mensal',
                      price: 'R\$ 9,90',
                      period: '/mês',
                      isSelected: selected == 0,
                      onTap: () => selectedPlan.value = 0,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _PlanCard(
                      title: 'Anual',
                      price: 'R\$ 59,90',
                      period: '/ano',
                      badge: 'MELHOR VALOR',
                      isSelected: selected == 1,
                      onTap: () => selectedPlan.value = 1,
                    ),
                  ),
                ],
              );
            },
          ),
        ),

        const SizedBox(height: 24),

        // Subscribe Button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: SizedBox(
            width: double.infinity,
            height: 64,
            child: ElevatedButton(
              onPressed: () async {
                await ref.read(subscriptionProvider.notifier).purchase();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      content: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        decoration: BoxDecoration(
                          color: context.isDark ? AppColors.cardDark : const Color(0xFF1E232C),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle, color: AppColors.success, size: 24),
                            const SizedBox(width: 12),
                            Text('Premium ativado! ✨', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                elevation: 0,
              ),
              child: Text(
                'Assinar Premium',
                style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),

        // Restore
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: TextButton(
            onPressed: () => ref.read(subscriptionProvider.notifier).restore(),
            child: Text(
              'Restaurar compra',
              style: GoogleFonts.plusJakartaSans(
                color: context.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ),

        const SizedBox(height: 8),
      ],
    );
  }
}

class _BenefitItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color textColor;
  final Color secondaryColor;

  const _BenefitItem({required this.icon, required this.text, required this.textColor, required this.secondaryColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              color: textColor,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
        const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String title;
  final String price;
  final String period;
  final String? badge;
  final bool isSelected;
  final VoidCallback onTap;

  const _PlanCard({
    required this.title,
    required this.price,
    required this.period,
    required this.isSelected,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : context.borderColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            if (badge != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badge!,
                  style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),
            ],
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: context.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              price,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: context.textColor,
              ),
            ),
            Text(
              period,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: context.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
