class Medication {
  final String tradenameTh;
  final String tradenameEn;
  final String categoryUse;
  final String legislationClass;
  final String indication;

  Medication({
    required this.tradenameTh,
    required this.tradenameEn,
    required this.categoryUse,
    required this.legislationClass,
    required this.indication,
  });

  factory Medication.fromJson(Map<String, dynamic> json) {
    return Medication(
      tradenameTh: json['tradenameTh'],
      tradenameEn: json['tradenameEn'],
      categoryUse: json['categoryUse'],
      legislationClass: json['legislationClass'],
      indication: json['indication'],
    );
  }
}
