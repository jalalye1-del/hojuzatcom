import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/network/api_exception.dart';
import '../data/auth_repository.dart';
import '../domain/auth_input_policy.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({
    super.key,
    required this.repository,
    required this.isEnglish,
  });

  final AuthRepository repository;
  final bool isEnglish;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  static const blue = Color(0xff2455e9);
  static const orange = Color(0xffff9600);
  static const navy = Color(0xff12345e);

  final phoneController = TextEditingController();
  final codeController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmationController = TextEditingController();

  bool codeRequested = false;
  bool busy = false;

  String text(String arabic, String english) =>
      widget.isEnglish ? english : arabic;

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> requestCode() async {
    if (busy) return;

    final phone = AuthInputPolicy.normalizePhone(phoneController.text);

    if (!AuthInputPolicy.isValidPhone(phone)) {
      showMessage(text('أدخل رقم هاتف صحيحًا.', 'Enter a valid phone number.'));
      return;
    }

    setState(() => busy = true);

    var continueToCodeEntry = false;
    try {
      await widget.repository.requestPasswordReset(phone);
      continueToCodeEntry = true;
    } on ApiException catch (error) {
      final statusCode = error.statusCode ?? 0;
      if (error.code == 'network_error' ||
          statusCode == 429 ||
          statusCode >= 500) {
        showMessage(
          text(
            'تعذر طلب رمز الاستعادة الآن. تحقق من الاتصال وحاول مجددًا.',
            'Unable to request a reset code now. Check your connection and try again.',
          ),
        );
      } else {
        // لا نعرض سبب رفض الخادم حتى لا نكشف ما إذا كان الرقم مسجلاً.
        continueToCodeEntry = true;
      }
    } on Object {
      showMessage(
        text(
          'تعذر طلب رمز الاستعادة. تحقق من الاتصال وحاول مجددًا.',
          'Unable to request a reset code. Check your connection and try again.',
        ),
      );
    } finally {
      if (mounted) setState(() => busy = false);
    }

    if (!mounted || !continueToCodeEntry) return;
    setState(() => codeRequested = true);
    showMessage(
      text(
        'إذا كان الرقم مسجلًا فسيتم إرسال رمز الاستعادة إليه.',
        'If the number is registered, a reset code will be sent.',
      ),
    );
  }

  Future<void> resetPassword() async {
    if (busy) return;

    final phone = AuthInputPolicy.normalizePhone(phoneController.text);
    final code = codeController.text.trim();
    final password = passwordController.text;
    final confirmation = confirmationController.text;

    if (!RegExp(r'^[0-9]{6}$').hasMatch(code)) {
      showMessage(
        text(
          'أدخل رمز الاستعادة المكوّن من 6 أرقام.',
          'Enter the 6-digit reset code.',
        ),
      );
      return;
    }

    if (!AuthInputPolicy.isValidPassword(password)) {
      showMessage(
        text(
          'كلمة المرور يجب أن تتكون من 8 إلى 128 حرفًا.',
          'The password must contain 8 to 128 characters.',
        ),
      );
      return;
    }

    if (password != confirmation) {
      showMessage(
        text('كلمتا المرور غير متطابقتين.', 'The passwords do not match.'),
      );
      return;
    }

    setState(() => busy = true);

    try {
      await widget.repository.resetPassword(
        phone: phone,
        code: code,
        newPassword: password,
      );

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          icon: const Icon(
            Icons.check_circle_rounded,
            color: Colors.green,
            size: 54,
          ),
          title: Text(text('تم تحديث كلمة المرور', 'Password updated')),
          content: Text(
            text(
              'يمكنك الآن تسجيل الدخول بكلمة المرور الجديدة.',
              'You can now sign in with your new password.',
            ),
            textAlign: TextAlign.center,
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(text('العودة لتسجيل الدخول', 'Return to sign in')),
            ),
          ],
        ),
      );

      if (!mounted) return;

      Navigator.pop(context, phone);
    } on ApiException catch (error) {
      showMessage(error.message);
    } on Object {
      showMessage(
        text(
          'تعذر تحديث كلمة المرور. حاول مجددًا.',
          'Unable to update the password. Try again.',
        ),
      );
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    phoneController.dispose();
    codeController.dispose();
    passwordController.dispose();
    confirmationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: widget.isEnglish ? TextDirection.ltr : TextDirection.rtl,
    child: Scaffold(
      appBar: AppBar(
        title: Text(text('استعادة كلمة المرور', 'Reset password')),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(22),
          children: [
            const SizedBox(height: 18),
            const Icon(Icons.lock_reset_rounded, size: 84, color: blue),
            const SizedBox(height: 16),
            Text(
              text(
                'استعادة الوصول إلى حسابك',
                'Recover access to your account',
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: navy,
                fontSize: 23,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              codeRequested
                  ? text(
                      'أدخل رمز الاستعادة وكلمة المرور الجديدة.',
                      'Enter the reset code and your new password.',
                    )
                  : text(
                      'أدخل رقم الهاتف المرتبط بحساب حجوزاتكم.',
                      'Enter the phone number linked to your Hujuzatcom account.',
                    ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: phoneController,
              enabled: !codeRequested && !busy,
              keyboardType: TextInputType.phone,
              autofillHints: const [AutofillHints.telephoneNumber],
              decoration: InputDecoration(
                labelText: text('رقم الهاتف', 'Phone number'),
                prefixIcon: const Icon(
                  Icons.phone_android_rounded,
                  color: blue,
                ),
                border: const OutlineInputBorder(),
              ),
            ),
            if (!codeRequested) ...[
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: busy ? null : requestCode,
                style: FilledButton.styleFrom(
                  backgroundColor: blue,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                icon: busy
                    ? const SizedBox(
                        width: 19,
                        height: 19,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.sms_rounded),
                label: Text(text('إرسال رمز الاستعادة', 'Send reset code')),
              ),
            ],
            if (codeRequested) ...[
              const SizedBox(height: 14),
              TextField(
                controller: codeController,
                enabled: !busy,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                decoration: InputDecoration(
                  labelText: text('رمز الاستعادة', 'Reset code'),
                  prefixIcon: const Icon(Icons.pin_rounded, color: orange),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: passwordController,
                enabled: !busy,
                obscureText: true,
                autofillHints: const [AutofillHints.newPassword],
                decoration: InputDecoration(
                  labelText: text('كلمة المرور الجديدة', 'New password'),
                  prefixIcon: const Icon(Icons.lock_rounded, color: blue),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: confirmationController,
                enabled: !busy,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: text('تأكيد كلمة المرور', 'Confirm password'),
                  prefixIcon: const Icon(
                    Icons.lock_outline_rounded,
                    color: blue,
                  ),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: busy ? null : resetPassword,
                style: FilledButton.styleFrom(
                  backgroundColor: blue,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                icon: busy
                    ? const SizedBox(
                        width: 19,
                        height: 19,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.verified_user_rounded),
                label: Text(text('تحديث كلمة المرور', 'Update password')),
              ),
              TextButton(
                onPressed: busy
                    ? null
                    : () {
                        setState(() {
                          codeRequested = false;
                          codeController.clear();
                          passwordController.clear();
                          confirmationController.clear();
                        });
                      },
                child: Text(text('تغيير رقم الهاتف', 'Change phone number')),
              ),
              TextButton(
                onPressed: busy ? null : requestCode,
                child: Text(text('إعادة إرسال الرمز', 'Resend code')),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
