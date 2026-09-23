import 'package:flutter_test/flutter_test.dart';
import 'package:hazri/features/reminders/data/reminder_service.dart';
import 'package:hazri/features/reminders/data/reminders_controller.dart';

import '../app_harness.dart';

/// `ReminderScheduler.reschedule()` end to end, which nothing covered before.
///
/// The planner had tests and was right; what was wrong sat either side of it,
/// which is exactly what a unit test of a pure function cannot see.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<TestApp> cold() async {
    final app = await TestApp.create(prefs: {'onboarding_done': true});
    addTearDown(app.dispose);
    return app;
  }

  test('a phone that has never opened the reminders screen still gets them',
      () async {
    // The bug: the defaults were seeded as a side effect of *watching*
    // `remindersProvider`, and the scheduler reads the table directly. So on
    // any phone where that screen was never opened -- including every phone
    // that upgraded into this build with onboarding already done -- the read
    // came back empty, nothing was scheduled, and nothing said so.
    final app = await cold();

    await app.container.read(reminderSchedulerProvider).reschedule();

    expect(await app.userDb.select(app.userDb.reminders).get(), hasLength(5));
    expect(app.reminders.scheduled, isNotEmpty);
  });

  test('every scheduled reminder carries a route to open', () async {
    final app = await cold();
    await app.container.read(reminderSchedulerProvider).reschedule();
    for (final n in app.reminders.scheduled) {
      expect(n.payload, isNotEmpty);
      expect(n.title, isNotEmpty);
      expect(n.body, isNotEmpty);
    }
  });

  test('the Gurpurab notification names the day it is about', () async {
    final app = await cold();
    await app.container.read(reminderSchedulerProvider).reschedule();

    final nights = app.reminders.scheduled
        .where((n) => n.channel == ReminderChannel.gurpurab)
        .toList();

    // Whatever the bundled calendar holds for the week under test, a Gurpurab
    // night must name a real event rather than repeating the screen's own
    // title -- and there cannot be one every night.
    expect(nights.length, lessThan(7));
    for (final n in nights) {
      expect(n.body.trim(), isNotEmpty);
      expect(n.payload, '/gurpurab');
    }
  });

  test('nothing is scheduled when the phone refuses notifications', () async {
    final app = await cold();
    app.reminders.notificationsGranted = false;

    await app.container.read(reminderSchedulerProvider).reschedule();

    expect(app.reminders.scheduled, isEmpty);
  });
}
