import 'package:flutter/material.dart';

import '../app/app_session_controller.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, required this.sessionController});

  final AppSessionController sessionController;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _userNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _userNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final success = await widget.sessionController.signUp(
      userName: _userNameController.text,
      email: _emailController.text,
      firstName: _firstNameController.text,
      lastName: _lastNameController.text,
      password: _passwordController.text,
    );

    if (!mounted || success) {
      return;
    }

    final message =
        widget.sessionController.errorMessage ?? 'Kayit sirasinda bir hata olustu.';
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kayit Ol'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Yeni kullanici hesabi olustur',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1B2842),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Otopark ve navigasyon ozelliklerini kullanmak icin bilgilerini gir.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF667086),
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: _LabeledField(
                        label: 'Ad',
                        child: TextFormField(
                          controller: _firstNameController,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(hintText: 'Ahmet'),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Ad gerekli.';
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _LabeledField(
                        label: 'Soyad',
                        child: TextFormField(
                          controller: _lastNameController,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(hintText: 'Yilmaz'),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Soyad gerekli.';
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _LabeledField(
                  label: 'Kullanici Adi',
                  child: TextFormField(
                    controller: _userNameController,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(hintText: 'ahmetyilmaz'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Kullanici adi gerekli.';
                      }
                      if (value.trim().length < 3) {
                        return 'Kullanici adi en az 3 karakter olmali.';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 18),
                _LabeledField(
                  label: 'E-posta Adresi',
                  child: TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(hintText: 'ornek@mail.com'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'E-posta adresi gerekli.';
                      }
                      if (!value.contains('@')) {
                        return 'Gecerli bir e-posta adresi gir.';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 18),
                _LabeledField(
                  label: 'Sifre',
                  child: TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      hintText: 'En az 8 karakter',
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                    validator: (value) {
                      final text = value ?? '';
                      if (text.isEmpty) {
                        return 'Sifre gerekli.';
                      }
                      if (text.length < 8) {
                        return 'Sifre en az 8 karakter olmali.';
                      }
                      if (!RegExp(r'[A-Z]').hasMatch(text) ||
                          !RegExp(r'[a-z]').hasMatch(text) ||
                          !RegExp(r'[0-9]').hasMatch(text)) {
                        return 'Sifre buyuk harf, kucuk harf ve rakam icermeli.';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 18),
                _LabeledField(
                  label: 'Sifre Tekrari',
                  child: TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      hintText: 'Sifreni tekrar gir',
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Sifre tekrar gerekli.';
                      }
                      if (value != _passwordController.text) {
                        return 'Sifreler ayni degil.';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: widget.sessionController.isBusy ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF2B5FE7),
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: widget.sessionController.isBusy
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Kaydi Tamamla',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: widget.sessionController.isBusy
                        ? null
                        : () => Navigator.of(context).maybePop(),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: const Text('Girise Don'),
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

class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: const Color(0xFF2A3347),
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}
