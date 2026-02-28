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
    if (pickedFile != null && mounted) {
      controller.setBackgroundImage(File(pickedFile.path));
    }
  }

  Future<void> _showTextDialog(DrawingController controller) async {
    final textController = TextEditingController();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 20, left: 20, right: 20, top: 20),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Adicionar Texto 💬',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Escreva uma mensagem para seu amor',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: textController,
                      autofocus: true,
                      maxLines: 3,
                      style: GoogleFonts.plusJakartaSans(color: const Color(0xFF1A1A2E)),
                      decoration: InputDecoration(
                        hintText: 'Ex: Te amo muito! ❤️',
                        hintStyle: GoogleFonts.plusJakartaSans(color: Colors.grey[400]),
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          if (textController.text.isNotEmpty) {
                            controller.addText(textController.text);
                          }
                          Navigator.of(ctx).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: Text(
                          'Adicionar ao Desenho',
                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
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
    final canvasBackground = isDark ? const Color(0xFF120D1A) : Colors.white;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFFDFCFD),
      body: Stack(
        children: [
          // Background glow disks
          Positioned(
            top: -80,
            right: -80,
            child: _GlowDisk(color: AppColors.primary.withOpacity(0.10), size: 360),
          ),
          Positioned(
            bottom: -40,
            left: -40,
            child: _GlowDisk(color: AppColors.secondary.withOpacity(0.07), size: 300),
          ),

          // Main Content
          SafeArea(
            child: Column(
              children: [
                // ── Header ──────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
                  child: _FloatingGlassContainer(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      child: Row(
                        children: [
                          _AnimatedAvatar(userName: userName),
                          const SizedBox(width: 10),
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
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: context.textColor,
                                      ),
                                    ),
                                    if (isPremium) ...[
                                      const SizedBox(width: 4),
                                      const Icon(Icons.verified_rounded, color: AppColors.primary, size: 14),
                                    ],
                                  ],
                                ),
                                _ConnectionStatus(pulseController: _pulseController),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => context.push('/settings'),
                            icon: const Icon(Icons.settings_rounded, size: 20),
                            color: context.textSecondary,
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Canvas Area ──────────────────────────────────────────
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Canvas container — SEM ClipRRect que quebra gestos
                        Container(
                          decoration: BoxDecoration(
                            color: canvasBackground,
                            borderRadius: BorderRadius.circular(32),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
                                blurRadius: 30,
                                offset: const Offset(0, 12),
                              ),
                            ],
                            border: Border.all(
                              color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.12),
                              width: 1,
                            ),
                          ),
                          // Usamos o Canvas DENTRO do Container, sem ClipRRect,
                          // para que os gestos de toque funcionem em toda a área.
                          child: DrawingCanvas(key: _canvasKey),
                        ),

                        // Floating action buttons (clear / undo) no canto superior direito
                        Positioned(
                          top: 14,
                          right: 14,
                          child: Column(
                            children: [
                              _CanvasActionButton(
                                icon: Icons.refresh_rounded,
                                tooltip: 'Limpar',
                                onTap: () => controller.clearCanvas(),
                              ),
                              const SizedBox(height: 10),
                              _CanvasActionButton(
                                icon: Icons.undo_rounded,
                                tooltip: 'Desfazer',
                                onTap: () => controller.undo(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Bottom Controls ──────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  child: Column(
                    children: [
                      // Tools panel
                      _FloatingGlassContainer(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                          child: Column(
                            children: [
                              // Row: Colors + quick tool buttons
                              Row(
                                children: [
                                  // Color picker expandido
                                  Expanded(
                                    child: SizedBox(
                                      height: 56,
                                      child: ColorPicker(
                                        selectedColor: drawingState.selectedColor,
                                        isPremium: isPremium,
                                        onColorSelected: (color) => controller.setColor(color),
                                        onPremiumLocked: () => context.push('/premium'),
                                      ),
                                    ),
                                  ),
                                  // Separador
                                  Container(
                                    width: 1,
                                    height: 32,
                                    color: Colors.grey.withOpacity(0.2),
                                    margin: const EdgeInsets.symmetric(horizontal: 8),
                                  ),
                                  // Botão: Foto
                                  _ToolIconButton(
                                    icon: Icons.image_rounded,
                                    label: 'Foto',
                                    color: const Color(0xFF6366F1),
                                    onTap: () => _pickImage(controller),
                                  ),
                                  const SizedBox(width: 6),
                                  // Botão: Texto
                                  _ToolIconButton(
                                    icon: Icons.text_fields_rounded,
                                    label: 'Texto',
                                    color: AppColors.primary,
                                    onTap: () => _showTextDialog(controller),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Stroke slider
                              Row(
                                children: [
                                  Icon(Icons.brush_rounded, size: 16, color: context.textSecondary),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: SliderTheme(
                                      data: SliderTheme.of(context).copyWith(
                                        activeTrackColor: AppColors.primary,
                                        inactiveTrackColor: Colors.grey.withOpacity(0.15),
                                        thumbColor: Colors.white,
                                        overlayColor: AppColors.primary.withOpacity(0.1),
                                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9, elevation: 4),
                                        trackHeight: 3,
                                      ),
                                      child: Slider(
                                        value: drawingState.selectedStrokeWidth,
                                        min: 2,
                                        max: 30,
                                        onChanged: (val) => controller.setStrokeWidth(val),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: 28,
                                    height: 28,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: drawingState.selectedColor.withOpacity(0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Container(
                                      width: (drawingState.selectedStrokeWidth / 30) * 20 + 2,
                                      height: (drawingState.selectedStrokeWidth / 30) * 20 + 2,
                                      decoration: BoxDecoration(
                                        color: drawingState.selectedColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Send button
                      SizedBox(
                        width: double.infinity,
                        height: 58,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(100),
                            gradient: const LinearGradient(
                              colors: [AppColors.primary, Color(0xFFFF6EB4)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.35),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _isSending ? null : _sendToPartner,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                              elevation: 0,
                            ),
                            child: _isSending
                                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.send_rounded, size: 18),
                                      const SizedBox(width: 10),
                                      Text(
                                        'Enviar para o Amor ❤️',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.2,
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

// ────────────────────────────────────────────────────────────────
// Reusable Widgets
// ────────────────────────────────────────────────────────────────

class _FloatingGlassContainer extends StatelessWidget {
  final Widget child;
  const _FloatingGlassContainer({required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.75),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.white.withOpacity(isDark ? 0.1 : 0.5),
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
    final initials = userName.isNotEmpty ? userName.substring(0, 1).toUpperCase() : '?';
    return Container(
      width: 44,
      height: 44,
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
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          initials,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
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
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: AppColors.success, blurRadius: 4, spreadRadius: 0)],
            ),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          'CONECTADO',
          style: GoogleFonts.plusJakartaSans(
            color: AppColors.success,
            fontSize: 10,
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
  final String tooltip;
  final VoidCallback onTap;
  const _CanvasActionButton({required this.icon, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDark ? Colors.black.withOpacity(0.5) : Colors.white.withOpacity(0.9),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(icon, size: 18, color: context.textColor.withOpacity(0.6)),
        ),
      ),
    );
  }
}

/// Botão de ferramenta com ícone + label pequeno abaixo
class _ToolIconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ToolIconButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.13),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
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
