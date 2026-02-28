import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/connection_provider.dart';

class ConnectScreen extends ConsumerStatefulWidget {
  const ConnectScreen({super.key});

  @override
  ConsumerState<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends ConsumerState<ConnectScreen> {
  final TextEditingController _codeController = TextEditingController();
  bool _isLoading = false;
  bool _codeCopied = false;
  String _myCode = '...';
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _ensureProfileExists();
  }

  /// Garante que o perfil existe no Supabase ANTES de mostrar o código
  /// Usa RPC ensure_profile (SECURITY DEFINER) para bypassar RLS
  Future<void> _ensureProfileExists() async {
    try {
      final client = Supabase.instance.client;
      var user = client.auth.currentUser;
      
      debugPrint('🔍 ConnectScreen: verificando perfil...');
      debugPrint('🔍 User autenticado: ${user?.id}');
      
      // ── PASSO 1: Garantir autenticação ──
      if (user == null) {
        debugPrint('❌ Usuário não autenticado! Criando conta anônima...');
        final authResponse = await client.auth.signInAnonymously();
        user = authResponse.user;
        debugPrint('✅ Conta anônima criada: ${user?.id}');
      }
      
      if (user == null) {
        debugPrint('❌ FATAL: Falha ao obter user após auth');
        if (mounted) setState(() { _myCode = 'ERRO'; _isInitializing = false; });
        return;
      }
      
      // ── PASSO 2: Obter nome do SharedPreferences ──
      final prefs = await SharedPreferences.getInstance();
      final name = prefs.getString('user_name') ?? 'Amor';
      final code = _generateCode();
      
      // ── PASSO 3: Usar RPC ensure_profile (SECURITY DEFINER) ──
      debugPrint('📝 Chamando RPC ensure_profile...');
      try {
        final result = await client.rpc('ensure_profile', params: {
          'p_display_name': name,
          'p_invite_code': code,
        });
        
        debugPrint('📝 RPC ensure_profile resultado: $result');
        
        if (result is Map && result['success'] == true) {
          final inviteCode = result['invite_code'] as String;
          debugPrint('✅ Perfil garantido via RPC! Código: $inviteCode (novo: ${result['is_new']})');
          if (mounted) setState(() { _myCode = inviteCode; _isInitializing = false; });
          return;
        } else {
          debugPrint('❌ RPC ensure_profile falhou: $result');
          // Cair para o fallback
        }
      } catch (rpcError) {
        debugPrint('❌ RPC ensure_profile exception: $rpcError');
        // Cair para o fallback
      }
      
      // ── PASSO 4: FALLBACK — upsert direto ──
      debugPrint('🔄 Fallback: tentando upsert direto...');
      try {
        // Primeiro verificar se já existe
        final existing = await client
            .from('profiles')
            .select()
            .eq('id', user.id)
            .maybeSingle();
        
        debugPrint('👤 Perfil existente (fallback): $existing');
        
        if (existing != null && existing['invite_code'] != null) {
          final existingCode = existing['invite_code'] as String;
          debugPrint('✅ Perfil já existe! Código: $existingCode');
          if (mounted) setState(() { _myCode = existingCode; _isInitializing = false; });
          return;
        }
        
        // Criar perfil
        await client.from('profiles').upsert({
          'id': user.id,
          'display_name': name,
          'invite_code': code,
          'updated_at': DateTime.now().toIso8601String(),
        });
        
        debugPrint('✅ Perfil criado via upsert direto! Código: $code');
        
        // Verificar se realmente salvou
        final verify = await client
            .from('profiles')
            .select('invite_code')
            .eq('id', user.id)
            .maybeSingle();
        
        if (verify != null && verify['invite_code'] != null) {
          final savedCode = verify['invite_code'] as String;
          debugPrint('✅ Verificação OK! Código salvo: $savedCode');
          if (mounted) setState(() { _myCode = savedCode; _isInitializing = false; });
        } else {
          debugPrint('❌ Verificação FALHOU — perfil não persistiu!');
          if (mounted) setState(() { _myCode = code; _isInitializing = false; });
        }
      } catch (fallbackError) {
        debugPrint('❌ Fallback upsert error: $fallbackError');
        if (mounted) setState(() { _myCode = code; _isInitializing = false; });
      }
      
    } catch (e, stackTrace) {
      debugPrint('❌ ERRO FATAL ao garantir perfil: $e');
      debugPrint('📋 Stack: $stackTrace');
      if (mounted) {
        setState(() { 
          _myCode = _generateCode(); 
          _isInitializing = false; 
        });
      }
    }
  }

