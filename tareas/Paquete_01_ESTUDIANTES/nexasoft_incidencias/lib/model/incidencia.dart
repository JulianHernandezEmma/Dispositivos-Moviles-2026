class Incidencia {
  String id;
  String titulo;
  String descripcion;
  String cliente;
  String categoria;
  String estado;
  String fecha;
  //campo nuevo para la FEAT-001, guarda la prioridad de la incidencia
  String prioridad;

  //lista con las 3 prioridades que pide el ticket, la uso en el formulario, en el detalle
  //y para validar, así no tengo que escribir la lista en cada archivo
  static const prioridades = ['Baja', 'Media', 'Alta'];

  Incidencia({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.cliente,
    required this.categoria,
    required this.estado,
    required this.fecha,
    required this.prioridad,
  });

  //Función que revisa que la prioridad sea Baja, Media o Alta, si no viene nada (como las incidencias
  //viejas que se guardaron antes de la prioridad) o viene otra cosa, regresa Media
  static String prioridadValida(String? valor) {
    return prioridades.contains(valor) ? valor! : 'Media';
  }

  factory Incidencia.desdeJson(Map<String, dynamic> m) {
    return Incidencia(
      id: m['id']?.toString() ?? '',
      titulo: m['titulo']?.toString() ?? '',
      descripcion: m['descripcion']?.toString() ?? '',
      cliente: m['cliente']?.toString() ?? '',
      categoria: m['categoria']?.toString() ?? 'Software',
      estado: m['estado']?.toString() ?? 'Pendiente',
      fecha: m['fecha']?.toString() ?? '',
      //si la incidencia no tiene prioridad ya no truena, se le pone Media
      prioridad: prioridadValida(m['prioridad']?.toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
      'descripcion': descripcion,
      'cliente': cliente,
      'categoria': categoria,
      'estado': estado,
      'fecha': fecha,
      //se agrega la prioridad al JSON para que también se guarde y no se pierda al reabrir la app
      'prioridad': prioridad,
    };
  }
}
