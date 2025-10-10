import 'package:flutter/material.dart';

enum DialogType { success, warning, error }

class ConfirmationDialog extends StatelessWidget {
  final DialogType type;
  final String title;
  final String message;
  final String confirmText;
  final String? cancelText;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;

  const ConfirmationDialog({
    super.key,
    required this.type,
    required this.title,
    required this.message,
    required this.confirmText,
    required this.onConfirm,
    this.cancelText,
    this.onCancel,
  });

  // Success dialog factory
  static ConfirmationDialog success({
    required String title,
    required String message,
    required VoidCallback onConfirm,
    String confirmText = 'Confirm',
  }) {
    return ConfirmationDialog(
      type: DialogType.success,
      title: title,
      message: message,
      confirmText: confirmText,
      onConfirm: onConfirm,
    );
  }

  // Warning/Confirmation dialog factory
  static ConfirmationDialog warning({
    required String title,
    required String message,
    required VoidCallback onConfirm,
    VoidCallback? onCancel,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
  }) {
    return ConfirmationDialog(
      type: DialogType.warning,
      title: title,
      message: message,
      confirmText: confirmText,
      cancelText: cancelText,
      onConfirm: onConfirm,
      onCancel: onCancel,
    );
  }

  // Error dialog factory
  static ConfirmationDialog error({
    required String title,
    required String message,
    required VoidCallback onConfirm,
    String confirmText = 'OK',
  }) {
    return ConfirmationDialog(
      type: DialogType.error,
      title: title,
      message: message,
      confirmText: confirmText,
      onConfirm: onConfirm,
    );
  }

  Color get _iconColor {
    switch (type) {
      case DialogType.success:
        return const Color(0xFF4CB04C);
      case DialogType.warning:
        return const Color(0xFFFFA726);
      case DialogType.error:
        return const Color(0xFFE53E3E);
    }
  }

  Color get _confirmButtonColor {
    switch (type) {
      case DialogType.success:
        return const Color(0xFF4CB04C);
      case DialogType.warning:
        return const Color(0xFFFF8A50);
      case DialogType.error:
        return const Color(0xFFE53E3E);
    }
  }

  IconData get _iconData {
    switch (type) {
      case DialogType.success:
        return Icons.check;
      case DialogType.warning:
        return Icons.warning;
      case DialogType.error:
        return Icons.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: type == DialogType.success
              ? Border.all(color: const Color(0xFF3B82F6), width: 2)
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: type == DialogType.success
                      ? [const Color(0xFF4CB04C), const Color(0xFFF8D86E)]
                      : [_iconColor, _iconColor.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Icon(_iconData, color: Colors.white, size: 40),
            ),

            const SizedBox(height: 24),

            // Title
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                fontFamily: 'Open Sans',
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),

            // Message
            Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontFamily: 'Open Sans',
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            // Buttons
            if (type == DialogType.success)
              // Single confirm button for success
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onConfirm();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _confirmButtonColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    confirmText,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      fontFamily: 'Open Sans',
                    ),
                  ),
                ),
              )
            else
              // Two buttons for warning/error
              Row(
                children: [
                  // Cancel button
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          if (onCancel != null) {
                            onCancel!();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE0E0E0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          cancelText ?? 'Cancel',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black54,
                            fontFamily: 'Open Sans',
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Confirm button
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          onConfirm();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _confirmButtonColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          confirmText,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            fontFamily: 'Open Sans',
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

// Helper method to show dialogs easily
class DialogHelper {
  static Future<void> showSuccess(
    BuildContext context, {
    required String title,
    required String message,
    required VoidCallback onConfirm,
    String confirmText = 'Confirm',
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ConfirmationDialog.success(
        title: title,
        message: message,
        onConfirm: onConfirm,
        confirmText: confirmText,
      ),
    );
  }

  static Future<void> showWarning(
    BuildContext context, {
    required String title,
    required String message,
    required VoidCallback onConfirm,
    VoidCallback? onCancel,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ConfirmationDialog.warning(
        title: title,
        message: message,
        onConfirm: onConfirm,
        onCancel: onCancel,
        confirmText: confirmText,
        cancelText: cancelText,
      ),
    );
  }

  static Future<void> showError(
    BuildContext context, {
    required String title,
    required String message,
    required VoidCallback onConfirm,
    String confirmText = 'OK',
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ConfirmationDialog.error(
        title: title,
        message: message,
        onConfirm: onConfirm,
        confirmText: confirmText,
      ),
    );
  }
}
