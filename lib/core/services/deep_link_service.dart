import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

class DeepLinkService {
  DeepLinkService._();
  static final _instance = DeepLinkService._();
  factory DeepLinkService() => _instance;

  final _controller = StreamController<String>.broadcast();
  Stream<String> get onDeepLink => _controller.stream;
  late final AppLinks _appLinks;

  Future<void> init() async {
    _appLinks = AppLinks();

    _appLinks.uriLinkStream.listen((uri) {
      _handleUri(uri);
    });
  }

  void _handleUri(Uri uri) {
    final host = uri.host;

    if (host == 'auth-callback') {
      _controller.add('verify');
    } else if (host == 'reset-password') {
      _controller.add('reset');
    }
  }
}
