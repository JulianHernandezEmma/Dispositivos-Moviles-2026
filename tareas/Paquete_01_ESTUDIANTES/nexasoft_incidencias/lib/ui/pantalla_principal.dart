import 'package:flutter/material.dart';
import '../model/incidencia.dart';
import '../services/gestor_incidencias.dart';
import 'pantalla_detalle.dart';
import 'pantalla_nueva.dart';

class PantallaPrincipal extends StatefulWidget {
  const PantallaPrincipal({super.key});

  @override
  State<PantallaPrincipal> createState() => _PantallaPrincipalState();
}

class _PantallaPrincipalState extends State<PantallaPrincipal> {
  final GestorIncidencias g = GestorIncidencias();
  bool cargando = true;
  String? error;
  String busqueda = '';
  //filtros de la FEAT-002, empiezan sin filtrar nada
  String filtroEstado = 'Todos';
  String filtroPrioridad = 'Todas';
  //controlador del buscador, antes no tenía y se necesita para poder borrar el texto con el botón Limpiar
  final buscador = TextEditingController();

  @override
  void initState() {
    super.initState();
    cargar();
  }

  @override
  void dispose() {
    buscador.dispose();
    super.dispose();
  }

  //Función del botón Limpiar, regresa el buscador y los dos filtros a como estaban al inicio
  //para que vuelvan a salir todas las incidencias
  void limpiarFiltros() {
    buscador.clear();
    setState(() {
      busqueda = '';
      filtroEstado = 'Todos';
      filtroPrioridad = 'Todas';
    });
  }

  //dropdown de los filtros, lo hice función porque los dos son iguales y sólo cambia la lista
  Widget filtro(String etiqueta, String valor, List<String> opciones, ValueChanged<String> cambiar) {
    return DropdownButtonFormField<String>(
      value: valor,
      decoration: InputDecoration(labelText: etiqueta, border: const OutlineInputBorder(), isDense: true),
      items: opciones.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
      onChanged: (v) => setState(() => cambiar(v ?? opciones.first)),
    );
  }

  Future<void> cargar() async {
    setState(() {
      cargando = true;
      error = null;
    });
    try {
      await g.iniciar();
    } catch (e) {
      error = 'No se pudieron cargar las incidencias: $e';
    }
    if (mounted) setState(() => cargando = false);
  }

  Color colorEstado(String estado) {
    if (estado == 'Resuelta') return const Color(0xFF147D64);
    if (estado == 'En proceso') return const Color(0xFFB56B13);
    return const Color(0xFFAC4052);
  }

  //color de la etiqueta de la prioridad, igual que como se hace con colorEstado
  Color colorPrioridad(String prioridad) {
    if (prioridad == 'Alta') return const Color(0xFFC62828);
    if (prioridad == 'Media') return const Color(0xFFB56B13);
    return const Color(0xFF546E7A);
  }

