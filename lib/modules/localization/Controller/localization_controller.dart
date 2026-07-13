import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChangeLanguageEvent {
  final String languageCode;
  ChangeLanguageEvent(this.languageCode);
}

class LocalizationState {
  final Locale locale;
  LocalizationState({required this.locale});
}

class LocalizationBloc extends Bloc<ChangeLanguageEvent, LocalizationState> {
  LocalizationBloc(Locale initialLocale) : super(LocalizationState(locale: initialLocale)) {
    on<ChangeLanguageEvent>((event, emit) async {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('active_language_code', event.languageCode);
      } catch (e) {
        // print removed
      }
      emit(LocalizationState(locale: Locale(event.languageCode)));
    });
  }
}
