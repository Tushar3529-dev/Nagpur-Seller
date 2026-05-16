import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthLoginRequested(this.email, this.password);

  @override
  List<Object?> get props => [email, password];
}

class AuthSignUpRequested extends AuthEvent {
  final String name;
  final String email;
  final String phone;
  final String password;
  final String address;
  final String city;
  final String state;
  final String landmark;
  final String zipcode;
  final String country;
  final String latitude;
  final String longitude;
  final String businessLicensePath;
  final String articlesOfIncorporationPath;
  final String nationalIdCardPath;
  final String authorizedSignaturePath;

  const AuthSignUpRequested({
    required this.name,
    required this.email,
    required this.phone,
    required this.password,
    required this.address,
    required this.city,
    required this.state,
    required this.landmark,
    required this.zipcode,
    required this.country,
    required this.latitude,
    required this.longitude,
    required this.businessLicensePath,
    required this.articlesOfIncorporationPath,
    required this.nationalIdCardPath,
    required this.authorizedSignaturePath,
  });

  @override
  List<Object?> get props => [
    name,
    email,
    phone,
    password,
    address,
    city,
    state,
    landmark,
    zipcode,
    country,
    latitude,
    longitude,
    businessLicensePath,
    articlesOfIncorporationPath,
    nationalIdCardPath,
    authorizedSignaturePath,
  ];
}

class AuthLogoutRequested extends AuthEvent {}

class AuthPhoneSendOTPRequested extends AuthEvent {
  final String phoneNumber;

  const AuthPhoneSendOTPRequested(this.phoneNumber);

  @override
  List<Object?> get props => [phoneNumber];
}

class AuthPhoneVerifyOTPRequested extends AuthEvent {
  final String verificationId;
  final String otp;
  final String? phoneNumber;

  const AuthPhoneVerifyOTPRequested({
    required this.verificationId,
    required this.otp,
    this.phoneNumber,
  });

  @override
  List<Object?> get props => [verificationId, otp, phoneNumber];
}
