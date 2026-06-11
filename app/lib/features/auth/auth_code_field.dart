import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Entry field for the numeric codes emailed during sign-in, sign-up,
/// and password reset.
class AuthCodeField extends StatelessWidget {
  const AuthCodeField({super.key, required this.controller, this.onSubmitted});

  final TextEditingController controller;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: true,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(10),
      ],
      textAlign: TextAlign.center,
      style: Theme.of(context)
          .textTheme
          .headlineSmall
          ?.copyWith(letterSpacing: 6),
      decoration: const InputDecoration(
        labelText: 'Code from your email',
        border: OutlineInputBorder(),
      ),
      onSubmitted: onSubmitted,
    );
  }
}
