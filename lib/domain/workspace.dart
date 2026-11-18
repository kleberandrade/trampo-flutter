/// BRL amounts are integer cents. Input always follows Brazilian notation.
abstract final class Money {
  static const maxCents = 999999999;
  static int parse(String input) {
    final value = input.trim();
    if (!RegExp(r'^(?:\d{1,3}(?:\.\d{3})+|\d+)(?:,\d{1,2})?$')
        .hasMatch(value)) {
      throw const FormatException('money');
    }
    final parts = value.replaceAll('.', '').split(',');
    final whole = int.tryParse(parts[0]);
    if (whole == null || whole > maxCents ~/ 100) {
      throw const FormatException('money');
    }
    final cents =
        whole * 100 +
        (parts.length == 2 ? int.parse(parts[1].padRight(2, '0')) : 0);
    if (cents > maxCents) throw const FormatException('money');
    return cents;
  }

  static String input(int cents) =>
      '${cents ~/ 100},${(cents % 100).toString().padLeft(2, '0')}';
  static String format(int cents) {
    final whole = (cents ~/ 100).toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
    return 'R\$ $whole,${(cents % 100).toString().padLeft(2, '0')}';
  }
}

class Budget {
  final int labor, materials, discount;
  Budget(this.labor, this.materials, this.discount) {
    if ([labor, materials, discount].any((v) => v < 0 || v > Money.maxCents) ||
        discount > labor + materials ||
        total > Money.maxCents) {
      throw ArgumentError('budget');
    }
  }
  int get total => labor + materials - discount;
  Map<String, dynamic> toJson() => {
    'labor': labor,
    'materials': materials,
    'discount': discount,
  };
  factory Budget.fromJson(Map<String, dynamic> json) => Budget(
    json['labor'] as int,
    json['materials'] as int,
    json['discount'] as int,
  );
}

String _text(String value, int max, {bool required = false}) {
  final result = value.trim();
  if ((required && result.isEmpty) || result.length > max) {
    throw ArgumentError('text');
  }
  return result;
}

class Client {
  final String id, name, phone, notes;
  Client(String id, String name, String phone, String notes)
    : id = _text(id, 100, required: true),
      name = _text(name, 100, required: true),
      phone = _text(phone, 50),
      notes = _text(notes, 1000);
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phone': phone,
    'notes': notes,
  };
  factory Client.fromJson(Map<String, dynamic> json) => Client(
    json['id'] as String,
    json['name'] as String,
    json['phone'] as String,
    json['notes'] as String,
  );
}

enum JobStatus { quote, scheduled, active, completed, cancelled }

class JobEvent {
  final DateTime at;
  final JobStatus status;
  final String action, title, clientId;
  final int total;
  JobEvent(
    this.at,
    this.status,
    this.action,
    this.title,
    this.total,
    this.clientId,
  );
  Map<String, dynamic> toJson() => {
    'at': at.toUtc().toIso8601String(),
    'status': status.name,
    'action': action,
    'title': title,
    'total': total,
    'clientId': clientId,
  };
  factory JobEvent.fromJson(
    Map<String, dynamic> json, {
    required String fallbackClientId,
  }) => JobEvent(
    DateTime.parse(json['at'] as String).toLocal(),
    JobStatus.values.byName(json['status'] as String),
    json['action'] as String,
    json['title'] as String,
    json['total'] as int,
    json['clientId'] as String? ?? fallbackClientId,
  );
}