  String _generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = DateTime.now().microsecondsSinceEpoch;
    return String.fromCharCodes(
      List.generate(6, (i) => chars.codeUnitAt((random + i * 37) % chars.length)),
    );
  }

  Future<void> _connect() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      _showCustomSnackBar('Insira o código do seu amor! 💕');
      return;
    }

    setState(() => _isLoading = true);

    try {
      debugPrint('🔗 Tentando conectar com código: $code');
      
      // Primeiro tentar via RPC function (mais seguro)
      final client = Supabase.instance.client;
      
      try {
        final result = await client.rpc('connect_partners', params: {
          'p_partner_code': code,
        });
        
        debugPrint('🔗 RPC resultado: $result');
        
        if (result is Map && result['success'] == true) {
          debugPrint('✅ Conectados via RPC!');
          await _onConnectionSuccess(code);
          return;
        } else {
          final error = result is Map ? result['error'] : 'Desconhecido';
          debugPrint('❌ RPC falhou: $error');
          
          if (mounted) {
            setState(() => _isLoading = false);
            _showCustomSnackBar('Código não encontrado. Verifique com seu amor! 💔');
          }
          return;
        }
      } catch (e) {
        debugPrint('❌ RPC exception: $e — tentando método direto');
        
        // Fallback: tentar busca direta
        final partner = await client
            .from('profiles')
            .select()
            .eq('invite_code', code)
            .maybeSingle();
        
        debugPrint('🔍 Busca direta resultado: $partner');
        
        if (partner != null) {
          final partnerId = partner['id'] as String;
          final myId = client.auth.currentUser?.id;
          
          if (partnerId == myId) {
            if (mounted) {
              setState(() => _isLoading = false);
              _showCustomSnackBar('Esse é o seu próprio código! 😅');
            }
            return;
          }
          
          // Conectar manualmente
          await client.from('profiles').update({
            'partner_id': partnerId,
            'updated_at': DateTime.now().toIso8601String(),
          }).eq('id', myId!);
          
          await client.from('profiles').update({
            'partner_id': myId,
            'updated_at': DateTime.now().toIso8601String(),
          }).eq('id', partnerId);
          
          debugPrint('✅ Conectados via método direto!');
          await _onConnectionSuccess(code);
          return;
        } else {
          if (mounted) {
            setState(() => _isLoading = false);
            _showCustomSnackBar('Código não encontrado. Verifique com seu amor! 💔');
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Erro geral na conexão: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        _showCustomSnackBar('Erro ao conectar. Tente novamente.');
      }
    }
  }

  Future<void> _onConnectionSuccess(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_connected', true);
    await prefs.setString('partner_code', code);
    
    if (mounted) {
      setState(() => _isLoading = false);
      _showSuccessDialog();
    }
  }

  void _copyCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    setState(() => _codeCopied = true);
    _showCustomSnackBar('Código copiado! Envie para o seu amor 💕');
    
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _codeCopied = false);
    });
  }

  void _showCustomSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.9),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            message, 
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white, 
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Theme.of(ctx).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.favorite_rounded, color: AppColors.primary, size: 56),
              ),
              const SizedBox(height: 24),
              Text(
                'Conectados! ❤️',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Agora vocês podem trocar carinhos diretamente no widget!',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  color: Colors.grey,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.go('/home');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                  ),
                  child: Text(
                    'Começar ✨', 
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.bold, 
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFFDFCFD),
      body: Stack(
        children: [
          // Background Glows
          Positioned(
            top: -50, left: -50,
            child: Container(
              width: 300, height: 300,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: 100, right: -100,
            child: Container(
              width: 400, height: 400,
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.arrow_back_ios_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  Text(
                    'Convide seu Amor',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Vocês precisam estar conectados para que as mensagens apareçam no widget.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      color: Colors.grey,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 48),

                  // My Code Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                    decoration: BoxDecoration(
                      color: isDark 
                          ? Colors.white.withOpacity(0.05) 
                          : Colors.white.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.2),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'SEU CÓDIGO',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: Colors.grey,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _isInitializing
                            ? const SizedBox(
                                width: 24, height: 24,
                                child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
                              )
                            : Text(
                                _myCode,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 42,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.primary,
                                  letterSpacing: 10,
                                ),
                              ),
                        const SizedBox(height: 32),
                        if (!_isInitializing)
                          InkWell(
                            onTap: () => _copyCode(_myCode),
                            borderRadius: BorderRadius.circular(100),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(100),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.4),
                                    blurRadius: 15,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _codeCopied ? Icons.check_circle_rounded : Icons.copy_rounded,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _codeCopied ? 'Copiado!' : 'Copiar para o Amor',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Divider
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey.withOpacity(0.3))),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'OU INSIRA O DELE(A)',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.grey.withOpacity(0.5),
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.grey.withOpacity(0.3))),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // Input Field
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
                      border: Border.all(color: Colors.grey.withOpacity(0.1)),
                    ),
                    child: TextField(
                      controller: _codeController,
                      textCapitalization: TextCapitalization.characters,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 8,
                      ),
                      decoration: InputDecoration(
                        hintText: 'X X X X X X',
                        hintStyle: GoogleFonts.plusJakartaSans(
                          fontSize: 28,
                          fontWeight: FontWeight.w300,
                          letterSpacing: 8,
                          color: Colors.grey.withOpacity(0.3),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 24),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Connect Button
                  SizedBox(
                    width: double.infinity,
                    height: 64,
                    child: ElevatedButton(
                      onPressed: _isLoading || _isInitializing ? null : _connect,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? Colors.white : Colors.black,
                        foregroundColor: isDark ? Colors.black : Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24, height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              'Conectar Agora',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
