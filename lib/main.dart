import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'core/time/time_service.dart';
import 'presentation/screens/main_screen.dart';

void main() => runApp(const OneDayApp());

class OneDayApp extends StatelessWidget {
  const OneDayApp({super.key, this.timeService});

  final TimeService? timeService;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: '오늘 하루',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    home: MainScreen(timeService: timeService ?? SystemTimeService()),
  );
}
