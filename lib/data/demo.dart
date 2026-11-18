import '../domain/workspace.dart';

Workspace demoWorkspace(DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final created = today.subtract(const Duration(days: 5));
  final tomorrow = today.add(const Duration(days: 1));
  final clients = [
    Client(
      'c1',
      'Marina Costa',
      '(11) 90000-0101',
      'Dados fictícios • Vila Madalena',
    ),
    Client(
      'c2',
      'Lucas Almeida',
      '(11) 90000-0102',
      'Dados fictícios • Pinheiros',
    ),
    Client(
      'c3',
      'Ateliê Aurora',
      '(11) 90000-0103',
      'Dados fictícios • Perdizes',
    ),
  ];
  Job quote(String id, String client, String title, int labor, int materials) =>
      Job.create(
        id: id,
        clientId: client,
        title: title,
        budget: Budget(labor, materials, 0),
        notes: 'Demonstração com dados sintéticos.',
        now: created,
      );
  final scheduled = quote('j1', 'c1', 'Instalação de luminárias', 28000, 6500)
      .schedule(
        tomorrow.add(const Duration(hours: 9)),
        tomorrow.add(const Duration(hours: 11)),
        [],
        created,
      );
  final painting = quote('j2', 'c3', 'Pintura do ateliê', 85000, 24000)
      .schedule(
        tomorrow.add(const Duration(hours: 14)),
        tomorrow.add(const Duration(hours: 18)),
        [scheduled],
        created,
      );
  var completed = quote('j3', 'c2', 'Manutenção de torneiras', 18000, 4500)
      .schedule(
        created.add(const Duration(hours: 9)),
        created.add(const Duration(hours: 10)),
        [],
        created,
      );
  completed = completed
      .transition(JobStatus.active, created.add(const Duration(hours: 9)))
      .transition(JobStatus.completed, created.add(const Duration(hours: 10)));
  return Workspace(
    clients: clients,
    jobs: [
      scheduled,
      painting,
      quote('j4', 'c2', 'Montagem de estante', 22000, 0),
      quote('j5', 'c1', 'Revisão elétrica', 32000, 8000),
      completed,
    ],
  );
}
