import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

class MenuScreen extends ConsumerStatefulWidget {
  const MenuScreen({super.key});

  @override
  ConsumerState<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends ConsumerState<MenuScreen> {
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('user_name') ?? 'Usuário';
    });
  }

  Future<void> _disconnect() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Clear all data
    if (mounted) {
      context.go('/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textGrey),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Configurações',
          style: GoogleFonts.plusJakartaSans(
            color: AppColors.textLight,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Profile Section
          Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary, width: 2),
                    boxShadow: [
                      BoxShadow(color: AppColors.primary.withOpacity(0.1), blurRadius: 15),
                    ],
                  ),
                  child: const CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.grey,
                    backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=12'),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _userName,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textLight,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Conectado',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 48),
          
          // Menu Items
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                _MenuItem(
                  icon: Icons.edit_outlined,
                  title: 'Editar Nome',
                  onTap: () {
                     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Em breve...')));
                  },
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _MenuItem(
                  icon: Icons.workspace_premium_rounded,
                  title: 'Desbloquear Premium',
                  onTap: () => context.push('/premium'),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _MenuItem(
                  icon: Icons.card_giftcard_rounded,
                  title: 'Presentear Amor',
                  onTap: () => context.push('/gifting'),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _MenuItem(
                  icon: Icons.help_outline,
                  title: 'Como funciona o Widget?',
                  onTap: () => context.push('/tutorial'),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _MenuItem(
                  icon: Icons.shield_outlined,
                  title: 'Termos e Privacidade',
                  onTap: () {},
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                 BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
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
                  builder: (context) => AlertDialog(
                    backgroundColor: Colors.white,
                    surfaceTintColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    title: Text('Desconectar?', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
                    content: Text('Você terá que entrar novamente para ver seus desenhos.', style: GoogleFonts.plusJakartaSans(color: AppColors.textGrey)),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Cancelar', style: GoogleFonts.plusJakartaSans(color: AppColors.textGrey)),
                      ),
                      TextButton(
                        onPressed: _disconnect,
                        child: Text('Sair', style: GoogleFonts.plusJakartaSans(color: AppColors.error, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  )
                );
              },
            ),
          ),
          
          const SizedBox(height: 32),
          
          Center(
            child: Text(
              'Versão 1.0.0 (Beta)',
              style: GoogleFonts.plusJakartaSans(color: AppColors.textGrey.withOpacity(0.5), fontSize: 12),
            ),
          ),
        ],
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
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDestructive ? AppColors.error.withOpacity(0.1) : AppColors.primary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: isDestructive ? AppColors.error : AppColors.primary, size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          color: isDestructive ? AppColors.error : AppColors.textLight,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),
      trailing: showTrailing ? const Icon(Icons.arrow_forward_ios, color: AppColors.textGrey, size: 14) : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}


