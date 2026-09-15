import 'package:flutter/material.dart';

class OnboardingData {
  final String titleTop;
  final String titleAccent;
  final String subtitle;
  final String imagePath;
  final Color accentColor;
  final String primaryButtonText;

  const OnboardingData({
    required this.titleTop,
    required this.titleAccent,
    required this.subtitle,
    required this.imagePath,
    required this.accentColor,
    required this.primaryButtonText,
  });
}
