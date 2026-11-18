import 'package:material_ui/material_ui.dart';

import '../data/workspace_store.dart';
import '../domain/workspace.dart';
import 'strings.dart';
import 'components.dart';

String newId() => DateTime.now().microsecondsSinceEpoch.toString();
Future<void> editClient(
  BuildContext context,
  WorkspaceStore store,
  Strings s, [
  Client? client,
]) => showDialog<void>(
  context: context,
  builder: (_) => ClientEditor(store: store, s: s, client: client),
);
Future<void> editJob(
  BuildContext context,
  WorkspaceStore store,
  Strings s, [
  Job? job,
]) => showDialog<void>(
  context: context,
  builder: (_) => JobEditor(store: store, s: s, job: job),
);

class ClientEditor extends StatefulWidget {
  final WorkspaceStore store;
  final Strings s;
  final Client? client;
  const ClientEditor({
    required this.store,
    required this.s,
    this.client,
    super.key,
  });
  @override
  State<ClientEditor> createState() => _ClientEditorState();
}

class _ClientEditorState extends State<ClientEditor> {
  final form = GlobalKey<FormState>();
  late final name = TextEditingController(text: widget.client?.name);
  late final phone = TextEditingController(text: widget.client?.phone);
  late final notes = TextEditingController(text: widget.client?.notes);
  bool busy = false;
  String? error;
  @override
  void dispose() {
    name.dispose();
    phone.dispose();
    notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    return AlertDialog(
      title: Text(
        widget.client == null
            ? s.t('Novo cliente', 'New client')
            : s.t('Editar cliente', 'Edit client'),
      ),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Form(
            key: form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: name,
                  autofocus: true,
                  maxLength: 100,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: s.t('Nome *', 'Name *'),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? s.t('Informe o nome.', 'Enter a name.')
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phone,
                  maxLength: 50,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: s.t('Telefone', 'Phone'),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: notes,
                  maxLength: 1000,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: s.t(
                      'Endereço e observações',
                      'Address and notes',
                    ),
                  ),
                ),
                if (error != null)
                  Text(error!, style: const TextStyle(color: Colors.red)),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: busy ? null : () => Navigator.pop(context),
          child: Text(s.t('Voltar', 'Back')),
        ),
        FilledButton(
          onPressed: busy ? null : save,
          child: Text(
            busy
                ? s.t('Salvando…', 'Saving…')
                : s.t('Salvar cliente', 'Save client'),
          ),
        ),
      ],
    );
  }

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.store.saveClient(
        Client(widget.client?.id ?? newId(), name.text, phone.text, notes.text),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() {
          busy = false;
          error = widget.s.error(e);
        });
      }
    }
  }
}

class JobEditor extends StatefulWidget {
  final WorkspaceStore store;
  final Strings s;
  final Job? job;
  const JobEditor({required this.store, required this.s, this.job, super.key});
  @override
  State<JobEditor> createState() => _JobEditorState();
}

class _JobEditorState extends State<JobEditor> {
  final form = GlobalKey<FormState>();
  late final title = TextEditingController(text: widget.job?.title);
  late final notes = TextEditingController(text: widget.job?.notes);
  late final labor = TextEditingController(
    text: Money.input(widget.job?.budget.labor ?? 0),
  );
  late final materials = TextEditingController(
    text: Money.input(widget.job?.budget.materials ?? 0),
  );
  late final discount = TextEditingController(
    text: Money.input(widget.job?.budget.discount ?? 0),
  );
  late String? clientId = widget.job?.clientId;
  bool busy = false;
  String? error;
  Budget budget() => Budget(
    Money.parse(labor.text),
    Money.parse(materials.text),
    Money.parse(discount.text),
  );
  @override
  void dispose() {
    for (final c in [title, notes, labor, materials, discount]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    String total;
    try {
      total = Money.format(budget().total);
    } catch (_) {
      total = '—';
    }
    Widget moneyField(TextEditingController c, String label) => Padding(
      padding: const EdgeInsets.only(top: 14),
      child: TextFormField(
        controller: c,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: label, prefixText: 'R\$ '),
        onChanged: (_) => setState(() {}),
        validator: (v) {
          try {
            Money.parse(v ?? '');
            return null;
          } catch (_) {
            return s.t(
              'Use 120,50. Máx. 9.999.999,99.',
              'Use 120,50. Max. 9.999.999,99.',
            );
          }
        },
      ),
    );
    return AlertDialog(
      title: Text(
        widget.job == null
            ? s.t('Novo orçamento', 'New quote')
            : s.t('Editar serviço', 'Edit service'),
      ),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Form(
            key: form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  s.t(
                    'Comece pelo combinado. Agende após a aprovação do cliente.',
                    'Start with the agreement. Schedule after client approval.',
                  ),
                  style: const TextStyle(color: muted),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: title,
                  autofocus: true,
                  maxLength: 120,
                  decoration: InputDecoration(
                    labelText: s.t('Nome do serviço *', 'Service name *'),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? s.t('Informe o serviço.', 'Enter a service.')
                      : null,
                ),
                DropdownButtonFormField<String>(
                  initialValue: clientId,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: s.t('Cliente *', 'Client *'),
                  ),
                  items: widget.store.workspace!.clients
                      .map(
                        (c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(c.name, overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => clientId = v,
                  validator: (v) => v == null
                      ? s.t('Selecione um cliente.', 'Select a client.')
                      : null,
                ),
                moneyField(labor, s.t('Mão de obra', 'Labor')),
                moneyField(materials, s.t('Materiais', 'Materials')),
                moneyField(discount, s.t('Desconto', 'Discount')),
                const SizedBox(height: 16),
                Text(
                  '${s.t('Total', 'Total')}: $total',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: teal,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: notes,
                  maxLength: 2000,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: s.t('Escopo e observações', 'Scope and notes'),
                  ),
                ),
                if (error != null)
                  Text(error!, style: const TextStyle(color: Colors.red)),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: busy ? null : () => Navigator.pop(context),
          child: Text(s.t('Voltar', 'Back')),
        ),
        FilledButton(
          onPressed: busy ? null : save,
          child: Text(
            busy
                ? s.t('Salvando…', 'Saving…')
                : s.t('Salvar orçamento', 'Save quote'),
          ),
        ),
      ],
    );
  }

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final now = DateTime.now();
      final job = widget.job == null
          ? Job.create(
              id: newId(),
              clientId: clientId!,
              title: title.text,
              notes: notes.text,
              budget: budget(),
              now: now,
            )
          : widget.job!.edit(
              clientId: clientId!,
              title: title.text,
              notes: notes.text,
              budget: budget(),
              now: now,
            );
      await widget.store.saveJob(job);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() {
          busy = false;
          error = widget.s.error(e);
        });
      }
    }
  }
}

