// Permitir que indentificamos quando o dispositivo não alcança a rede
import 'dart:io';

// Converter o texto em JSON da resposta em objetos Dart.
import 'dart:convert';

// Permite reconhecer quando uma operação ultrapassa o tempo de limite
import 'dart:async';

import 'package:clima_app/models/clima.dart';

// Biblioteca externa usada para fazer requisições HTTP.
import 'package:http/http.dart' as http;

import 'package:flutter/foundation.dart';

// Exceção própria: gyarda a mensagem que a tela pode mostrar
class ClimaException implements Exception {
  final String mensagem;
  // Contrutor recebe o texto explicativo do erro
  const ClimaException(this.mensagem);
  // Define como a exceção será converida em texto.
  @override
  String toString() => mensagem;
}

// Reúne a logica de comunicação com a API
class ClimaService {
  // Future<double>: o resultado será um numero decimal.
  //// mas chegara no futuro, apos a resposta da internet.
  Future<double> buscarTemperatura() async {
    // Endereço com as coodernadas de São Paulo
    //current=temperature_2m pedir a temperatura atual.
    final url = Uri.parse(
      'https://api.open-meteo.com/v1/forecast'
      '?latitude=-23.55&longitude=-46.63'
      '&current=temperature_2m'
      '&timezone=America%2FSao_Paulo',
    );

    //esperar  a resposta sem travar a interface
    // timeout evita aguardar indefinidamente.
    final respota = await http.get(url).timeout(const Duration(seconds: 12));

    // 200 siginifica que a consulta HTTP foi bem-sucessida
    if (respota.statusCode != 200) {
      // Lança o erro para interface poder informar a falhar
      throw Exception('Erro HTTP: ${respota.statusCode}');
    }

    // JsonDecode transforma o texto JSON em dados Dart.
    // Map<String, dynamic> indica um objeto JSON.
    final dados = jsonDecode(respota.body) as Map<String, dynamic>;

    // current é um objeto dentro do JSON recebido
    final atual = dados['current'] as Map<String, dynamic>;

    // num aceita numeros inteuros ou decimais
    //toDouble() garante o yipo double prometido no Future.
    final temperatura = atual['temperature_2m'] as num;
    return temperatura.toDouble();
  }

  // a forma antiga de fazer busca do nosso clima
  Future<Clima> buscarClimaAntiga() async {
    // Endereço com as coodernadas de São Paulo
    //current=temperature_2m pedir a temperatura atual.
    final url = Uri.parse(
      'https://api.open-meteo.com/v1/forecast'
      '?latitude=-23.55&longitude=-46.63'
      '&current=temperature_2m,apparent_temperature,'
      'relative_humidity_2m,wind_speed_10m'
      '&timezone=America%2FSao_Paulo',
    );

    try {
      //esperar  a resposta sem travar a interface
      // timeout evita aguardar indefinidamente.
      final resposta = await http.get(url).timeout(const Duration(seconds: 12));

      // 200 siginifica que a consulta HTTP foi bem-sucessida
      if (resposta.statusCode != 200) {
        // Lança o erro para interface poder informar a falhar
        throw const ClimaException(
          'O serviço de clima está indisponivel. Tente novamente.',
        );
      }

      // JsonDecode transforma o texto JSON em dados Dart.
      // Map<String, dynamic> indica um objeto JSON.
      final dados = jsonDecode(resposta.body);
      if (dados is! Map<String, dynamic>) {
        throw const ClimaException('Resposta inesperada da API.');
      }

      // current é um objeto dentro do JSON recebido
      final atual = dados['current'];
      if (atual is! Map<String, dynamic>) {
        throw const ClimaException('Dados Atuais indisponíveis.');
      }
      // O modelo faz a conversão de chaves JSON em campos Dart.
      // Erros de tipo ou campos ausentes serão tratados abaixo.
      return Clima.fromJson(atual);
    } on ClimaException {
      // Preserva as mensagem que nos criamos la em cima
      rethrow;
    } on SocketException {
      // Sem rede. DNS indisponivel ou conexão recusada
      throw const ClimaException(
        'Sem conexão coma internet. Verifique sua Rede.',
      );
    } on TimeoutException {
      // A API demorou mais que o tempo permitido
      throw ClimaException('A consulta demorou de mais. Tente novamente.');
    } on http.ClientException {
      // Outros problemas reportados pelo Cliente
      throw const ClimaException(
        'Não foi possivel conectar ao servidor de clima.',
      );
    } on FormatException {
      // O texto retornado não contém um JSON válido.
      throw const ClimaException('Resposa invalida da API.');
    } on TypeError {
      throw const ClimaException(
        'Os dados recebidos estão incompletos ou inválidos.',
      );
    }
  }

