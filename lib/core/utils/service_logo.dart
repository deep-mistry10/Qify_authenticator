import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../constants/app_constants.dart';

class ServiceLogo {
  const ServiceLogo._();

  static Widget? logoFor(String issuer) {
    final name = issuer.trim().toLowerCase();

    FaIconData? icon;

    if (name.contains('github')) {
      icon = FontAwesomeIcons.github;
    } else if (name == 'google' ||
        name.contains('google workspace') ||
        name.contains('google cloud')) {
      icon = FontAwesomeIcons.google;
    } else if (name.contains('facebook') || name == 'meta') {
      icon = FontAwesomeIcons.facebook;
    } else if (name.contains('microsoft') ||
        name.contains('outlook') ||
        name.contains('hotmail') ||
        name.contains('office 365') ||
        name.contains('office365')) {
      icon = FontAwesomeIcons.microsoft;
    } else if (name.contains('apple')) {
      icon = FontAwesomeIcons.apple;
    } else if (name.contains('amazon')) {
      icon = FontAwesomeIcons.amazon;
    } else if (name.contains('discord')) {
      icon = FontAwesomeIcons.discord;
    } else if (name.contains('gitlab')) {
      icon = FontAwesomeIcons.gitlab;
    } else if (name.contains('slack')) {
      icon = FontAwesomeIcons.slack;
    } else if (name.contains('reddit')) {
      icon = FontAwesomeIcons.reddit;
    } else if (name.contains('spotify')) {
      icon = FontAwesomeIcons.spotify;
    } else if (name.contains('telegram')) {
      icon = FontAwesomeIcons.telegram;
    } else if (name.contains('youtube')) {
      icon = FontAwesomeIcons.youtube;
    } else if (name.contains('twitch')) {
      icon = FontAwesomeIcons.twitch;
    } else if (name.contains('whatsapp')) {
      icon = FontAwesomeIcons.whatsapp;
    } else if (name.contains('linkedin')) {
      icon = FontAwesomeIcons.linkedin;
    } else if (name.contains('twitter') || name == 'x') {
      icon = FontAwesomeIcons.xTwitter;
    }

    if (icon == null) {
      return null;
    }

    return FaIcon(
      icon,
      size: 22,
      color: AppConstants.primary,
    );
  }

  static Widget avatar(String issuer) {
    final logo = logoFor(issuer);

    final normalized = issuer.trim();

    final initial = normalized.isEmpty
        ? '?'
        : normalized.substring(0, 1).toUpperCase();

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppConstants.primary.withValues(alpha: 0.08),
        shape: BoxShape.circle,
        border: Border.all(
          color: AppConstants.primary.withValues(alpha: 0.13),
        ),
      ),
      alignment: Alignment.center,
      child: logo ??
          Text(
            initial,
            style: const TextStyle(
              color: AppConstants.primary,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
    );
  }
}