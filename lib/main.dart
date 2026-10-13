// ============================================================================
//  StudyFlow — планировщик учебных задач для студентов колледжа
//  Курсовой проект по модулю ПМ07 «Разработка мобильных приложений»
//  Выполнил: студент группы ПО2408 Айткужинов Амир
//  Колледж ТОО «Astana IT University», 2026
//
//  Один файл, без внешних библиотек и без подключения к сети.
//  Запуск: flutter create moy_proekt → заменить lib/main.dart → flutter run
//
//  Структура файла:
//    1. Оформление (цвета и тема)
//    2. Даты на русском языке
//    3. Модели данных (пользователь, задача)
//    4. Хранилище данных и логика входа (AppStore)
//    5. Проверка вводимых данных (Validators)
//    6. Приложение и маршруты
//    7. Экран запуска
//    8. Экран авторизации
//    9. Экран регистрации
//   10. Оболочка с нижней навигацией
//   11. Главная страница
//   12. Основной раздел — задачи
//   13. Экран добавления и редактирования задачи
//   14. Профиль, редактирование профиля, выход
//   15. Общие виджеты
// ============================================================================

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

// ─── 1. Оформление ──────────────────────────────────────────────────────────

const Color kPrimary = Color(0xFF4F46E5); // индиго — основной цвет приложения
const Color kSecondary = Color(0xFF7C3AED); // фиолетовый — для градиентов
const Color kBackground = Color(0xFFF5F6FB); // светлый фон всех экранов
const Color kText = Color(0xFF1F2333);
const Color kMuted = Color(0xFF6B7085);
const Color kBorder = Color(0xFFE2E4EE);
const Color kDanger = Color(0xFFDC2626);
const Color kSuccess = Color(0xFF16A34A);
const Color kWarning = Color(0xFFF59E0B);

const LinearGradient kBrandGradient = LinearGradient(
  colors: [kPrimary, kSecondary],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

ThemeData buildTheme() {
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: const BorderSide(color: kBorder),
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: kPrimary, primary: kPrimary),
    scaffoldBackgroundColor: kBackground,
    appBarTheme: const AppBarTheme(
      backgroundColor: kBackground,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      errorMaxLines: 2, // длинное сообщение об ошибке переносится, а не обрезается
      hoverColor: const Color(0xFFF9FAFD),
      helperMaxLines: 2,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: const BorderSide(color: kPrimary, width: 1.6),
      ),
      errorBorder: border.copyWith(
        borderSide: const BorderSide(color: kDanger),
      ),
      focusedErrorBorder: border.copyWith(
        borderSide: const BorderSide(color: kDanger, width: 1.6),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(64, 52),
        side: const BorderSide(color: kBorder),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}

// ─── 2. Даты на русском языке (без пакета intl) ─────────────────────────────

const List<String> kMonthsGenitive = [
  'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
  'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря',
];
const List<String> kMonthsShort = [
  'янв', 'фев', 'мар', 'апр', 'май', 'июн',
  'июл', 'авг', 'сен', 'окт', 'ноя', 'дек',
];
const List<String> kWeekdays = [
  'понедельник', 'вторник', 'среда', 'четверг',
  'пятница', 'суббота', 'воскресенье',
];
const List<String> kWeekdaysShort = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

/// Дата без времени (полночь того же дня).
DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Сколько дней от сегодняшнего дня до даты [d]. Отрицательное — в прошлом.
int daysFromToday(DateTime d) {
  final now = DateTime.now();
  return DateTime.utc(d.year, d.month, d.day)
      .difference(DateTime.utc(now.year, now.month, now.day))
      .inDays;
}

/// Выбор формы слова: 1 день, 2 дня, 5 дней.
String plural(int n, String one, String few, String many) {
  final mod10 = n % 10;
  final mod100 = n % 100;
  if (mod10 == 1 && mod100 != 11) return one;
  if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) return few;
  return many;
}

String formatDate(DateTime d) => '${d.day} ${kMonthsGenitive[d.month - 1]}';

String formatDateYear(DateTime d) => '${formatDate(d)} ${d.year} г.';

String formatLongDate(DateTime d) {
  final weekday = kWeekdays[d.weekday - 1];
  return '${weekday[0].toUpperCase()}${weekday.substring(1)}, ${formatDate(d)}';
}

String deadlineText(DateTime d) {
  final days = daysFromToday(d);
  if (days < 0) {
    return 'просрочено на ${-days} ${plural(-days, 'день', 'дня', 'дней')}';
  }
  if (days == 0) return 'сегодня';
  if (days == 1) return 'завтра';
  return 'через $days ${plural(days, 'день', 'дня', 'дней')}';
}

String greeting() {
  final hour = DateTime.now().hour;
  if (hour < 5) return 'Доброй ночи';
  if (hour < 12) return 'Доброе утро';
  if (hour < 18) return 'Добрый день';
  if (hour < 23) return 'Добрый вечер';
  return 'Доброй ночи';
}

// ─── 3. Модели данных ───────────────────────────────────────────────────────

/// Учебные предметы, к которым можно привязать задачу.
const List<String> kSubjects = [
  'Мобильная разработка',
  'Базы данных',
  'Веб-программирование',
  'Английский язык',
  'Казахский язык',
  'Математика',
  'Другое',
];

/// Приоритеты задачи: индекс в списке = значение поля priority.
const List<String> kPriorityNames = ['Низкий', 'Средний', 'Высокий'];
const List<Color> kPriorityColors = [Color(0xFF94A3B8), kWarning, kDanger];

/// Зарегистрированный пользователь.
class AppUser {
  AppUser({
    required this.name,
    required this.email,
    required this.password,
    required this.group,
    required this.registeredAt,
  });

