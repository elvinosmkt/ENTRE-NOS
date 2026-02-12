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
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Custom Header
            Row(
              children: [
                GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: const Icon(Icons.arrow_back_ios_new, size: 20, color: Color(0xFF1E232C)),
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'Ajustes',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1E232C),
                  ),
                ),
              ],
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
                      border: Border.all(color: const Color(0xFFFF4D8D), width: 2),
                    ),
                    child: const CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.grey,
                      backgroundImage: NetworkImage('https://api.dicebear.com/7.x/avataaars/svg?seed=Avatar'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _userName,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E232C),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF4D8D).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'CONECTADO ❤️',
                      style: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFFFF4D8D),
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
                color: Colors.white,
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
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
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
                    builder: (context) => AlertDialog(
                      backgroundColor: Colors.white,
                      surfaceTintColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      title: Text('Desconectar?', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800)),
                      content: Text('Você terá que entrar novamente para ver seus desenhos.', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF8391A1))),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Cancelar', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF8391A1))),
                        ),
                        TextButton(
                          onPressed: _disconnect,
                          child: Text('Sair', style: GoogleFonts.plusJakartaSans(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    )
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFF3F4F6), width: 1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildBottomNavItem(Icons.edit_rounded, 'Desenhar', onTap: () => context.go('/home')),
            _buildBottomNavItem(Icons.history_rounded, 'Histórico', onTap: () => context.push('/history')),
            _buildBottomNavItem(Icons.emoji_events_rounded, 'Premium', onTap: () => context.push('/premium')),
            _buildBottomNavItem(Icons.settings_rounded, 'Ajustes', isActive: true),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavItem(IconData icon, String label, {bool isActive = false, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 24, color: isActive ? const Color(0xFFFF4D8D) : const Color(0xFFD1D5DB)),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              color: isActive ? const Color(0xFFFF4D8D) : const Color(0xFFD1D5DB),
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
          color: isDestructive ? Colors.red.withOpacity(0.05) : const Color(0xFFFF4D8D).withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: isDestructive ? Colors.redAccent : const Color(0xFFFF4D8D), size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          color: isDestructive ? Colors.redAccent : const Color(0xFF1E232C),
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      trailing: showTrailing ? const Icon(Icons.arrow_forward_ios, color: Color(0xFFD1D5DB), size: 14) : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }
}
