import 'dart:async';

import 'package:flutter/material.dart';

class OtpCountdown extends StatefulWidget {
  final int period;
  const OtpCountdown({super.key, required this.period});

  @override
  State<OtpCountdown> createState() => _OtpCountdownState();
}

class _OtpCountdownState extends State<OtpCountdown> {
  Timer? _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final unix = _now.millisecondsSinceEpoch ~/ 1000;
    final remaining = widget.period - (unix % widget.period);
    final progress = remaining / widget.period;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(width: 30, height: 30, child: CircularProgressIndicator(value: progress, strokeWidth: 3)),
        const SizedBox(width: 8),
        Text('${remaining}s', style: Theme.of(context).textTheme.labelLarge),
      ],
    );
  }
}
