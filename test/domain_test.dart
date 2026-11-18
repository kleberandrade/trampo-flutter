import 'package:flutter_test/flutter_test.dart';
import 'package:trampo/domain/workspace.dart';

void main() {
  test(
    'BRL parsing never uses floating point and rejects ambiguous inputs',
    () {
      expect(Money.parse('1.234,56'), 123456);
      expect(Money.parse('0,10') + Money.parse('0,20'), 30);
      expect(Money.parse('12'), 1200);
      for (final value in ['-1', '1.2', '1,999', 'abc', '1.23,45', '']) {
        expect(() => Money.parse(value), throwsFormatException);
      }
      expect(Money.format(123456), 'R\$ 1.234,56');
    },
  );
  test('budget calculates cents and validates discounts', () {
    expect(Budget(10010, 20020, 30).total, 30000);
    expect(() => Budget(100, 0, 101), throwsArgumentError);
    expect(() => Budget(-1, 0, 0), throwsArgumentError);
  });
  test('schedule uses half-open intervals and one operator', () {
    final start = DateTime(2026, 11, 18, 9);
    final a = Job.create(
      id: 'a',
      clientId: 'c',
      title: 'Repair',
      budget: Budget(100, 0, 0),
      now: start,
    );
    final other = Job.create(
      id: 'b',
      clientId: 'c',
      title: 'Other',
      budget: Budget(100, 0, 0),
      now: start,
    );
    final scheduled = other.schedule(
      start,
      start.add(const Duration(hours: 1)),
      [],
      start,
    );
    expect(() => a.schedule(start, start, [], start), throwsArgumentError);
    expect(
      () => a.schedule(
        start.add(const Duration(minutes: 30)),
        start.add(const Duration(hours: 2)),
        [scheduled],
        start,
      ),
      throwsStateError,
    );
    expect(
      a.schedule(
        start.add(const Duration(hours: 1)),
        start.add(const Duration(hours: 2)),
        [scheduled],
        start,
      ).status,
      JobStatus.scheduled,
    );
  });
  test('transition guards preserve terminal history and dates', () {
    final now = DateTime(2026, 11, 18, 9);
    var job = Job.create(
      id: 'a',
      clientId: 'c',
      title: 'Repair',
      budget: Budget(100, 0, 0),
      now: now,
    );
    expect(() => job.transition(JobStatus.completed, now), throwsStateError);
    job = job.schedule(now, now.add(const Duration(hours: 1)), [], now);
    expect(
      () => job.transition(
        JobStatus.active,
        now.subtract(const Duration(days: 1)),
      ),
      throwsStateError,
    );
    job = job.transition(JobStatus.active, now);
    job = job.transition(
      JobStatus.completed,
      now.add(const Duration(minutes: 30)),
    );
    expect(job.history.length, 4);
    expect(() => job.transition(JobStatus.cancelled, now), throwsStateError);
    expect(Job.fromJson(job.toJson()).history.last.status, JobStatus.completed);
  });
  test(
    'backup rejects forged totals and impossible historical transitions',
    () {
      final now = DateTime(2026);
      final job = Job.create(
        id: 'a',
        clientId: 'c',
        title: 'Repair',
        budget: Budget(100, 0, 0),
        now: now,
      );
      final forged = job.toJson();
      (forged['history'] as List).last['total'] = 999;
      expect(() => Job.fromJson(forged), throwsFormatException);
      final impossible = job.toJson();
      (impossible['history'] as List).add({
        ...job.history.first.toJson(),
        'action': 'status',
        'status': 'completed',
      });
      impossible['status'] = 'completed';
      impossible['start'] = now.toIso8601String();
      impossible['end'] = now.add(const Duration(hours: 1)).toIso8601String();
      expect(() => Job.fromJson(impossible), throwsFormatException);
    },
  );
  test('snapshot rejects broken references and duplicate identities', () {
    final now = DateTime(2026);
    final job = Job.create(
      id: 'a',
      clientId: 'missing',
      title: 'Repair',
      budget: Budget(1, 0, 0),
      now: now,
    );
    expect(() => Workspace(clients: [], jobs: [job]), throwsFormatException);
    expect(
      () => Workspace(
        clients: [Client('c', 'Ana', '', ''), Client('c', 'Bia', '', '')],
        jobs: [],
      ),
      throwsFormatException,
    );
  });
}
