import 'dart:convert';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import '../data/workspace_store.dart';
import '../domain/workspace.dart';
import 'components.dart';
import 'editors.dart';
import 'job_details.dart';
import 'strings.dart';

class WorkspacePage extends StatefulWidget {
  final WorkspaceStore store;
  const WorkspacePage({required this.store, super.key});
  @override
  State<WorkspacePage> createState() => _WorkspacePageState();
}

class _WorkspacePageState extends State<WorkspacePage> {
  int page = 0;
  String query = '';
  JobStatus? filter;
  DateTime? agendaDate;
  final search = TextEditingController();
  WorkspaceStore get store => widget.store;
  Workspace get w => store.workspace!;
  Strings get s => Strings(store.workspace?.language == 'en');
  List<String> get titles => [
    s.t('Visão geral', 'Overview'),
    s.t('Serviços', 'Services'),
    s.t('Agenda', 'Schedule'),
    s.t('Clientes', 'Clients'),
    s.t('Orçamentos', 'Quotes'),
    s.t('Histórico', 'History'),
  ];
  final icons = const [
    Icons.grid_view_rounded,
    Icons.home_repair_service_outlined,
    Icons.calendar_month_outlined,
    Icons.people_outline,
    Icons.request_quote_outlined,
    Icons.history,
  ];
  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  void navigate(int index) => setState(() {
    page = index;
    query = '';
    search.clear();
    filter = null;
  });
  void report(Object e) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(s.error(e))));
    }
  }

  Future<void> action(Future<void> Function() call) async {
    try {
      await call();
    } catch (e) {
      report(e);
    }
  }

  void createJob() {
    if (w.clients.isEmpty) {
      editClient(context, store, s);
    } else {
      editJob(context, store, s);
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: store,
    builder: (context, _) {
      if (store.loading) {
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 24),
                Text(s.t('Abrindo seu espaço…', 'Opening your workspace…')),
              ],
            ),
          ),
        );
      }
      if (store.error != null || store.workspace == null) {
        return Scaffold(
          body: Center(
            child: SizedBox(
              width: 600,
              child: EmptyState(
                s.t(
                  'Não foi possível abrir os dados',
                  'Could not open your data',
                ),
                s.t(
                  'O armazenamento pode estar indisponível ou ter um formato inválido. Os dados existentes não foram substituídos. Verifique o armazenamento do navegador e tente novamente.',
                  'Storage may be unavailable or have an invalid format. Existing data was not replaced. Check browser storage and retry.',
                ),
                icon: Icons.cloud_off_outlined,
                action: FilledButton(
                  onPressed: store.load,
                  child: Text(s.t('Tentar novamente', 'Retry')),
                ),
              ),
            ),
          ),
        );
      }
      final wide = MediaQuery.sizeOf(context).width >= 1050;
      return Scaffold(
        drawer: wide
            ? null
            : Drawer(
                child: Builder(
                  builder: (drawerContext) =>
                      sidebar(drawerContext: drawerContext),
                ),
              ),
        body: Row(
          children: [
            if (wide) SizedBox(width: 232, child: sidebar()),
            Expanded(
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: wide ? 36 : 16,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        if (!wide)
                          Builder(
                            builder: (context) => IconButton(
                              tooltip: s.t(
                                'Abrir navegação',
                                'Open navigation',
                              ),
                              onPressed: () =>
                                  Scaffold.of(context).openDrawer(),
                              icon: const Icon(Icons.menu),
                            ),
                          ),
                        const Icon(
                          Icons.work_outline_rounded,
                          color: teal,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            s.t('Meu espaço de trabalho', 'My workspace'),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        if (wide)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE4EBDF),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Text(
                              s.t('Demonstração local', 'Local demo'),
                              style: const TextStyle(
                                color: teal,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        const SizedBox(width: 12),
                        LanguageButton(
                          language: 'pt',
                          selected: w.language,
                          onPressed: store.saving
                              ? null
                              : () => action(
                                  () => store.update(
                                    (w) => w.copy(language: 'pt'),
                                  ),
                                ),
                        ),
                        LanguageButton(
                          language: 'en',
                          selected: w.language,
                          onPressed: store.saving
                              ? null
                              : () => action(
                                  () => store.update(
                                    (w) => w.copy(language: 'en'),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                  if (store.saving) const LinearProgressIndicator(minHeight: 2),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        wide ? 36 : 20,
                        14,
                        wide ? 36 : 20,
                        32,
                      ),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1380),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (!wide)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: Text(
                                    s.t(
                                      'DEMONSTRAÇÃO LOCAL · DADOS SINTÉTICOS',
                                      'LOCAL DEMO · SYNTHETIC DATA',
                                    ),
                                    style: const TextStyle(
                                      fontSize: 10,
                                      letterSpacing: 1,
                                      color: teal,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              header(),
                              const SizedBox(height: 26),
                              switch (page) {
                                0 => overview(),
                                1 => services(),
                                2 => agenda(),
                                3 => clients(),
                                4 => services(quotes: true),
                                _ => history(),
                              },
                              const SizedBox(height: 28),
                              Text(
                                s.t(
                                  'Salvo neste navegador • Sem conexão com Firebase • Valores em BRL',
                                  'Saved in this browser • No Firebase connection • Amounts in BRL',
                                ),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: muted,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: wide
            ? null
            : NavigationBar(
                selectedIndex: page < 4 ? page : 1,
                onDestinationSelected: navigate,
                destinations: [
                  for (var i = 0; i < 4; i++)
                    NavigationDestination(
                      icon: Icon(icons[i]),
                      label: titles[i],
                    ),
                ],
              ),
      );
    },
  );
  Widget sidebar({BuildContext? drawerContext}) => Container(
    color: ink,
    child: LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: IntrinsicHeight(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD8ED8A),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.handyman_outlined,
                            color: ink,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: FittedBox(
                            alignment: Alignment.centerLeft,
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'trampo',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                letterSpacing: -1,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      s.t(
                        'Seu trabalho, bem cuidado.',
                        'Good work. Well managed.',
                      ),
                      style: const TextStyle(
                        color: Color(0xFFB5C7C8),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 38),
                    for (var i = 0; i < titles.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Material(
                          color: page == i
                              ? const Color(0xFF315057)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          child: ListTile(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            leading: Icon(
                              icons[i],
                              size: 21,
                              color: page == i
                                  ? const Color(0xFFD8ED8A)
                                  : const Color(0xFFB5C7C8),
                            ),
                            title: Text(
                              titles[i],
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: page == i
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                                fontSize: 14,
                              ),
                            ),
                            selected: page == i,
                            onTap: () {
                              navigate(i);
                              if (drawerContext != null) {
                                Navigator.pop(drawerContext);
                              }
                            },
                          ),
                        ),
                      ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .06),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.devices_outlined,
                            color: Color(0xFFD8ED8A),
                            size: 22,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            s.t('Um espaço só seu', 'A space of your own'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            s.t(
                              'Dados sintéticos. Alterações ficam neste navegador.',
                              'Synthetic data. Changes stay in this browser.',
                            ),
                            style: const TextStyle(
                              color: Color(0xFFB5C7C8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                      ),
                      onPressed: backup,
                      icon: const Icon(Icons.save_alt, size: 18),
                      label: Text(s.t('Backup dos dados', 'Data backup')),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  Widget header() {
    final subtitles = [
      s.t(
        'Menos correria. Mais trabalho bem feito.',
        'Less busywork. More good work.',
      ),
      s.t(
        'Do primeiro combinado à última entrega.',
        'From the first agreement to the final delivery.',
      ),
      s.t('Cada compromisso no seu tempo.', 'Make room for every commitment.'),
      s.t(
        'Pessoas que confiam no seu trabalho.',
        'People who trust your work.',
      ),
      s.t(
        'Combine o escopo, registre cada valor.',
        'Agree on the scope. Record every amount.',
      ),
      s.t(
        'Cada passo do seu trabalho, registrado.',
        'Every step of your work, recorded.',
      ),
    ];
    return LayoutBuilder(
      builder: (context, size) {
        final title = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titles[page],
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 6),
            Text(subtitles[page], style: const TextStyle(color: muted)),
          ],
        );
        final button = FilledButton.icon(
          onPressed: store.saving
              ? null
              : page == 3
              ? () => editClient(context, store, s)
              : createJob,
          icon: const Icon(Icons.add, size: 20),
          label: Text(
            page == 3
                ? s.t('Novo cliente', 'New client')
                : s.t('Novo orçamento', 'New quote'),
          ),
        );
        return size.maxWidth < 650
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [title, const SizedBox(height: 18), button],
              )
            : Row(
                children: [
                  Expanded(child: title),
                  const SizedBox(width: 20),
                  button,
                ],
              );
      },
    );
  }

  Widget overview() {
    final upcoming = w.jobs.where((j) => j.reservesTime).toList()
      ..sort((a, b) => a.start!.compareTo(b.start!));
    final quotes = w.jobs.where((j) => j.status == JobStatus.quote).toList();
    final completed = w.jobs.where((j) => j.status == JobStatus.completed);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: teal,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.t(
                        'ORGANIZAR É ABRIR CAMINHO',
                        'MAKE SPACE FOR GOOD WORK',
                      ),
                      style: const TextStyle(
                        color: Color(0xFFD8ED8A),
                        letterSpacing: 1.5,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      s.t(
                        'Seu próximo trampo\ncomeça aqui.',
                        'Your next good job\nstarts here.',
                      ),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        height: 1.16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      s.t(
                        'Clientes, agenda e orçamentos no mesmo lugar.',
                        'Clients, schedules and quotes in one place.',
                      ),
                      style: const TextStyle(color: Color(0xFFE0F0E9)),
                    ),
                  ],
                ),
              ),
              if (MediaQuery.sizeOf(context).width > 750)
                Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: .2),
                      width: 20,
                    ),
                  ),
                  child: const Icon(
                    Icons.task_alt_rounded,
                    size: 75,
                    color: Color(0xFFD8ED8A),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        LayoutBuilder(
          builder: (context, size) {
            final count = size.maxWidth > 800 ? 4 : 2;
            final values = [
              (
                '${upcoming.length}',
                s.t('Na agenda', 'Scheduled'),
                Icons.calendar_today_outlined,
              ),
              (
                '${quotes.length}',
                s.t('Aguardando aprovação', 'Awaiting approval'),
                Icons.request_quote_outlined,
              ),
              (
                Money.format(completed.fold(0, (v, j) => v + j.budget.total)),
                s.t('Serviços concluídos¹', 'Completed services¹'),
                Icons.task_alt,
              ),
              (
                '${w.clients.length}',
                s.t('Clientes cadastrados', 'Registered clients'),
                Icons.people_outline,
              ),
            ];
            return Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                for (var i = 0; i < values.length; i++)
                  SizedBox(
                    width: (size.maxWidth - (count - 1) * 14) / count,
                    child: Surface(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(values[i].$3, color: teal, size: 22),
                          const SizedBox(height: 18),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              values[i].$1,
                              style: const TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.w800,
                                color: ink,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            values[i].$2,
                            style: const TextStyle(color: muted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 10),
        Text(
          s.t(
            '¹ Valor dos serviços, sem controle de recebimento ou pagamento.',
            '¹ Service value; does not track receipts or payments.',
          ),
          style: const TextStyle(color: muted, fontSize: 11),
        ),
        const SizedBox(height: 24),
        sectionTitle(
          s.t('Próximos compromissos', 'Upcoming work'),
          s.t('Ver agenda', 'View schedule'),
          () => navigate(2),
        ),
        const SizedBox(height: 14),
        if (upcoming.isEmpty)
          EmptyState(
            s.t('Agenda livre', 'A clear schedule'),
            s.t(
              'Aprove um orçamento para reservar um horário.',
              'Approve a quote to reserve a time slot.',
            ),
          )
        else
          for (final j in upcoming.take(3)) jobCard(j),
        const SizedBox(height: 20),
        sectionTitle(
          s.t('No radar', 'On your radar'),
          s.t('Ver orçamentos', 'View quotes'),
          () => navigate(4),
        ),
        const SizedBox(height: 14),
        if (quotes.isEmpty)
          EmptyState(
            s.t('Tudo em dia', 'All caught up'),
            s.t(
              'Novos orçamentos aparecerão aqui.',
              'New quotes will appear here.',
            ),
          )
        else
          for (final j in quotes.take(2)) jobCard(j),
      ],
    );
  }

  Widget sectionTitle(String title, String link, VoidCallback onTap) => Row(
    children: [
      Expanded(
        child: Text(title, style: Theme.of(context).textTheme.titleLarge),
      ),
      TextButton(onPressed: onTap, child: Text(link)),
    ],
  );
  Widget jobCard(Job job) {
    final overdue = job.reservesTime && job.end!.isBefore(DateTime.now());
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE1E7E3)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => showJob(context, store, s, job.id),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: LayoutBuilder(
              builder: (context, size) {
                final details = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      w.client(job.clientId).name,
                      style: const TextStyle(color: muted),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        StatusChip(job.status, s),
                        if (job.start != null)
                          Text(
                            '${s.date(job.start!)} — ${s.clock(job.end!)}',
                            style: const TextStyle(color: muted, fontSize: 12),
                          ),
                        if (overdue)
                          Text(
                            s.t('Requer atualização', 'Update needed'),
                            style: const TextStyle(
                              color: Color(0xFF78520C),
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ],
                );
                final amount = Text(
                  Money.format(job.budget.total),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: ink,
                  ),
                );
                return size.maxWidth < 520
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [details, const SizedBox(height: 14), amount],
                      )
                    : Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: paper,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.handyman_outlined,
                              color: teal,
                            ),
                          ),
                          const SizedBox(width: 18),
                          Expanded(child: details),
                          const SizedBox(width: 20),
                          amount,
                          const SizedBox(width: 20),
                          const Icon(
                            Icons.arrow_forward,
                            color: muted,
                            size: 20,
                          ),
                        ],
                      );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget searchBox({bool clientsOnly = false}) => TextField(
    controller: search,
    onChanged: (v) => setState(() => query = v.trim().toLowerCase()),
    decoration: InputDecoration(
      prefixIcon: const Icon(Icons.search),
      hintText: clientsOnly
          ? s.t('Buscar clientes', 'Search clients')
          : s.t('Buscar por serviço ou cliente', 'Search services or clients'),
      suffixIcon: query.isEmpty
          ? null
          : IconButton(
              tooltip: s.t('Limpar busca', 'Clear search'),
              onPressed: () => setState(() {
                query = '';
                search.clear();
              }),
              icon: const Icon(Icons.close),
            ),
    ),
  );
  bool matches(Job j) => '${j.title} ${w.client(j.clientId).name} ${j.notes}'
      .toLowerCase()
      .contains(query);
  Widget services({bool quotes = false}) {
    final jobs =
        w.jobs
            .where(
              (j) =>
                  matches(j) &&
                  (quotes
                      ? j.status == JobStatus.quote
                      : filter == null || j.status == filter),
            )
            .toList()
          ..sort((a, b) => b.history.last.at.compareTo(a.history.last.at));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        searchBox(),
        const SizedBox(height: 16),
        if (!quotes)
          Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: Text(s.t('Todos', 'All')),
                  selected: filter == null,
                  onSelected: (_) => setState(() => filter = null),
                ),
                for (final status in JobStatus.values)
                  ChoiceChip(
                    label: Text(s.status(status)),
                    selected: filter == status,
                    onSelected: (_) => setState(() => filter = status),
                  ),
              ],
            ),
          ),
        if (quotes)
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Text(
              s.t(
                'Orçamentos aguardando aprovação. Abra um serviço para conferir valores e agendar.',
                'Quotes awaiting approval. Open a service to review amounts and schedule.',
              ),
              style: const TextStyle(color: muted),
            ),
          ),
        Text(
          '${jobs.length} ${s.t('serviço(s)', 'service(s)')}',
          style: const TextStyle(color: muted, fontSize: 12),
        ),
        const SizedBox(height: 12),
        if (jobs.isEmpty)
          EmptyState(
            s.t('Nenhum serviço por aqui', 'No services here'),
            s.t(
              'Ajuste a busca ou crie um novo orçamento.',
              'Adjust your search or create a new quote.',
            ),
            action: FilledButton(
              onPressed: createJob,
              child: Text(s.t('Novo orçamento', 'New quote')),
            ),
          )
        else
          for (final job in jobs) jobCard(job),
      ],
    );
  }

  Widget agenda() {
    final jobs =
        w.jobs
            .where(
              (j) =>
                  j.reservesTime &&
                  (agendaDate == null ||
                      DateUtils.isSameDay(j.start, agendaDate)),
            )
            .toList()
          ..sort((a, b) => a.start!.compareTo(b.start!));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Surface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                s.t(
                  'Sua agenda, sem sobreposições',
                  'Your schedule, without overlaps',
                ),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                s.t(
                  'Uma pessoa por horário. Serviços concluídos e cancelados ficam no histórico.',
                  'One professional per time slot. Completed and cancelled services stay in history.',
                ),
                style: const TextStyle(color: muted),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  OutlinedButton.icon(
                    onPressed: () async {
                      final now = DateTime.now();
                      final chosen = await showDatePicker(
                        context: context,
                        initialDate: agendaDate ?? now,
                        firstDate: DateTime(2020),
                        lastDate: now.add(const Duration(days: 365 * 5)),
                      );
                      if (chosen != null && mounted) {
                        setState(() => agendaDate = chosen);
                      }
                    },
                    icon: const Icon(Icons.date_range),
                    label: Text(
                      agendaDate == null
                          ? s.t('Escolher dia', 'Choose day')
                          : s.date(agendaDate!, time: false),
                    ),
                  ),
                  if (agendaDate != null)
                    TextButton(
                      onPressed: () => setState(() => agendaDate = null),
                      child: Text(s.t('Mostrar todos', 'Show all')),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        if (jobs.isEmpty)
          EmptyState(
            s.t('Nenhum compromisso', 'No appointments'),
            s.t(
              'Escolha outro dia ou aprove um orçamento.',
              'Choose another day or approve a quote.',
            ),
            icon: Icons.event_available,
          )
        else
          for (var i = 0; i < jobs.length; i++) ...[
            if (i == 0 ||
                !DateUtils.isSameDay(jobs[i].start, jobs[i - 1].start))
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 14),
                child: Text(
                  s.date(jobs[i].start!, time: false),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: teal,
                  ),
                ),
              ),
            jobCard(jobs[i]),
          ],
      ],
    );
  }

  Widget clients() {
    final list =
        w.clients
            .where(
              (c) => '${c.name} ${c.phone} ${c.notes}'.toLowerCase().contains(
                query,
              ),
            )
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        searchBox(clientsOnly: true),
        const SizedBox(height: 22),
        if (list.isEmpty)
          EmptyState(
            s.t('Nenhum cliente encontrado', 'No clients found'),
            s.t(
              'Cadastre um cliente para começar um orçamento.',
              'Add a client to start a quote.',
            ),
            icon: Icons.people_outline,
          )
        else
          LayoutBuilder(
            builder: (context, size) {
              final columns = size.maxWidth > 950
                  ? 3
                  : size.maxWidth > 600
                  ? 2
                  : 1;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  for (final c in list)
                    SizedBox(
                      width: (size.maxWidth - (columns - 1) * 16) / columns,
                      child: Surface(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: const Color(0xFFE7EFDF),
                                  foregroundColor: teal,
                                  child: Text(
                                    c.name.characters.first.toUpperCase(),
                                  ),
                                ),
                                const Spacer(),
                                IconButton(
                                  tooltip: s.t('Editar cliente', 'Edit client'),
                                  onPressed: store.saving
                                      ? null
                                      : () => editClient(context, store, s, c),
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    size: 20,
                                  ),
                                ),
                                IconButton(
                                  tooltip: s.t(
                                    'Excluir cliente',
                                    'Delete client',
                                  ),
                                  onPressed: store.saving
                                      ? null
                                      : () async {
                                          if (await confirm(
                                            context,
                                            s,
                                            s.t(
                                              'Excluir cliente?',
                                              'Delete client?',
                                            ),
                                            s.t(
                                              'Só é possível excluir clientes sem serviços vinculados.',
                                              'Only clients without linked services can be deleted.',
                                            ),
                                          )) {
                                            action(
                                              () => store.deleteClient(c.id),
                                            );
                                          }
                                        },
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    size: 20,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Text(
                              c.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              c.phone.isEmpty
                                  ? s.t('Sem telefone', 'No phone')
                                  : c.phone,
                              style: const TextStyle(color: muted),
                            ),
                            if (c.notes.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Text(c.notes),
                              ),
                            const SizedBox(height: 18),
                            Text(
                              '${w.jobs.where((j) => j.clientId == c.id).length} ${s.t('serviço(s) no histórico', 'service(s) in history')}',
                              style: const TextStyle(
                                color: teal,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
      ],
    );
  }

  Widget history() {
    final events = [
      for (final j in w.jobs)
        for (final e in j.history) (j, e),
    ]..sort((a, b) => b.$2.at.compareTo(a.$2.at));
    final visible = events
        .where(
          (e) =>
              matches(e.$1) ||
              '${e.$2.title} ${w.client(e.$2.clientId).name}'
                  .toLowerCase()
                  .contains(query),
        )
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        searchBox(),
        const SizedBox(height: 22),
        if (visible.isEmpty)
          EmptyState(
            s.t('Histórico vazio', 'No history yet'),
            s.t(
              'Crie um orçamento para registrar o primeiro passo.',
              'Create a quote to record your first step.',
            ),
            icon: Icons.history,
          ),
        for (final pair in visible)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Surface(
              padding: const EdgeInsets.all(18),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.check_circle_outline, color: teal),
                title: Text(
                  pair.$2.title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  '${s.event(pair.$2.action)} · ${s.status(pair.$2.status)}\n${s.date(pair.$2.at)} · ${w.client(pair.$2.clientId).name}\n${Money.format(pair.$2.total)}',
                ),
                isThreeLine: true,
                onTap: () => showJob(context, store, s, pair.$1.id),
                trailing: const Icon(Icons.chevron_right),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> backup() async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.t('Backup local', 'Local backup')),
        content: SizedBox(
          width: 480,
          child: Text(
            s.t(
              'Copie um snapshot JSON e guarde em um arquivo seguro. Ele inclui clientes, serviços e histórico. O navegador pode apagar dados; este modo não é um banco de dados de produção.',
              'Copy a JSON snapshot and keep it in a safe file. It includes clients, services and history. Browser data can be cleared; this mode is not a production database.',
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(s.t('Fechar', 'Close')),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              restore();
            },
            child: Text(s.t('Restaurar backup', 'Restore backup')),
          ),
          FilledButton.icon(
            onPressed: () async {
              try {
                await Clipboard.setData(
                  ClipboardData(
                    text: const JsonEncoder.withIndent('  ')
                        .convert(w.toJson()),
                  ),
                );
                if (context.mounted && mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    SnackBar(
                      content: Text(
                        s.t(
                          'Backup copiado. Cole em um arquivo seguro.',
                          'Backup copied. Paste it into a safe file.',
                        ),
                      ),
                    ),
                  );
                }
              } catch (e) {
                report(e);
              }
            },
            icon: const Icon(Icons.copy),
            label: Text(s.t('Copiar JSON', 'Copy JSON')),
          ),
        ],
      ),
    );
  }

  Future<void> restore() async {
    final input = TextEditingController();
    String? error;
    bool busy = false;
    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          title: Text(s.t('Restaurar backup', 'Restore backup')),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    s.t(
                      'Substitui todos os dados locais. Copie o backup atual antes de continuar.',
                      'Replaces all local data. Copy your current backup before continuing.',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: input,
                    maxLines: 8,
                    decoration: const InputDecoration(labelText: 'JSON'),
                  ),
                  if (error != null)
                    Text(error!, style: const TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: busy ? null : () => Navigator.pop(context),
              child: Text(s.t('Voltar', 'Back')),
            ),
            FilledButton(
              onPressed: busy
                  ? null
                  : () async {
                      Workspace restored;
                      try {
                        restored = Workspace.fromJson(
                          jsonDecode(input.text) as Map<String, dynamic>,
                        );
                      } catch (_) {
                        setDialog(
                          () => error = s.t(
                            'Backup inválido ou incompatível. Nada foi alterado.',
                            'Invalid or incompatible backup. Nothing changed.',
                          ),
                        );
                        return;
                      }
                      if (!await confirm(
                        context,
                        s,
                        s.t(
                          'Substituir os dados locais?',
                          'Replace local data?',
                        ),
                        s.t(
                          'Esta ação substitui clientes, serviços, idioma e histórico pelo backup informado.',
                          'This replaces clients, services, language and history with the supplied backup.',
                        ),
                      )) {
                        return;
                      }
                      setDialog(() {
                        busy = true;
                        error = null;
                      });
                      try {
                        await store.update((_) => restored);
                        if (context.mounted) Navigator.pop(context);
                      } catch (e) {
                        setDialog(() {
                          busy = false;
                          error = s.error(e);
                        });
                      }
                    },
              child: Text(s.t('Validar e restaurar', 'Validate and restore')),
            ),
          ],
        ),
      ),
    );
    // Dialog routes finish their closing animation before controllers are disposed.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    input.dispose();
  }
}
