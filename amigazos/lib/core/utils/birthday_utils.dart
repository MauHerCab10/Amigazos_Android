import 'package:intl/intl.dart';

int diasParaCumpleanos(DateTime fechaCumple) {
  final hoy = DateTime.now();

  final cumpleEsteAno = DateTime(hoy.year, fechaCumple.month, fechaCumple.day);

  if (cumpleEsteAno.isBefore(DateTime(hoy.year, hoy.month, hoy.day))) {
    //Si ya pasó este año, se calcula para el próximo año
    final cumpleProximoAno = DateTime(
      hoy.year + 1,
      fechaCumple.month,
      fechaCumple.day,
    );
    return cumpleProximoAno
        .difference(DateTime(hoy.year, hoy.month, hoy.day))
        .inDays;
  } else {
    return cumpleEsteAno
        .difference(DateTime(hoy.year, hoy.month, hoy.day))
        .inDays;
  }
}

String formatearFechaCumpleanos(DateTime fecha) {
  String fechaFormateada = DateFormat('dd/MMMM', 'es_ES').format(fecha);
  return fechaFormateada.replaceFirstMapped(
    RegExp(r'\/\w'),
    (match) => match.group(0)!.toUpperCase(),
  );
}
