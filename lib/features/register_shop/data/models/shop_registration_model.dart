import '../../../../core/models/model_converters.dart';
import '../../../../shared/enums/database_enums.dart';

class ShopRegistrationModel {
  const ShopRegistrationModel({
    required this.id,
    required this.userId,
    required this.shopName,
    required this.phoneNumber,
    required this.address,
    required this.fullName,
    required this.cccdNumber,
    required this.dateOfBirth,
    required this.issuedDate,
    required this.issuedPlace,
    required this.businessType,
    this.shopDescription,
    this.cccdFrontUrl,
    this.cccdBackUrl,
    this.businessLicenseUrl,
    this.taxCode,
    this.status = ShopRegistrationStatus.pending,
    this.rejectionReason,
    this.submittedAt,
    this.reviewedAt,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final String shopName;
  final String? shopDescription;
  final String phoneNumber;
  final String address;

  final String? cccdFrontUrl;
  final String? cccdBackUrl;
  final String fullName;
  final String cccdNumber;
  final DateTime dateOfBirth;
  final DateTime issuedDate;
  final String issuedPlace;

  final String? businessLicenseUrl;
  final String? taxCode;
  final BusinessType businessType;

  final ShopRegistrationStatus status;
  final String? rejectionReason;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory ShopRegistrationModel.fromJson(Map<String, dynamic> json) {
    return ShopRegistrationModel(
      id: json['id'].toString(),
      userId: json['user_id'].toString(),
      shopName: json['shop_name'].toString(),
      shopDescription: json['shop_description'] as String?,
      phoneNumber: json['phone_number'].toString(),
      address: json['address'].toString(),
      cccdFrontUrl: json['cccd_front_url'] as String?,
      cccdBackUrl: json['cccd_back_url'] as String?,
      fullName: json['full_name'].toString(),
      cccdNumber: json['cccd_number'].toString(),
      dateOfBirth: dateTimeFromJson(json['date_of_birth']) ?? DateTime.now(),
      issuedDate: dateTimeFromJson(json['issued_date']) ?? DateTime.now(),
      issuedPlace: json['issued_place'].toString(),
      businessLicenseUrl: json['business_license_url'] as String?,
      taxCode: json['tax_code'] as String?,
      businessType: enumFromSnake(
        BusinessType.values,
        json['business_type'],
        BusinessType.individual,
      ),
      status: enumFromSnake(
        ShopRegistrationStatus.values,
        json['status'],
        ShopRegistrationStatus.pending,
      ),
      rejectionReason: json['rejection_reason'] as String?,
      submittedAt: dateTimeFromJson(json['submitted_at']),
      reviewedAt: dateTimeFromJson(json['reviewed_at']),
      createdAt: dateTimeFromJson(json['created_at']),
      updatedAt: dateTimeFromJson(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'shop_name': shopName,
    'shop_description': shopDescription,
    'phone_number': phoneNumber,
    'address': address,
    'cccd_front_url': cccdFrontUrl,
    'cccd_back_url': cccdBackUrl,
    'full_name': fullName,
    'cccd_number': cccdNumber,
    'date_of_birth': dateTimeToJson(dateOfBirth),
    'issued_date': dateTimeToJson(issuedDate),
    'issued_place': issuedPlace,
    'business_license_url': businessLicenseUrl,
    'tax_code': taxCode,
    'business_type': enumToSnake(businessType),
    'status': enumToSnake(status),
    'rejection_reason': rejectionReason,
    'submitted_at': dateTimeToJson(submittedAt),
    'reviewed_at': dateTimeToJson(reviewedAt),
    'created_at': dateTimeToJson(createdAt),
    'updated_at': dateTimeToJson(updatedAt),
  };

  String get statusDisplay => switch (status) {
    ShopRegistrationStatus.pending => 'Đang chờ duyệt',
    ShopRegistrationStatus.approved => 'Đã duyệt',
    ShopRegistrationStatus.rejected => 'Bị từ chối',
  };

  String get businessTypeDisplay => switch (businessType) {
    BusinessType.individual => 'Cá nhân',
    BusinessType.household => 'Hộ kinh doanh',
    BusinessType.company => 'Doanh nghiệp',
  };
}
