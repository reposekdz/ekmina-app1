import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final connectivityServiceProvider = Provider((ref) => ConnectivityService());

final connectivityStatusProvider = StreamProvider<ConnectivityResult>((ref) {
  return ref.watch(connectivityServiceProvider).connectivityStream;
});

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  
  Stream<ConnectivityResult> get connectivityStream => _connectivity.onConnectivityChanged.map((results) => results.first);

  Future<bool> get isConnected async {
    final result = await _connectivity.checkConnectivity();
    return result.first != ConnectivityResult.none;
  }

  Future<ConnectivityResult> checkConnectivity() async {
    final results = await _connectivity.checkConnectivity();
    return results.first;
  }
}
