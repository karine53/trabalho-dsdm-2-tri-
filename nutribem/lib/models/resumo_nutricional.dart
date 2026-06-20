class ResumoNutricional {
  final double totalCalorias;
  final double totalCarbs;
  final double totalProteina;
  final double totalGordura;
  final double totalAgua;

  const ResumoNutricional({
    this.totalCalorias = 0,
    this.totalCarbs = 0,
    this.totalProteina = 0,
    this.totalGordura = 0,
    this.totalAgua = 0,
  });

  factory ResumoNutricional.fromMap(Map<String, dynamic> map) =>
      ResumoNutricional(
        totalCalorias: (map['totalCalorias'] as num? ?? 0).toDouble(),
        totalCarbs: (map['totalCarbs'] as num? ?? 0).toDouble(),
        totalProteina: (map['totalProteina'] as num? ?? 0).toDouble(),
        totalGordura: (map['totalGordura'] as num? ?? 0).toDouble(),
        totalAgua: (map['totalAgua'] as num? ?? 0).toDouble(),
      );
}