class Job {
  final String id, clientId, title, notes;
  final Budget budget;
  final JobStatus status;
  final DateTime? start, end;
  final List<JobEvent> history;
  Job._(
    this.id,
    this.clientId,
    this.title,
    this.notes,
    this.budget,
    this.status,
    this.start,
    this.end,
    List<JobEvent> events,
  ) : history = List.unmodifiable(events);
  factory Job.create({
    required String id,
    required String clientId,
    required String title,
    String notes = '',
    required Budget budget,
    required DateTime now,
  }) {
    final validTitle = _text(title, 120, required: true);
    return Job._(
      _text(id, 100, required: true),
      _text(clientId, 100, required: true),
      validTitle,
      _text(notes, 2000),
      budget,
      JobStatus.quote,
      null,
      null,
      [
        JobEvent(
          now,
          JobStatus.quote,
          'created',
          validTitle,
          budget.total,
          clientId,
        ),
      ],
    );
  }
  bool get reservesTime =>
      status == JobStatus.scheduled || status == JobStatus.active;
  bool get editable =>
      status == JobStatus.quote || status == JobStatus.scheduled;
  List<JobStatus> get nextStatuses => switch (status) {
    JobStatus.quote => [JobStatus.cancelled],
    JobStatus.scheduled => [JobStatus.active, JobStatus.cancelled],
    JobStatus.active => [JobStatus.completed, JobStatus.cancelled],
    _ => [],
  };
  void _checkClock(DateTime now) {
    if (now.isBefore(history.last.at)) throw StateError('clock');
  }

  Job schedule(DateTime from, DateTime to, Iterable<Job> others, DateTime now) {
    if (!editable) throw StateError('transition');
    if (!to.isAfter(from) ||
        to.difference(from) > const Duration(hours: 24) ||
        from.isBefore(now)) {
      throw ArgumentError('dates');
    }
    for (final other in others) {
      if (other.id != id &&
          other.reservesTime &&
          from.isBefore(other.end!) &&
          to.isAfter(other.start!)) {
        throw StateError('conflict');
      }
    }
    _checkClock(now);
    return Job._(
      id,
      clientId,
      title,
      notes,
      budget,
      JobStatus.scheduled,
      from,
      to,
      [
        ...history,
        JobEvent(
          now,
          JobStatus.scheduled,
          'scheduled',
          title,
          budget.total,
          clientId,
        ),
      ],
    );
  }

  Job transition(JobStatus target, DateTime now) {
    if (!nextStatuses.contains(target)) throw StateError('transition');
    _checkClock(now);
    if (target == JobStatus.active && now.isBefore(start!)) {
      throw StateError('early');
    }
    return Job._(id, clientId, title, notes, budget, target, start, end, [
      ...history,
      JobEvent(now, target, 'status', title, budget.total, clientId),
    ]);
  }

