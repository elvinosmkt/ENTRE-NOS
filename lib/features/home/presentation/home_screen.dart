import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'drawing_canvas.dart';
import 'drawing_controller.dart';
import 'color_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../widget_config/widget_service.dart';
import '../../subscription/data/subscription_provider.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/network/supabase_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with SingleTickerProviderStateMixin {
  final GlobalKey<DrawingCanvasState> _canvasKey = GlobalKey();
  final WidgetService _widgetService = WidgetService();
  final SupabaseService _supabaseService = SupabaseService();
  late AnimationController _pulseController;
  int _activeTab = 0;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
       vsync: this,
       duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(DrawingController controller) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      if (mounted) {
        controller.setBackgroundImage(File(pickedFile.path));
        setState(() => _activeTab = 1);
      }
    }
  }

  void _sendToPartner() async {
    if (_isSending) return;
    setState(() => _isSending = true);

    final bytes = await _canvasKey.currentState?.capturePng();
    if (bytes != null) {
      if (context.mounted) {
        final userName = ref.read(userProvider).value?.name ?? 'Alguém';

        try {
          final directory = await getApplicationDocumentsDirectory();
          final fileName = 'drawing_${DateTime.now().millisecondsSinceEpoch}.png';
          final file = File('${directory.path}/$fileName');
          await file.writeAsBytes(bytes);

          final prefs = await SharedPreferences.getInstance();
          final history = prefs.getStringList('history') ?? [];
          history.add(file.path);
          await prefs.setStringList('history', history);
        } catch (e) {
          debugPrint('Error saving drawing: $e');
        }

        final cloudSuccess = await _supabaseService.sendDrawingToPartner(bytes);

        await _widgetService.sendData(
          imageBytes: bytes,
          text: 'Novo desenho de $userName! ❤️',
          author: userName,
        );

        if (context.mounted) {
          _showCustomSnackBar(
            cloudSuccess ? 'Carinho enviado com sucesso! ❤️' : 'Salvo (offline)',
            isSuccess: cloudSuccess,
          );
        }
      }
    }
    if (mounted) setState(() => _isSending = false);
  }

  void _showCustomSnackBar(String message, {bool isSuccess = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: (isSuccess ? AppColors.primary : Colors.orange).withOpacity(0.9),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 8)),
              ],
            ),
            child: Row(
              children: [
                Icon(isSuccess ? Icons.favorite_rounded : Icons.cloud_off_rounded, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final drawingState = ref.watch(drawingControllerProvider);
    final controller = ref.read(drawingControllerProvider.notifier);
    final isPremium = ref.watch(subscriptionProvider).value ?? false;
    final userState = ref.watch(userProvider);
    final userName = userState.value?.name ?? 'Você';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFFDFCFD),
      body: Stack(
        children: [
          // 1. Mesh Background
          Positioned(
            top: -100,
            right: -100,
            child: _GlowDisk(color: AppColors.primary.withOpacity(0.12), size: 400),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: _GlowDisk(color: AppColors.secondary.withOpacity(0.08), size: 350),
          ),

          // 2. Main Content
          SafeArea(
            child: Column(
              children: [
                // Floating Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                  child: _FloatingGlassContainer(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Row(
                        children: [
                          _AnimatedAvatar(userName: userName),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      userName,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: context.textColor,
                                      ),
                                    ),
                                    if (isPremium) ...[
                                      const SizedBox(width: 4),
                                      const Icon(Icons.verified_rounded, color: AppColors.primary, size: 16),
                                    ],
                                  ],
                                ),
                                _ConnectionStatus(pulseController: _pulseController),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => context.push('/settings'),
                            icon: const Icon(Icons.settings_rounded, size: 22),
                            color: context.textSecondary,
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Canvas Area (Immersive)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Stack(
                      children: [
                        // Canvas Frame
                        Container(
                          decoration: BoxDecoration(
                            color: isDark ? Colors.black.withOpacity(0.2) : Colors.white,
                            borderRadius: BorderRadius.circular(40),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                                blurRadius: 40,
                                offset: const Offset(0, 20),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(40),
                            child: DrawingCanvas(key: _canvasKey),
                          ),
                        ),
                        
                        // Floating Canvas Controls
                        Positioned(
                          top: 20,
                          right: 20,
                          child: Column(
                            children: [
                              _CanvasActionButton(
                                icon: Icons.refresh_rounded,
                                onTap: () => controller.clearCanvas(),
                              ),
                              const SizedBox(height: 12),
                              _CanvasActionButton(
                                icon: Icons.undo_rounded,
                                onTap: () => controller.undo(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom Controls Area
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Column(
                    children: [
                      _FloatingGlassContainer(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              // Color & Tools Row
                              Row(
                                children: [
                                  Expanded(
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: ColorPicker(
                                        selectedColor: drawingState.selectedColor,
                                        isPremium: isPremium,
                                        onColorSelected: (color) => controller.setColor(color),
                                        onPremiumLocked: () => context.push('/premium'),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    width: 1,
                                    height: 30,
                                    color: context.dividerColor.withOpacity(0.1),
                                  ),
                                  const SizedBox(width: 12),
                                  _ToolButton(
                                    icon: Icons.image_rounded,
                                    onTap: () => _pickImage(controller),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              // Stroke Size Slider
                              Row(
                                children: [
                                  Icon(Icons.brush_rounded, size: 18, color: context.textSecondary),
                                  Expanded(
                                    child: SliderTheme(
                                      data: SliderTheme.of(context).copyWith(
                                        activeTrackColor: AppColors.primary,
                                        inactiveTrackColor: context.dividerColor.withOpacity(0.2),
                                        thumbColor: Colors.white,
                                        overlayColor: AppColors.primary.withOpacity(0.1),
                                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10, elevation: 4),
                                      ),
                                      child: Slider(
                                        value: drawingState.selectedStrokeWidth,
                                        min: 2,
                                        max: 30,
                                        onChanged: (val) => controller.setStrokeWidth(val),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Submit Button (Hero Style)
                      SizedBox(
                        width: double.infinity,
                        height: 64,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(100),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _isSending ? null : _sendToPartner,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                              elevation: 0,
                            ),
                            child: _isSending
                                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.send_rounded, size: 20),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Enviar para o Amor',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ],
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

class _FloatingGlassContainer extends StatelessWidget {
  final Widget child;
  const _FloatingGlassContainer({required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: Colors.white.withOpacity(isDark ? 0.1 : 0.4),
              width: 1.5,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _AnimatedAvatar extends StatelessWidget {
  final String userName;
  const _AnimatedAvatar({required this.userName});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          userName.substring(0, 1).toUpperCase(),
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
    );
  }
}

class _ConnectionStatus extends StatelessWidget {
  final AnimationController pulseController;
  const _ConnectionStatus({required this.pulseController});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ScaleTransition(
          scale: Tween(begin: 0.8, end: 1.2).animate(
            CurvedAnimation(parent: pulseController, curve: Curves.easeInOut),
          ),
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: AppColors.success, blurRadius: 6, spreadRadius: 1)],
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          'CONECTADO',
          style: GoogleFonts.plusJakartaSans(
            color: AppColors.success,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _CanvasActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CanvasActionButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? Colors.black.withOpacity(0.4) : Colors.white.withOpacity(0.8),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20, color: context.textColor.withOpacity(0.7)),
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _ToolButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.image_rounded, color: AppColors.primary, size: 22),
      ),
    );
  }
}

class _GlowDisk extends StatelessWidget {
  final Color color;
  final double size;
  const _GlowDisk({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.5), blurRadius: size / 2, spreadRadius: 10),
        ],
      ),
    );
  }
}
