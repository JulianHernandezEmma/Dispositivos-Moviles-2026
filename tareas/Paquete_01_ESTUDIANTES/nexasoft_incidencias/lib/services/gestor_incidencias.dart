import '../data/almacen_local.dart';
import '../model/incidencia.dart';

class GestorIncidencias {
  final AlmacenLocal datos = AlmacenLocal();
  List<Incidencia> incidencias = [];
  int cantidadPendientes = 0;

  Future<void> iniciar() async {
    incidencias = await datos.leer();
    cantidadPendientes =
        incidencias.where((x) => x.estado == 'Pendiente').length;
  }

  List<Incidencia> buscar(String texto) {
    if (texto.trim().isEmpty) return incidencias;
    return incidencias.where((x) => x.titulo.contains(texto)).toList();
  }

  Incidencia? porId(String id) {
    for (var x in incidencias) {
      if (x.id == id) return x;
    }
    return null;
  }

  int contar(String estado) {
    if (estado == 'Pendiente') return cantidadPendientes;
    return incidencias.where((x) => x.estado == estado).length;
  }

//Función que cambia el estado que tiene cada incidencia
//Es una función future que espera la id de la incidencia a cambiar,
//y un status al cual lo queremos cambiar
//la función es asincrona por lo que espera a que se termine de ejecutar para poder
//enviar la respuesta en los breaks
  Future<void> cambiarEstado(String id, String estado) async {
//recorremos la lista completa de las incidencias que tenemos actualmente
    for (var i = 0; i < incidencias.length; i++) {
      //si la incidencia que tenemos en cada posición corresponde a la que buscamos
      //se cumple el condicional y entra
      print(
          "Que tiene la lista original: ${incidencias.map((x) => '${x.id}:${x.estado}').toList()}"); //Print de prueba para ver que recibe
      if (incidencias[i].id == id) {
        //Si coincidió cambia el estado del elemento en la lista en su campo estado
        //al que recibimos en esta función
        //si lo cambia, pero no se guarda el estado para futuras consultas
        print(
            "Antes de cambiar estado:  ${incidencias.map((x) => '${x.id}:${x.estado}').toList()}"); //Qué hay antes de cambiar el estado?
        incidencias[i].estado = estado;
        print(
            "Después de cambiar el estado:  ${incidencias.map((x) => '${x.id}:${x.estado}').toList()}"); //Qué hay después de cambiar el estado?
        //rompe la función por que terminó
        break;
      }
    }
    //debemos de guardar la lista de los datos que tenemos
    //actializada con el nuevo estado, no sólo cambiarlo
    print(
        "Antes de guardar la nueva lista  ${incidencias.map((x) => '${x.id}:${x.estado}').toList()}"); //Qué hay después de terminar el condicional, si se actualizó?
    await datos.guardar(incidencias);
    print(
        "Después de guardar la lista  ${incidencias.map((x) => '${x.id}:${x.estado}').toList()}"); //se guardó correctamente en la lista?
    print(
        "Lo que quedó en el almacén: ${(await datos.leer()).map((x) => '${x.id}:${x.estado}').toList()}"); //se guardó correctamente en el almacén?
  }

  Future<void> crear(String titulo, String descripcion, String cliente,
      String categoria) async {
    final nuevo = Incidencia(
      id: 'INC-${DateTime.now().microsecondsSinceEpoch}',
      titulo: titulo,
      descripcion: descripcion,
      cliente: cliente,
      categoria: categoria,
      estado: 'Pendiente',
      fecha: DateTime.now().toIso8601String().split('T').first,
    );
    incidencias.insert(0, nuevo);
    cantidadPendientes++;
    await datos.guardar(incidencias);
  }

  Future<void> reiniciarDemo() async {
    await datos.restaurarDatosDeEjemplo();
    await iniciar();
  }
}