  Job edit({
    required String clientId,
    required String title,
    required String notes,
    required Budget budget,
    required DateTime now,
  }) {
    if (!editable) throw StateError('transition');
    _checkClock(now);
    final validTitle = _text(title, 120, required: true);
    return Job._(
      id,
      _text(clientId, 100, required: true),
      validTitle,
      _text(notes, 2000),
      budget,
      status,
      start,
      end,
      [
        ...history,
        JobEvent(now, status, 'edited', validTitle, budget.total, clientId),
      ],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'clientId': clientId,
    'title': title,
    'notes': notes,
    'budget': budget.toJson(),
    'status': status.name,
    'start': start?.toUtc().toIso8601String(),
    'end': end?.toUtc().toIso8601String(),
    'history': history.map((e) => e.toJson()).toList(),
  };
  static bool _validEvent(JobStatus previous, JobEvent event) =>
      switch (event.action) {
        'edited' =>
          event.status == previous &&
              (previous == JobStatus.quote || previous == JobStatus.scheduled),
        'scheduled' =>
          event.status == JobStatus.scheduled &&
              (previous == JobStatus.quote || previous == JobStatus.scheduled),
        'status' => switch (previous) {
          JobStatus.quote => event.status == JobStatus.cancelled,
          JobStatus.scheduled =>
            event.status == JobStatus.active ||
                event.status == JobStatus.cancelled,
          JobStatus.active =>
            event.status == JobStatus.completed ||
                event.status == JobStatus.cancelled,
          _ => false,
        },
        _ => false,
      };
  factory Job.fromJson(Map<String, dynamic> json) {
    final job = Job._(
      _text(json['id'] as String, 100, required: true),
      _text(json['clientId'] as String, 100, required: true),
      _text(json['title'] as String, 120, required: true),
      _text(json['notes'] as String, 2000),
      Budget.fromJson(json['budget'] as Map<String, dynamic>),
      JobStatus.values.byName(json['status'] as String),
      json['start'] == null
          ? null
          : DateTime.parse(json['start'] as String).toLocal(),
      json['end'] == null
          ? null
          : DateTime.parse(json['end'] as String).toLocal(),
      (json['history'] as List)
          .map(
            (e) => JobEvent.fromJson(
              e as Map<String, dynamic>,
              fallbackClientId: json['clientId'] as String,
            ),
          )
          .toList(),
    );
    if (job.history.isEmpty ||
        job.history.last.status != job.status ||
        job.history.last.total != job.budget.total ||
        job.history.last.title != job.title ||
        job.history.last.clientId != job.clientId ||
        (job.status == JobStatus.quote && job.start != null) ||
        (job.start == null) != (job.end == null) ||
        (job.status != JobStatus.quote &&
            job.status != JobStatus.cancelled &&
            job.start == null) ||
        (job.start != null &&
            (!job.end!.isAfter(job.start!) ||
                job.end!.difference(job.start!) > const Duration(hours: 24)))) {
      throw const FormatException('job');
    }
    final first = job.history.first;
    if (first.action != 'created' || first.status != JobStatus.quote) {
      throw const FormatException('history');
    }
    for (var i = 0; i < job.history.length; i++) {
      final event = job.history[i];
      if (event.title.trim().isEmpty ||
          event.title.length > 120 ||
          event.total < 0 ||
          event.total > Money.maxCents) {
        throw const FormatException('history');
      }
      if (i == 0) continue;
      final previous = job.history[i - 1];
      if (event.at.isBefore(previous.at) ||
          !_validEvent(previous.status, event)) {
        throw const FormatException('history');
      }
    }
    return job;
  }
}

class Workspace {
  final List<Client> clients;
  final List<Job> jobs;
  final String language;
  Workspace({
    required List<Client> clients,
    required List<Job> jobs,
    this.language = 'pt',
  }) : clients = List.unmodifiable(clients),
       jobs = List.unmodifiable(jobs) {
    final ids = clients.map((c) => c.id).toSet();
    if (!['pt', 'en'].contains(language) ||
        ids.length != clients.length ||
        jobs.map((j) => j.id).toSet().length != jobs.length ||
        jobs.any(
          (j) =>
              !ids.contains(j.clientId) ||
              j.history.any((e) => !ids.contains(e.clientId)),
        )) {
      throw const FormatException('workspace');
    }
    final reserved = jobs.where((j) => j.reservesTime).toList();
    for (var i = 0; i < reserved.length; i++) {
      for (var k = i + 1; k < reserved.length; k++) {
        if (reserved[i].start!.isBefore(reserved[k].end!) &&
            reserved[i].end!.isAfter(reserved[k].start!)) {
          throw const FormatException('conflict');
        }
      }
    }
  }
  Workspace copy({List<Client>? clients, List<Job>? jobs, String? language}) =>
      Workspace(
        clients: clients ?? this.clients,
        jobs: jobs ?? this.jobs,
        language: language ?? this.language,
      );
  Client client(String id) => clients.firstWhere((c) => c.id == id);
  Map<String, dynamic> toJson() => {
    'version': 1,
    'language': language,
    'clients': clients.map((c) => c.toJson()).toList(),
    'jobs': jobs.map((j) => j.toJson()).toList(),
  };
  factory Workspace.fromJson(Map<String, dynamic> json) {
    if (json['version'] != 1) throw const FormatException('version');
    return Workspace(
      clients: (json['clients'] as List)
          .map((c) => Client.fromJson(c as Map<String, dynamic>))
          .toList(),
      jobs: (json['jobs'] as List)
          .map((j) => Job.fromJson(j as Map<String, dynamic>))
          .toList(),
      language: json['language'] as String,
    );
  }
}
