import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';

class ConnectScreen extends ConsumerStatefulWidget {
  const ConnectScreen({super.key});

  @override
  ConsumerState<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends ConsumerState<ConnectScreen> {
  final TextEditingController _codeController = TextEditingController();
  String _generatedCode = 'XLF7B5';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadOrGenerateCode();
  }

  Future<void> _loadOrGenerateCode() async {
    final prefs = await SharedPreferences.getInstance();
    String? code = prefs.getString('my_code');
    if (code == null) {
      const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
      code = List.generate(6, (index) => chars[Random().nextInt(chars.length)]).join();
      await prefs.setString('my_code', code);
    }
    setState(() {
      _generatedCode = code!;
    });
  }

  Future<void> _connect() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Insira o código do seu amor!')),
      );
      return;
    }

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_connected', true);
      await prefs.setString('partner_code', code);
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background Gradient Blobs
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.04),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: -50,
            top: 200,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.03),
                shape: BoxShape.circle,
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                // Top Bar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: GestureDetector(
                      onTap: () => context.pop(),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.arrow_back_ios_new, size: 20, color: AppColors.primary),
                      ),
                    ),
                  ),
                ),
                
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        
                        // Icon/Profile Illustration
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.black.withOpacity(0.05), width: 1),
                              ),
                              child: Container(
                                width: 110,
                                height: 110,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFDF7F9),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Icon(Icons.favorite_rounded, size: 50, color: AppColors.primary.withOpacity(0.2)),
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))
                                ],
                              ),
                              child: const Icon(Icons.favorite_rounded, size: 16, color: AppColors.primary),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 32),
                        
                        Text(
                          'Conecte-se',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1E232C),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Insira o código do seu parceiro para começar a enviar mensagens para o widget dele.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            color: const Color(0xFF8391A1),
                            height: 1.5,
                          ),
                        ),
                        
                        const SizedBox(height: 40),
                        
                        // Input Area
                        Container(
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 40,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _codeController,
                            textAlign: TextAlign.center,
                            decoration: InputDecoration(
                              hintText: 'Ex: LOVE-2024',
                              hintStyle: GoogleFonts.plusJakartaSans(color: Colors.grey[300]),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(100),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.all(24),
                            ),
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Buttons
                        SizedBox(
                          width: double.infinity,
                          height: 64,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _connect,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                              elevation: 10,
                              shadowColor: AppColors.primary.withOpacity(0.4),
                            ),
                            child: _isLoading 
                              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('Conectar', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 18)),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.bolt, size: 20),
                                  ],
                                ),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        SizedBox(
                          width: double.infinity,
                          height: 64,
                          child: OutlinedButton(
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: _generatedCode));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Código copiado! ❤️')),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: BorderSide(color: AppColors.primary.withOpacity(0.2), width: 1),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                            ),
                            child: Text('Gerar meu código', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 18)),
                          ),
                        ),
                        
                        const SizedBox(height: 32),
                        
                        TextButton(
                          onPressed: () {},
                          child: Text(
                            'Onde encontro o código?',
                            style: GoogleFonts.plusJakartaSans(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 48),
                        
                        // Footer/Social Proof
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                             // Miniature avatars
                             SizedBox(
                               width: 48,
                               height: 24,
                               child: Stack(
                                 children: [
                                   Positioned(left: 0, child: CircleAvatar(radius: 12, backgroundColor: Colors.grey[200])),
                                   Positioned(left: 14, child: CircleAvatar(radius: 12, backgroundColor: Colors.grey[300], child: const Icon(Icons.person, size: 12, color: Colors.white))),
                                 ],
                               ),
                             ),
                             const SizedBox(width: 8),
                             Text(
                               '+100k casais conectados',
                               style: GoogleFonts.plusJakartaSans(
                                 color: Colors.grey[500],
                                 fontSize: 12,
                                 fontWeight: FontWeight.w500,
                               ),
                             ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
