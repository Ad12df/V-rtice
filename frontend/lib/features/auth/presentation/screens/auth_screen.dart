import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vertice/core/constants/app_colors.dart';
import 'package:vertice/core/utils/responsive.dart';
import 'package:vertice/features/auth/presentation/widgets/custom_button.dart';
import 'package:vertice/features/auth/presentation/widgets/custom_text_field.dart';
import 'package:vertice/features/auth/presentation/widgets/password_strength_indicator.dart';
import 'package:vertice/features/auth/presentation/widgets/tactical_alert_dialog.dart';
import 'package:vertice/features/auth/services/auth_service.dart';
import 'package:vertice/features/map/presentation/screens/map_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  final _authService = AuthService();
  late TabController _tabController;
  final _loginFormKey = GlobalKey<FormState>();
  final _registerFormKey = GlobalKey<FormState>();

  // Controladores de Login
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  bool _loginObscurePassword = true;
  bool _isLoginLoading = false;
  bool _rememberSession = true;
  bool _loginAutoValidate = false;

  // Controladores de Registro
  final _registerNameController = TextEditingController();
  final _registerEmailController = TextEditingController();
  final _registerPasswordController = TextEditingController();
  final _registerConfirmPasswordController = TextEditingController();
  bool _registerObscurePassword = true;
  bool _registerObscureConfirmPassword = true;
  bool _isRegisterLoading = false;
  bool _registerAutoValidate = false;
  String _currentRegisterPassword = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _registerNameController.dispose();
    _registerEmailController.dispose();
    _registerPasswordController.dispose();
    _registerConfirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    setState(() => _loginAutoValidate = true);

    if (!_loginFormKey.currentState!.validate()) {
      TacticalAlert.show(
        context,
        title: 'CREDENCIALES INCOMPLETAS',
        message: 'Corrige los parámetros señalados antes de sincronizar enlace.',
        type: AlertType.warning,
      );
      return;
    }

    setState(() => _isLoginLoading = true);

    try {
      final email = _loginEmailController.text.trim();
      final password = _loginPasswordController.text;

      final response = await _authService.signInWithPassword(
        email: email,
        password: password,
      );

      if (!mounted) return;
      setState(() => _isLoginLoading = false);

      if (response.user != null) {
        TacticalAlert.show(
          context,
          title: 'SINCRONIZACIÓN EXITOSA',
          message: 'Protocolo de enlace verificado. Desplegando visor de cartografía...',
          type: AlertType.success,
        );

        await Future.delayed(const Duration(milliseconds: 500));
        if (!mounted) return;

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const MapScreen(isGuest: false),
          ),
        );
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _isLoginLoading = false);
      TacticalAlert.show(
        context,
        title: 'ERROR DE AUTENTICACIÓN',
        message: e.message,
        type: AlertType.error,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoginLoading = false);
      TacticalAlert.show(
        context,
        title: 'FALLA DE ENLACE',
        message: 'No se pudo conectar con el servidor: $e',
        type: AlertType.error,
      );
    }
  }

  Future<void> _handleRegister() async {
    setState(() => _registerAutoValidate = true);

    if (!_registerFormKey.currentState!.validate()) {
      TacticalAlert.show(
        context,
        title: 'REGISTRO INTERRUMPIDO',
        message: 'Verifica los campos del formulario de enlace.',
        type: AlertType.warning,
      );
      return;
    }

    setState(() => _isRegisterLoading = true);

    try {
      final name = _registerNameController.text.trim();
      final email = _registerEmailController.text.trim();
      final password = _registerPasswordController.text;

      final response = await _authService.signUp(
        email: email,
        password: password,
        displayName: name,
      );

      if (!mounted) return;
      setState(() => _isRegisterLoading = false);

      if (response.user != null) {
        TacticalAlert.show(
          context,
          title: 'AGENTE REGISTRADO',
          message: 'Identificador creado con éxito en Supabase. Iniciando sesión de exploración...',
          type: AlertType.success,
        );

        await Future.delayed(const Duration(milliseconds: 600));
        if (!mounted) return;

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const MapScreen(isGuest: false),
          ),
        );
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _isRegisterLoading = false);
      TacticalAlert.show(
        context,
        title: 'ERROR EN REGISTRO',
        message: e.message,
        type: AlertType.error,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isRegisterLoading = false);
      TacticalAlert.show(
        context,
        title: 'FALLA DE ENLACE',
        message: 'No se pudo completar el registro: $e',
        type: AlertType.error,
      );
    }
  }

  void _handleGuestEntry() {
    TacticalAlert.show(
      context,
      title: 'CONEXIÓN DE EMERGENCIA',
      message: 'Ingresando como Explorador Anónimo. La telemetría será temporal.',
      type: AlertType.info,
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const MapScreen(isGuest: true),
      ),
    );
  }

  void _showPasswordRecoveryDialog() {
    final recoveryEmailController = TextEditingController();
    final recoveryFormKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.cyan.withValues(alpha: 0.6),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.cyan.withValues(alpha: 0.2),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.8),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Form(
              key: recoveryFormKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.cyan.withValues(alpha: 0.15),
                        ),
                        child: const Icon(
                          Icons.lock_reset_rounded,
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
                              'RECUPERAR PROTOCOLO',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                              ),
                            ),
                            Text(
                              'Restablecimiento de clave criptográfica',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Ingresa tu identificador o correo asociado para enviarte un token de reautenticación segura.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 18),
                  CustomTextField(
                    controller: recoveryEmailController,
                    label: 'Correo de Enlace',
                    hint: 'agente@vertice.sv',
                    prefixIcon: Icons.alternate_email_rounded,
                    keyboardType: TextInputType.emailAddress,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Ingresa tu correo electrónico';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                          .hasMatch(val.trim())) {
                        return 'Sintaxis de enlace inválida';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          text: 'CANCELAR',
                          variant: ButtonVariant.ghost,
                          height: 46,
                          onPressed: () => Navigator.of(dialogContext).pop(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomButton(
                          text: 'ENVIAR TOKEN',
                          variant: ButtonVariant.primary,
                          height: 46,
                          onPressed: () {
                            if (recoveryFormKey.currentState!.validate()) {
                              final email = recoveryEmailController.text.trim();
                              Navigator.of(dialogContext).pop();
                              _sendPasswordRecovery(email);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _sendPasswordRecovery(String email) async {
    try {
      await _authService.resetPasswordForEmail(email);
      if (!mounted) return;
      TacticalAlert.show(
        context,
        title: 'TOKEN TRANSMITIDO',
        message:
            'Revisa tu bandeja de entrada para restaurar la clave de acceso.',
        type: AlertType.info,
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      TacticalAlert.show(
        context,
        title: 'ERROR EN RECUPERACIÓN',
        message: e.message,
        type: AlertType.error,
      );
    } catch (e) {
      if (!mounted) return;
      TacticalAlert.show(
        context,
        title: 'FALLA DE TRANSMISIÓN',
        message: 'No se pudo enviar el token: $e',
        type: AlertType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTabletOrLarger = !Responsive.isMobile(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Resplandor ambiental de fondo
          Positioned(
            top: -120,
            right: -120,
            child: Container(
              width: isTabletOrLarger ? 450 : 300,
              height: isTabletOrLarger ? 450 : 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.cyan.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -100,
            child: Container(
              width: isTabletOrLarger ? 400 : 260,
              height: isTabletOrLarger ? 400 : 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.gold.withValues(alpha: 0.04),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: isTabletOrLarger ? 40 : 24,
                  vertical: isTabletOrLarger ? 32 : 20,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isTabletOrLarger ? 960 : 440,
                  ),
                  child: isTabletOrLarger
                      ? _buildTabletLayout()
                      : _buildMobileLayout(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Layout para Smartphones (1 columna vertical)
  Widget _buildMobileLayout() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(isCompact: true),
        const SizedBox(height: 28),
        _buildFormCard(),
        const SizedBox(height: 20),
        _buildGuestOption(),
        const SizedBox(height: 18),
        _buildFooter(),
      ],
    );
  }

  /// Layout para Tablets y pantallas anchas (2 columnas balanceadas)
  Widget _buildTabletLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Columna Izquierda: Identidad y Lore Animus
        Expanded(
          flex: 5,
          child: Padding(
            padding: const EdgeInsets.only(right: 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildHeader(isCompact: false),
                const SizedBox(height: 32),
                _buildLoreCard(),
              ],
            ),
          ),
        ),
        // Columna Derecha: Formulario de Autenticación
        Expanded(
          flex: 5,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildFormCard(),
                const SizedBox(height: 20),
                _buildGuestOption(),
                const SizedBox(height: 16),
                _buildFooter(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader({required bool isCompact}) {
    return Column(
      crossAxisAlignment:
          isCompact ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Container(
          width: isCompact ? 58 : 68,
          height: isCompact ? 58 : 68,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.surfaceElevated,
            border: Border.all(
              color: AppColors.cyan.withValues(alpha: 0.6),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.cyan.withValues(alpha: 0.25),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Center(
            child: Icon(
              Icons.change_history_rounded,
              color: AppColors.cyan,
              size: isCompact ? 28 : 34,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'V É R T I C E',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: isCompact ? 26 : 32,
            fontWeight: FontWeight.w900,
            letterSpacing: isCompact ? 6 : 8,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Descubre el territorio oculto',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: isCompact ? 13 : 15,
            fontWeight: FontWeight.w400,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildLoreCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.cyan,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'PROTOCOLO DE SINCRONIZACIÓN SV',
                style: TextStyle(
                  color: AppColors.cyan,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'El Salvador aguarda. Despeja la niebla de guerra cartográfica explorando volcanes, playas y rutas ancestrales. Cada paso sincroniza un nuevo sector.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'NODO: SV-CENTRAL',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
              ),
              Text(
                'SEGURIDAD: ENCRIPTADO',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.surfaceBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildTabSelector(),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.04, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: _tabController.index == 0
                    ? _buildLoginForm()
                    : _buildRegisterForm(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSelector() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.surfaceBorder, width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton(
              label: 'INICIAR SESIÓN',
              index: 0,
            ),
          ),
          Expanded(
            child: _buildTabButton(
              label: 'REGISTRARSE',
              index: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({required String label, required int index}) {
    final bool isSelected = _tabController.index == index;
    return GestureDetector(
      onTap: () {
        _tabController.animateTo(index);
        setState(() {});
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surfaceElevated : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(
                  color: AppColors.cyan.withValues(alpha: 0.5),
                  width: 1,
                )
              : Border.all(color: Colors.transparent),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? AppColors.cyan : AppColors.textSecondary,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              letterSpacing: 1.1,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _loginFormKey,
      autovalidateMode: _loginAutoValidate
          ? AutovalidateMode.onUserInteraction
          : AutovalidateMode.disabled,
      child: Column(
        key: const ValueKey<String>('login_form'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CustomTextField(
            controller: _loginEmailController,
            label: 'Identificador / Correo',
            hint: 'agente@vertice.sv',
            prefixIcon: Icons.alternate_email_rounded,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Identificador de agente requerido';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                  .hasMatch(value.trim())) {
                return 'Sintaxis de enlace inválida';
              }
              return null;
            },
          ),
          const SizedBox(height: 18),
          CustomTextField(
            controller: _loginPasswordController,
            label: 'Clave de Acceso',
            hint: '••••••••',
            prefixIcon: Icons.lock_outline_rounded,
            obscureText: _loginObscurePassword,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _handleLogin(),
            suffixIcon: IconButton(
              icon: Icon(
                _loginObscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 20,
              ),
              onPressed: () {
                setState(() {
                  _loginObscurePassword = !_loginObscurePassword;
                });
              },
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Clave de acceso requerida';
              }
              if (value.length < 6) {
                return 'Clave criptográfica débil (mín. 6 caracteres)';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          // Recordar sesión & Recuperar contraseña
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    _rememberSession = !_rememberSession;
                  });
                },
                child: Row(
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: Checkbox(
                        value: _rememberSession,
                        activeColor: AppColors.cyan,
                        checkColor: AppColors.background,
                        side: const BorderSide(
                          color: AppColors.surfaceBorder,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        onChanged: (val) {
                          setState(() {
                            _rememberSession = val ?? true;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Recordar enlace',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: _showPasswordRecoveryDialog,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  '¿Recuperar clave?',
                  style: TextStyle(
                    color: AppColors.cyan,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          CustomButton(
            text: 'SINCRONIZAR SESIÓN',
            icon: Icons.login_rounded,
            isLoading: _isLoginLoading,
            onPressed: _handleLogin,
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterForm() {
    return Form(
      key: _registerFormKey,
      autovalidateMode: _registerAutoValidate
          ? AutovalidateMode.onUserInteraction
          : AutovalidateMode.disabled,
      child: Column(
        key: const ValueKey<String>('register_form'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CustomTextField(
            controller: _registerNameController,
            label: 'Identificador / Alias',
            hint: 'Cadete Alfa',
            prefixIcon: Icons.badge_outlined,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Identificador de agente requerido';
              }
              if (value.trim().length < 3) {
                return 'Alias muy corto (mín. 3 letras)';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _registerEmailController,
            label: 'Correo de Enlace',
            hint: 'agente@vertice.sv',
            prefixIcon: Icons.alternate_email_rounded,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Correo de enlace requerido';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                  .hasMatch(value.trim())) {
                return 'Sintaxis de enlace inválida';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _registerPasswordController,
            label: 'Crear Clave',
            hint: 'Mínimo 6 caracteres',
            prefixIcon: Icons.lock_outline_rounded,
            obscureText: _registerObscurePassword,
            onChanged: (val) {
              setState(() {
                _currentRegisterPassword = val;
              });
            },
            suffixIcon: IconButton(
              icon: Icon(
                _registerObscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 20,
              ),
              onPressed: () {
                setState(() {
                  _registerObscurePassword = !_registerObscurePassword;
                });
              },
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Clave de acceso requerida';
              }
              if (value.length < 6) {
                return 'Clave criptográfica débil (mín. 6 caracteres)';
              }
              return null;
            },
          ),
          // Indicador dinámico de fortaleza de clave
          PasswordStrengthIndicator(password: _currentRegisterPassword),
          const SizedBox(height: 12),
          CustomTextField(
            controller: _registerConfirmPasswordController,
            label: 'Confirmar Clave',
            hint: 'Repite tu contraseña',
            prefixIcon: Icons.lock_reset_rounded,
            obscureText: _registerObscureConfirmPassword,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _handleRegister(),
            suffixIcon: IconButton(
              icon: Icon(
                _registerObscureConfirmPassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 20,
              ),
              onPressed: () {
                setState(() {
                  _registerObscureConfirmPassword =
                      !_registerObscureConfirmPassword;
                });
              },
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Confirma tu clave criptográfica';
              }
              if (value != _registerPasswordController.text) {
                return 'Las claves criptográficas no coinciden';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          CustomButton(
            text: 'CREAR REGISTRO',
            icon: Icons.person_add_alt_1_rounded,
            isLoading: _isRegisterLoading,
            onPressed: _handleRegister,
          ),
        ],
      ),
    );
  }

  Widget _buildGuestOption() {
    return Column(
      children: [
        Row(
          children: [
            const Expanded(child: Divider(color: AppColors.surfaceBorder)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'O ACCESO DE EMERGENCIA',
                style: TextStyle(
                  color: AppColors.gold.withValues(alpha: 0.8),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            const Expanded(child: Divider(color: AppColors.surfaceBorder)),
          ],
        ),
        const SizedBox(height: 14),
        CustomButton(
          text: 'CONTINUAR COMO EXPLORADOR INVITADO',
          icon: Icons.radar_rounded,
          variant: ButtonVariant.outline,
          onPressed: _handleGuestEntry,
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return const Center(
      child: Text(
        'SISTEMA DE CARTOGRAFÍA // SV-2026',
        style: TextStyle(
          color: AppColors.textMuted,
          fontSize: 10,
          letterSpacing: 2,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}
