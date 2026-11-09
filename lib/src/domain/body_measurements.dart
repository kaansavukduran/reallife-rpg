import 'wellness_values.dart';

/// The adult reference is opt-in. BMI alone does not establish health status.
class BodyMeasurements {
  const BodyMeasurements({this.heightCm, this.adultReference = false});
  final double? heightCm;
  final bool adultReference;
  Map<String, Object?> toJson() => {
    'height_cm': heightCm,
    'adult_reference': adultReference,
  };
  static BodyMeasurements fromJson(Object? raw) {
    if (raw == null) return const BodyMeasurements();
    final j = wellnessObject(raw);
    if (j['adult_reference'] is! bool) {
      throw const FormatException('Invalid adult reference');
    }
    return BodyMeasurements(
      heightCm: wellnessOptional(j, 'height_cm', 50, 250),
      adultReference: j['adult_reference']! as bool,
    );
  }
}

double? bodyMassIndex(double? kg, double? heightCm) {
  if (kg == null ||
      heightCm == null ||
      !kg.isFinite ||
      !heightCm.isFinite ||
      kg <= 0 ||
      heightCm <= 0) {
    return null;
  }
  final m = heightCm / 100;
  return kg / (m * m);
}

enum AdultBmiRange {
  underweight,
  normal,
  overweight,
  obesity1,
  obesity2,
  obesity3,
}

AdultBmiRange adultBmiRange(double bmi) {
  if (!bmi.isFinite || bmi <= 0) throw ArgumentError.value(bmi, 'bmi');
  if (bmi < 18.5) return AdultBmiRange.underweight;
  if (bmi < 25) return AdultBmiRange.normal;
  if (bmi < 30) return AdultBmiRange.overweight;
  if (bmi < 35) return AdultBmiRange.obesity1;
  if (bmi < 40) return AdultBmiRange.obesity2;
  return AdultBmiRange.obesity3;
}
