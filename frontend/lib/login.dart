import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:material_loading_buttons/material_loading_buttons.dart';
import 'package:plant_it/auth_scaffold.dart';
import 'package:plant_it/commons.dart';
import 'package:plant_it/environment.dart';
import 'package:plant_it/reset_password.dart';
import 'package:plant_it/signup.dart';

class LoginPage extends StatefulWidget {
  final Environment env;

  const LoginPage({
    super.key,
    required this.env,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _showPassword = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return AuthScaffold(
      title: '${localizations.loginMessage} ${localizations.appName}',
      subtitle: localizations.loginTagline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Username
                TextFormField(
                  autofocus: true,
                  controller: _usernameController,
                  autofillHints: const [AutofillHints.username],
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context).username,
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppLocalizations.of(context).enterValue;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Password
                Column(
                  children: [
                    TextFormField(
                      controller: _passwordController,
                      autofillHints: const [AutofillHints.password],
                      obscureText: !_showPassword,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context).password,
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(_showPassword
                              ? Icons.visibility
                              : Icons.visibility_off),
                          onPressed: () {
                            setState(() {
                              _showPassword = !_showPassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return AppLocalizations.of(context).enterValue;
                        }
                        return null;
                      },
                      onFieldSubmitted: (value) {
                        if (_formKey.currentState!.validate()) {
                          loginAndSetAppKey(
                              widget.env,
                              context,
                              _usernameController.text,
                              _passwordController.text);
                        }
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => goToPageSlidingUp(
                              context,
                              ResetPassword(
                                env: widget.env,
                              )),
                          child:
                              Text(AppLocalizations.of(context).forgotPassword),
                        ),
                      ),
                    ),
                  ],
                ),

                // Button
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedLoadingButton(
                    isLoading: _isLoading,
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        setState(() {
                          _isLoading = true;
                        });
                        try {
                          await loginAndSetAppKey(
                              widget.env,
                              context,
                              _usernameController.text,
                              _passwordController.text);
                        } finally {
                          if (mounted) {
                            setState(() {
                              _isLoading = false;
                            });
                          }
                        }
                      }
                    },
                    child: Text(AppLocalizations.of(context).login),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Divider(),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  AppLocalizations.of(context).or,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              const Expanded(
                child: Divider(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Signup(env: widget.env),
        ],
      ),
    );
  }
}

class Signup extends StatelessWidget {
  final Environment env;

  const Signup({super.key, required this.env});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(AppLocalizations.of(context).areYouNew),
        TextButton(
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => SignupPage(env: env)),
          ),
          child: Text(AppLocalizations.of(context).createAccount),
        ),
      ],
    );
  }
}
