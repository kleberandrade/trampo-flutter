import 'package:material_ui/material_ui.dart';

import '../data/workspace_store.dart';
import '../domain/workspace.dart';
import 'components.dart';
import 'editors.dart';
import 'strings.dart';

Future<void> showJob(
  BuildContext context,
  WorkspaceStore store,
  Strings s,
  String id,
) => showDialog<void>(
  context: context,
  builder: (context) => AnimatedBuilder(
    animation: store,
    builder: (context, _) {
      final job = store.workspace!.jobs.firstWhere((j) => j.id == id);
      Future<void> transition(JobStatus target) async {
        if (target == JobStatus.cancelled &&
            !await confirm(
              context,
              s,
              s.t('Cancelar serviço?', 'Cancel service?'),
              s.t(
                'O horário será liberado e o histórico será preservado. Esta ação é definitiva.',
                'The time slot will be released and history preserved. This action is final.',
              ),
            )) {
          return;
        }
        try {
          await store.update((w) {
            final current = w.jobs.firstWhere((j) => j.id == id);
            return w.copy(
              jobs: [
                ...w.jobs.where((j) => j.id != id),
                current.transition(target, DateTime.now()),
              ],
            );
          });
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(s.error(e))));
          }
        }
      }

      Widget amount(String label, int value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text(
              Money.format(value),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
      return AlertDialog(
        title: Row(
          children: [
            Expanded(child: Text(job.title)),
            IconButton(
              tooltip: s.t('Fechar', 'Close'),
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close),
            ),
          ],
        ),
        content: SizedBox(
          width: 600,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                StatusChip(job.status, s),
                const SizedBox(height: 16),
                Text(
                  store.workspace!.client(job.clientId).name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (job.start != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text('${s.date(job.start!)} → ${s.date(job.end!)}'),
                  ),
                if (job.status == JobStatus.scheduled &&
                    job.end!.isBefore(DateTime.now()))
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      s.t(
                        'Horário ultrapassado. Atualize o status ou reagende.',
                        'Scheduled time has passed. Update the status or reschedule.',
                      ),
                      style: const TextStyle(color: Color(0xFF78520C)),
                    ),
                  ),
                const SizedBox(height: 20),
                amount(s.t('Mão de obra', 'Labor'), job.budget.labor),
                amount(s.t('Materiais', 'Materials'), job.budget.materials),
                amount(s.t('Desconto', 'Discount'), job.budget.discount),
                const Divider(),
                amount(
                  s.t('Total do orçamento', 'Quote total'),
                  job.budget.total,
                ),
                if (job.notes.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    child: SelectableText(job.notes),
                  ),
                const Divider(),
                Text(
                  s.t('Histórico do serviço', 'Service history'),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                for (final event in job.history.reversed)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.history, size: 18, color: muted),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${s.event(event.action)} · ${s.status(event.status)}',
                              ),
                              Text(
                                '${s.date(event.at)} · ${Money.format(event.total)} · ${store.workspace!.client(event.clientId).name}',
                                style: const TextStyle(
                                  color: muted,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                event.title,
                                style: const TextStyle(
                                  color: muted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          if (job.editable)
            TextButton(
              onPressed: store.saving
                  ? null
                  : () => editJob(context, store, s, job),
              child: Text(s.t('Editar', 'Edit')),
            ),
          if (job.editable)
            FilledButton.icon(
              onPressed: store.saving
                  ? null
                  : () => scheduleJob(context, store, s, job),
              icon: const Icon(Icons.event_available),
              label: Text(
                job.status == JobStatus.quote
                    ? s.t('Aprovar e agendar', 'Approve and schedule')
                    : s.t('Reagendar', 'Reschedule'),
              ),
            ),
          for (final next in job.nextStatuses)
            next == JobStatus.cancelled
                ? TextButton(
                    onPressed: store.saving ? null : () => transition(next),
                    child: Text(s.t('Cancelar serviço', 'Cancel service')),
                  )
                : FilledButton(
                    onPressed: store.saving ? null : () => transition(next),
                    child: Text(
                      next == JobStatus.active
                          ? s.t('Iniciar serviço', 'Start service')
                          : s.t('Concluir serviço', 'Complete service'),
                    ),
                  ),
        ],
      );
    },
  ),
);
