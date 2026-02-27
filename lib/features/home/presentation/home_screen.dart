import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'drawing_canvas.dart';
import 'drawing_controller.dart';
import 'color_picker.dart';
import '../../../core/theme/app_colors.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
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
  int _activeTab = 0; // 0: Pincel, 1: Foto
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

  bool _checkPremium() {
    final isPremium = ref.read(subscriptionProvider).value ?? false;
    if (!isPremium) {
      context.push('/premium');
      return false;
    }
    return true;
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

        // Save locally for history
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

        // 1. Send to Supabase (cloud — viaja pro parceiro)
        final cloudSuccess = await _supabaseService.sendDrawingToPartner(bytes);
        debugPrint('Cloud sync: ${cloudSuccess ? "SUCCESS" : "FAILED"}');

        // 2. Send to local Widget (aparece na home screen deste celular)
        await _widgetService.sendData(
          imageBytes: bytes,
          text: 'Novo desenho de $userName! ❤️',
          author: userName,
        );

        // Feedback visual
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              duration: const Duration(seconds: 3),
              content: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: context.isDark
                      ? AppColors.cardDark.withOpacity(0.95)
                      : const Color(0xFF1E232C).withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.24), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Row(
                  children: [
                    Icon(
                      cloudSuccess ? Icons.check_circle_outline_rounded : Icons.cloud_off_rounded,
                      color: cloudSuccess ? AppColors.success : AppColors.warning,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            cloudSuccess ? 'Carinho enviado!' : 'Salvo localmente',
                            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          Text(
                            cloudSuccess
                                ? 'Ele(a) verá em instantes no widget. ❤️'
                                : 'Conecte-se a um parceiro para enviar online.',
                            style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.white.withOpacity(0.8)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      }
    }
    if (mounted) setState(() => _isSending = false);
  }

  @override
  Widget build(BuildContext context) {
    final drawingState = ref.watch(drawingControllerProvider);
    final controller = ref.read(drawingControllerProvider.notifier);
    final isPremium = ref.watch(subscriptionProvider).value ?? false;
    final userState = ref.watch(userProvider);
    final userName = userState.value?.name ?? 'Você';

    return Scaffold(
      backgroundColor: context.surfaceColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SizedBox(height: 8),
            // 1. Profile Status — Compact horizontal row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  // Avatar compacto
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 2),
                          image: DecorationImage(
                            image: NetworkImage('https://api.dicebear.com/7.x/avataaars/svg?seed=$userName'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                           color: AppColors.success,
                           shape: BoxShape.circle,
                           border: Border.all(color: context.cardColor, width: 2),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  // Nome + status
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              userName,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: context.textColor,
                              ),
                            ),
                            if (isPremium) ...[
                              const SizedBox(width: 4),
                              const Icon(Icons.stars_rounded, color: AppColors.warning, size: 16),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            ScaleTransition(
                              scale: Tween(begin: 0.8, end: 1.2).animate(
                                CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
                              ),
                              child: Container(
                                width: 6, height: 6,
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                  boxShadow: [BoxShadow(color: AppColors.primary, blurRadius: 4, spreadRadius: 1)]
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'CONECTADO ❤️',
                              style: GoogleFonts.plusJakartaSans(
                                color: AppColors.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // 2. Tab Selector
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildTabItem(0, Icons.edit_rounded, 'Pincel', onTap: () => setState(() => _activeTab = 0)),
                  _buildTabItem(1, Icons.image_rounded, 'Foto', isAction: true, onAction: () => _pickImage(controller)),
                  _buildLockedTabItem(Icons.emoji_emotions_rounded, 'Stickers'),
                  _buildLockedTabItem(Icons.text_fields_rounded, 'Texto'),
                ],
              ),
            ),

            // 3. Canvas Card
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: context.cardColor,
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: context.cardColor, width: 8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 30,
                        offset: const Offset(0, 12),
                      ),
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.03),
                        blurRadius: 20,
                        spreadRadius: -5,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Stack(
                      children: [
                        Container(color: context.isDark ? const Color(0xFF1A1025) : const Color(0xFFFDFDFD)),
                        DrawingCanvas(key: _canvasKey),
                        Positioned(
                          top: 16,
                          right: 16,
                          child: GestureDetector(
                            onTap: () => controller.clearCanvas(),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: context.surfaceColor.withOpacity(0.8),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.refresh_rounded, size: 20, color: context.textSecondary),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // 4. Color Palette & Brush Size
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ColorPicker(
                          selectedColor: drawingState.selectedColor,
                          isPremium: isPremium,
                          onColorSelected: (color) => controller.setColor(color),
                          onPremiumLocked: () => context.push('/premium'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildSmallTool(Icons.wash_rounded, context.isDark ? AppColors.cardDark : const Color(0xFF4B5563), onTap: () => controller.setColor(Colors.white)),
                      _buildSmallTool(Icons.undo_rounded, context.surfaceColor, iconColor: context.textSecondary, onTap: () => controller.undo()),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 80,
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: AppColors.primary,
                            inactiveTrackColor: context.dividerColor,
                            thumbColor: AppColors.primary,
                            trackHeight: 3,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                          ),
                          child: Slider(
                            value: drawingState.selectedStrokeWidth,
                            min: 2,
                            max: 25,
                            onChanged: (val) => controller.setStrokeWidth(val),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),

                  // 5. Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _isSending ? null : _sendToPartner,
                      icon: _isSending
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.send_rounded, size: 20),
                      label: Text(
                        _isSending ? 'Enviando...' : 'Enviar para a tela dele',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: AppColors.primary.withOpacity(0.6),
                        disabledForegroundColor: Colors.white70,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem(int index, IconData icon, String label, {bool isAction = false, VoidCallback? onAction, VoidCallback? onTap}) {
    final isSelected = _activeTab == index;
    return GestureDetector(
      onTap: isAction ? onAction : onTap,
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: isSelected ? AppColors.primary : context.textSecondary),
              const SizedBox(width: 4),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? AppColors.primary : context.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 2,
            color: isSelected ? AppColors.primary : Colors.transparent,
          ),
        ],
      ),
    );
  }

  Widget _buildLockedTabItem(IconData icon, String label) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            duration: const Duration(seconds: 2),
            content: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: context.isDark ? AppColors.cardDark : const Color(0xFF1E232C),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_rounded, color: AppColors.warning, size: 18),
                  const SizedBox(width: 8),
                  Text('$label chega em breve! ✨', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        );
      },
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: context.textSecondary.withOpacity(0.4)),
              const SizedBox(width: 4),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: context.textSecondary.withOpacity(0.4),
                ),
              ),
              const SizedBox(width: 2),
              Icon(Icons.lock_rounded, size: 10, color: context.textSecondary.withOpacity(0.4)),
            ],
          ),
          const SizedBox(height: 8),
          Container(width: 40, height: 2, color: Colors.transparent),
        ],
      ),
    );
  }

  Widget _buildSmallTool(IconData icon, Color bgColor, {Color iconColor = Colors.white, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        width: 38,
        height: 38,
        decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
        child: Icon(icon, color: iconColor, size: 18),
      ),
    );
  }
}
