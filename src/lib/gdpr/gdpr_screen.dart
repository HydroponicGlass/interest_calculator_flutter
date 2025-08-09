import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

import '../gdpr/gpdr_helper.dart';

class GdprScreen extends StatefulWidget {
  final Widget nextScreen;

  const GdprScreen({super.key, required this.nextScreen});

  @override
  State<GdprScreen> createState() => _GdprScreenState();
}

class _GdprScreenState extends State<GdprScreen> {
  final Logger _logger = Logger();
  final GdprHelper _gdprHelper = GdprHelper();

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final navigator = Navigator.of(context);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _gdprHelper.init();
      navigator.pushReplacement(
        MaterialPageRoute(builder: (context) => widget.nextScreen),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