  String name;
  final String email;
  final String password;
  String group; // поле, добавленное в регистрацию: учебная группа студента
  final DateTime registeredAt;

  String get firstName => name.trim().split(RegExp(r'\s+')).first;

  String get initials => name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .take(2)
      .map((part) => part[0].toUpperCase())
      .join();

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'password': password,
        'group': group,
        'registeredAt': registeredAt.toIso8601String(),
      };

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        name: json['name'] as String,
        email: json['email'] as String,
        password: json['password'] as String,
        group: json['group'] as String,
        registeredAt: DateTime.parse(json['registeredAt'] as String),
      );
}

/// Учебная задача: домашнее задание, лабораторная, подготовка к экзамену.
class StudyTask {
  StudyTask({
    required this.id,
    required this.ownerEmail,
    required this.title,
    required this.subject,
    required this.deadline,
    this.priority = 1,
    this.note = '',
    this.done = false,
  });

  final String id;
  final String ownerEmail; // чья задача: у каждого пользователя свой список
  String title;
  String subject;
  DateTime deadline;
  int priority; // 0 — низкий, 1 — средний, 2 — высокий
  String note;
  bool done;

  bool get isOverdue => !done && daysFromToday(deadline) < 0;

  Map<String, dynamic> toJson() => {
        'id': id,
        'ownerEmail': ownerEmail,
        'title': title,
        'subject': subject,
        'deadline': deadline.toIso8601String(),
        'priority': priority,
        'note': note,
        'done': done,
      };

  factory StudyTask.fromJson(Map<String, dynamic> json) => StudyTask(
        id: json['id'] as String,
        ownerEmail: json['ownerEmail'] as String,
        title: json['title'] as String,
        subject: json['subject'] as String,
        deadline: DateTime.parse(json['deadline'] as String),
        priority: json['priority'] as int,
        note: json['note'] as String? ?? '',
        done: json['done'] as bool? ?? false,
      );
}

// ─── 4. Хранилище данных и логика входа ─────────────────────────────────────

/// Единое хранилище приложения. Наследует ChangeNotifier: после каждого
/// изменения вызывает notifyListeners(), и экраны перерисовываются сами.
class AppStore extends ChangeNotifier {
  final Map<String, AppUser> _users = {}; // ключ — почта в нижнем регистре
  final List<StudyTask> _tasks = [];
  String? _currentEmail; // кто сейчас вошёл; null — никто
  bool _rememberMe = false;

  AppUser? get currentUser =>
      _currentEmail == null ? null : _users[_currentEmail];

  /// Задачи текущего пользователя: сначала невыполненные по сроку,
  /// при одинаковом сроке — более важные выше, выполненные в конце.
  List<StudyTask> get myTasks {
    final list = _tasks.where((t) => t.ownerEmail == _currentEmail).toList();
    list.sort((a, b) {
      if (a.done != b.done) return a.done ? 1 : -1;
      final byDate = a.deadline.compareTo(b.deadline);
      if (byDate != 0) return byDate;
      return b.priority.compareTo(a.priority);
    });
    return list;
  }

  // Данные сохраняются в JSON-файл во временном каталоге приложения,
  // поэтому регистрация не теряется после перезапуска на телефоне.
  // В браузере (Flutter Web) доступа к файлам нет — там данные хранятся
  // в памяти до перезагрузки страницы.
  File? get _file {
    if (kIsWeb) return null;
    try {
      return File(
          '${Directory.systemTemp.path}${Platform.pathSeparator}studyflow_data.json');
    } catch (_) {
      return null;
    }
  }

  /// Загрузка сохранённых данных. Вызывается один раз на экране запуска.
  Future<void> load() async {
    final file = _file;
    if (file == null) return;
    try {
      if (!await file.exists()) return;
      final data =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      _users.clear();
      for (final item in data['users'] as List<dynamic>) {
        final user = AppUser.fromJson(item as Map<String, dynamic>);
        _users[user.email] = user;
      }
      _tasks
        ..clear()
        ..addAll((data['tasks'] as List<dynamic>)
            .map((item) => StudyTask.fromJson(item as Map<String, dynamic>)));
      _currentEmail = data['session'] as String?;
      _rememberMe = _currentEmail != null;
    } catch (_) {
      // Файл повреждён — приложение просто начинает с пустыми данными.
    }
    notifyListeners();
  }

  Future<void> _save() async {
    final file = _file;
    if (file == null) return;
    try {
      await file.writeAsString(jsonEncode({
        'users': _users.values.map((u) => u.toJson()).toList(),
        'tasks': _tasks.map((t) => t.toJson()).toList(),
        // Сессию сохраняем, только если включено «Запомнить меня».
        'session': _rememberMe ? _currentEmail : null,
      }));
    } catch (_) {
      // Ошибка записи не должна ломать работу приложения.
    }
  }

  /// Сообщить экранам об изменениях и сохранить данные.
  Future<void> _commit() async {
    notifyListeners();
    await _save();
  }

  /// Регистрация. Возвращает текст ошибки или null, если всё прошло успешно.
  Future<String?> register({
    required String name,
    required String group,
    required String email,
    required String password,
  }) async {
    final key = email.trim().toLowerCase();
    if (_users.containsKey(key)) {
      return 'Пользователь с почтой $key уже зарегистрирован';
    }
    _users[key] = AppUser(
      name: name.trim(),
      email: key,
      password: password,
      group: group.trim().toUpperCase(),
      registeredAt: DateTime.now(),
    );
    _tasks.addAll(_starterTasks(key));
    await _commit();
    return null;
  }

