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

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final GlobalKey<DrawingCanvasState> _canvasKey = GlobalKey();
  final WidgetService _widgetService = WidgetService();

  Future<void> _pickImage(DrawingController controller) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      if (mounted) {
        controller.setBackgroundImage(File(pickedFile.path));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final drawingState = ref.watch(drawingControllerProvider);
    final controller = ref.read(drawingControllerProvider.notifier);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Stack(
        children: [
           // Blobs
           Positioned(
             top: -50, left: -50,
             child: Container(
               width: 200, height: 200,
               decoration: BoxDecoration(
                 color: AppColors.primary.withOpacity(0.05),
                 borderRadius: BorderRadius.circular(100),
                 boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.05), blurRadius: 40, spreadRadius: 10)]
               ),
             )
           ),
           Positioned(
             bottom: 100, right: -50,
             child: Container(
               width: 150, height: 150,
               decoration: BoxDecoration(
                 color: AppColors.secondary.withOpacity(0.05),
                 borderRadius: BorderRadius.circular(100),
                 boxShadow: [BoxShadow(color: AppColors.secondary.withOpacity(0.05), blurRadius: 40, spreadRadius: 10)]
               ),
             )
           ),

          SafeArea(
            child: Column(
              children: [
                // 1. Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Menu
                      IconButton(
                        icon: const Icon(Icons.grid_view_rounded, color: AppColors.textGrey),
                        onPressed: () => context.push('/menu'),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.all(12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                          shadowColor: Colors.black.withOpacity(0.05),
                        ),
                      ),
                      
                      // Title
                      Column(
                        children: [
                          Text(
                            'EntreNós',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textLight,
                            ),
                          ),
                          Row(
                            children: [
                              Container(
                                width: 6, height: 6,
                                decoration: const BoxDecoration(
                                  color: AppColors.success,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Online',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: AppColors.textGrey,
                                  fontWeight: FontWeight.w500,
                                ),
                              )
                            ],
                          )
                        ],
                      ),

                      // History
                      IconButton(
                        icon: const Icon(Icons.history_rounded, color: AppColors.textGrey),
                        onPressed: () => context.push('/history'),
                         style: IconButton.styleFrom(
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.all(12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                          shadowColor: Colors.black.withOpacity(0.05),
                        ),
                      ),

                      // Premium
                      IconButton(
                        icon: const Icon(Icons.workspace_premium_rounded, color: AppColors.primary),
                        onPressed: () => context.push('/premium'),
                         style: IconButton.styleFrom(
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.all(12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                          shadowColor: Colors.black.withOpacity(0.05),
                        ),
                      ),
                    ],
                  ),
                ),

                // 2. Canvas Area
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.08),
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(32),
                        child: Stack(
                          children: [
                            // Canvas
                            DrawingCanvas(key: _canvasKey),
                            
                            // Floating Actions (Undo/Clear)
                            Positioned(
                              top: 20,
                              right: 20,
                              child: Row(
                                children: [
                                  _buildCanvasAction(
                                    icon: Icons.undo_rounded,
                                    onTap: () => controller.undo(),
                                  ),
                                  const SizedBox(width: 12),
                                  _buildCanvasAction(
                                    icon: Icons.delete_outline_rounded,
                                    color: Colors.redAccent,
                                    onTap: () => controller.clearCanvas(),
                                  ),
                                ],
                              ),
                            ),
                            
                             // Background Image Indicator
                             if (drawingState.backgroundImage != null)
                              Positioned(
                                top: 20,
                                left: 20,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.6),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.image, color: Colors.white, size: 14),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Imagem de fundo',
                                        style: GoogleFonts.plusJakartaSans(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                       const SizedBox(width: 8),
                                       GestureDetector(
                                          onTap: () => controller.setBackgroundImage(null),
                                          child: const Icon(Icons.close, color: Colors.white, size: 14)
                                       )
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // 3. Tools
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                       // Color Picker
                       SizedBox(
                         height: 50,
                         child: ListView(
                           scrollDirection: Axis.horizontal,
                           children: [
                             _buildColorOption(Colors.black, controller, drawingState),
                             _buildColorOption(AppColors.primary, controller, drawingState),
                             _buildColorOption(const Color(0xFFFFB3C6), controller, drawingState), // pink-light
                             _buildColorOption(const Color(0xFF6B4EFF), controller, drawingState), // purple
                             _buildColorOption(const Color(0xFF00C9A7), controller, drawingState), // teal
                             _buildColorOption(const Color(0xFFFFD166), controller, drawingState), // yellow
                             _buildColorOption(const Color(0xFFEF476F), controller, drawingState), // red
                           ],
                         ),
                       ),
                       
                       const SizedBox(height: 24),
                       
                       // Bottom Actions
                       Row(
                         children: [
                           // Image Picker
                           _buildToolButton(
                             icon: Icons.image_outlined,
                             onTap: () => _pickImage(controller),
                           ),
                           const SizedBox(width: 16),
                           
                           // Stroke Size (Mock)
                           Expanded(
                             child: Container(
                               height: 56,
                               decoration: BoxDecoration(
                                 color: AppColors.backgroundLight,
                                 borderRadius: BorderRadius.circular(16),
                               ),
                               padding: const EdgeInsets.symmetric(horizontal: 16),
                               child: Row(
                                 children: [
                                   const Icon(Icons.brush, color: AppColors.textGrey, size: 20),
                                   Expanded(
                                     child: SliderTheme(
                                       data: SliderTheme.of(context).copyWith(
                                         activeTrackColor: AppColors.textLight,
                                         inactiveTrackColor: Colors.grey[300],
                                         thumbColor: AppColors.textLight,
                                         overlayColor: AppColors.textLight.withOpacity(0.1),
                                         trackHeight: 2,
                                         thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                       ),
                                       child: Slider(
                                         value: drawingState.selectedStrokeWidth,
                                         min: 2,
                                         max: 20,
                                         onChanged: (val) => controller.setStrokeWidth(val),
                                       ),
                                     ),
                                   ),
                                    Container(
                                      width: 24,
                                      height: 24, 
                                      alignment: Alignment.center,
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Container(
                                        width: drawingState.selectedStrokeWidth.clamp(2.0, 20.0),
                                        height: drawingState.selectedStrokeWidth.clamp(2.0, 20.0),
                                        decoration: BoxDecoration(
                                          color: drawingState.selectedColor,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    )
                                 ],
                               ),
                             ),
                           ),
                           
                           const SizedBox(width: 16),
                           
                           // Send Button
                           GestureDetector(
                             onTap: () async {
                              final bytes = await _canvasKey.currentState?.capturePng();
                              if (bytes != null) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Enviando carinho... ✨'),
                                      backgroundColor: AppColors.primary,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                  
                                  // Save locally
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

                                  await Future.delayed(const Duration(seconds: 1));
                                  
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text('Enviado com sucesso! 🚀'),
                                        backgroundColor: AppColors.success,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                    );
                                  }
                                }
                              }
                            },
                             child: Container(
                               width: 56,
                               height: 56,
                               decoration: BoxDecoration(
                                 color: AppColors.primary,
                                 borderRadius: BorderRadius.circular(16),
                                 boxShadow: [
                                   BoxShadow(
                                     color: AppColors.primary.withOpacity(0.4),
                                     blurRadius: 15,
                                     offset: const Offset(0, 8),
                                   ),
                                 ],
                               ),
                               child: const Icon(Icons.send_rounded, color: Colors.white),
                             ),
                           ),
                         ],
                       ),
                       const SizedBox(height: 16), // Bottom safety margin
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

  Widget _buildCanvasAction({required IconData icon, Color? color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: color ?? AppColors.textGrey, size: 20),
      ),
    );
  }
  
  Widget _buildToolButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(icon, color: AppColors.textGrey),
      ),
    );
  }

  Widget _buildColorOption(Color color, DrawingController controller, dynamic state) {
    final isSelected = state.selectedColor == color;
    return GestureDetector(
      onTap: () => controller.setColor(color),
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: isSelected ? Border.all(color: Colors.white, width: 3) : Border.all(color: Colors.grey.withOpacity(0.1), width: 1),
          boxShadow: isSelected ? [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 10,
              spreadRadius: 2,
            )
          ] : [],
        ),
        child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
      ),
    );
  }
}
