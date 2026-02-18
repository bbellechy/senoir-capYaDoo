class Medication {
  final String? id;
  final String? tradenameTh;
  final String? tradenameEn;
  final String? basicDoseForm;
  final String? doseFormTh;
  final String? doseFormEn;
  final String? categoryUse;
  final String? legislationClass;
  final String? indication;
  final String? approvalDate;
  final String? validityDate;
  final String? licenseeName;

  Medication({
    this.id,
    this.tradenameTh,
    this.tradenameEn,
    this.basicDoseForm,
    this.doseFormTh,
    this.doseFormEn,
    this.categoryUse,
    this.legislationClass,
    this.indication,
    this.approvalDate,
    this.validityDate,
    this.licenseeName,
  });

  // Alias for backward compatibility or when only name is available
  // Display name format: <English Name> (<Thai Name>)
  String get name {
    if (tradenameEn != null && tradenameTh != null) {
      return '$tradenameEn ($tradenameTh)';
    }
    return tradenameEn ?? tradenameTh ?? '-';
  }

  factory Medication.fromJson(Map<String, dynamic> json) {
    return Medication(
      id: json['id']?.toString(),
      tradenameTh: json['tradenameTh'],
      tradenameEn: json['tradenameEn'],
      basicDoseForm: json['basicDoseForm'],
      doseFormTh: json['doseFormTh'],
      doseFormEn: json['doseFormEn'],
      categoryUse: json['categoryUse'],
      legislationClass: json['legislationClass'],
      indication: json['indication'],
      approvalDate: json['approvalDate'],
      validityDate: json['validityDate'],
      licenseeName: json['licenseeName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tradenameTh': tradenameTh,
      'tradenameEn': tradenameEn,
      'basicDoseForm': basicDoseForm,
      'doseFormTh': doseFormTh,
      'doseFormEn': doseFormEn,
      'categoryUse': categoryUse,
      'legislationClass': legislationClass,
      'indication': indication,
      'approvalDate': approvalDate,
      'validityDate': validityDate,
      'licenseeName': licenseeName,
    };
  }
}