  /// Авторизация. Возвращает текст ошибки или null при успешном входе.
  Future<String?> login({
    required String email,
    required String password,
    required bool remember,
  }) async {
    final user = _users[email.trim().toLowerCase()];
    // Не уточняем, что именно неверно (почта или пароль), — так безопаснее.
    if (user == null || user.password != password) {
      return 'Неверная почта или пароль';
    }
    _currentEmail = user.email;
    _rememberMe = remember;
    await _commit();
    return null;
  }

  /// Выход: сессия удаляется, для закрытых разделов нужен повторный вход.
  Future<void> logout() async {
    _currentEmail = null;
    _rememberMe = false;
    await _commit();
  }

  Future<void> updateProfile({
    required String name,
    required String group,
  }) async {
    final user = currentUser;
    if (user == null) return;
    user.name = name.trim();
    user.group = group.trim().toUpperCase();
    await _commit();
  }

  Future<void> addTask({
    required String title,
    required String subject,
    required DateTime deadline,
    required int priority,
    required String note,
  }) async {
    final email = _currentEmail;
    if (email == null) return;
    _tasks.add(StudyTask(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      ownerEmail: email,
      title: title,
      subject: subject,
      deadline: deadline,
      priority: priority,
      note: note,
    ));
    await _commit();
  }

  /// Поля задачи уже изменены на экране редактирования — остаётся сохранить.
  Future<void> updateTask(StudyTask task) => _commit();

  Future<void> toggleTask(StudyTask task) {
    task.done = !task.done;
    return _commit();
  }

  /// Удаляет задачу и возвращает её позицию, чтобы удаление можно было отменить.
  int deleteTask(StudyTask task) {
    final index = _tasks.indexOf(task);
    _tasks.remove(task);
    _commit();
    return index;
  }

  void restoreTask(int index, StudyTask task) {
    if (index < 0 || index > _tasks.length) {
      _tasks.add(task);
    } else {
      _tasks.insert(index, task);
    }
    _commit();
  }

  /// Примеры задач для нового пользователя, чтобы главная не была пустой.
  List<StudyTask> _starterTasks(String email) {
    final today = dateOnly(DateTime.now());
    DateTime inDays(int n) => DateTime(today.year, today.month, today.day + n);
    return [
      StudyTask(
        id: '$email-1',
        ownerEmail: email,
        title: 'Подготовить пояснительную записку',
        subject: 'Мобильная разработка',
        deadline: inDays(2),
        priority: 2,
        note: 'Введение, теоретическая часть, список литературы',
      ),
      StudyTask(
        id: '$email-2',
        ownerEmail: email,
        title: 'Выучить 20 новых слов по теме IT',
        subject: 'Английский язык',
        deadline: inDays(1),
        priority: 0,
      ),
      StudyTask(
        id: '$email-3',
        ownerEmail: email,
        title: 'Лабораторная работа №3: SQL-запросы',
        subject: 'Базы данных',
        deadline: inDays(5),
        priority: 1,
      ),
      StudyTask(
        id: '$email-4',
        ownerEmail: email,
        title: 'Прочитать лекцию о виджетах Flutter',
        subject: 'Мобильная разработка',
        deadline: today,
        priority: 1,
        done: true,
      ),
    ];
  }
}

/// Один экземпляр хранилища на всё приложение.
final AppStore store = AppStore();

// ─── 5. Проверка вводимых данных ────────────────────────────────────────────
// Каждый метод возвращает текст ошибки или null, если значение верное.
// Эти методы передаются в параметр validator полей TextFormField.

class Validators {
  static final RegExp _email = RegExp(r'^[\w.+-]+@[\w-]+(\.[\w-]+)*\.[A-Za-z]{2,}$');
  static final RegExp _group =
      RegExp(r'^[A-Za-zА-Яа-яЁёӘәҒғҚқҢңӨөҰұҮүҺһІі]{1,5}-?\d{3,4}$');
  static final RegExp _letters = RegExp(r'[A-Za-zА-Яа-яЁёӘәҒғҚқҢңӨөҰұҮүҺһІі]');
  static final RegExp _digits = RegExp(r'\d');

  static String? name(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Введите имя и фамилию';
    if (text.length < 2) return 'Слишком короткое имя';
    if (_digits.hasMatch(text)) return 'Имя не должно содержать цифры';
    return null;
  }

  static String? group(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Введите учебную группу';
    if (!_group.hasMatch(text)) return 'Формат: буквы и цифры, например ПО2408';
    return null;
  }

  static String? email(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Введите электронную почту';
    if (!_email.hasMatch(text)) return 'Неверный формат почты, пример: name@mail.kz';
    return null;
  }

  /// Пароль при регистрации: не короче 6 символов, есть буквы и цифры.
  static String? newPassword(String? value) {
    final text = value ?? '';
    if (text.isEmpty) return 'Введите пароль';
    if (text.length < 6) return 'Пароль должен быть не короче 6 символов';
    if (!_letters.hasMatch(text) || !_digits.hasMatch(text)) {
      return 'Пароль должен содержать буквы и цифры';
    }
    return null;
  }

  /// Пароль при входе: достаточно, чтобы поле не было пустым.
  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Введите пароль';
    return null;
  }

  static String? taskTitle(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Введите название задачи';
    if (text.length < 3) return 'Название должно быть не короче 3 символов';
    return null;
  }
}

// ─── 6. Приложение и маршруты ───────────────────────────────────────────────

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StudyFlow',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      initialRoute: AppRoutes.splash,
      routes: {
        AppRoutes.splash: (context) => const SplashScreen(),
        AppRoutes.login: (context) => const LoginScreen(),
        AppRoutes.register: (context) => const RegisterScreen(),
        // Закрытый маршрут: без входа вместо главной откроется авторизация.
        AppRoutes.home: (context) => store.currentUser == null
            ? const LoginScreen()
            : const HomeShell(),
      },
    );
  }
}

