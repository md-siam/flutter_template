import 'package:flutter/material.dart';

import 'package:flutter_template/shared/presentation/theme/base/app_colors.dart';

abstract class BaseColorTheme {
  AppColors get getAppColors;

  ThemeData getTheme();
}
