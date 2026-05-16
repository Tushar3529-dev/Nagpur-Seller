import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local_seller/config/hive_storage.dart';

class LanguageCubit extends Cubit<Locale> {
  LanguageCubit() : super(Locale(HiveStorage.languageCode));

  Future<void> changeLanguage(String languageCode) async {
    await HiveStorage.setLanguageCode(languageCode);
    emit(Locale(languageCode));
  }
}
