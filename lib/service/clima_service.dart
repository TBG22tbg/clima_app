// Permitir que indentificamos quando o dispositivo não alcança a rede
import 'dart:io';

// Converter o texto em JSON da resposta em objetos Dart.
import 'dart:convert';

// Permite reconhecer quando uma operação ultrapassa o tempo de limite
import 'dart:async';

//
import 'package:clima_app/models/clima.dart';

// Biblioteca externa usada para fazer requisições HTTP.
import 'package:http/http.dart' as http;

// Exceção própria: guarda a mensagem que a tela pode mostrar
class ClimaException implements Exception {
  final String mensagem;
  // construtor recebe o texto explicativo do erro
  const ClimaException(this.mensagem);
  // Define como a exceção 
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

  Future<Clima> buscarClima() async {
    // Endereço com as coodernadas de São Paulo
    //current=temperature_2m pedir a temperatura atual.
    final url = Uri.parse(
      'https://api.open-meteo.com/v1/forecast'
      '?latitude=-23.55&longitude=-46.63'
      '&current=temperature_2m,apparent_temperature,'
      'relative_humidity_2m,wind_speed_10m'
      '&timezone=America%2FSao_Paulo',
    );

    try{
    //esperar  a resposta sem travar a interface
    // timeout evita aguardar indefinidamente.
    final resposta = await http.get(url).timeout(const Duration(seconds: 12));

    // 200 siginifica que a consulta HTTP foi bem-sucessida
    if (resposta.statusCode != 200) {
      // Lança o erro para interface poder informar a falhar
      throw const ClimaException(
        'O serviço de clima está indisponivel. Tente novamente.'
      );
    }

    // JsonDecode transforma o texto JSON em dados Dart.
    // Map<String, dynamic> indica um objeto JSON.
    final dados = jsonDecode(resposta.body);
    if(dados is! Map<String, dynamic>){
      throw const ClimaException('Resposta inesperada da API.');
    }

    // current é um objeto dentro do JSON recebido
    final atual = dados['current'];
    if(atual is! Map<String, dynamic>){
      throw const ClimaException('Dados atuais indisponíveis.');
    }
    // o modelo faz a conversaõ de chaves JSON em campos Dart.
    // Erros de tipo ou campos ausentes serão tratados abaixo.
    return Clima.fromJson(atual);
    } on ClimaException {
      // Preserva as mensagens que nos criamos la em cima
      rethrow;
    } on SocketException {
      // Sem rede. DNS indisponivel ou conexão recusada
      throw const ClimaException(
        'Sem conexção com a internet. Verifique a rede.',
      );
    } on TimeoutException {
      throw ClimaException('A consulta demorou de mais. Tente novamente.');
    } on http.ClientException{
      // Outros problemas reportados pelo cliente
      throw const ClimaException(
        'Não foi possivel conectar ao servidor de clima.',
      );
    } on FormatException {
      // o texto retornado não contem um JSON válido.
      throw const ClimaException('Resposta invalida da API.');
    } on TypeError {
      throw const ClimaException(
        'Os dados recebidos estão incompletos ou inválidos.',
      );
    }
      
  }
}