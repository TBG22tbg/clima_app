//MODELO: representa uma resposat do clima com tipos conhecidos
// Cada objeto Clima guarda informações da mesma consulta

class Clima {
  // final o valor é definido no contrutor e não muda depois
  final double temperatura;
  final double sensacaoTermica;
  final int umidade;
  final double vento;

  // required: quem cria Clima, precisa fornecer cada campo
  const Clima({
    required this.temperatura,
    required this.sensacaoTermica,
    required this.umidade,
    required this.vento,
  });
 
 //factory Clima.fromJson() é um construtor nomeado que cria u, objeto a partir do Map recebido
  factory Clima.fromJson(Map<String, dynamic> json) {
    return Clima(
      temperatura: (json['temperature_2m'] as num).toDouble(),
      sensacaoTermica: (json['apparent_temperature'] as num).toDouble(),
      umidade: (json['relative_humidity_2m'] as num).toInt(),
      vento: (json['wind_speed_10m'] as num).toDouble(),

    );
  }
}