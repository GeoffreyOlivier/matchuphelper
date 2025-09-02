import 'package:flutter/foundation.dart';

/// Debug logger: prints only in debug mode. No output in release/profile.
void logd(String message) {
  if (kDebugMode) {
    debugPrint(message);
  }
}
