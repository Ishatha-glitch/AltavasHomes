import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';

class SignUpScreen extends StatefulWidget {
  final String role;

  const SignUpScreen({
    super.key,
    required this.role,
  });

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptTerms = false;

  String _serviceCategory = 'Plumber';

  static const List<String> categories = [
    'Plumber',
    'Electrician',
    'Mover',
    'Cleaner',
    'Painter',
    'Carpenter',
    'Other',
  ];

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please accept the Terms & Conditions.',
          ),
        ),
      );
      return;
    }

    final auth = context.read<AuthProvider>();

    auth.clearError();

    try {
      await auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: _fullNameController.text.trim(),
        phone: _phoneController.text.trim(),
        role: widget.role,
        serviceCategory:
            widget.role == 'service_provider'
                ? _serviceCategory
                : null,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Account created successfully. Please verify your email before signing in.',
          ),
          backgroundColor: Colors.green,
        ),
      );

      context.go('/signin');
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            auth.error ?? 'Registration failed.',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    final roleLabel = widget.role
        .replaceAll('_', ' ')
        .split(' ')
        .map(
          (word) =>
              word[0].toUpperCase() + word.substring(1),
        )
        .join(' ');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Create $roleLabel Account",
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 500,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.person_add_alt_1,
                      size: 80,
                      color: Color(0xFF2563EB),
                    ),

                    const SizedBox(height: 20),

                    Text(
                      "Join as $roleLabel",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      "Create your AltavasHomes account",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey,
                      ),
                    ),

                    const SizedBox(height: 30),

                    TextFormField(
                      controller: _fullNameController,
                      textCapitalization:
                          TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: "Full Name",
                        prefixIcon:
                            Icon(Icons.person_outline),
                      ),
                      validator: (value) {
                        if (value == null ||
                            value.trim().isEmpty) {
                          return "Full name is required.";
                        }

                        if (value.trim().length < 3) {
                          return "Enter your full name.";
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 18),

                    TextFormField(
                      controller: _phoneController,
                      keyboardType:
                          TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: "Phone Number",
                        prefixIcon:
                            Icon(Icons.phone_outlined),
                      ),
                      validator: (value) {
                        if (value == null ||
                            value.trim().isEmpty) {
                          return "Phone number is required.";
                        }

                        if (value.trim().length < 10) {
                          return "Enter a valid phone number.";
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 18),

                    TextFormField(
                      controller: _emailController,
                      keyboardType:
                          TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: "Email",
                        prefixIcon:
                            Icon(Icons.email_outlined),
                      ),
                      validator: (value) {
                        if (value == null ||
                            value.trim().isEmpty) {
                          return "Email is required.";
                        }

                        if (!RegExp(
                          r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                        ).hasMatch(value.trim())) {
                          return "Enter a valid email.";
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 18),

                    TextFormField(
                      controller:
                          _passwordController,
                      obscureText:
                          _obscurePassword,
                      decoration: InputDecoration(
                        labelText: "Password",
                        prefixIcon:
                            const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword =
                                  !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null ||
                            value.isEmpty) {
                          return "Password is required.";
                        }

                        if (value.length < 8) {
                          return "Minimum 8 characters.";
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 18),

                    TextFormField(
                      controller:
                          _confirmPasswordController,
                      obscureText:
                          _obscureConfirmPassword,
                      decoration: InputDecoration(
                        labelText:
                            "Confirm Password",
                        prefixIcon:
                            const Icon(Icons.lock_reset),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value !=
                            _passwordController
                                .text) {
                          return "Passwords do not match.";
                        }

                        return null;
                      },
                    ),

                    if (widget.role ==
                        'service_provider') ...[
                      const SizedBox(height: 24),

                      const Text(
                        "Service Category",
                        style: TextStyle(
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            categories.map((category) {
                          return ChoiceChip(
                            label: Text(category),
                            selected:
                                _serviceCategory ==
                                    category,
                            onSelected: (_) {
                              setState(() {
                                _serviceCategory =
                                    category;
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],

                    const SizedBox(height: 24),

                    CheckboxListTile(
                      value: _acceptTerms,
                      contentPadding:
                          EdgeInsets.zero,
                      onChanged: (value) {
                        setState(() {
                          _acceptTerms =
                              value ?? false;
                        });
                      },
                      title: const Text(
                        "I agree to the Terms & Conditions",
                      ),
                    ),

                    const SizedBox(height: 20),

                    FilledButton(
                      onPressed:
                          auth.busy ? null : _submit,
                      child: auth.busy
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Padding(
                              padding:
                                  EdgeInsets.symmetric(
                                vertical: 14,
                              ),
                              child: Text(
                                "Create Account",
                                style: TextStyle(
                                  fontSize: 16,
                                ),
                              ),
                            ),
                    ),

                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Already have an account?",
                        ),
                        TextButton(
                          onPressed: () {
                            context.go('/signin');
                          },
                          child: const Text(
                            "Sign In",
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