  Widget resumen(String etiqueta, String valor, IconData icono) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icono, size: 19, color: const Color(0xFF174C83)),
              const SizedBox(height: 4),
              Text(valor, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              Text(etiqueta, textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> abrirDetalle(Incidencia item) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => PantallaDetalle(gestor: g, id: item.id)),
    );
    if (mounted) setState(() {});
  }

  Future<void> abrirFormulario() async {
    final guardado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => PantallaNueva(gestor: g)),
    );
    if (guardado == true && mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Incidencia registrada')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    //ahora la lista sale de filtrar, que usa el texto y los dos filtros al mismo tiempo
    //los contadores de arriba siguen usando contar sobre toda la lista, así no dependen de los filtros (bug 3)
    final items = g.filtrar(busqueda, filtroEstado, filtroPrioridad);
    return Scaffold(
      appBar: AppBar(
        title: const Text('NexaSoft | Incidencias'),
        actions: [
          IconButton(
            tooltip: 'Restablecer datos de demostración',
            onPressed: () async {
              final aceptar = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Restablecer demostración'),
                  content: const Text('Se descartarán los cambios locales y se cargarán las incidencias iniciales.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                    FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Restablecer')),
                  ],
                ),
              );
              if (aceptar != true) return;
              try {
                await g.reiniciarDemo();
                if (mounted) setState(() {});
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al reiniciar: $e')));
                }
              }
            },
            icon: const Icon(Icons.restart_alt),
          ),
        ],
      ),
      floatingActionButton: cargando || error != null
          ? null
          : FloatingActionButton.extended(
              onPressed: abrirFormulario,
              label: const Text('Nueva incidencia'),
              icon: const Icon(Icons.add),
            ),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(error!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    FilledButton(onPressed: cargar, child: const Text('Reintentar')),
                  ]),
                ))
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 860),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 14, 12, 8),
                          child: Row(children: [
                            resumen('Pendientes', '${g.contar('Pendiente')}', Icons.pending_actions),
                            resumen('En proceso', '${g.contar('En proceso')}', Icons.build_outlined),
                            resumen('Resueltas', '${g.contar('Resuelta')}', Icons.check_circle_outline),
                          ]),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 5),
                          child: TextField(
                            controller: buscador,
                            decoration: const InputDecoration(
                              labelText: 'Buscar incidencias',
                              hintText: 'Ejemplo: WiFi, correo, pantalla',
                              prefixIcon: Icon(Icons.search),
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (texto) => setState(() => busqueda = texto),
                          ),
                        ),
                        //fila con los filtros de estado y prioridad y el botón para limpiar todo
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 5),
                          child: Row(children: [
                            Expanded(
                              child: filtro('Estado', filtroEstado,
                                  ['Todos', 'Pendiente', 'En proceso', 'Resuelta'], (v) => filtroEstado = v),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: filtro('Prioridad', filtroPrioridad,
                                  ['Todas', ...Incidencia.prioridades], (v) => filtroPrioridad = v),
                            ),
                            const SizedBox(width: 10),
                            OutlinedButton.icon(
                              onPressed: limpiarFiltros,
                              icon: const Icon(Icons.filter_alt_off_outlined),
                              label: const Text('Limpiar'),
                            ),
                          ]),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text('${items.length} registros', style: const TextStyle(color: Colors.black54)),
                          ),
                        ),
                        Expanded(
                          child: items.isEmpty
                              //cuando no hay resultados se explica por qué y se da la opción de limpiar ahí mismo
                              ? Center(
                                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                                    const Icon(Icons.search_off, size: 40, color: Colors.black45),
                                    const SizedBox(height: 8),
                                    const Text('No se encontraron incidencias con esa búsqueda y esos filtros',
                                        textAlign: TextAlign.center),
                                    const SizedBox(height: 8),
                                    TextButton(onPressed: limpiarFiltros, child: const Text('Limpiar búsqueda y filtros')),
                                  ]),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.only(left: 12, right: 12, bottom: 100),
                                  itemCount: items.length,
                                  itemBuilder: (context, i) {
                                    final item = items[i];
                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 10),
                                      child: ListTile(
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        title: Text(item.titulo, style: const TextStyle(fontWeight: FontWeight.w600)),
                                        subtitle: Padding(
                                          padding: const EdgeInsets.only(top: 8),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text('${item.id}  ·  ${item.cliente}'),
                                              const SizedBox(height: 6),
                                              //se puso el estado en un Row para que a un lado salga la prioridad como etiqueta
                                              Row(children: [
                                                Text(item.estado, style: TextStyle(
                                                  color: colorEstado(item.estado), fontWeight: FontWeight.bold,
                                                )),
                                                const SizedBox(width: 10),
                                                Chip(
                                                  label: Text(item.prioridad),
                                                  labelStyle: TextStyle(
                                                    color: colorPrioridad(item.prioridad), fontSize: 12, fontWeight: FontWeight.w600,
                                                  ),
                                                  side: BorderSide(color: colorPrioridad(item.prioridad)),
                                                  backgroundColor: colorPrioridad(item.prioridad).withValues(alpha: 0.08),
                                                  visualDensity: VisualDensity.compact,
                                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                ),
                                              ]),
                                            ],
                                          ),
                                        ),
                                        trailing: const Icon(Icons.chevron_right),
                                        onTap: () => abrirDetalle(item),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}
