
class ResumoNutricional {

  // Quantidade total de calorias consumidas.
  final double totalCalorias;

  // Quantidade total de carboidratos consumidos (em gramas).
  final double totalCarbs;

  // Quantidade total de proteínas consumidas (em gramas).
  final double totalProteina;

  // Quantidade total de gorduras consumidas (em gramas).
  final double totalGordura;

  // Quantidade total de água ingerida (em litros).
  final double totalAgua;

  // Construtor da classe.
  //
  // Caso nenhum valor seja informado, todos os totais
  // serão inicializados com zero.
  //
  // Isso garante que o aplicativo tenha valores válidos
  // mesmo quando ainda não houver refeições cadastradas.
  const ResumoNutricional({
    this.totalCalorias = 0,
    this.totalCarbs = 0,
    this.totalProteina = 0,
    this.totalGordura = 0,
    this.totalAgua = 0,
  });

  // Método responsável por criar um objeto ResumoNutricional
  // a partir de um Map recebido do banco de dados.
  //
  // Cada valor é convertido para o tipo double.
  // Caso algum campo não exista ou seja nulo,
  // será utilizado o valor 0 para evitar erros.
  factory ResumoNutricional.fromMap(Map<String, dynamic> map) =>
      ResumoNutricional(

        // Recupera o total de calorias consumidas.
        totalCalorias: (map['totalCalorias'] as num? ?? 0).toDouble(),
        // as num diz que o valor deve ser tratado como um numero
        // ? que pode ser nulo,
        //?? mas se existir o num usa ele 
        //double transforma em decimal para armazenar 

        // Recupera o total de carboidratos consumidos.
        totalCarbs: (map['totalCarbs'] as num? ?? 0).toDouble(),

        // Recupera o total de proteínas consumidas.
        totalProteina: (map['totalProteina'] as num? ?? 0).toDouble(),

        // Recupera o total de gorduras consumidas.
        totalGordura: (map['totalGordura'] as num? ?? 0).toDouble(),

        // Recupera o total de água ingerida.
        totalAgua: (map['totalAgua'] as num? ?? 0).toDouble(),
      );
}