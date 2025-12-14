import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

final internetStatusProvider = StreamProvider<InternetConnectionStatus>((ref) {
  return InternetConnectionChecker().onStatusChange;
});
