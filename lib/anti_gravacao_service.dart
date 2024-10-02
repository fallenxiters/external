import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AntiGravacaoService {
  final FlutterSecureStorage _storage = FlutterSecureStorage();
  final BuildContext context;
  final Function onSuccess;
  final Function onFailure;

  AntiGravacaoService({
    required this.context,
    required this.onSuccess,
    required this.onFailure,
  });

  Future<void> toggleAntiGravacao(bool isActivated) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool newState = !isActivated;
    prefs.setBool('anti_gravacao_activated', newState);

    if (newState) {
      onSuccess();  // Chama o callback para sucesso (ativada)
    } else {
      onFailure();  // Chama o callback para falha (desativada)
    }
  }

  Future<bool> isAntiGravacaoActivated() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool('anti_gravacao_activated') ?? false;
  }
}
