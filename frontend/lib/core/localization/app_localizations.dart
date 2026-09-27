import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Sistema de Internacionalización (i18n) para Next Trip.
/// Soporta 5 idiomas oficiales: Español ('es'), Inglés ('en'), Chino Simplificado ('zh'),
/// Ruso ('ru') y Portugués ('pt') con tipado estricto y fallback seguro.
class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('es'));
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('es'),
    Locale('en'),
    Locale('zh'),
    Locale('ru'),
    Locale('pt'),
  ];

  static final Map<String, Map<String, String>> _localizedValues = {
    'es': {
      // General & Common
      'appName': 'Next Trip',
      'appSubtitle': 'Cartografía Táctica & Turismo en El Salvador',
      'cancel': 'CANCELAR',
      'accept': 'ACEPTAR',
      'confirm': 'CONFIRMAR',
      'close': 'CERRAR',
      'save': 'GUARDAR',
      'delete': 'ELIMINAR',
      'loading': 'CARGANDO...',
      'pleaseWait': 'Por favor espera...',
      'error': 'ERROR',
      'success': 'ÉXITO',
      'warning': 'ADVERTENCIA',
      'retry': 'REINTENTAR',

      // Auth
      'authTitle': 'NEXT TRIP // ENLACE TÁCTICO',
      'authSubtitle': 'Sistema de Cartografía y Exploración',
      'login': 'INICIAR SESIÓN',
      'register': 'REGISTRARSE',
      'email': 'Correo Electrónico',
      'password': 'Clave de Acceso',
      'confirmPassword': 'Confirmar Clave',
      'fullName': 'Nombre Completo',
      'username': 'Nombre de Usuario',
      'birthdate': 'Fecha de Nacimiento',
      'noAccount': '¿No tienes cuenta táctica? Regístrate',
      'haveAccount': '¿Ya posees credenciales? Inicia sesión',
      'passwordMinLength': 'Mínimo 8 caracteres',
      'passwordsDontMatch': 'Las claves no coinciden',
      'fieldRequired': 'Campo obligatorio',
      'invalidEmail': 'Ingresa un correo válido',
      'loginSuccess': 'Enlace establecido con éxito.',
      'registerSuccess': 'Operador registrado correctamente.',
      'sessionExpired': 'Sesión caducada. Por favor autentícate de nuevo.',

      // Map
      'tacticalMap': 'MAPA TÁCTICO',
      'searchPlaceholder': 'Buscar cumbres, ruinas, volcanes...',
      'operator': 'OPERADOR',
      'operatorPosition': 'POSICIÓN DEL OPERADOR',
      'targetDistance': 'DISTANCIA AL OBJETIVO',
      'difficulty': 'NIVEL DE ACCESO',
      'category': 'CATEGORÍA',
      'exploration': 'EXPLORACIÓN',
      'reconnaissance': 'RECONOCIMIENTO DE CAMPO',
      'focus': 'ENFOCAR',
      'traceRoute': 'TRAZAR RUTA',
      'cancelRoute': 'CANCELAR RUTA',
      'deletePin': 'ELIMINAR PIN',
      'inspect': 'INSPECCIONAR',
      'pinAdded': 'PIN AÑADIDO',
      'outsideJurisdiction': 'Coordenada fuera de la jurisdicción táctica de El Salvador.',
      'gpsDisabledWarning': 'Activa el GPS de tu dispositivo para actualizar tu posición táctica real.',
      'gpsSettingsDisabled': 'GPS desactivado en ajustes. Actívalo para rastrear tu posición.',
      'gpsPending': 'GPS PENDIENTE',
      'touristDestinations': 'Destinos Turísticos',
      'eventsBillboard': 'Cartelera de Eventos',
      'trafficStatus': 'Estado del Tráfico',
      'trafficNormal': 'Tráfico Fluido',
      'trafficCongested': 'Tráfico Congestionado',
      'trafficFreeFlow': 'Flujo Libre',
      'trafficModerate': 'Tráfico Moderado',
      'trafficHeavy': 'Congestión Pesada',
      'trafficLayer': 'Capa de Tráfico',
      'addAsDestination': 'AGREGAR COMO DESTINO TURÍSTICO',
      'viewDetails': 'VER DETALLES',
      'selectedPoint': 'Punto Seleccionado',
      'department': 'DEPARTAMENTO',
      'estimatedTime': 'TIEMPO ESTIMADO (ETA)',
      'distance': 'DISTANCIA',

      // Settings
      'settingsTitle': 'AJUSTES // SISTEMA',
      'profileTitle': 'PERFIL DE OPERADOR',
      'profilePhoto': 'FOTO DE PERFIL DE OPERADOR',
      'takePhoto': 'Tomar foto con la cámara',
      'chooseGallery': 'Elegir de la galería',
      'removePhoto': 'Eliminar foto actual',
      'identificationData': 'DATOS DE IDENTIFICACIÓN',
      'securityHeader': 'SEGURIDAD // CLAVE DE ACCESO',
      'newPassword': 'Nueva Clave',
      'updatePassword': 'ACTUALIZAR CLAVE',
      'passwordUpdated': 'Clave de acceso actualizada correctamente.',
      'systemPreferences': 'PREFERENCIAS DEL SISTEMA',
      'themeMode': 'MODO VISUAL',
      'themeDark': 'Oscuro Táctico',
      'themeLight': 'Claro Alto Contraste',
      'themeSystem': 'Sistema',
      'fontScale': 'TAMAÑO DE FUENTE',
      'fontSmall': 'Pequeño (0.85x)',
      'fontNormal': 'Normal (1.00x)',
      'fontLarge': 'Grande (1.15x)',
      'fontExtraLarge': 'Muy Grande (1.25x)',
      'language': 'IDIOMA // LANGUAGE',
      'langSpanish': 'Español',
      'langEnglish': 'English',
      'langChinese': '简体中文',
      'langRussian': 'Русский',
      'langPortuguese': 'Português',
      'gpsTracking': 'Rastreo GPS en tiempo real',
      'gpsTrackingActive': 'Activo — posición visible en mapa',
      'gpsTrackingInactive': 'Inactivo — sensor desconectado',
      'offlineMapCache': 'CACHÉ OFFLINE DE MAPAS',
      'offlineMapDesc': 'Almacena teselas de El Salvador para navegación sin conexión',
      'precacheTiles': 'DESCARGAR MAPA OFFLINE (ZOOM 8-11)',
      'precacheProgress': 'Descargando teselas:',
      'precacheSuccess': 'Mapa de El Salvador precacheado en disco.',
      'clearCache': 'LIMPIAR CACHÉ DE MAPA',
      'cacheCleared': 'Caché de mapas eliminado.',
      'signOut': 'CERRAR SESIÓN TÁCTICA',
      'signOutConfirmTitle': 'DESCONECTAR ENLACE',
      'signOutConfirmMessage': '¿Deseas cerrar la sesión táctica actual?',
      'systemFooter': 'SISTEMA DE CARTOGRAFÍA // SV-2026',
    },
    'en': {
      // General & Common
      'appName': 'Next Trip',
      'appSubtitle': 'Tactical Cartography & Tourism in El Salvador',
      'cancel': 'CANCEL',
      'accept': 'ACCEPT',
      'confirm': 'CONFIRM',
      'close': 'CLOSE',
      'save': 'SAVE',
      'delete': 'DELETE',
      'loading': 'LOADING...',
      'pleaseWait': 'Please wait...',
      'error': 'ERROR',
      'success': 'SUCCESS',
      'warning': 'WARNING',
      'retry': 'RETRY',

      // Auth
      'authTitle': 'NEXT TRIP // TACTICAL LINK',
      'authSubtitle': 'Cartography & Exploration System',
      'login': 'SIGN IN',
      'register': 'SIGN UP',
      'email': 'Email Address',
      'password': 'Password',
      'confirmPassword': 'Confirm Password',
      'fullName': 'Full Name',
      'username': 'Username',
      'birthdate': 'Birthdate',
      'noAccount': "Don't have an account? Sign up",
      'haveAccount': 'Already have credentials? Sign in',
      'passwordMinLength': 'Minimum 8 characters',
      'passwordsDontMatch': 'Passwords do not match',
      'fieldRequired': 'Required field',
      'invalidEmail': 'Enter a valid email address',
      'loginSuccess': 'Tactical link established.',
      'registerSuccess': 'Operator registered successfully.',
      'sessionExpired': 'Session expired. Please authenticate again.',

      // Map
      'tacticalMap': 'TACTICAL MAP',
      'searchPlaceholder': 'Search peaks, ruins, volcanoes...',
      'operator': 'OPERATOR',
      'operatorPosition': 'OPERATOR POSITION',
      'targetDistance': 'DISTANCE TO TARGET',
      'difficulty': 'ACCESS LEVEL',
      'category': 'CATEGORY',
      'exploration': 'EXPLORATION',
      'reconnaissance': 'FIELD RECON',
      'focus': 'FOCUS',
      'traceRoute': 'ROUTE TARGET',
      'cancelRoute': 'CANCEL ROUTE',
      'deletePin': 'DELETE PIN',
      'inspect': 'INSPECT',
      'pinAdded': 'PIN ADDED',
      'outsideJurisdiction': 'Coordinate outside tactical jurisdiction of El Salvador.',
      'gpsDisabledWarning': 'Enable device GPS to update your real-time tactical position.',
      'gpsSettingsDisabled': 'GPS disabled in settings. Enable it to track position.',
      'gpsPending': 'GPS PENDING',
      'touristDestinations': 'Tourist Destinations',
      'eventsBillboard': 'Event Billboard',
      'trafficStatus': 'Traffic Status',
      'trafficNormal': 'Smooth Traffic',
      'trafficCongested': 'Heavy Traffic',
      'trafficFreeFlow': 'Free Flow',
      'trafficModerate': 'Moderate Traffic',
      'trafficHeavy': 'Heavy Congestion',
      'trafficLayer': 'Traffic Layer',
      'addAsDestination': 'ADD AS TOURIST DESTINATION',
      'viewDetails': 'VIEW DETAILS',
      'selectedPoint': 'Selected Point',
      'department': 'DEPARTMENT',
      'estimatedTime': 'ESTIMATED TIME (ETA)',
      'distance': 'DISTANCE',

      // Settings
      'settingsTitle': 'SETTINGS // SYSTEM',
      'profileTitle': 'OPERATOR PROFILE',
      'profilePhoto': 'OPERATOR PROFILE PHOTO',
      'takePhoto': 'Take photo with camera',
      'chooseGallery': 'Choose from gallery',
      'removePhoto': 'Remove current photo',
      'identificationData': 'IDENTIFICATION DATA',
      'securityHeader': 'SECURITY // ACCESS KEY',
      'newPassword': 'New Password',
      'updatePassword': 'UPDATE PASSWORD',
      'passwordUpdated': 'Password updated successfully.',
      'systemPreferences': 'SYSTEM PREFERENCES',
      'themeMode': 'THEME MODE',
      'themeDark': 'Tactical Dark',
      'themeLight': 'High-Contrast Light',
      'themeSystem': 'System',
      'fontScale': 'FONT SCALE',
      'fontSmall': 'Small (0.85x)',
      'fontNormal': 'Normal (1.00x)',
      'fontLarge': 'Large (1.15x)',
      'fontExtraLarge': 'Extra Large (1.25x)',
      'language': 'LANGUAGE // IDIOMA',
      'langSpanish': 'Español',
      'langEnglish': 'English',
      'langChinese': '简体中文',
      'langRussian': 'Русский',
      'langPortuguese': 'Português',
      'gpsTracking': 'Real-Time GPS Tracking',
      'gpsTrackingActive': 'Active — position visible on map',
      'gpsTrackingInactive': 'Inactive — sensor disconnected',
      'offlineMapCache': 'OFFLINE MAP CACHE',
      'offlineMapDesc': 'Stores El Salvador tiles for offline navigation',
      'precacheTiles': 'PRE-CACHE MAP (ZOOM 8-11)',
      'precacheProgress': 'Downloading tiles:',
      'precacheSuccess': 'El Salvador map cached to disk.',
      'clearCache': 'CLEAR MAP CACHE',
      'cacheCleared': 'Map cache cleared.',
      'signOut': 'TACTICAL SIGN OUT',
      'signOutConfirmTitle': 'DISCONNECT LINK',
      'signOutConfirmMessage': 'Do you want to end the current tactical session?',
      'systemFooter': 'CARTOGRAPHY SYSTEM // SV-2026',
    },
    'zh': {
      // General & Common
      'appName': 'Next Trip',
      'appSubtitle': '萨尔瓦多战术地图与旅游探索',
      'cancel': '取消',
      'accept': '接受',
      'confirm': '确认',
      'close': '关闭',
      'save': '保存',
      'delete': '删除',
      'loading': '加载中...',
      'pleaseWait': '请稍候...',
      'error': '错误',
      'success': '成功',
      'warning': '警告',
      'retry': '重试',

      // Auth
      'authTitle': 'NEXT TRIP // 战术链接',
      'authSubtitle': '制图与探索系统',
      'login': '登录',
      'register': '注册',
      'email': '电子邮箱',
      'password': '访问密码',
      'confirmPassword': '确认密码',
      'fullName': '全名',
      'username': '用户名',
      'birthdate': '出生日期',
      'noAccount': '还没有战术账户？立即注册',
      'haveAccount': '已有凭据？立即登录',
      'passwordMinLength': '至少8个字符',
      'passwordsDontMatch': '两次输入的密码不一致',
      'fieldRequired': '此项为必填项',
      'invalidEmail': '请输入有效的电子邮箱',
      'loginSuccess': '战术链接建立成功。',
      'registerSuccess': '操作员注册成功。',
      'sessionExpired': '会话已过期，请重新登录。',

      // Map
      'tacticalMap': '战术地图',
      'searchPlaceholder': '搜索山峰、遗址、火山...',
      'operator': '操作员',
      'operatorPosition': '操作员当前位置',
      'targetDistance': '到目标距离',
      'difficulty': '通行难度',
      'category': '类别',
      'exploration': '探索',
      'reconnaissance': '实地侦察',
      'focus': '聚焦',
      'traceRoute': '规划路线',
      'cancelRoute': '取消路线',
      'deletePin': '删除标记',
      'inspect': '查看详情',
      'pinAdded': '标记已添加',
      'outsideJurisdiction': '坐标超出萨尔瓦多战术管辖范围。',
      'gpsDisabledWarning': '请开启设备GPS以获取实时战术位置。',
      'gpsSettingsDisabled': '设置中已停用GPS。请开启以追踪位置。',
      'gpsPending': 'GPS待命',
      'touristDestinations': '旅游目的地',
      'eventsBillboard': '活动看板',
      'trafficStatus': '实时路况',
      'trafficNormal': '路况通畅',
      'trafficCongested': '交通拥堵',
      'trafficFreeFlow': '畅通无阻',
      'trafficModerate': '轻度拥堵',
      'trafficHeavy': '严重拥堵',
      'trafficLayer': '路况图层',
      'addAsDestination': '添加为旅游目的地',
      'viewDetails': '查看详情',
      'selectedPoint': '已选定点',
      'department': '省份 / 地区',
      'estimatedTime': '预计时间 (ETA)',
      'distance': '总距离',

      // Settings
      'settingsTitle': '设置 // 系统',
      'profileTitle': '操作员资料',
      'profilePhoto': '操作员头像',
      'takePhoto': '使用相机拍摄',
      'chooseGallery': '从相册选择',
      'removePhoto': '删除当前照片',
      'identificationData': '身份识别信息',
      'securityHeader': '安全 // 访问密码',
      'newPassword': '新密码',
      'updatePassword': '更新密码',
      'passwordUpdated': '访问密码更新成功。',
      'systemPreferences': '系统偏好设置',
      'themeMode': '视觉主题',
      'themeDark': '战术深色',
      'themeLight': '高对比浅色',
      'themeSystem': '跟随系统',
      'fontScale': '字体缩放',
      'fontSmall': '小 (0.85x)',
      'fontNormal': '正常 (1.00x)',
      'fontLarge': '大 (1.15x)',
      'fontExtraLarge': '特大 (1.25x)',
      'language': '语言 // LANGUAGE',
      'langSpanish': 'Español',
      'langEnglish': 'English',
      'langChinese': '简体中文',
      'langRussian': 'Русский',
      'langPortuguese': 'Português',
      'gpsTracking': '实时GPS追踪',
      'gpsTrackingActive': '已激活 — 地图显示位置',
      'gpsTrackingInactive': '未激活 — 传感器已断开',
      'offlineMapCache': '离线地图缓存',
      'offlineMapDesc': '保存萨尔瓦多地图瓦片以便无网络导航',
      'precacheTiles': '下载离线地图 (ZOOM 8-11)',
      'precacheProgress': '正在下载瓦片：',
      'precacheSuccess': '萨尔瓦多地图已离线缓存到磁盘。',
      'clearCache': '清除地图缓存',
      'cacheCleared': '地图缓存已清理。',
      'signOut': '断开战术会话',
      'signOutConfirmTitle': '断开链接',
      'signOutConfirmMessage': '确定要退出当前的战术会话吗？',
      'systemFooter': '制图系统 // SV-2026',
    },
    'ru': {
      // General & Common
      'appName': 'Next Trip',
      'appSubtitle': 'Тактическая картография и туризм в Сальвадоре',
      'cancel': 'ОТМЕНА',
      'accept': 'ПРИНЯТЬ',
      'confirm': 'ПОДТВЕРДИТЬ',
      'close': 'ЗАКРЫТЬ',
      'save': 'СОХРАНИТЬ',
      'delete': 'УДАЛИТЬ',
      'loading': 'ЗАГРУЗКА...',
      'pleaseWait': 'Пожалуйста, подождите...',
      'error': 'ОШИБКА',
      'success': 'УСПЕХ',
      'warning': 'ВНИМАНИЕ',
      'retry': 'ПОВТОРИТЬ',

      // Auth
      'authTitle': 'NEXT TRIP // ТАКТИЧЕСКИЙ КАНАЛ',
      'authSubtitle': 'Система картографии и исследований',
      'login': 'ВОЙТИ',
      'register': 'РЕГИСТРАЦИЯ',
      'email': 'Электронная почта',
      'password': 'Пароль доступа',
      'confirmPassword': 'Подтвердите пароль',
      'fullName': 'Полное имя',
      'username': 'Имя пользователя',
      'birthdate': 'Дата рождения',
      'noAccount': 'Нет тактического аккаунта? Зарегистрируйтесь',
      'haveAccount': 'Уже есть учетные данные? Войдите',
      'passwordMinLength': 'Минимум 8 символов',
      'passwordsDontMatch': 'Пароли не совпадают',
      'fieldRequired': 'Обязательное поле',
      'invalidEmail': 'Введите корректный email',
      'loginSuccess': 'Тактический канал успешно установлен.',
      'registerSuccess': 'Оператор успешно зарегистрирован.',
      'sessionExpired': 'Сессия истекла. Пожалуйста, выполните вход снова.',

      // Map
      'tacticalMap': 'ТАКТИЧЕСКАЯ КАРТА',
      'searchPlaceholder': 'Поиск вершин, руин, вулканов...',
      'operator': 'ОПЕРАТОР',
      'operatorPosition': 'ПОЗИЦИЯ ОПЕРАТОРА',
      'targetDistance': 'РАССТОЯНИЕ ДО ЦЕЛИ',
      'difficulty': 'УРОВЕНЬ ДОСТУПА',
      'category': 'КАТЕГОРИЯ',
      'exploration': 'ИССЛЕДОВАНИЕ',
      'reconnaissance': 'РАЗВЕДКА НА МЕСТНОСТИ',
      'focus': 'ФОКУС',
      'traceRoute': 'ПОСТРОИТЬ МАРШРУТ',
      'cancelRoute': 'ОТМЕНИТЬ МАРШРУТ',
      'deletePin': 'УДАЛИТЬ ТОЧКУ',
      'inspect': 'ОСМОТРЕТЬ',
      'pinAdded': 'ТОЧКА ДОБАВЛЕНА',
      'outsideJurisdiction': 'Координаты вне юрисдикции Сальвадора.',
      'gpsDisabledWarning': 'Включите GPS для обновления реальной позиции.',
      'gpsSettingsDisabled': 'GPS отключен в настройках. Включите его для трекинга.',
      'gpsPending': 'GPS ОЖИДАЕТСЯ',
      'touristDestinations': 'Туристические объекты',
      'eventsBillboard': 'Афиша событий',
      'trafficStatus': 'Состояние движения',
      'trafficNormal': 'Свободное движение',
      'trafficCongested': 'Плотный затор',
      'trafficFreeFlow': 'Свободный поток',
      'trafficModerate': 'Умеренное движение',
      'trafficHeavy': 'Сильная пробка',
      'trafficLayer': 'Слой дорожного движения',
      'addAsDestination': 'ДОБАВИТЬ КАК ТУРИСТИЧЕСКИЙ ОБЪЕКТ',
      'viewDetails': 'ПОДРОБНЕЕ',
      'selectedPoint': 'Выбранная точка',
      'department': 'ДЕПАРТАМЕНТ',
      'estimatedTime': 'ВРЕМЯ ПРИБЫТИЯ (ETA)',
      'distance': 'РАССТОЯНИЕ',

      // Settings
      'settingsTitle': 'НАСТРОЙКИ // СИСТЕМА',
      'profileTitle': 'ПРОФИЛЬ ОПЕРАТОРА',
      'profilePhoto': 'ФОТО ОПЕРАТОРА',
      'takePhoto': 'Сделать снимок камерой',
      'chooseGallery': 'Выбрать из галереи',
      'removePhoto': 'Удалить текущее фото',
      'identificationData': 'ДАННЫЕ ОПЕРАТОРА',
      'securityHeader': 'БЕЗОПАСНОСТЬ // КЛЮЧ ДОСТУПА',
      'newPassword': 'Новый пароль',
      'updatePassword': 'ОБНОВИТЬ ПАРОЛЬ',
      'passwordUpdated': 'Пароль успешно обновлен.',
      'systemPreferences': 'НАСТРОЙКИ СИСТЕМЫ',
      'themeMode': 'ВИЗУАЛЬНАЯ ТЕМА',
      'themeDark': 'Тактическая темная',
      'themeLight': 'Контрастная светлая',
      'themeSystem': 'Системная',
      'fontScale': 'МАСШТАБ ТЕКСТА',
      'fontSmall': 'Мелкий (0.85x)',
      'fontNormal': 'Обычный (1.00x)',
      'fontLarge': 'Крупный (1.15x)',
      'fontExtraLarge': 'Очень крупный (1.25x)',
      'language': 'ЯЗЫК // LANGUAGE',
      'langSpanish': 'Español',
      'langEnglish': 'English',
      'langChinese': '简体中文',
      'langRussian': 'Русский',
      'langPortuguese': 'Português',
      'gpsTracking': 'GPS-трекинг в реальном времени',
      'gpsTrackingActive': 'Активен — позиция видна на карте',
      'gpsTrackingInactive': 'Неактивен — датчик отключен',
      'offlineMapCache': 'ОФЛАЙН-КЭШ КАРТ',
      'offlineMapDesc': 'Сохраняет тайлы Сальвадора для навигации без сети',
      'precacheTiles': 'СКАЧАТЬ ОФЛАЙН КАРТУ (ZOOM 8-11)',
      'precacheProgress': 'Загрузка тайлов:',
      'precacheSuccess': 'Карта Сальвадора сохранена на устройство.',
      'clearCache': 'ОЧИСТИТЬ КЭШ КАРТ',
      'cacheCleared': 'Кэш карт очищен.',
      'signOut': 'ВЫХОД ИЗ СИСТЕМЫ',
      'signOutConfirmTitle': 'ОТКЛЮЧИТЬ КАНАЛ',
      'signOutConfirmMessage': 'Завершить текущую тактическую сессию?',
      'systemFooter': 'КАРТОГРАФИЧЕСКАЯ СИСТЕМА // SV-2026',
    },
    'pt': {
      // General & Common
      'appName': 'Next Trip',
      'appSubtitle': 'Cartografia Tática e Turismo em El Salvador',
      'cancel': 'CANCELAR',
      'accept': 'ACEITAR',
      'confirm': 'CONFIRMAR',
      'close': 'FECHAR',
      'save': 'SALVAR',
      'delete': 'EXCLUIR',
      'loading': 'CARREGANDO...',
      'pleaseWait': 'Por favor, aguarde...',
      'error': 'ERRO',
      'success': 'SUCESSO',
      'warning': 'AVISO',
      'retry': 'TENTAR NOVAMENTE',

      // Auth
      'authTitle': 'NEXT TRIP // CONEXÃO TÁTICA',
      'authSubtitle': 'Sistema de Cartografia e Exploração',
      'login': 'ENTRAR',
      'register': 'REGISTRAR',
      'email': 'E-mail',
      'password': 'Senha de Acesso',
      'confirmPassword': 'Confirmar Senha',
      'fullName': 'Nome Completo',
      'username': 'Nome de Usuário',
      'birthdate': 'Data de Nascimento',
      'noAccount': 'Não tem conta tática? Cadastre-se',
      'haveAccount': 'Já tem credenciais? Conecte-se',
      'passwordMinLength': 'Mínimo de 8 caracteres',
      'passwordsDontMatch': 'As senhas não coincidem',
      'fieldRequired': 'Campo obrigatório',
      'invalidEmail': 'Insira um e-mail válido',
      'loginSuccess': 'Conexão estabelecida com sucesso.',
      'registerSuccess': 'Operador registrado com sucesso.',
      'sessionExpired': 'Sessão expirada. Faça login novamente.',

      // Map
      'tacticalMap': 'MAPA TÁTICO',
      'searchPlaceholder': 'Buscar picos, ruínas, vulcões...',
      'operator': 'OPERADOR',
      'operatorPosition': 'POSIÇÃO DO OPERADOR',
      'targetDistance': 'DISTÂNCIA ATÉ O ALVO',
      'difficulty': 'NÍVEL DE ACESSO',
      'category': 'CATEGORIA',
      'exploration': 'EXPLORAÇÃO',
      'reconnaissance': 'RECONHECIMENTO DE CAMPO',
      'focus': 'FOCAR',
      'traceRoute': 'TRAÇAR ROTA',
      'cancelRoute': 'CANCELAR ROTA',
      'deletePin': 'EXCLUIR PONTO',
      'inspect': 'INSPECIONAR',
      'pinAdded': 'PONTO ADICIONADO',
      'outsideJurisdiction': 'Coordenada fora da jurisdição tática de El Salvador.',
      'gpsDisabledWarning': 'Ative o GPS para atualizar sua posição tática real.',
      'gpsSettingsDisabled': 'GPS desativado nas configurações. Ative-o para rastrear sua posição.',
      'gpsPending': 'GPS PENDENTE',
      'touristDestinations': 'Destinos Turísticos',
      'eventsBillboard': 'Quadro de Eventos',
      'trafficStatus': 'Estado do Trânsito',
      'trafficNormal': 'Trânsito Fluido',
      'trafficCongested': 'Trânsito Congestionado',
      'trafficFreeFlow': 'Fluxo Livre',
      'trafficModerate': 'Trânsito Moderado',
      'trafficHeavy': 'Congestionamento Pesado',
      'trafficLayer': 'Camada de Trânsito',
      'addAsDestination': 'ADICIONAR COMO DESTINO TURÍSTICO',
      'viewDetails': 'VER DETALHES',
      'selectedPoint': 'Ponto Selecionado',
      'department': 'DEPARTAMENTO',
      'estimatedTime': 'TEMPO ESTIMADO (ETA)',
      'distance': 'DISTÂNCIA',

      // Settings
      'settingsTitle': 'CONFIGURAÇÕES // SISTEMA',
      'profileTitle': 'PERFIL DO OPERADOR',
      'profilePhoto': 'FOTO DO OPERADOR',
      'takePhoto': 'Tirar foto com a câmera',
      'chooseGallery': 'Escolher da galeria',
      'removePhoto': 'Remover foto atual',
      'identificationData': 'DADOS DE IDENTIFICAÇÃO',
      'securityHeader': 'SEGURANÇA // SENHA DE ACESSO',
      'newPassword': 'Nova Senha',
      'updatePassword': 'ATUALIZAR SENHA',
      'passwordUpdated': 'Senha atualizada com sucesso.',
      'systemPreferences': 'PREFERÊNCIAS DO SISTEMA',
      'themeMode': 'MODO VISUAL',
      'themeDark': 'Escuro Tático',
      'themeLight': 'Claro Alto Contraste',
      'themeSystem': 'Sistema',
      'fontScale': 'TAMANHO DA FONTE',
      'fontSmall': 'Pequeno (0.85x)',
      'fontNormal': 'Normal (1.00x)',
      'fontLarge': 'Grande (1.15x)',
      'fontExtraLarge': 'Muito Grande (1.25x)',
      'language': 'IDIOMA // LANGUAGE',
      'langSpanish': 'Español',
      'langEnglish': 'English',
      'langChinese': '简体中文',
      'langRussian': 'Русский',
      'langPortuguese': 'Português',
      'gpsTracking': 'Rastreamento GPS em tempo real',
      'gpsTrackingActive': 'Ativo — posição visível no mapa',
      'gpsTrackingInactive': 'Inativo — sensor desconectado',
      'offlineMapCache': 'CACHE OFFLINE DE MAPAS',
      'offlineMapDesc': 'Armazena mapas de El Salvador para navegação offline',
      'precacheTiles': 'BAIXAR MAPA OFFLINE (ZOOM 8-11)',
      'precacheProgress': 'Baixando blocos:',
      'precacheSuccess': 'Mapa de El Salvador armazenado em disco.',
      'clearCache': 'LIMPAR CACHE DE MAPAS',
      'cacheCleared': 'Cache de mapas limpo.',
      'signOut': 'ENCERRAR SESSÃO TÁTICA',
      'signOutConfirmTitle': 'DESCONECTAR',
      'signOutConfirmMessage': 'Deseja encerrar a sessão tática atual?',
      'systemFooter': 'SISTEMA DE CARTOGRAFIA // SV-2026',
    },
  };

  String translate(String key) {
    final code = locale.languageCode;
    return _localizedValues[code]?[key] ??
        _localizedValues['es']?[key] ??
        key;
  }

  // Getters comunes
  String get appName => translate('appName');
  String get appSubtitle => translate('appSubtitle');
  String get cancel => translate('cancel');
  String get accept => translate('accept');
  String get confirm => translate('confirm');
  String get close => translate('close');
  String get save => translate('save');
  String get delete => translate('delete');
  String get loading => translate('loading');
  String get pleaseWait => translate('pleaseWait');
  String get error => translate('error');
  String get success => translate('success');
  String get warning => translate('warning');
  String get retry => translate('retry');

  // Auth
  String get authTitle => translate('authTitle');
  String get authSubtitle => translate('authSubtitle');
  String get login => translate('login');
  String get register => translate('register');
  String get email => translate('email');
  String get password => translate('password');
  String get confirmPassword => translate('confirmPassword');
  String get fullName => translate('fullName');
  String get username => translate('username');
  String get birthdate => translate('birthdate');
  String get noAccount => translate('noAccount');
  String get haveAccount => translate('haveAccount');
  String get passwordMinLength => translate('passwordMinLength');
  String get passwordsDontMatch => translate('passwordsDontMatch');
  String get fieldRequired => translate('fieldRequired');
  String get invalidEmail => translate('invalidEmail');
  String get loginSuccess => translate('loginSuccess');
  String get registerSuccess => translate('registerSuccess');
  String get sessionExpired => translate('sessionExpired');

  // Map
  String get tacticalMap => translate('tacticalMap');
  String get searchPlaceholder => translate('searchPlaceholder');
  String get operator => translate('operator');
  String get operatorPosition => translate('operatorPosition');
  String get targetDistance => translate('targetDistance');
  String get difficulty => translate('difficulty');
  String get category => translate('category');
  String get exploration => translate('exploration');
  String get reconnaissance => translate('reconnaissance');
  String get focus => translate('focus');
  String get traceRoute => translate('traceRoute');
  String get cancelRoute => translate('cancelRoute');
  String get deletePin => translate('deletePin');
  String get inspect => translate('inspect');
  String get pinAdded => translate('pinAdded');
  String get outsideJurisdiction => translate('outsideJurisdiction');
  String get gpsDisabledWarning => translate('gpsDisabledWarning');
  String get gpsSettingsDisabled => translate('gpsSettingsDisabled');
  String get gpsPending => translate('gpsPending');
  String get touristDestinations => translate('touristDestinations');
  String get eventsBillboard => translate('eventsBillboard');
  String get trafficStatus => translate('trafficStatus');
  String get trafficNormal => translate('trafficNormal');
  String get trafficCongested => translate('trafficCongested');
  String get trafficFreeFlow => translate('trafficFreeFlow');
  String get trafficModerate => translate('trafficModerate');
  String get trafficHeavy => translate('trafficHeavy');
  String get trafficLayer => translate('trafficLayer');
  String get addAsDestination => translate('addAsDestination');
  String get viewDetails => translate('viewDetails');
  String get selectedPoint => translate('selectedPoint');
  String get department => translate('department');
  String get estimatedTime => translate('estimatedTime');
  String get distance => translate('distance');

  // Settings
  String get settingsTitle => translate('settingsTitle');
  String get profileTitle => translate('profileTitle');
  String get profilePhoto => translate('profilePhoto');
  String get takePhoto => translate('takePhoto');
  String get chooseGallery => translate('chooseGallery');
  String get removePhoto => translate('removePhoto');
  String get identificationData => translate('identificationData');
  String get securityHeader => translate('securityHeader');
  String get newPassword => translate('newPassword');
  String get updatePassword => translate('updatePassword');
  String get passwordUpdated => translate('passwordUpdated');
  String get systemPreferences => translate('systemPreferences');
  String get themeMode => translate('themeMode');
  String get themeDark => translate('themeDark');
  String get themeLight => translate('themeLight');
  String get themeSystem => translate('themeSystem');
  String get fontScale => translate('fontScale');
  String get fontSmall => translate('fontSmall');
  String get fontNormal => translate('fontNormal');
  String get fontLarge => translate('fontLarge');
  String get fontExtraLarge => translate('fontExtraLarge');
  String get language => translate('language');
  String get langSpanish => translate('langSpanish');
  String get langEnglish => translate('langEnglish');
  String get langChinese => translate('langChinese');
  String get langRussian => translate('langRussian');
  String get langPortuguese => translate('langPortuguese');
  String get gpsTracking => translate('gpsTracking');
  String get gpsTrackingActive => translate('gpsTrackingActive');
  String get gpsTrackingInactive => translate('gpsTrackingInactive');
  String get offlineMapCache => translate('offlineMapCache');
  String get offlineMapDesc => translate('offlineMapDesc');
  String get precacheTiles => translate('precacheTiles');
  String get precacheProgress => translate('precacheProgress');
  String get precacheSuccess => translate('precacheSuccess');
  String get clearCache => translate('clearCache');
  String get cacheCleared => translate('cacheCleared');
  String get signOut => translate('signOut');
  String get signOutConfirmTitle => translate('signOutConfirmTitle');
  String get signOutConfirmMessage => translate('signOutConfirmMessage');
  String get systemFooter => translate('systemFooter');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['es', 'en', 'zh', 'ru', 'pt'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

extension LocalizationExtension on BuildContext {
  AppLocalizations get loc => AppLocalizations.of(this);
}