// ─── 7. Экран запуска ───────────────────────────────────────────────────────

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
    _start();
  }

  Future<void> _start() async {
    // Одновременно загружаем сохранённые данные и показываем заставку 2,5 с.
    await Future.wait([
      store.load(),
      Future<void>.delayed(const Duration(milliseconds: 2500)),
    ]);
    if (!mounted) return;
    // Если пользователь выбрал «Запомнить меня», сразу открываем главную.
    final next = store.currentUser != null ? AppRoutes.home : AppRoutes.login;
    Navigator.pushReplacementNamed(context, next);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appear = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: kBrandGradient),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: FadeTransition(
                    opacity: _controller,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.7, end: 1).animate(appear),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AppLogo(size: 112, inverted: true),
                          SizedBox(height: 24),
                          Text(
                            'StudyFlow',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Планировщик учёбы студента',
                            style: TextStyle(color: Colors.white70, fontSize: 16),
                          ),
                          SizedBox(height: 48),
                          SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 20),
                child: Text(
                  'ПО2408 · Айткужинов Амир',
                  style: TextStyle(color: Colors.white60, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── 8. Экран авторизации ───────────────────────────────────────────────────

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _hidePassword = true;
  bool _remember = true;
  bool _submitted = false; // после первой попытки ошибки обновляются при вводе
  bool _loading = false;
  String? _error; // сообщение о неверной авторизации

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _submitted = true;
      _error = null;
    });
    // 1) Проверка формы: пустые поля и неверный формат почты.
    if (!_formKey.currentState!.validate()) return;

    // 2) Проверка почты и пароля по сохранённым пользователям.
    setState(() => _loading = true);
    final error = await store.login(
      email: _emailController.text,
      password: _passwordController.text,
      remember: _remember,
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    // 3) Успешный вход: открываем главную и убираем экраны входа из истории,
    //    чтобы кнопка «Назад» не возвращала на авторизацию.
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (route) => false);
  }

  Future<void> _openRegister() async {
    final messenger = ScaffoldMessenger.of(context);
    // Экран регистрации возвращает почту нового пользователя.
    final email = await Navigator.pushNamed(context, AppRoutes.register);
    if (!mounted || email is! String) return;
    // Сбрасываем старые ошибки формы и подставляем почту нового пользователя.
    _formKey.currentState?.reset();
    setState(() {
      _emailController.text = email;
      _submitted = false;
      _error = null;
    });
    messenger.showSnackBar(const SnackBar(
      content: Text('Аккаунт создан. Введите пароль, чтобы войти'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      title: 'Вход в StudyFlow',
      subtitle: 'Войдите, чтобы увидеть свои задачи и дедлайны',
      child: Form(
        key: _formKey,
        autovalidateMode:
            _submitted ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'Электронная почта',
                hintText: 'name@mail.kz',
                prefixIcon: Icon(Icons.alternate_email_rounded),
              ),
              validator: Validators.email,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _passwordController,
              obscureText: _hidePassword,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: 'Пароль',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  tooltip: _hidePassword ? 'Показать пароль' : 'Скрыть пароль',
                  icon: Icon(_hidePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _hidePassword = !_hidePassword),
                ),
              ),
              validator: Validators.password,
            ),
            const SizedBox(height: 4),
            CheckboxListTile(
              value: _remember,
              onChanged: (value) => setState(() => _remember = value ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: const Text('Запомнить меня', style: TextStyle(fontSize: 14)),
            ),
            if (_error != null) ...[
              ErrorBanner(message: _error!),
              const SizedBox(height: 12),
            ],
            FilledButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : const Text('Войти'),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Нет аккаунта?', style: TextStyle(color: kMuted)),
                TextButton(
                  onPressed: _openRegister,
                  child: const Text('Зарегистрироваться'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 9. Экран регистрации ───────────────────────────────────────────────────

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _groupController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _hidePassword = true;
  bool _agree = false;
  bool _submitted = false; // была ли попытка отправить форму
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _groupController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _submitted = true;
      _error = null;
    });
    // Проверяются все поля сразу; согласие проверяется отдельно.
    final formValid = _formKey.currentState!.validate();
    if (!formValid || !_agree) return;

    setState(() => _loading = true);
    final email = _emailController.text.trim().toLowerCase();
    final error = await store.register(
      name: _nameController.text,
      group: _groupController.text,
      email: email,
      password: _passwordController.text,
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (error != null) {
      setState(() => _error = error); // например, почта уже занята
      return;
    }
    // Возвращаемся на экран входа и передаём туда почту.
    Navigator.pop(context, email);
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      title: 'Создание аккаунта',
      subtitle: 'Заполните данные, чтобы начать планировать учёбу',
      showBack: true,
      child: Form(
        key: _formKey,
        autovalidateMode:
            _submitted ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Имя и фамилия',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
              validator: Validators.name,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _groupController,
              textCapitalization: TextCapitalization.characters,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Учебная группа',
                hintText: 'ПО2408',
                prefixIcon: Icon(Icons.groups_outlined),
              ),
              validator: Validators.group,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'Электронная почта',
                hintText: 'name@mail.kz',
                prefixIcon: Icon(Icons.alternate_email_rounded),
              ),
              validator: Validators.email,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _passwordController,
              obscureText: _hidePassword,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Пароль',
                helperText: 'Не менее 6 символов, буквы и цифры',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  tooltip: _hidePassword ? 'Показать пароль' : 'Скрыть пароль',
                  icon: Icon(_hidePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _hidePassword = !_hidePassword),
                ),
              ),
              validator: Validators.newPassword,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _confirmController,
              obscureText: _hidePassword,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Повторите пароль',
                prefixIcon: Icon(Icons.lock_reset_rounded),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Повторите пароль';
                if (value != _passwordController.text) return 'Пароли не совпадают';
                return null;
              },
            ),
            const SizedBox(height: 6),
            CheckboxListTile(
              value: _agree,
              onChanged: (value) => setState(() => _agree = value ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: const Text(
                'Согласен на обработку персональных данных',
                style: TextStyle(fontSize: 14),
              ),
              subtitle: _submitted && !_agree
                  ? const Text(
                      'Нужно согласие, чтобы создать аккаунт',
                      style: TextStyle(color: kDanger, fontSize: 12),
                    )
                  : null,
            ),
            const SizedBox(height: 8),
            if (_error != null) ...[
              ErrorBanner(message: _error!),
              const SizedBox(height: 12),
            ],
            FilledButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : const Text('Создать аккаунт'),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Уже есть аккаунт?', style: TextStyle(color: kMuted)),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Войти'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 10. Оболочка с нижней навигацией ───────────────────────────────────────

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0; // 0 — главная, 1 — задачи, 2 — профиль

  void _openTab(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    // ListenableBuilder перестраивает экраны при любом изменении в store.
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final user = store.currentUser;
        if (user == null) return const Scaffold(); // идёт выход из аккаунта
        return Scaffold(
          body: SafeArea(
            // IndexedStack хранит все вкладки и показывает выбранную,
            // поэтому поиск и фильтр в задачах не сбрасываются.
            child: IndexedStack(
              index: _index,
              children: [
                HomeTab(user: user, onOpenTab: _openTab),
                const TasksTab(),
                ProfileTab(user: user),
              ],
            ),
          ),
          floatingActionButton: _index == 1
              ? FloatingActionButton.extended(
                  onPressed: () => openTaskForm(context),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Задача'),
                )
              : null,
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: _openTab,
            backgroundColor: Colors.white,
            indicatorColor: kPrimary.withAlpha(36),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded, color: kPrimary),
                label: 'Главная',
              ),
              NavigationDestination(
                icon: Icon(Icons.checklist_rounded),
                selectedIcon: Icon(Icons.checklist_rounded, color: kPrimary),
                label: 'Задачи',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline_rounded),
                selectedIcon: Icon(Icons.person_rounded, color: kPrimary),
                label: 'Профиль',
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── 11. Главная страница ───────────────────────────────────────────────────

const List<String> kTips = [
  'Разбивайте большую задачу на шаги по 25 минут — так легче начать (метод «Помидора»).',
  'Самое сложное делайте утром, пока внимание свежее.',
  'Записывайте задание сразу, как только его задали: память подводит.',
  'Ставьте себе срок на день раньше настоящего дедлайна.',
  'Отмечайте выполненное: видимый прогресс мотивирует продолжать.',
  'Повторяйте материал через день, через неделю и через месяц.',
  'Планируйте отдых так же, как учёбу, — это тоже часть плана.',
];

class HomeTab extends StatelessWidget {
  const HomeTab({super.key, required this.user, required this.onOpenTab});

  final AppUser user;
  final ValueChanged<int> onOpenTab;

  @override
  Widget build(BuildContext context) {
    final tasks = store.myTasks;
    final done = tasks.where((t) => t.done).length;
    final overdue = tasks.where((t) => t.isOverdue).length;
    final upcoming = tasks.where((t) => !t.done).take(3).toList();
    final today = DateTime.now();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(formatLongDate(today),
                      style: const TextStyle(color: kMuted, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(
                    '${greeting()}, ${user.firstName}!',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: kText,
                    ),
                  ),
                ],
              ),
            ),
            InkWell(
              customBorder: const CircleBorder(),
              onTap: () => onOpenTab(2),
              child: UserAvatar(user: user, radius: 24),
            ),
          ],
        ),
        const SizedBox(height: 20),
        ProgressCard(total: tasks.length, done: done, overdue: overdue),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: QuickAction(
                icon: Icons.add_task_rounded,
                label: 'Новая\nзадача',
                color: kPrimary,
                onTap: () => openTaskForm(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: QuickAction(
                icon: Icons.checklist_rounded,
                label: 'Все\nзадачи',
                color: kSuccess,
                onTap: () => onOpenTab(1),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: QuickAction(
                icon: Icons.person_rounded,
                label: 'Мой\nпрофиль',
                color: kWarning,
                onTap: () => onOpenTab(2),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        SectionTitle(
          title: 'Ближайшие дедлайны',
          actionLabel: 'Все',
          onAction: () => onOpenTab(1),
        ),
        const SizedBox(height: 8),
        if (upcoming.isEmpty)
          const EmptyState(
            icon: Icons.celebration_outlined,
            title: 'Все задачи выполнены',
            subtitle: 'Добавьте новую задачу, когда появится задание',
          )
        else
          for (final task in upcoming)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: TaskTile(task: task),
            ),
        const SizedBox(height: 14),
        TipCard(text: kTips[(today.weekday - 1) % kTips.length]),
      ],
    );
  }
}

