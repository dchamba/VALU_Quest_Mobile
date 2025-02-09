
class QuestionsModel {

  String? oId;
  String? questionId;
  String? subCatId;
  String? questionName;
  String? quesType;
  String? minValue;
  String? maxValue;
  String? unit;
  String? isFixed;
  String? isBMI;
  String? isActive;
  String? createdBy;
  String? createdDate;
  String? modifiedBy;
  String? modifiedDate;
  String? blockId;
  String? blockName;
  String? blockNewName;
  String? questionTreeId;
  List<Option>? options;
  QuestionsModel({
    this.oId,
    this.questionId,
    this.subCatId,
    this.questionName,
    this.quesType,
    this.minValue,
    this.maxValue,
    this.unit,
    this.isFixed,
    this.isBMI,
    this.isActive,
    this.createdBy,
    this.createdDate,
    this.modifiedBy,
    this.modifiedDate,
    this.options,
    this.blockId,
    this.blockName,
    this.blockNewName,
    this.questionTreeId
  });

  factory QuestionsModel.fromJson(Map<String, dynamic> json) {
    return QuestionsModel(
      oId: json['optionId'],
      questionId: json['questionId'],
      subCatId: json['subCatId'],
      questionName: json['questionName'],
      quesType: json['quesType'],
      minValue: json['minValue'],
      maxValue: json['maxValue'],
      unit: json['unit'],
      isFixed: json['isFixed'].toString(),
      isBMI: json['isBMI'].toString(),
      isActive: json['isActive'],
      blockId: json['blockId'],
      blockName: json['blockName'],
      blockNewName: json['blockNameNew'],
      questionTreeId: json['questionTreeId'],
      createdBy: json['createdBy'],
      createdDate: json['createdDate'],
      modifiedBy: json['modifiedBy'],
      modifiedDate: json['modifiedDate'],
      options: (json['options'] as List)
          .map((item) => Option.fromJson(item))
          .toList(),
    );
  }
}



class Option {
  String? optionId;
  String? optionName;
  String? optionValue;
  String? isActive;
  String? refOptionId;

  Option(
      {this.optionId,
        this.optionName,
        this.optionValue,
        this.isActive,
        this.refOptionId});

  factory Option.fromJson(Map<String, dynamic> json) {
    return Option(
      optionId: json['optionId'],
      optionName: json['optionName'],
      optionValue: json['option_value'],
      refOptionId: json['refOptionId'],
      isActive: json['isActive'],
    );
  }
}