Future<bool> confirm(
  BuildContext context,
  Strings s,
  String title,
  String message,
) async =>
    await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text(s.t('Voltar', 'Back')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(s.t('Confirmar', 'Confirm')),
          ),
        ],
      ),
    ) ??
    false;

Future<void> scheduleJob(
  BuildContext context,
  WorkspaceStore store,
  Strings s,
  Job job,
) => showDialog<void>(
  context: context,
  builder: (_) => ScheduleEditor(store: store, s: s, job: job),
);

class ScheduleEditor extends StatefulWidget {
  final WorkspaceStore store;
  final Strings s;
  final Job job;
  const ScheduleEditor({
    required this.store,
    required this.s,
    required this.job,
    super.key,
  });
  @override
  State<ScheduleEditor> createState() => _ScheduleEditorState();
}

class _ScheduleEditorState extends State<ScheduleEditor> {
  late DateTime start =
      widget.job.start != null && widget.job.start!.isAfter(DateTime.now())
      ? widget.job.start!
      : DateTime.now()
            .add(const Duration(days: 1))
            .copyWith(
              hour: 9,
              minute: 0,
              second: 0,
              millisecond: 0,
              microsecond: 0,
            );
  late DateTime end = start.add(
    widget.job.end != null
        ? widget.job.end!.difference(widget.job.start!)
        : const Duration(hours: 1),
  );
  bool busy = false;
  String? error;
  Future<void> pick(bool isStart) async {
    final old = isStart ? start : end;
    final now = DateTime.now();
    final day = await showDatePicker(
      context: context,
      initialDate: old,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365 * 5)),
    );
    if (day == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(old),
    );
    if (time == null || !mounted) return;
    setState(() {
      final selected = DateTime(
        day.year,
        day.month,
        day.day,
        time.hour,
        time.minute,
      );
      if (isStart) {
        final duration = end.difference(start);
        start = selected;
        end = selected.add(duration);
      } else {
        end = selected;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    return AlertDialog(
      title: Text(s.t('Aprovar e agendar', 'Approve and schedule')),
      content: SizedBox(
        width: 450,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              s.t(
                'Uma agenda para um profissional. Intervalos sobrepostos são bloqueados. Ao agendar, você registra a aprovação do orçamento.',
                'One schedule for one professional. Overlapping intervals are blocked. Scheduling records approval of the quote.',
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: busy ? null : () => pick(true),
              icon: const Icon(Icons.event_outlined),
              label: Text('${s.t('Início', 'Start')}: ${s.date(start)}'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: busy ? null : () => pick(false),
              icon: const Icon(Icons.schedule),
              label: Text('${s.t('Fim', 'End')}: ${s.date(end)}'),
            ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(error!, style: const TextStyle(color: Colors.red)),
              ),
          ],
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
                  setState(() {
                    busy = true;
                    error = null;
                  });
                  try {
                    await widget.store.update((w) {
                      final current = w.jobs.firstWhere(
                        (j) => j.id == widget.job.id,
                      );
                      final scheduled = current.schedule(
                        start,
                        end,
                        w.jobs,
                        DateTime.now(),
                      );
                      return w.copy(
                        jobs: [
                          ...w.jobs.where((j) => j.id != current.id),
                          scheduled,
                        ],
                      );
                    });
                    if (context.mounted) Navigator.pop(context);
                  } catch (e) {
                    if (mounted) {
                      setState(() {
                        busy = false;
                        error = s.error(e);
                      });
                    }
                  }
                },
          child: Text(
            busy
                ? s.t('Salvando…', 'Saving…')
                : s.t('Confirmar agenda', 'Confirm schedule'),
          ),
        ),
      ],
    );
  }
}