class ProgressCard extends StatelessWidget {
  const ProgressCard({
    super.key,
    required this.total,
    required this.done,
    required this.overdue,
  });

  final int total;
  final int done;
  final int overdue;

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : done / total;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: kBrandGradient,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: kPrimary.withAlpha(60),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Прогресс по задачам',
                        style: TextStyle(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 6),
                    Text(
                      '$done из $total выполнено',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 58,
                height: 58,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(40),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${(progress * 100).round()}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              color: Colors.white,
              backgroundColor: Colors.white24,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _MiniStat(label: 'Активные', value: total - done),
              _MiniStat(label: 'Просрочено', value: overdue),
              _MiniStat(label: 'Готово', value: done),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$value',
              style: const TextStyle(
                  color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }
}

class QuickAction extends StatelessWidget {
  const QuickAction({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: kText,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TipCard extends StatelessWidget {
  const TipCard({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFDE2A7)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_outline_rounded, color: kWarning),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Совет дня',
                    style: TextStyle(fontWeight: FontWeight.w700, color: kText)),
                const SizedBox(height: 4),
                Text(text, style: const TextStyle(color: kText, height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 12. Основной раздел — задачи ───────────────────────────────────────────

enum TaskFilter { all, active, done }

const Map<TaskFilter, String> kFilterNames = {
  TaskFilter.all: 'Все',
  TaskFilter.active: 'Активные',
  TaskFilter.done: 'Выполненные',
};

class TasksTab extends StatefulWidget {
  const TasksTab({super.key});

  @override
  State<TasksTab> createState() => _TasksTabState();
}

class _TasksTabState extends State<TasksTab> {
  TaskFilter _filter = TaskFilter.all;
  String _query = '';

  bool _matches(StudyTask task) {
    final byStatus = _filter == TaskFilter.all ||
        (_filter == TaskFilter.active ? !task.done : task.done);
    final query = _query.trim().toLowerCase();
    final byQuery = query.isEmpty ||
        task.title.toLowerCase().contains(query) ||
        task.subject.toLowerCase().contains(query);
    return byStatus && byQuery;
  }

  void _delete(StudyTask task) {
    final index = store.deleteTask(task);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text('Задача «${task.title}» удалена'),
        action: SnackBarAction(
          label: 'Отменить',
          onPressed: () => store.restoreTask(index, task),
        ),
      ));
  }

  @override
  Widget build(BuildContext context) {
    // Вкладка сама слушает store: список обновляется сразу после
    // добавления, удаления или отметки задачи.
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) => _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final all = store.myTasks;
    final active = all.where((t) => !t.done).length;
    final tasks = all.where(_matches).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Мои задачи',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: kText),
              ),
              const SizedBox(height: 4),
              Text(
                'Активных: $active из ${all.length}',
                style: const TextStyle(color: kMuted),
              ),
              const SizedBox(height: 14),
              TextField(
                onChanged: (value) => setState(() => _query = value),
                decoration: const InputDecoration(
                  hintText: 'Поиск по названию или предмету',
                  prefixIcon: Icon(Icons.search_rounded),
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  for (final filter in TaskFilter.values)
                    ChoiceChip(
                      label: Text(kFilterNames[filter]!),
                      selected: _filter == filter,
                      onSelected: (_) => setState(() => _filter = filter),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: tasks.isEmpty
              ? ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    EmptyState(
                      icon: Icons.inbox_outlined,
                      title: all.isEmpty ? 'Задач пока нет' : 'Ничего не найдено',
                      subtitle: all.isEmpty
                          ? 'Нажмите «Задача», чтобы добавить первую'
                          : 'Измените фильтр или текст поиска',
                    ),
                  ],
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
                  itemCount: tasks.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    // Свайп влево удаляет задачу; удаление можно отменить.
                    return Dismissible(
                      key: ValueKey(task.id),
                      direction: DismissDirection.endToStart,
                      onDismissed: (_) => _delete(task),
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 24),
                        decoration: BoxDecoration(
                          color: kDanger,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.delete_outline_rounded,
                            color: Colors.white),
                      ),
                      child: TaskTile(task: task),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

/// Карточка задачи: отметка выполнения, название, предмет, срок и приоритет.
class TaskTile extends StatelessWidget {
  const TaskTile({super.key, required this.task});

  final StudyTask task;

  @override
  Widget build(BuildContext context) {
    final days = daysFromToday(task.deadline);
    final Color deadlineColor = task.done
        ? kMuted
        : task.isOverdue
            ? kDanger
            : days <= 1
                ? const Color(0xFFB45309)
                : kMuted;
    final deadlineLabel = task.done ? 'выполнено' : deadlineText(task.deadline);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => openTaskForm(context, task: task),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 10, 14, 10),
          child: Row(
            children: [
              Checkbox(
                value: task.done,
                shape: const CircleBorder(),
                onChanged: (_) => store.toggleTask(task),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w600,
                        color: task.done ? kMuted : kText,
                        decoration: task.done ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Tag(text: task.subject, color: kPrimary),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.schedule_rounded, size: 14, color: deadlineColor),
                            const SizedBox(width: 3),
                            Text(
                              '${formatDate(task.deadline)} · $deadlineLabel',
                              style: TextStyle(fontSize: 12.5, color: deadlineColor),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Tooltip(
                message: 'Приоритет: ${kPriorityNames[task.priority].toLowerCase()}',
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: kPriorityColors[task.priority],
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Открывает экран задачи (новой или существующей) и показывает итог.
Future<void> openTaskForm(BuildContext context, {StudyTask? task}) async {
  final messenger = ScaffoldMessenger.of(context);
  final message = await Navigator.push<String>(
    context,
    MaterialPageRoute(builder: (context) => TaskFormScreen(task: task)),
  );
  if (message != null) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

// ─── 13. Экран добавления и редактирования задачи ───────────────────────────

class TaskFormScreen extends StatefulWidget {
  const TaskFormScreen({super.key, this.task});

  /// null — создаётся новая задача, иначе редактируется существующая.
  final StudyTask? task;

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _noteController;
  late final ScrollController _daysController;
  late String _subject;
  late DateTime _deadline;
  late int _priority;
  late bool _done;
  bool _submitted = false;

  bool get _isEdit => widget.task != null;

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    _titleController = TextEditingController(text: task?.title ?? '');
    _noteController = TextEditingController(text: task?.note ?? '');
    _subject = task?.subject ?? kSubjects.first;
    _deadline = dateOnly(task?.deadline ?? DateTime.now().add(const Duration(days: 1)));
    _priority = task?.priority ?? 1;
    _done = task?.done ?? false;
    // Лента дат сразу прокручивается к выбранному сроку (ширина дня 58 + отступ 8).
    final index = _days.indexOf(_deadline);
    _daysController = ScrollController(
      initialScrollOffset: index > 1 ? (index - 1) * 66.0 : 0,
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    _daysController.dispose();
    super.dispose();
  }

  /// Дни для выбора срока: сегодня и следующие 29 дней.
  List<DateTime> get _days {
    final today = dateOnly(DateTime.now());
    final days = List.generate(
        30, (i) => DateTime(today.year, today.month, today.day + i));
    // У просроченной задачи старый срок тоже показываем в списке.
    if (!days.contains(_deadline)) {
      days
        ..add(_deadline)
        ..sort();
    }
    return days;
  }

  Future<void> _save() async {
    setState(() => _submitted = true);
    if (!_formKey.currentState!.validate()) return;
    final title = _titleController.text.trim();
    final note = _noteController.text.trim();
    final task = widget.task;
    if (task != null) {
      task
        ..title = title
        ..subject = _subject
        ..deadline = _deadline
        ..priority = _priority
        ..note = note
        ..done = _done;
      await store.updateTask(task);
    } else {
      await store.addTask(
        title: title,
        subject: _subject,
        deadline: _deadline,
        priority: _priority,
        note: note,
      );
    }
    if (!mounted) return;
    Navigator.pop(context, _isEdit ? 'Изменения сохранены' : 'Задача добавлена');
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить задачу?'),
        content: Text('Задача «${widget.task!.title}» будет удалена.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: kDanger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    store.deleteTask(widget.task!);
    Navigator.pop(context, 'Задача удалена');
  }

  @override
  Widget build(BuildContext context) {
    final days = _days;
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Редактирование' : 'Новая задача'),
        actions: [
          if (_isEdit)
            IconButton(
              tooltip: 'Удалить задачу',
              icon: const Icon(Icons.delete_outline_rounded, color: kDanger),
              onPressed: _delete,
            ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          autovalidateMode:
              _submitted ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              TextFormField(
                controller: _titleController,
                maxLength: 60,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Название задачи',
                  hintText: 'Например: лабораторная работа №4',
                  prefixIcon: Icon(Icons.edit_note_rounded),
                ),
                validator: Validators.taskTitle,
              ),
              const SizedBox(height: 8),
              const FieldLabel('Предмет'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final subject in kSubjects)
                    ChoiceChip(
                      label: Text(subject),
                      selected: _subject == subject,
                      onSelected: (_) => setState(() => _subject = subject),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              const FieldLabel('Срок сдачи'),
              SizedBox(
                height: 78,
                child: ListView.separated(
                  controller: _daysController,
                  scrollDirection: Axis.horizontal,
                  itemCount: days.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final day = days[index];
                    final selected = day == _deadline;
                    return InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => setState(() => _deadline = day),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 58,
                        decoration: BoxDecoration(
                          color: selected ? kPrimary : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: selected ? kPrimary : kBorder),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              kWeekdaysShort[day.weekday - 1],
                              style: TextStyle(
                                fontSize: 12,
                                color: selected ? Colors.white70 : kMuted,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${day.day}',
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w700,
                                color: selected ? Colors.white : kText,
                              ),
                            ),
                            Text(
                              kMonthsShort[day.month - 1],
                              style: TextStyle(
                                fontSize: 11,
                                color: selected ? Colors.white70 : kMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Сдать: ${formatLongDate(_deadline).toLowerCase()} (${deadlineText(_deadline)})',
                style: const TextStyle(color: kMuted),
              ),
              const SizedBox(height: 20),
              const FieldLabel('Приоритет'),
              SegmentedButton<int>(
                showSelectedIcon: false,
                segments: [
                  for (var i = 0; i < kPriorityNames.length; i++)
                    ButtonSegment(value: i, label: Text(kPriorityNames[i])),
                ],
                selected: {_priority},
                onSelectionChanged: (value) => setState(() => _priority = value.first),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _noteController,
                maxLength: 200,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Комментарий (необязательно)',
                  alignLabelWithHint: true,
                ),
              ),
              if (_isEdit)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Задача выполнена'),
                  value: _done,
                  onChanged: (value) => setState(() => _done = value),
                ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.check_rounded),
                label: Text(_isEdit ? 'Сохранить изменения' : 'Добавить задачу'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── 14. Профиль, редактирование профиля, выход ─────────────────────────────

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key, required this.user});

  final AppUser user;

  Future<void> _editProfile(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => EditProfileScreen(user: user)),
    );
    if (saved == true) {
      messenger.showSnackBar(const SnackBar(content: Text('Профиль обновлён')));
    }
  }

  void _showAbout(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Center(child: AppLogo(size: 56)),
        title: const Text('StudyFlow 1.0'),
        content: const Text(
          'Планировщик учебных задач для студентов колледжа.\n\n'
          'Курсовой проект по модулю ПМ07 «Разработка мобильных приложений».\n'
          'Автор: Айткужинов Амир, группа ПО2408.\n'
          'Колледж ТОО «Astana IT University», 2026.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tasks = store.myTasks;
    final done = tasks.where((t) => t.done).length;
    final overdue = tasks.where((t) => t.isOverdue).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        const Text(
          'Профиль',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: kText),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: kBrandGradient,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            children: [
              UserAvatar(user: user, radius: 40, inverted: true),
              const SizedBox(height: 12),
              Text(
                user.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(user.email, style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(40),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Группа ${user.group}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            StatBox(value: tasks.length, label: 'Всего задач', color: kPrimary),
            const SizedBox(width: 10),
            StatBox(value: done, label: 'Выполнено', color: kSuccess),
            const SizedBox(width: 10),
            StatBox(value: overdue, label: 'Просрочено', color: kDanger),
          ],
        ),
        const SizedBox(height: 16),
        WhiteCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Column(
            children: [
              InfoRow(icon: Icons.badge_outlined, label: 'Имя и фамилия', value: user.name),
              const Divider(height: 1, color: kBorder),
              InfoRow(
                  icon: Icons.alternate_email_rounded,
                  label: 'Электронная почта',
                  value: user.email),
              const Divider(height: 1, color: kBorder),
              InfoRow(icon: Icons.groups_outlined, label: 'Учебная группа', value: user.group),
              const Divider(height: 1, color: kBorder),
              InfoRow(
                icon: Icons.event_available_outlined,
                label: 'Дата регистрации',
                value: formatDateYear(user.registeredAt),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () => _editProfile(context),
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Редактировать профиль'),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () => _showAbout(context),
          icon: const Icon(Icons.info_outline_rounded),
          label: const Text('О приложении'),
        ),
        const SizedBox(height: 10),
        FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: kDanger),
          onPressed: () => confirmLogout(context),
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Выйти из аккаунта'),
        ),
      ],
    );
  }
}

/// Выход из аккаунта с подтверждением.
Future<void> confirmLogout(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      icon: const Icon(Icons.logout_rounded, color: kDanger),
      title: const Text('Выйти из аккаунта?'),
      content: const Text(
        'Чтобы снова открыть задачи и профиль, нужно будет войти по почте и паролю.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Отмена'),
        ),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: kDanger),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Выйти'),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;
  await store.logout();
  if (!context.mounted) return;
  // Удаляем всю историю экранов: «Назад» не вернёт в закрытые разделы.
  Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
}

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, required this.user});

  final AppUser user;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController =
      TextEditingController(text: widget.user.name);
  late final TextEditingController _groupController =
      TextEditingController(text: widget.user.group);
  bool _submitted = false;

  @override
  void dispose() {
    _nameController.dispose();
    _groupController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _submitted = true);
    if (!_formKey.currentState!.validate()) return;
    await store.updateProfile(
      name: _nameController.text,
      group: _groupController.text,
    );
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Редактирование профиля')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          autovalidateMode:
              _submitted ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              Center(child: UserAvatar(user: widget.user, radius: 40)),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Имя и фамилия',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
                validator: Validators.name,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _groupController,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Учебная группа',
                  prefixIcon: Icon(Icons.groups_outlined),
                ),
                validator: Validators.group,
              ),
              const SizedBox(height: 14),
              TextFormField(
                initialValue: widget.user.email,
                enabled: false,
                decoration: const InputDecoration(
                  labelText: 'Электронная почта (не меняется)',
                  prefixIcon: Icon(Icons.alternate_email_rounded),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.check_rounded),
                label: const Text('Сохранить'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── 15. Общие виджеты ──────────────────────────────────────────────────────

/// Логотип приложения: книга в скруглённом квадрате.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 72, this.inverted = false});

  final double size;
  final bool inverted; // белый логотип для цветного фона

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: inverted ? Colors.white : null,
        gradient: inverted ? null : kBrandGradient,
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(30),
            blurRadius: size * 0.2,
            offset: Offset(0, size * 0.08),
          ),
        ],
      ),
      child: Icon(
        Icons.auto_stories_rounded,
        size: size * 0.55,
        color: inverted ? kPrimary : Colors.white,
      ),
    );
  }
}

/// Общий макет экранов входа и регистрации.
class AuthLayout extends StatelessWidget {
  const AuthLayout({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.showBack = false,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Нажатие на пустое место скрывает клавиатуру.
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: showBack ? AppBar() : null,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(child: AppLogo(size: 68)),
                    const SizedBox(height: 18),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: kText,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: kMuted, fontSize: 15),
                    ),
                    const SizedBox(height: 24),
                    WhiteCard(child: child),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class WhiteCard extends StatelessWidget {
  const WhiteCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1F2333).withAlpha(14),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class ErrorBanner extends StatelessWidget {
  const ErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: kDanger, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message, style: const TextStyle(color: Color(0xFFB91C1C))),
          ),
        ],
      ),
    );
  }
}

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.user,
    this.radius = 24,
    this.inverted = false,
  });

  final AppUser user;
  final double radius;
  final bool inverted;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: inverted ? Colors.white : null,
        gradient: inverted ? null : kBrandGradient,
      ),
      child: Text(
        user.initials,
        style: TextStyle(
          color: inverted ? kPrimary : Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: radius * 0.75,
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: kText,
            ),
          ),
        ),
        if (actionLabel != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ],
    );
  }
}

class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 15,
          color: kText,
        ),
      ),
    );
  }
}

class Tag extends StatelessWidget {
  const Tag({super.key, required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(24),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return WhiteCard(
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: kPrimary.withAlpha(24),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: kPrimary, size: 32),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: kText,
            ),
          ),
          const SizedBox(height: 4),
          Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: kMuted)),
        ],
      ),
    );
  }
}

class StatBox extends StatelessWidget {
  const StatBox({
    super.key,
    required this.value,
    required this.label,
    required this.color,
  });

  final int value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: WhiteCard(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Column(
          children: [
            Text(
              '$value',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(color: kMuted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  const InfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: kPrimary, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: kMuted, fontSize: 12.5)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: kText,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
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
