import 'package:clima_app/models/clima.dart';
import 'package:clima_app/service/clima_service.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // O controller permitir ler o texto do campos de pesquisa
  final TextEditingController _cidadeController = TextEditingController(
    text: 'São Paulo',
  );
  // instancia responsavel pelas requisições HTTP.
  final ClimaService _servico = ClimaService();

  // Guarda a opeção assincrona de busca
  // late Future<double> _temperatura;
  late Future<Clima> _clima;

  // Nome exibido acima das informações meteorologicas.
  String _cidadeExibida = 'São Paulo';

  @override
  void initState() {
    super.initState();
    // iniciamos a consulta um vez ao abrir a tela
    // _temperatura = _servico.buscarTemperatura();
    _clima = _servico.buscarClima(_cidadeExibida);
  }

  // void _atualizar() {
  //   setState(() {
  //     // _temperatura = _servico.buscarTemperatura();
  //     _clima = _servico.buscarClima();
  //   });
  // }

  // Executando a busca com o texto digitado pela primeira vez
  void _pesquisar() {
    // trim() evitar buscas com espaços extras
    final nome = _cidadeController.text.trim();
    // setState informa a interface que ela precisa atualizar
    setState(() {
      _cidadeExibida = nome;

      // Um novo Future faz o FututeBuilder carregar novamente.
      _clima = _servico.buscarClima(nome);
    });
  }

  @override
  void dispose() {
    // Libera os recursos do controller ao destruir a tela.
    _cidadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ClimaApp'),
        actions: [
          // botão repete a consulta da cidade exibida
          IconButton(
            onPressed: () {
              setState(() {
                _clima = _servico.buscarClima(_cidadeExibida);
              });
            },
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar Clima',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [
            TextField(
              controller: _cidadeController,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _pesquisar(),
              decoration: const InputDecoration(
                labelText: 'Cidade',
                hintText: 'Ex: Campinas',
                prefixIcon: Icon(Icons.location_city),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            ElevatedButton.icon(
              onPressed: _pesquisar,
              label: const Text('Pesquisar'),
              icon: Icon(Icons.search),
            ),

            const SizedBox(height: 20),

            // Expanded oferece o espaço restante à aerea de dados
            Expanded(
              child: FutureBuilder<Clima>(
                future: _clima,
                builder: (context, snapshot) {
                  // Enquanto a resposta não chega, mostra o progresso
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Consultando o clima ...'),
                        ],
                      ),
                    );
                  }

                  // hasError: o Future terminou com uma exceção
                  if (snapshot.hasError) {
                    // mostrar a mensagem expecifica do nosso serviço
                    final erro = snapshot.error;
                    final mensagem = erro is ClimaException
                        ? erro.mensagem
                        : 'Ocorreu um erro inesperado.';
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.wifi_off, size: 48),
                            const SizedBox(height: 12),
                            Text(mensagem, textAlign: TextAlign.center),

                            const SizedBox(height: 16),

                            ElevatedButton.icon(
                              onPressed: _pesquisar,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Tentar Novamente'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  // final temperatura = snapshot.data;
                  final clima = snapshot.data;

                  if (clima == null) {
                    return const Center(
                      child: Text('Dados de clima indisponíveis.'),
                    );
                  }

                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.thermostat, size: 60),
                        const Text('São paulo'),
                        Text(
                          '${clima.temperatura.toStringAsFixed(1)} °C',
                          style: const TextStyle(fontSize: 36),
                        ),
                        Text(
                          'Sensação: '
                          '${clima.sensacaoTermica.toStringAsFixed(1)} °C',
                        ),

                        Text('Umidade: ${clima.umidade}%'),
                        Text('Vento: ${clima.vento.toStringAsFixed(1)} km/h'),
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