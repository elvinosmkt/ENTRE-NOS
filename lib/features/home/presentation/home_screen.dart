import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'drawing_canvas.dart';
import 'drawing_controller.dart';
import '../../../core/theme/app_colors.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widget_config/widget_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final GlobalKey<DrawingCanvasState> _canvasKey = GlobalKey();
  final WidgetService _widgetService = WidgetService();
  int _activeTab = 0; // 0: Pincel, 1: Foto, 2: Stickers, 3: Texto

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

  void _showStickersSheet() {
    setState(() => _activeTab = 2);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Escolha um Sticker', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 24),
              GridView.builder(
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, crossAxisSpacing: 16, mainAxisSpacing: 16),
                itemCount: 8,
                itemBuilder: (context, index) {
                  final stickers = ['❤️', '✨', '🌸', '🧸', '🐱', '🦋', '🍭', '🌈'];
                  return GestureDetector(
                    onTap: () {
                      // No futuro: Adicionar sticker no canvas
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sticker selecionado! (Em breve no canvas)')));
                    },
                    child: Container(
                      decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(16)),
                      child: Center(child: Text(stickers[index], style: const TextStyle(fontSize: 32))),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  void _showTextInput() {
    setState(() => _activeTab = 3);
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Adicionar Texto', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Escreva algo lindo...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Texto adicionado! (Em breve no canvas)')));
            },
            child: const Text('Ok'),
          ),
        ],
      ),
    );
  }

  void _sendToPartner() async {
    final bytes = await _canvasKey.currentState?.capturePng();
    if (bytes != null) {
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(40),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 40)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 80),
                   const SizedBox(height: 24),
                   Text(
                     'Carinho Enviado!',
                     style: GoogleFonts.plusJakartaSans(
                       fontSize: 24,
                       fontWeight: FontWeight.w800,
                       color: AppColors.textLight,
                     ),
                   ),
                   const SizedBox(height: 12),
                   Text(
                     'Seu amor já recebeu o desenho no widget!',
                     textAlign: TextAlign.center,
                     style: GoogleFonts.plusJakartaSans(
                       color: AppColors.textGrey,
                       fontSize: 15,
                       height: 1.5,
                     ),
                   ),
                ],
              ),
            ),
          ),
        );

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

        // Send to Widget
        final prefs = await SharedPreferences.getInstance();
        final userName = prefs.getString('user_name') ?? 'Alguém';
        await _widgetService.sendData(
          imageBytes: bytes,
          text: 'Novo desenho de $userName! ❤️',
          author: userName,
        );

        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.pop(context);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final drawingState = ref.watch(drawingControllerProvider);
    final controller = ref.read(drawingControllerProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 12),
                // 1. Profile Status
                Column(
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 2),
                            image: const DecorationImage(
                              image: NetworkImage('https://api.dicebear.com/7.x/avataaars/svg?seed=Lucas'),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                             color: AppColors.success,
                             shape: BoxShape.circle,
                             border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Lucas',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E232C),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 6, height: 6,
                          decoration: const BoxDecoration(color: Color(0xFFFF4D8D), shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'CONECTADO ❤️',
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFFFF4D8D),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // 2. Tab Selector
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildTabItem(0, Icons.edit_rounded, 'Pincel', onTap: () => setState(() => _activeTab = 0)),
                      _buildTabItem(1, Icons.image_rounded, 'Foto', isAction: true, onAction: () => _pickImage(controller)),
                      _buildTabItem(2, Icons.emoji_emotions_rounded, 'Stickers', isAction: true, onAction: _showStickersSheet),
                      _buildTabItem(3, Icons.text_fields_rounded, 'Texto', isAction: true, onAction: _showTextInput),
                    ],
                  ),
                ),

                // 3. Canvas Card
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 40,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(32),
                        child: Stack(
                          children: [
                            DrawingCanvas(key: _canvasKey),
                            // Undo/Reset
                            Positioned(
                              top: 16,
                              right: 16,
                              child: GestureDetector(
                                onTap: () => controller.clearCanvas(),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(color: Color(0xFFF3F4F6), shape: BoxShape.circle),
                                  child: const Icon(Icons.refresh_rounded, size: 20, color: Color(0xFF9CA3AF)),
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
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _buildColorCircle(const Color(0xFFFF4D8D), controller, drawingState),
                                  _buildColorCircle(const Color(0xFFFF8585), controller, drawingState),
                                  _buildColorCircle(const Color(0xFF60A5FA), controller, drawingState),
                                  _buildColorCircle(Colors.black, controller, drawingState),
                                  _buildColorCircle(Colors.white, controller, drawingState, hasBorder: true),
                                  const SizedBox(width: 8),
                                  _buildSmallTool(Icons.wash_rounded, const Color(0xFF4B5563)),
                                  _buildSmallTool(Icons.brush_rounded, const Color(0xFFF3F4F6), iconColor: Colors.grey),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          SizedBox(
                            width: 80,
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: const Color(0xFFFF4D8D),
                                inactiveTrackColor: const Color(0xFFE5E7EB),
                                thumbColor: const Color(0xFFFF4D8D),
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
                      
                      const SizedBox(height: 24),

                      // 5. Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 64,
                        child: ElevatedButton.icon(
                          onPressed: _sendToPartner,
                          icon: const Icon(Icons.send_rounded, size: 20),
                          label: Text(
                            'Enviar para a tela dele',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF4D8D),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 12),

                // 6. Bottom Navigation Bar
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: Color(0xFFF3F4F6), width: 1)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildBottomNavItem(Icons.edit_rounded, 'Desenhar', isActive: true),
                      _buildBottomNavItem(Icons.history_rounded, 'Histórico', onTap: () => context.push('/history')),
                      _buildBottomNavItem(Icons.emoji_events_rounded, 'Premium', onTap: () => context.push('/premium')),
                      _buildBottomNavItem(Icons.settings_rounded, 'Ajustes', onTap: () => context.push('/menu')),
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

  Widget _buildTabItem(int index, IconData icon, String label, {bool isAction = false, VoidCallback? onAction, VoidCallback? onTap}) {
    final isSelected = _activeTab == index;
    return GestureDetector(
      onTap: isAction ? onAction : onTap,
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: isSelected ? const Color(0xFFFF4D8D) : const Color(0xFF9CA3AF)),
              const SizedBox(width: 4),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? const Color(0xFFFF4D8D) : const Color(0xFF9CA3AF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 2,
            color: isSelected ? const Color(0xFFFF4D8D) : Colors.transparent,
          ),
        ],
      ),
    );
  }

  Widget _buildColorCircle(Color color, DrawingController controller, dynamic state, {bool hasBorder = false}) {
    final isSelected = state.selectedColor == color;
    return GestureDetector(
      onTap: () => controller.setColor(color),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: isSelected 
            ? Border.all(color: Colors.white, width: 3) 
            : (hasBorder ? Border.all(color: const Color(0xFFE5E7EB), width: 1) : null),
          boxShadow: isSelected ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 10)] : [],
        ),
      ),
    );
  }

  Widget _buildSmallTool(IconData icon, Color bgColor, {Color iconColor = Colors.white}) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: iconColor, size: 18),
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
