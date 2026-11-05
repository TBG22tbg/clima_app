import 'package:clima_app/models/clima.dart';
import 'package:clima_app/service/clima_service.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // instancia responsavel pelas requisições HTTP.
  final ClimaService _servico = ClimaService();

  // Guarda a opeção assincrona de busca
  // late Future<double> _temperatura;
  late Future<Clima> _clima;

  @override
  void initState() {
    super.initState();
    // iniciamos a consulta um vez ao abrir a tela
    // _temperatura = _servico.buscarTemperatura();
    _clima = _servico.buscarClima();
  }

  void _atualizar() {
    setState(() {
      // _temperatura = _servico.buscarTemperatura();
      _clima = _servico.buscarClima();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ClimaApp'),
        actions: [
          // botão para executar a função atualizar
          IconButton(
            onPressed: _atualizar, 
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar Clima',
          ),
        ],
      ),
      body: FutureBuilder<Clima>(
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
                  Text('Consutando o clima...')
                ],
              )
            );
          }

          // hasError: o Future terminou com uma exceção
          if (snapshot.hasError) {
            // Mostrar a mensagem especifica do nosso serviço
            final erro = snapshot.error;
            final mensagem = erro is ClimaException
                  ? erro.mensagem
                  : 'Ocorreu um erro inesperado.';
            return Center(
              child:Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.wifi_off, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      mensagem,
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 16),

                    ElevatedButton.icon(
                      onPressed: _atualizar,
                      icon: const Icon(Icons.refresh),
                      label: const Text('data'),
                    )
                  ],
                ),
              )
            );
          }

          // final temperatura = snapshot.data;
          final clima = snapshot.data;

          if (clima == null) {
            return const Center(child: Text('Dados de clima indisponíveis.'));
          }

          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.thermostat, size: 60),
                const Text('São Paulo'),
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
    );
  }
}