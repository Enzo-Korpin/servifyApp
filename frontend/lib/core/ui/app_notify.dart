import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum _NotifyType { success, error, info }

class _NotifyConfig {
  final Color accent;
  final IconData icon;
  final String title;

  const _NotifyConfig({
    required this.accent,
    required this.icon,
    required this.title,
  });
}

class AppNotify {
  AppNotify._();

  static void success(BuildContext context, String message, {String? title}) =>
      _show(context, message, _NotifyType.success, title);

  static void error(BuildContext context, String message, {String? title}) =>
      _show(context, message, _NotifyType.error, title);

  static void info(BuildContext context, String message, {String? title}) =>
      _show(context, message, _NotifyType.info, title);

  /// Extracts a clean, user-friendly message from a Dio error or any exception.
  ///
  /// The backend returns errors as `{ success, data, error: { code, message,
  /// details } }`, so the human-readable text lives at `error.message`.
  static String messageFromError(
    Object? error, {
    String fallback = "Something went wrong. Please try again.",
  }) {
    if (error is DioException) {
      final data = error.response?.data;

      if (data is Map) {
        final err = data["error"];
        if (err is Map) {
          final msg = err["message"];
          if (msg is String && msg.trim().isNotEmpty) return msg.trim();
        }
        if (err is String && err.trim().isNotEmpty) return err.trim();

        final topMsg = data["message"];
        if (topMsg is String && topMsg.trim().isNotEmpty) return topMsg.trim();
      }

      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return "The connection timed out. Please try again.";
        case DioExceptionType.connectionError:
          return "Can't reach the server. Check your internet connection.";
        default:
          break;
      }
    }

    return fallback;
  }

  static void _show(
    BuildContext context,
    String message,
    _NotifyType type,
    String? title,
  ) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    final config = _configFor(type);

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        padding: EdgeInsets.zero,
        duration: Duration(
          milliseconds: type == _NotifyType.error ? 4000 : 2800,
        ),
        content: _NotifyCard(
          message: message,
          title: title ?? config.title,
          config: config,
        ),
      ),
    );
  }

  static _NotifyConfig _configFor(_NotifyType type) {
    switch (type) {
      case _NotifyType.success:
        return const _NotifyConfig(
          accent: Color(0xFF12A150),
          icon: Icons.check_circle_rounded,
          title: "Success",
        );
      case _NotifyType.error:
        return const _NotifyConfig(
          accent: Color(0xFFE5484D),
          icon: Icons.error_rounded,
          title: "Something went wrong",
        );
      case _NotifyType.info:
        return const _NotifyConfig(
          accent: Color(0xFF1E40AF),
          icon: Icons.info_rounded,
          title: "Heads up",
        );
    }
  }
}

class _NotifyCard extends StatelessWidget {
  final String message;
  final String title;
  final _NotifyConfig config;

  const _NotifyCard({
    required this.message,
    required this.title,
    required this.config,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.14),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 5, color: config.accent),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 13, 8, 13),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: config.accent.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(config.icon, color: config.accent, size: 21),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(4, 11, 14, 11),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.inter(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          message,
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            height: 1.35,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
