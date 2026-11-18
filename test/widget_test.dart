import 'dart:convert';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trampo/main.dart';
import 'package:trampo/ui/components.dart';
import 'package:trampo/data/workspace_store.dart';
import 'package:trampo/domain/workspace.dart';

import 'repository_test.dart' show MemoryRepository;

void main() {
  testWidgets(
    'desktop creates quote, blocks conflict, schedules and preserves language',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repo = MemoryRepository();
      final store = WorkspaceStore(repo);
      await store.load();
      await tester.pumpWidget(TrampoApp(store: store));
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(FilledButton, 'Novo orçamento').first,
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'Reparo de janela',
      );
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Marina Costa').last);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(1), '100,10');
      await tester.enterText(find.byType(TextFormField).at(2), '200,20');
      await tester.enterText(find.byType(TextFormField).at(3), '0,30');
      await tester.ensureVisible(find.text('Salvar orçamento'));
      await tester.tap(find.text('Salvar orçamento'));
      await tester.pumpAndSettle();
      expect(store.workspace!.jobs.last.budget.total, 30000);
      await tester.tap(find.widgetWithText(ListTile, 'Serviços'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reparo de janela'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Aprovar e agendar'));
      await tester.pumpAndSettle();
      // Synthetic appointments reserve tomorrow at 09:00; UI must show a conflict.
      await tester.tap(find.text('Confirmar agenda'));
      await tester.pumpAndSettle();
      expect(find.textContaining('coincide com outro serviço'), findsOneWidget);
      expect(store.workspace!.jobs.last.status, JobStatus.quote);
      await tester.tap(find.text('Voltar').last);
      await tester.pumpAndSettle();
      await store.update(
        (w) => w.copy(
          jobs: w.jobs
              .map(
                (j) => j.id == 'j1'
                    ? j.transition(JobStatus.cancelled, DateTime.now())
                    : j,
              )
              .toList(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Aprovar e agendar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirmar agenda'));
      await tester.pumpAndSettle();
      expect(store.workspace!.jobs.last.status, JobStatus.scheduled);
      await tester.tap(find.byTooltip('Fechar'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byWidgetPredicate(
          (w) => w is LanguageButton && w.language == 'en',
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Services'), findsWidgets);
      expect(store.workspace!.jobs.last.title, 'Reparo de janela');
      expect(repo.value!.language, 'en');
    },
  );
  testWidgets('mobile client creation and navigation have no overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = WorkspaceStore(MemoryRepository());
    await store.load();
    await tester.pumpWidget(TrampoApp(store: store));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clientes').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Novo cliente'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Cliente novo');
    await tester.tap(find.text('Salvar cliente'));
    await tester.pumpAndSettle();
    expect(store.workspace!.clients.any((c) => c.name == 'Cliente novo'), true);
    await tester.tap(find.byTooltip('Abrir navegação'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Histórico'));
    await tester.pumpAndSettle();
    expect(find.text('Histórico'), findsWidgets);
  });
  testWidgets('loading and failed storage have recovery states', (
    tester,
  ) async {
    final store = WorkspaceStore(MemoryRepository());
    await tester.pumpWidget(TrampoApp(store: store));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    store.loading = false;
    store.error = StateError('corrupt');
    store.notifyListeners();
    await tester.pump();
    expect(find.text('Tentar novamente'), findsOneWidget);
    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();
    expect(find.text('Visão geral'), findsWidgets);
  });
  testWidgets('mobile enlarged text and accessible controls remain usable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final semantics = tester.ensureSemantics();

    final store = WorkspaceStore(MemoryRepository());
    await store.load();
    await tester.pumpWidget(TrampoApp(store: store));
    await tester.pumpAndSettle();
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    semantics.dispose();
  });
  testWidgets('navigation fits short desktop and mobile windows', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = WorkspaceStore(MemoryRepository());
    await store.load();
    tester.view.physicalSize = const Size(1280, 600);
    await tester.pumpWidget(TrampoApp(store: store));
    await tester.pumpAndSettle();
    tester.view.physicalSize = const Size(390, 600);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Abrir navegação'));
    await tester.pumpAndSettle();
  });
  testWidgets(
    'backup restore rejects invalid data and confirms valid replacement',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final store = WorkspaceStore(MemoryRepository());
      await store.load();
      final snapshot = store.workspace!.copy(language: 'en');
      await tester.pumpWidget(TrampoApp(store: store));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Backup dos dados'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Restaurar backup'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '{invalid');
      await tester.tap(find.text('Validar e restaurar'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Backup inválido'), findsOneWidget);
      expect(store.workspace!.language, 'pt');
      await tester.enterText(
        find.byType(TextField),
        jsonEncode(snapshot.toJson()),
      );
      await tester.tap(find.text('Validar e restaurar'));
      await tester.pumpAndSettle();
      expect(find.text('Substituir os dados locais?'), findsOneWidget);
      expect(store.workspace!.language, 'pt');
      await tester.tap(find.text('Confirmar'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 350));
      expect(store.workspace!.toJson(), snapshot.toJson());
    },
  );
}
