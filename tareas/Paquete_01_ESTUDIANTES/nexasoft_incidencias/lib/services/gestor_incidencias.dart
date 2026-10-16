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

  //Función que normaliza un texto para poder compararlo sin que importen las tildes
  //ni las mayúsculas, recibe el texto original y devuelve el texto ya limpio
  String _normalizar(String texto) {
    //Letras con tilde y su equivalente sin tilde, deben estar en el mismo orden
    //para que la posición de una corresponda con la posición de la otra
    const con = 'áéíóúü';
    const sin = 'aeiouu';
    //Variable local para no modificar el texto original, hace el trim y lo pone en minúscula
    var lista_local = texto.trim().toLowerCase();
    //Recorremos las letras con tilde y reemplazamos cada una por su versión sin tilde
    for (var i = 0; i < con.length; i++) {
      lista_local = lista_local.replaceAll(con[i], sin[i]);
    }
    return lista_local;
  }

  //Función que guarda en una lista que sirve para buscar las coinciencias de las incidencias
  //Recibe un string del texto que se ingresó en el input
  List<Incidencia> buscar(String texto) {
    //Ponemos una variable local con el texto que recibe la función ya normalizado
    //(sin tildes, sin espacios a los lados y en minúscula) para no modificar la original
    final lista_local = _normalizar(texto);
    //retornamos toda la lista de incidencias si no hay nada escrito en el input
    if (lista_local.isEmpty) return incidencias;
    //Normalizamos también el título y la descripción de cada incidencia antes de comparar,
    //así "camara" encuentra "cámara" y viceversa
    //retornamos la lista de las incidencias con los elementos que coincidieron
    return incidencias
        .where((x) =>
            _normalizar(x.titulo).contains(lista_local) ||
            _normalizar(x.descripcion).contains(lista_local))
        .toList();
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
      /*print(
          "Que tiene la lista original: ${incidencias.map((x) => '${x.id}:${x.estado}').toList()}"); //Print de prueba para ver que recibe */
      if (incidencias[i].id == id) {
        //Si coincidió cambia el estado del elemento en la lista en su campo estado
        //al que recibimos en esta función
        //si lo cambia, pero no se guarda el estado para futuras consultas
        /*print(
            "Antes de cambiar estado:  ${incidencias.map((x) => '${x.id}:${x.estado}').toList()}"); //Qué hay antes de cambiar el estado? */
        incidencias[i].estado = estado;
        /* print(
            "Después de cambiar el estado:  ${incidencias.map((x) => '${x.id}:${x.estado}').toList()}"); //Qué hay después de cambiar el estado? */
        //rompe la función por que terminó
        break;
      }
    }
    //debemos de guardar la lista de los datos que tenemos
    //actializada con el nuevo estado, no sólo cambiarlo
    /* print(
        "Antes de guardar la nueva lista  ${incidencias.map((x) => '${x.id}:${x.estado}').toList()}"); //Qué hay después de terminar el condicional, si se actualizó? */
    await datos.guardar(incidencias);
    /*  print(
        "Después de guardar la lista  ${incidencias.map((x) => '${x.id}:${x.estado}').toList()}"); //se guardó correctamente en la lista?
    print(
        "Lo que quedó en el almacén: ${(await datos.leer()).map((x) => '${x.id}:${x.estado}').toList()}"); //se guardó correctamente en el almacén?*/
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
