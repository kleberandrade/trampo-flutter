import '../domain/workspace.dart';

class Strings {
  final bool en;
  const Strings(this.en);
  String t(String pt, String english) => en ? english : pt;
  String status(JobStatus value) => switch (value) {
    JobStatus.quote => t('Orçamento', 'Quote'),
    JobStatus.scheduled => t('Agendado', 'Scheduled'),
    JobStatus.active => t('Em andamento', 'In progress'),
    JobStatus.completed => t('Concluído', 'Completed'),
    JobStatus.cancelled => t('Cancelado', 'Cancelled'),
  };
  String date(DateTime value, {bool time = true}) {
    final d = value.toLocal();
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    return '${en ? '$month/$day' : '$day/$month'}/${d.year}${time ? ' · ${clock(d)}' : ''}';
  }

  String clock(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  String event(String action) => switch (action) {
    'created' => t('Orçamento criado', 'Quote created'),
    'edited' => t('Dados atualizados', 'Details updated'),
    'scheduled' => t('Agenda atualizada', 'Schedule updated'),
    _ => t('Status atualizado', 'Status updated'),
  };
  String error(Object e) {
    final code = switch (e) {
      StateError(:final message) => message,
      ArgumentError(:final message) => message,
      FormatException(:final message) => message,
      _ => '',
    };
    return switch (code) {
      'conflict' => t(
        'Este horário coincide com outro serviço. Escolha outro intervalo.',
        'This time overlaps another service. Choose another interval.',
      ),
      'early' => t(
        'O serviço só pode começar a partir do horário agendado.',
        'The service can only start at its scheduled time.',
      ),
      'dates' => t(
        'Escolha um início futuro e fim posterior, com até 24 horas.',
        'Choose a future start and later end, up to 24 hours.',
      ),
      'money' => t(
        'Use valores como 120,50, com até duas casas decimais.',
        'Use BRL amounts such as 120,50, with up to two decimal places.',
      ),
      'budget' => t(
        'Confira os valores. O desconto não pode superar o subtotal.',
        'Check amounts. Discount cannot exceed the subtotal.',
      ),
      'referenced' => t(
        'Este cliente possui serviços e precisa permanecer no histórico.',
        'This client has services and must remain in history.',
      ),
      'transition' => t(
        'Esta alteração não é permitida para o status atual.',
        'This change is not allowed for the current status.',
      ),
      'clock' => t(
        'Confira o relógio do dispositivo e tente novamente.',
        'Check your device clock and try again.',
      ),
      _ => t(
        'Não foi possível salvar. Seus dados anteriores foram preservados. Tente novamente.',
        'Could not save. Your previous data was preserved. Try again.',
      ),
    };
  }
}
