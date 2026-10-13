import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyflow/main.dart';

void main() {
  final file = File('${Directory.systemTemp.path}${Platform.pathSeparator}studyflow_data.json');
  setUp(() { if (file.existsSync()) file.deleteSync(); });
  tearDown(() { if (file.existsSync()) file.deleteSync(); });

  test('register → login(remember) → reload keeps session and tasks', () async {
    final a = AppStore();
    expect(await a.register(name: 'Амир Айткужинов', group: 'по2408', email: 'Amir@Mail.kz', password: 'amir2408'), isNull);
    expect(await a.register(name: 'X', group: 'ПО2408', email: 'amir@mail.kz', password: 'amir2408'), isNotNull);
    expect(await a.login(email: 'amir@mail.kz', password: 'bad', remember: true), 'Неверная почта или пароль');
    expect(await a.login(email: ' AMIR@mail.kz ', password: 'amir2408', remember: true), isNull);
    expect(a.currentUser!.group, 'ПО2408');
    expect(a.myTasks.length, 4);
    await a.addTask(title: 'Test', subject: 'Другое', deadline: DateTime.now(), priority: 2, note: '');
    expect(a.myTasks.length, 5);

    final b = AppStore();
    await b.load();
    expect(b.currentUser?.email, 'amir@mail.kz');
    expect(b.myTasks.length, 5);

    await b.logout();
    final c = AppStore();
    await c.load();
    expect(c.currentUser, isNull);
    expect(await c.login(email: 'amir@mail.kz', password: 'amir2408', remember: false), isNull);
    final d = AppStore();
    await d.load();
    expect(d.currentUser, isNull, reason: 'without remember the session is not restored');
  });

  test('validators', () {
    expect(Validators.email(''), isNotNull);
    expect(Validators.email('amir@mail'), isNotNull);
    expect(Validators.email('amir@mail.kz'), isNull);
    expect(Validators.group('ПО2408'), isNull);
    expect(Validators.group('по-2408'), isNull);
    expect(Validators.group('группа'), isNotNull);
    expect(Validators.newPassword('12345'), isNotNull);
    expect(Validators.newPassword('123456'), isNotNull);
    expect(Validators.newPassword('amir2408'), isNull);
    expect(Validators.name('Амир1'), isNotNull);
    expect(plural(1, 'день', 'дня', 'дней'), 'день');
    expect(plural(3, 'день', 'дня', 'дней'), 'дня');
    expect(plural(11, 'день', 'дня', 'дней'), 'дней');
    expect(plural(22, 'день', 'дня', 'дней'), 'дня');
  });
}
