import 'package:material_ui/material_ui.dart';

import '../domain/workspace.dart';
import 'strings.dart';

const ink = Color(0xFF182F37);
const teal = Color(0xFF086B5C);
const paper = Color(0xFFF5F6F1);
const muted = Color(0xFF5D6E72);

Color statusColor(JobStatus s) => switch (s) {
  JobStatus.quote => const Color(0xFF78520C),
  JobStatus.scheduled => const Color(0xFF17646F),
  JobStatus.active => const Color(0xFF4749A0),
  JobStatus.completed => teal,
  JobStatus.cancelled => const Color(0xFF805252),
};

class StatusChip extends StatelessWidget {
  final JobStatus status;
  final Strings s;
  const StatusChip(this.status, this.s, {super.key});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: statusColor(status).withValues(alpha: .09),
      borderRadius: BorderRadius.circular(30),
    ),
    child: Text(
      s.status(status),
      style: TextStyle(
        color: statusColor(status),
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class Surface extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const Surface({
    required this.child,
    this.padding = const EdgeInsets.all(24),
    super.key,
  });
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: const BorderSide(color: Color(0xFFE1E7E3)),
    ),
    clipBehavior: Clip.antiAlias,
    child: Padding(padding: padding, child: child),
  );
}

class EmptyState extends StatelessWidget {
  final String title, message;
  final IconData icon;
  final Widget? action;
  const EmptyState(
    this.title,
    this.message, {
    this.icon = Icons.inbox_outlined,
    this.action,
    super.key,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(32),
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 38, color: teal),
          const SizedBox(height: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: muted),
          ),
          if (action != null)
            Padding(padding: const EdgeInsets.only(top: 20), child: action),
        ],
      ),
    ),
  );
}

/// Flags are painted locally, without network assets or emoji rendering.
class LanguageButton extends StatelessWidget {
  final String language, selected;
  final VoidCallback? onPressed;
  const LanguageButton({
    required this.language,
    required this.selected,
    required this.onPressed,
    super.key,
  });
  @override
  Widget build(BuildContext context) {
    final label = language == 'pt'
        ? 'Português (Brasil)'
        : 'English (United Kingdom)';
    return Semantics(
      label: label,
      selected: language == selected,
      button: true,
      child: Tooltip(
        excludeFromSemantics: true,
        message: label,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(24),
          child: SizedBox(
            width: 48,
            height: 48,
            child: Center(
              child: Container(
                width: 30,
                height: 30,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: language == selected ? teal : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: CustomPaint(
                    painter: _FlagPainter(language),
                    size: const Size(24, 24),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FlagPainter extends CustomPainter {
  final String language;
  _FlagPainter(this.language);
  @override
  void paint(Canvas c, Size z) {
    final w = z.width, h = z.height;
    void line(
      double x1,
      double y1,
      double x2,
      double y2,
      Color color,
      double width,
    ) => c.drawLine(
      Offset(x1, y1),
      Offset(x2, y2),
      Paint()
        ..color = color
        ..strokeWidth = width,
    );
    if (language == 'pt') {
      c.drawRect(Offset.zero & z, Paint()..color = const Color(0xFF19864A));
      c.drawPath(
        Path()
          ..moveTo(w / 2, h * .1)
          ..lineTo(w * .95, h / 2)
          ..lineTo(w / 2, h * .9)
          ..lineTo(w * .05, h / 2)
          ..close(),
        Paint()..color = const Color(0xFFFFD547),
      );
      c.drawCircle(
        Offset(w / 2, h / 2),
        w * .23,
        Paint()..color = const Color(0xFF174594),
      );
      line(w * .29, h * .44, w * .7, h * .56, Colors.white, 1.5);
    } else {
      c.drawRect(Offset.zero & z, Paint()..color = const Color(0xFF243D7C));
      line(0, 0, w, h, Colors.white, 5);
      line(w, 0, 0, h, Colors.white, 5);
      line(0, 0, w, h, const Color(0xFFC82E40), 2);
      line(w, 0, 0, h, const Color(0xFFC82E40), 2);
      line(w / 2, 0, w / 2, h, Colors.white, 8);
      line(0, h / 2, w, h / 2, Colors.white, 8);
      line(w / 2, 0, w / 2, h, const Color(0xFFC82E40), 4);
      line(0, h / 2, w, h / 2, const Color(0xFFC82E40), 4);
    }
  }

  @override
  bool shouldRepaint(_FlagPainter old) => old.language != language;
}
