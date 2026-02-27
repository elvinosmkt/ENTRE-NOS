import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/providers/user_provider.dart';
import 'package:flutter/services.dart';
import '../../subscription/data/subscription_provider.dart';

class MenuScreen extends ConsumerWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(subscriptionProvider).value ?? false;
    final userState = ref.watch(userProvider);
    final userName = userState.value?.name ?? 'Usuário';
    final myCode = userState.value?.myCode ?? '...';

    return Scaffold(
      backgroundColor: context.surfaceColor,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Header
            Text(
              'Ajustes',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: context.textColor,
              ),
            ),
            const SizedBox(height: 32),
            
            // Profile Section
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: isPremium ? AppColors.warning : AppColors.primary, width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: context.surfaceColor,
                      backgroundImage: NetworkImage('https://api.dicebear.com/7.x/avataaars/svg?seed=$userName'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    userName,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: context.textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isPremium ? AppColors.warning.withOpacity(0.1) : AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isPremium ? 'PREMIUM ATIVO ✨' : 'CONECTADO ❤️',
                      style: GoogleFonts.plusJakartaSans(
                        color: isPremium ? const Color(0xFFB8860B) : AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Menu Items
            Container(
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 20,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _MenuItem(
                    icon: Icons.person_add_outlined,
                    title: 'Meu Código: $myCode',
                    onTap: () {
                       Clipboard.setData(ClipboardData(text: myCode));
                       ScaffoldMessenger.of(context).showSnackBar(
                         SnackBar(content: Text('Código "$myCode" copiado! Compartilhe com seu amor. ❤️'))
                       );
                    },
                  ),
                  Divider(height: 1, indent: 16, endIndent: 16, color: context.dividerColor),
                  _MenuItem(
                    icon: Icons.edit_outlined,
                    title: 'Editar Nome',
                    onTap: () {
                       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Em breve...')));
                    },
                  ),
                  if (!isPremium) ...[
                    Divider(height: 1, indent: 16, endIndent: 16, color: context.dividerColor),
                    _MenuItem(
                      icon: Icons.workspace_premium_rounded,
                      title: 'Desbloquear Premium',
                      onTap: () => context.push('/premium'),
                    ),
                  ],
                  Divider(height: 1, indent: 16, endIndent: 16, color: context.dividerColor),
                  _MenuItem(
                    icon: Icons.card_giftcard_rounded,
                    title: 'Presentear Amor',
                    onTap: () => context.push('/gifting'),
                  ),
                  Divider(height: 1, indent: 16, endIndent: 16, color: context.dividerColor),
                  _MenuItem(
                    icon: Icons.help_outline,
                    title: 'Como funciona o Widget?',
                    onTap: () => context.push('/tutorial'),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            Container(
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                   BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 20,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: _MenuItem(
                icon: Icons.logout,
                title: 'Desconectar',
                isDestructive: true,
                showTrailing: false,
                onTap: () {
                  showDialog(
                    context: context, 
                    builder: (ctx) => AlertDialog(
                      backgroundColor: context.cardColor,
                      surfaceTintColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      title: Text('Desconectar?', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: context.textColor)),
                      content: Text('Você terá que entrar novamente para ver seus desenhos.', style: GoogleFonts.plusJakartaSans(color: context.textSecondary)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text('Cancelar', style: GoogleFonts.plusJakartaSans(color: context.textSecondary)),
                        ),
                        TextButton(
                          onPressed: () async {
                            Navigator.pop(ctx);
                            await ref.read(userProvider.notifier).disconnect();
                            if (context.mounted) {
                              context.go('/onboarding');
                            }
                          },
                          child: Text('Sair', style: GoogleFonts.plusJakartaSans(color: AppColors.error, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    )
                  );
                },
              ),
            ),

            const SizedBox(height: 80), // padding for bottom nav
          ],
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isDestructive;
  final bool showTrailing;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isDestructive = false,
    this.showTrailing = true,
  });

  @override
  Widget build(BuildContext context) {
    final iconBgColor = isDestructive 
        ? AppColors.error.withOpacity(0.05) 
        : AppColors.primary.withOpacity(0.05);
    final iconColor = isDestructive ? AppColors.error : AppColors.primary;
    final titleColor = isDestructive ? AppColors.error : context.textColor;

    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconBgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          color: titleColor,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      trailing: showTrailing ? Icon(Icons.arrow_forward_ios, color: context.dividerColor, size: 14) : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }
}
