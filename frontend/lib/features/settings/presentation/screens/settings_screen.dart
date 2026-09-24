import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vertice/core/constants/app_colors.dart';
import 'package:vertice/core/localization/app_localizations.dart';
import 'package:vertice/core/providers/settings_provider.dart';
import 'package:vertice/features/auth/presentation/screens/auth_screen.dart';
import 'package:vertice/features/auth/services/auth_service.dart';
import 'package:vertice/features/map/services/map_cache_service.dart';
import 'package:vertice/features/settings/presentation/screens/admin_panel_screen.dart';

/// Pantalla de Ajustes y Perfil de Usuario — Estilo Táctico / Cyberpunk.
class SettingsScreen extends StatefulWidget {
  final UserProfile? userProfile;
  final ValueNotifier<bool> gpsEnabledNotifier;
  final VoidCallback onProfileUpdated;

  const SettingsScreen({
    super.key,
    required this.userProfile,
    required this.gpsEnabledNotifier,
    required this.onProfileUpdated,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _authService = AuthService();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _passwordFormKey = GlobalKey<FormState>();

  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isUpdatingPassword = false;
  bool _isSigningOut = false;
  bool _isUploadingAvatar = false;
  String? _localAvatarUrl;

  // Estado para gestión de caché offline de mapas
  bool _isPrecaching = false;
  int _precacheCurrent = 0;
  int _precacheTotal = 0;
  bool _isClearingCache = false;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool get _passwordsMatch =>
      _newPasswordController.text.isNotEmpty &&
      _newPasswordController.text == _confirmPasswordController.text &&
      _newPasswordController.text.length >= 8;

  Future<void> _handleUpdatePassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;
    if (!_passwordsMatch) return;

    setState(() => _isUpdatingPassword = true);
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: _newPasswordController.text),
      );
      if (!mounted) return;
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      _showSnack(
        '✅ Clave de acceso actualizada correctamente.',
        AppColors.success,
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      _showSnack('⚠️ ${e.message}', AppColors.error);
    } catch (e) {
      if (!mounted) return;
      _showSnack('⚠️ Error al actualizar la clave: $e', AppColors.error);
    } finally {
      if (mounted) setState(() => _isUpdatingPassword = false);
    }
  }

  Future<void> _handlePrecacheMap() async {
    setState(() {
      _isPrecaching = true;
      _precacheCurrent = 0;
      _precacheTotal = 0;
    });

    try {
      await MapCacheService.instance.precacheElSalvador(
        onProgress: (current, total) {
          if (mounted) {
            setState(() {
              _precacheCurrent = current;
              _precacheTotal = total;
            });
          }
        },
      );
      if (!mounted) return;
      _showSnack('✅ ${context.loc.precacheSuccess}', AppColors.success);
    } catch (e) {
      if (!mounted) return;
      _showSnack('⚠️ Error: $e', AppColors.error);
    } finally {
      if (mounted) {
        setState(() => _isPrecaching = false);
      }
    }
  }

  Future<void> _handleClearCache() async {
    setState(() => _isClearingCache = true);
    try {
      await MapCacheService.instance.clearCache();
      if (!mounted) return;
      _showSnack('🗑️ ${context.loc.cacheCleared}', AppColors.cyan);
    } catch (e) {
      if (!mounted) return;
      _showSnack('⚠️ Error: $e', AppColors.error);
    } finally {
      if (mounted) {
        setState(() => _isClearingCache = false);
      }
    }
  }

  Future<void> _handleSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.surfaceBorder),
        ),
        title: const Row(
          children: [
            Icon(Icons.power_settings_new_rounded, color: Colors.redAccent, size: 20),
            SizedBox(width: 8),
            Text(
              'DESCONECTAR ENLACE',
              style: TextStyle(
                color: Colors.redAccent,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        content: const Text(
          '¿Deseas cerrar la sesión táctica actual?',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('CANCELAR', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent.withValues(alpha: 0.85),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('CERRAR SESIÓN'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    setState(() => _isSigningOut = true);
    await _authService.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthScreen()),
      (route) => false,
    );
  }

  void _showSnack(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.surfaceElevated,
        content: Text(message, style: TextStyle(color: color)),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showAvatarOptionsSheet() {
    final avatarUrl = _localAvatarUrl ?? widget.userProfile?.avatarUrl;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: AppColors.surfaceBorder),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textMuted,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'FOTO DE PERFIL DE OPERADOR',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 18),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.cyan.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.photo_camera_rounded, color: AppColors.cyan),
                ),
                title: const Text('Tomar foto con la cámara', style: TextStyle(color: AppColors.textPrimary)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndUploadAvatar(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.cyan.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: AppColors.cyan),
                ),
                title: const Text('Elegir de la galería', style: TextStyle(color: AppColors.textPrimary)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndUploadAvatar(ImageSource.gallery);
                },
              ),
              if (avatarUrl != null && avatarUrl.isNotEmpty) ...[
                const Divider(color: AppColors.surfaceBorder, height: 16),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                  ),
                  title: const Text('Eliminar foto actual', style: TextStyle(color: AppColors.error)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _removeAvatar();
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickAndUploadAvatar(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (picked == null) return;

      setState(() => _isUploadingAvatar = true);

      final bytes = await picked.readAsBytes();
      final rawExt = picked.name.split('.').last.toLowerCase();
      String validExt = 'jpeg';
      String mimeType = 'image/jpeg';

      if (rawExt == 'png') {
        validExt = 'png';
        mimeType = 'image/png';
      } else if (rawExt == 'webp') {
        validExt = 'webp';
        mimeType = 'image/webp';
      } else if (rawExt == 'gif') {
        validExt = 'gif';
        mimeType = 'image/gif';
      } else {
        // En los estándares MIME y en el bucket de Supabase, JPG es image/jpeg
        validExt = 'jpeg';
        mimeType = 'image/jpeg';
      }

      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('No hay sesión de usuario activa');

      // Carpeta por usuario {user.id}/{timestamp}.{ext}
      // Permite que las políticas RLS de Supabase verifiquen que (storage.foldername(name))[1] == auth.uid()
      final fileName = '${user.id}/${DateTime.now().millisecondsSinceEpoch}.$validExt';

      await Supabase.instance.client.storage.from('avatars').uploadBinary(
        fileName,
        bytes,
        fileOptions: FileOptions(
          contentType: mimeType,
          upsert: true,
        ),
      );

      final publicUrl = Supabase.instance.client.storage.from('avatars').getPublicUrl(fileName);

      await _authService.updateProfile(avatarUrl: publicUrl);
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(data: {'avatar_url': publicUrl}),
      );

      if (!mounted) return;

      setState(() {
        _localAvatarUrl = publicUrl;
        _isUploadingAvatar = false;
      });

      widget.onProfileUpdated();
      _showSnack('✅ Foto de perfil actualizada con éxito.', AppColors.success);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploadingAvatar = false);
      _showSnack('⚠️ Error al subir foto: $e', AppColors.error);
    }
  }

  Future<void> _removeAvatar() async {
    setState(() => _isUploadingAvatar = true);
    try {
      await _authService.updateProfile(avatarUrl: '');
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(data: {'avatar_url': null}),
      );

      if (!mounted) return;

      setState(() {
        _localAvatarUrl = '';
        _isUploadingAvatar = false;
      });

      widget.onProfileUpdated();
      _showSnack('Foto de perfil eliminada.', AppColors.cyan);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploadingAvatar = false);
      _showSnack('⚠️ Error al eliminar foto: $e', AppColors.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.userProfile;
    final String? avatarUrl = _localAvatarUrl ?? profile?.avatarUrl;
    final String displayName = profile?.fullName ?? profile?.username ?? 'AGENTE';
    final String username = profile?.username ?? '—';
    final String email = profile?.email ??
        Supabase.instance.client.auth.currentUser?.email ?? '—';
    final String birthdate = profile?.birthdate != null
        ? '${profile!.birthdate!.year}-${profile.birthdate!.month.toString().padLeft(2, '0')}-${profile.birthdate!.day.toString().padLeft(2, '0')}'
        : '—';

    String initials = '?';
    if (displayName.isNotEmpty && displayName != 'AGENTE') {
      final parts = displayName.trim().split(' ');
      if (parts.length >= 2) {
        initials = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      } else {
        initials = displayName.substring(0, displayName.length.clamp(1, 2)).toUpperCase();
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.turquoise, width: 1.2),
              ),
              child: ClipOval(
                child: Image.asset('assets/images/logo.png', fit: BoxFit.cover),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'GEOTURISMO // AJUSTES',
              style: TextStyle(
                color: AppColors.turquoise,
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: AppColors.turquoise.withValues(alpha: 0.2),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: [
          // ─── ENCABEZADO DE PERFIL ───────────────────────────────────
          Center(
            child: Column(
              children: [
                // Avatar grande con selector interactivo
                GestureDetector(
                  onTap: _isUploadingAvatar ? null : _showAvatarOptionsSheet,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.cyan, width: 2.5),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.cyan.withValues(alpha: 0.35),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: _isUploadingAvatar
                              ? Container(
                                  color: AppColors.surfaceElevated,
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.cyan),
                                    ),
                                  ),
                                )
                              : (avatarUrl != null && avatarUrl.isNotEmpty
                                  ? Image.network(
                                      avatarUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) => _buildLargeInitialsAvatar(initials),
                                    )
                                  : _buildLargeInitialsAvatar(initials)),
                        ),
                      ),
                      // Botón circular de cámara táctico
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF001520),
                            border: Border.all(color: AppColors.cyan, width: 1.5),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x7700F0FF),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.photo_camera_rounded,
                            color: AppColors.cyan,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  displayName.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '@$username',
                  style: const TextStyle(
                    color: AppColors.cyan,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.cyan.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.cyan.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    '[${(profile?.role ?? 'USER').toUpperCase()}]',
                    style: const TextStyle(
                      color: AppColors.cyan,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),
          _buildIlluminatedHeader('IDENTIDAD DEL OPERADOR', Icons.badge_outlined),

          // ─── DATOS DEL PERFIL (Solo Lectura) ───────────────────────
          _buildReadOnlyField(
            icon: Icons.badge_outlined,
            label: 'Nombre Completo',
            value: profile?.fullName ?? '—',
          ),
          const SizedBox(height: 10),
          _buildReadOnlyField(
            icon: Icons.alternate_email_rounded,
            label: 'Nombre de Usuario',
            value: '@$username',
          ),
          const SizedBox(height: 10),
          _buildReadOnlyField(
            icon: Icons.mail_outline_rounded,
            label: 'Correo Electrónico',
            value: email,
          ),
          const SizedBox(height: 10),
          _buildReadOnlyField(
            icon: Icons.calendar_today_rounded,
            label: 'Fecha de Nacimiento',
            value: birthdate,
          ),

          // ─── PANEL DE CONTROL ADMINISTRATIVO (SOLO ADMIN) ───────────
          if (profile?.isAdmin ?? false) ...[
            const SizedBox(height: 28),
            _buildIlluminatedHeader('CONSOLA DE COMANDO ADMIN', Icons.admin_panel_settings_rounded),
            _buildAdminPanelCard(context),
          ],

          const SizedBox(height: 28),
          _buildIlluminatedHeader('SEGURIDAD Y CREDENCIALES', Icons.lock_outline_rounded),

          // ─── CAMBIO DE CONTRASEÑA ───────────────────────────────────
          Form(
            key: _passwordFormKey,
            child: Column(
              children: [
                _buildPasswordField(
                  controller: _newPasswordController,
                  label: 'Nueva Clave',
                  hint: 'Mínimo 8 caracteres',
                  obscure: _obscureNew,
                  onToggleObscure: () => setState(() => _obscureNew = !_obscureNew),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Ingresa la nueva clave';
                    if (val.length < 8) return 'Mínimo 8 caracteres';
                    return null;
                  },
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 10),
                _buildPasswordField(
                  controller: _confirmPasswordController,
                  label: 'Confirmar Clave',
                  hint: 'Repite la nueva clave',
                  obscure: _obscureConfirm,
                  onToggleObscure: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Confirma la clave';
                    if (val != _newPasswordController.text) return 'Las claves no coinciden';
                    return null;
                  },
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: AnimatedOpacity(
                    opacity: _passwordsMatch ? 1.0 : 0.45,
                    duration: const Duration(milliseconds: 200),
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.cyan.withValues(alpha: 0.15),
                        foregroundColor: AppColors.cyan,
                        disabledBackgroundColor: AppColors.surfaceElevated,
                        disabledForegroundColor: AppColors.textMuted,
                        side: BorderSide(
                          color: _passwordsMatch
                              ? AppColors.cyan.withValues(alpha: 0.7)
                              : AppColors.surfaceBorder,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: _isUpdatingPassword
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(AppColors.cyan),
                              ),
                            )
                          : const Icon(Icons.lock_reset_rounded, size: 18),
                      label: Text(
                        'ACTUALIZAR CLAVE',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                          color: _passwordsMatch ? AppColors.cyan : AppColors.textMuted,
                        ),
                      ),
                      onPressed: _passwordsMatch && !_isUpdatingPassword
                          ? _handleUpdatePassword
                          : null,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),
          _buildIlluminatedHeader(context.loc.systemPreferences, Icons.tune_rounded),

          // ─── SELECTOR DE MODO VISUAL (TEMA) CON PREVISUALIZACIÓN VIVA ─
          ListenableBuilder(
            listenable: SettingsProvider.instance,
            builder: (context, _) {
              final currentMode = SettingsProvider.instance.themeMode;
              return _buildPreferenceCard(
                title: context.loc.themeMode,
                icon: Icons.palette_outlined,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildThemeOption(
                            label: context.loc.themeDark,
                            icon: Icons.dark_mode_rounded,
                            isSelected: currentMode == ThemeMode.dark,
                            onTap: () => SettingsProvider.instance.setThemeMode(ThemeMode.dark),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildThemeOption(
                            label: context.loc.themeLight,
                            icon: Icons.light_mode_rounded,
                            isSelected: currentMode == ThemeMode.light,
                            onTap: () => SettingsProvider.instance.setThemeMode(ThemeMode.light),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildThemeOption(
                            label: context.loc.themeSystem,
                            icon: Icons.settings_brightness_rounded,
                            isSelected: currentMode == ThemeMode.system,
                            onTap: () => SettingsProvider.instance.setThemeMode(ThemeMode.system),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Tarjeta interactiva de previsualización de tema
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: currentMode == ThemeMode.light
                            ? const Color(0xFFF0F4F8)
                            : const Color(0xFF040810),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.cyan.withValues(alpha: 0.4),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            currentMode == ThemeMode.light
                                ? Icons.wb_sunny_rounded
                                : Icons.nightlight_round,
                            color: currentMode == ThemeMode.light
                                ? Colors.orange
                                : AppColors.cyan,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'PREVISUALIZACIÓN: ${currentMode == ThemeMode.dark ? "MODO OSCURO CYBERPUNK" : (currentMode == ThemeMode.light ? "MODO CLARO ALTO CONTRASTE" : "SISTEMA OPERATIVO")} ACTIVO',
                              style: TextStyle(
                                color: currentMode == ThemeMode.light
                                    ? Colors.black87
                                    : AppColors.cyan,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'monospace',
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 12),

          // ─── SELECTOR DE ESCALA DE FUENTE CON PREVISUALIZACIÓN VIVA ─
          ListenableBuilder(
            listenable: SettingsProvider.instance,
            builder: (context, _) {
              final currentScale = SettingsProvider.instance.textScaleFactor;
              return _buildPreferenceCard(
                title: context.loc.fontScale,
                icon: Icons.format_size_rounded,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildScaleOption(
                            label: context.loc.fontSmall,
                            scaleValue: 0.85,
                            isSelected: (currentScale - 0.85).abs() < 0.05,
                            onTap: () => SettingsProvider.instance.setTextScaleFactor(0.85),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildScaleOption(
                            label: context.loc.fontNormal,
                            scaleValue: 1.0,
                            isSelected: (currentScale - 1.0).abs() < 0.05,
                            onTap: () => SettingsProvider.instance.setTextScaleFactor(1.0),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildScaleOption(
                            label: context.loc.fontLarge,
                            scaleValue: 1.25,
                            isSelected: (currentScale - 1.25).abs() < 0.05,
                            onTap: () => SettingsProvider.instance.setTextScaleFactor(1.25),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Tarjeta interactiva con escala tipográfica en tiempo real
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.cyan.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.text_fields_rounded, color: AppColors.cyan, size: 14),
                              SizedBox(width: 6),
                              Text(
                                'TELEMETRÍA EN VIVO (ESCALA ACTIVA)',
                                style: TextStyle(
                                  color: AppColors.cyan,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'VÉRTICE SV: LAT 13.7942° N | LON 88.8965° W',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: (11.5 * currentScale).clamp(8.0, 18.0),
                              fontWeight: FontWeight.w600,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 12),

          // ─── SELECTOR DE IDIOMA (i18n) CON PREVISUALIZACIÓN VIVA ───
          ListenableBuilder(
            listenable: SettingsProvider.instance,
            builder: (context, _) {
              final currentLang = SettingsProvider.instance.locale.languageCode;
              return _buildPreferenceCard(
                title: context.loc.language,
                icon: Icons.translate_rounded,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildLangOption(
                            label: 'Español (ES)',
                            code: 'es',
                            isSelected: currentLang == 'es',
                            onTap: () => SettingsProvider.instance.setLocale(const Locale('es')),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildLangOption(
                            label: 'English (US)',
                            code: 'en',
                            isSelected: currentLang == 'en',
                            onTap: () => SettingsProvider.instance.setLocale(const Locale('en')),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Tarjeta interactiva con traducción en vivo
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.cyan.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.language_rounded, color: AppColors.cyan, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              currentLang == 'es'
                                  ? 'RED VÉRTICE // SISTEMA TÁCTICO EL SALVADOR ONLINE'
                                  : 'GEOTURISMO NETWORK // EL SALVADOR TACTICAL SYSTEM ONLINE',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'monospace',
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 12),

          // ─── TOGGLE GPS ─────────────────────────────────────────────
          ValueListenableBuilder<bool>(
            valueListenable: widget.gpsEnabledNotifier,
            builder: (context, gpsEnabled, _) {
              return _buildPreferenceToggle(
                icon: Icons.gps_fixed_rounded,
                title: context.loc.gpsTracking,
                subtitle: gpsEnabled
                    ? context.loc.gpsTrackingActive
                    : context.loc.gpsTrackingInactive,
                value: gpsEnabled,
                onChanged: (val) {
                  widget.gpsEnabledNotifier.value = val;
                },
              );
            },
          ),

          const SizedBox(height: 28),
          _buildIlluminatedHeader('CARTOGRAFÍA Y ALMACENAMIENTO', Icons.map_rounded),

          // ─── CACHÉ OFFLINE DE MAPAS (FLUTTER_MAP) ───────────────────
          _buildMapCacheCard(),

          const SizedBox(height: 28),
          _buildIlluminatedHeader('TERMINACIÓN DE SESIÓN', Icons.power_settings_new_rounded),

          // ─── CERRAR SESIÓN ──────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent.withValues(alpha: 0.1),
                foregroundColor: Colors.redAccent,
                side: BorderSide(
                  color: Colors.redAccent.withValues(alpha: 0.5),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: _isSigningOut
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.redAccent),
                      ),
                    )
                  : const Icon(Icons.logout_rounded, size: 18),
              label: const Text(
                'CERRAR SESIÓN TÁCTICA',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
              onPressed: _isSigningOut ? null : _handleSignOut,
            ),
          ),
          const SizedBox(height: 12),
          const Center(
            child: Text(
              'SISTEMA DE CARTOGRAFÍA // SV-2026',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 9,
                letterSpacing: 2,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildLargeInitialsAvatar(String initials) {
    return Container(
      color: AppColors.surfaceElevated,
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(
          color: AppColors.cyan,
          fontSize: 30,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildIlluminatedHeader(String title, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.cyan.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cyan.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.cyan.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.cyan.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: AppColors.cyan, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title.toUpperCase(),
              style: const TextStyle(
                color: AppColors.cyan,
                fontSize: 10.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.6,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyField({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.cyanDim, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 9,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.lock_outline_rounded, color: AppColors.textMuted, size: 14),
        ],
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool obscure,
    required VoidCallback onToggleObscure,
    required String? Function(String?) validator,
    ValueChanged<String>? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
      onChanged: onChanged,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
        filled: true,
        fillColor: AppColors.surfaceElevated,
        prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.cyanDim, size: 18),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: AppColors.textMuted,
            size: 18,
          ),
          onPressed: onToggleObscure,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.surfaceBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.surfaceBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.cyan, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        errorStyle: const TextStyle(color: AppColors.error, fontSize: 11),
      ),
    );
  }

  Widget _buildPreferenceToggle({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: value
              ? AppColors.cyan.withValues(alpha: 0.35)
              : AppColors.surfaceBorder,
        ),
      ),
      child: Row(
        children: [
          Icon(icon,
              color: value ? AppColors.cyan : AppColors.textMuted, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: value ? AppColors.textPrimary : AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: value ? AppColors.cyanDim : AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.cyan,
            activeTrackColor: AppColors.cyan.withValues(alpha: 0.25),
            inactiveThumbColor: AppColors.textMuted,
            inactiveTrackColor: AppColors.surfaceBorder,
          ),
        ],
      ),
    );
  }

  Widget _buildPreferenceCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.cyan, size: 16),
              const SizedBox(width: 8),
              Text(
                title.toUpperCase(),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _buildThemeOption({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.cyan.withValues(alpha: 0.18)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.cyan : AppColors.surfaceBorderSubtle,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? AppColors.cyan : AppColors.textMuted,
            ),
            const SizedBox(height: 5),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected ? AppColors.cyan : AppColors.textSecondary,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScaleOption({
    required String label,
    required double scaleValue,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.cyan.withValues(alpha: 0.18)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.cyan : AppColors.surfaceBorderSubtle,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Aa',
              style: TextStyle(
                fontSize: 12 * scaleValue,
                fontWeight: FontWeight.bold,
                color: isSelected ? AppColors.cyan : AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected ? AppColors.cyan : AppColors.textSecondary,
                fontSize: 9.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLangOption({
    required String label,
    required String code,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.cyan.withValues(alpha: 0.18)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.cyan : AppColors.surfaceBorderSubtle,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? AppColors.cyan : AppColors.textSecondary,
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMapCacheCard() {
    final progressRatio = _precacheTotal > 0 ? (_precacheCurrent / _precacheTotal) : 0.0;
    final progressPercent = (progressRatio * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.cloud_download_outlined, color: AppColors.gold, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.loc.offlineMapCache,
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            context.loc.offlineMapDesc,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11.5,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),

          // Barra de progreso si está descargando
          if (_isPrecaching) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progressRatio.clamp(0.0, 1.0),
                backgroundColor: AppColors.surface,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.gold),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${context.loc.precacheProgress} $_precacheCurrent / $_precacheTotal',
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontSize: 10.5,
                    fontFamily: 'monospace',
                  ),
                ),
                Text(
                  '$progressPercent%',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.gold,
                    side: BorderSide(
                      color: _isPrecaching ? AppColors.surfaceBorder : AppColors.gold.withValues(alpha: 0.7),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: _isPrecaching
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.gold),
                          ),
                        )
                      : const Icon(Icons.download_for_offline_rounded, size: 16),
                  label: Text(
                    _isPrecaching ? context.loc.loading : context.loc.precacheTiles,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                  onPressed: _isPrecaching ? null : _handlePrecacheMap,
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: BorderSide(
                    color: _isClearingCache ? AppColors.surfaceBorder : AppColors.error.withValues(alpha: 0.6),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: _isClearingCache
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.error),
                        ),
                      )
                    : const Icon(Icons.delete_sweep_outlined, size: 16),
                label: Text(
                  context.loc.clearCache,
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                onPressed: (_isPrecaching || _isClearingCache) ? null : _handleClearCache,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Tarjeta de acceso al Panel de Control Administrativo (Exclusiva para rol Admin)
  Widget _buildAdminPanelCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.cyan.withValues(alpha: 0.6),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.cyan.withValues(alpha: 0.15),
            blurRadius: 16,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.cyan.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.cyan.withValues(alpha: 0.4)),
                ),
                child: const Icon(
                  Icons.admin_panel_settings_rounded,
                  color: AppColors.cyan,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'GESTIÓN DE OPERADORES',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'NIVEL DE ACCESO: ADMINISTRADOR',
                      style: TextStyle(
                        color: AppColors.cyan,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Audita la nómina de usuarios registrados en el sistema, consulta estados y suspende o reactiva accesos en tiempo real con efecto inmediato en la red táctica.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11.5,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cyan.withValues(alpha: 0.2),
                foregroundColor: AppColors.cyan,
                side: BorderSide(
                  color: AppColors.cyan.withValues(alpha: 0.8),
                  width: 1.2,
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.people_alt_rounded, size: 18),
              label: const Text(
                'ABRIR CONSOLA DE OPERADORES',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AdminPanelScreen(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