  // Nova forma de busca clima passando a cidade
  Future<Clima> buscarClima(String cidade) async {
    final nome = cidade.trim();
    if (nome.isEmpty) {
      throw const ClimaException('Digite o nomede uma cidade.');
    }

    try {
      final geoUrl = Uri.https('geocoding-api.open-meteo.com', '/v1/search', {
        'name': nome,
        'count': '1',
        'language': 'pt',
        'format': 'json',
      });

      //esperar  a resposta sem travar a interface
      // timeout evita aguardar indefinidamente.
      final geoResposta = await http
          .get(geoUrl)
          .timeout(const Duration(seconds: 12));

      // 200 siginifica que a consulta HTTP foi bem-sucessida
      if (geoResposta.statusCode != 200) {
        // Lança o erro para interface poder informar a falhar
        throw const ClimaException('Falha ao localizar cidade.');
      }

      // JsonDecode transforma o texto JSON em dados Dart.
      // Map<String, dynamic> indica um objeto JSON.
      final geoDados = jsonDecode(geoResposta.body);
      if (geoDados is! Map<String, dynamic>) {
        throw const ClimaException('Resposta da localização inválida.');
      }

      // results é a lista de cidades encontradas
      final resultados = geoDados['results'];
      if (resultados is! List || resultados.isEmpty) {
        throw const ClimaException('Cidade não encontrada.');
      }

      debugPrint('RESULTADO: $resultados');
      debugPrint('Tipo: ${resultados.first.runtimeType}');
      final local = resultados.first;
      if (local is! Map<String, dynamic>) {
        throw const ClimaException('Localização inválida.');
      }

      // num aceita tanto numeros inteiros como decimais.
      final latitude = local['latitude'];
      final longitude = local['longitude'];
      if (latitude is! num || longitude is! num) {
        throw const ClimaException(' Coordenadas indisponíveis.');
      }

      final climaUrl = Uri.https('api.open-meteo.com', '/v1/forecast', {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'current':
            'temperature_2m,apparent_temperature,'
            'relative_humidity_2m,wind_speed_10m',
        'timezone': 'auto',
      });

      final resposta = await http
          .get(climaUrl)
          .timeout(const Duration(seconds: 12));
      if (resposta.statusCode != 200) {
        throw const ClimaException('Falha ao consultar clima.');
      }

      final dados = jsonDecode(resposta.body);
      if (dados is! Map<String, dynamic>) {
        throw const ClimaException('Resposta de clima inválida.');
      }

      // current é um objeto dentro do JSON recebido
      final atual = dados['current'];
      if (atual is! Map<String, dynamic>) {
        throw const ClimaException('Dados Atuais indisponíveis.');
      }
      // O modelo faz a conversão de chaves JSON em campos Dart.
      // Erros de tipo ou campos ausentes serão tratados abaixo.
      return Clima.fromJson(atual);
    } on ClimaException {
      // Preserva as mensagem que nos criamos la em cima
      rethrow;
    } on SocketException {
      // Sem rede. DNS indisponivel ou conexão recusada
      throw const ClimaException(
        'Sem conexão coma internet. Verifique sua Rede.',
      );
    } on TimeoutException {
      // A API demorou mais que o tempo permitido
      throw ClimaException('A consulta demorou de mais. Tente novamente.');
    } on http.ClientException {
      // Outros problemas reportados pelo Cliente
      throw const ClimaException(
        'Não foi possivel conectar ao servidor de clima.',
      );
    } on FormatException {
      // O texto retornado não contém um JSON válido.
      throw const ClimaException('Resposa invalida da API.');
    } on TypeError {
      throw const ClimaException(
        'Os dados recebidos estão incompletos ou inválidos.',
      );
    }
  }
}