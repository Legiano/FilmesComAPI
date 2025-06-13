// ignore_for_file: avoid_print
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:logging/logging.dart';

void main() {
  _setupLogging();
  runApp(const MeuAppHTTP());
}

void _setupLogging() {
  Logger.root.level = Level.ALL; 
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });
}

final Logger logger = Logger('MeuAppHTTP');

class Filme {
  final int id;
  final String titulo;
  final bool favorito;

  Filme({required this.id, required this.titulo, required this.favorito});
// contrutor para converter de JSON para objeto Filme
  factory Filme.fromJson(Map<String, dynamic> json) {
    return Filme(
      id: json['id'],
      titulo: json['titulo'],
      favorito: json['favorito'],
    );
  }
}

class MeuAppHTTP extends StatefulWidget {
  const MeuAppHTTP({super.key});

  @override
  State<MeuAppHTTP> createState() => _MeuAppHTTPState();
}

class _MeuAppHTTPState extends State<MeuAppHTTP> {
  List<Filme> filmes = [];
  bool carregando = true;
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    carregarFilmes();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> carregarFilmes() async {
    try {
      final response = await http.get(Uri.parse('http://localhost:3000/ws/filme'));
      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        setState(() {
          filmes = jsonData.map((item) => Filme.fromJson(item)).toList();
          carregando = false;
        });
        logger.info('Filmes carregados com sucesso');
      } else {
        logger.warning('Erro ao carregar filmes. Código: ${response.statusCode}');
      }
    } catch (e) {
      logger.severe('Erro de conexão ao carregar filmes: $e');
    }
  }

  Future<void> adicionarFilme(String titulo) async {
    try {
      final response = await http.post(
        Uri.parse('http://localhost:3000/ws/filme'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'titulo': titulo, 'favorito': false}),
      );

      if (response.statusCode == 201) {
        await carregarFilmes();
        logger.info('Filme adicionado: $titulo');
      } else {
        logger.warning('Erro ao adicionar filme. Código: ${response.statusCode}');
      }
    } catch (e) {
      logger.severe('Erro de conexão ao adicionar filme: $e');
    }
  }

 Future<void> alterarFavorito(Filme filme) async {
  try {
    final url = Uri.parse('http://localhost:3000/ws/filme');
    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'id': filme.id,
        'titulo': filme.titulo,
        'favorito': !filme.favorito,
      }),
    );

    if (response.statusCode == 200) {
      await carregarFilmes();
      logger.info('Favorito alterado para o filme id ${filme.id}');
    } else {
      logger.warning('Erro ao alterar favorito: ${response.statusCode}');
    }
  } catch (e) {
    logger.severe('Erro de conexão ao alterar favorito: $e');
  }
}

  Future<void> removerFilme(int id) async {
    try {
      final url = Uri.parse('http://localhost:3000/ws/filme/$id');
      final response = await http.delete(url);

      if (response.statusCode == 200) {
        await carregarFilmes();
        logger.info('Filme removido: id $id');
      } else {
        logger.warning('Erro ao remover filme: ${response.statusCode}');
      }
    } catch (e) {
      logger.severe('Erro de conexão ao remover filme: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: const Text("Meus Filmes Favoritos usando (HTTP)")),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        labelText: "Novo filme",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      final titulo = _controller.text.trim();
                      if (titulo.isNotEmpty) {
                        adicionarFilme(titulo);
                        _controller.clear();
                        FocusScope.of(context).unfocus(); 
                      }
                    },
                  )
                ],
              ),
            ),
            Expanded(
              child: carregando
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.separated(
                      itemCount: filmes.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, index) {
                        final filme = filmes[index];
                        return ListTile(
                          title: Text(filme.titulo),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: () => alterarFavorito(filme),
                                icon: Icon(
                                  Icons.favorite,
                                  color: filme.favorito ? Colors.red : Colors.grey,
                                ),
                              ),
                              const SizedBox(width: 16),
                              GestureDetector(
                                onTap: () => removerFilme(filme.id),
                                child: const Icon(
                                  Icons.delete,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
