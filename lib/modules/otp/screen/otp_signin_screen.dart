import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

import '../../../core/utils/localization/app_localization.dart';
import '../../../routes/app_routes.dart';
import '../../../utils/colors_code.dart';
import '../../../utils/enums.dart';
import '../../../core/utils/ui_utils.dart';
import '../../localization/Controller/localization_controller.dart';
import '../controller/otp_receive_bloc.dart';
import '../controller/otp_receive_event.dart';
import '../controller/otp_receive_state.dart';
import '../../auth/controller/send_otp_bloc.dart';
import '../../auth/controller/send_otp_event.dart';
import '../../auth/controller/send_otp_state.dart';

class OtpSignIn extends StatefulWidget {
  final String number;

  const OtpSignIn({super.key, required this.number});

  @override
  State<OtpSignIn> createState() => _OtpSignInState();
}

class _OtpSignInState extends State<OtpSignIn> {
  final PinInputController _otpController = PinInputController();
  Timer? _timer;
  int _secondsRemaining = 120; // 2 minutes

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _secondsRemaining = 120;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  String get _formattedTime {
    int minutes = _secondsRemaining ~/ 60;
    int seconds = _secondsRemaining % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _resendCode(BuildContext context, String langCode, AppLocalizations loc) {
    if (_secondsRemaining > 0) return;

    // Dispatch SendOtp to actually request a new code
    try {
      context.read<SendOtpBloc>().add(SendOtp(widget.number, langCode));
    } catch (e) {
      print("SendOtpBloc not available here.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    // Padding outside card = 48, Padding inside card = 48, Estimated gaps between 6 cells = 40. Total = 136
    final availableWidth = screenWidth - 136;
    final double cellWidth = (availableWidth / 6).clamp(35.0, 50.0);
    final double cellHeight = (cellWidth * 1.2).clamp(45.0, 60.0);

    return BlocBuilder<LocalizationBloc, LocalizationState>(
      builder: (context, localizationState) {
        return MultiBlocListener(
          listeners: [
            BlocListener<OtpReceiveBloc, OtpReceiveState>(
              listener: (context, state) {
                if (state.status == OtpReceiveStatus.failure) {
                  UiUtils.showApiErrorPopup(context, state.errorMessage ?? "Otp failed");
                }
                if (state.status == OtpReceiveStatus.success) {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    AppRoutes.navbar,
                    (route) => false,
                  );
                }
              },
            ),
            // Listen for Resend OTP API response
            BlocListener<SendOtpBloc, SendOtpState>(
              listener: (context, state) {
                if (state.status == OtpStatus.success) {
                  setState(() {
                    _startTimer();
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(loc.translate("otp_resent") ?? "OTP sent successfully"),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } else if (state.status == OtpStatus.failure) {
                  UiUtils.showApiErrorPopup(context, state.errorMessage ?? "Failed to resend OTP");
                }
              },
            ),
          ],
          child: Scaffold(
            backgroundColor: Theme.of(context).colorScheme.surface,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black87),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            bottomNavigationBar: SafeArea(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    )
                  ],
                ),
                padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24, top: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Timer & Resend
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          (loc.translate("resend_code_in") ?? "Resend code in ").replaceAll("{time}", "").trimRight(),
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _secondsRemaining > 0
                            ? Text(
                                _formattedTime,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: AppColors.resendCodeTime ?? Colors.red,
                                  fontWeight: FontWeight.w600,
                                ),
                              )
                            : GestureDetector(
                                onTap: () => _resendCode(context, localizationState.locale.languageCode, loc),
                                child: Text(
                                  loc.translate("resend") ?? "Resend OTP",
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: AppColors.submitButton,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    BlocBuilder<OtpReceiveBloc, OtpReceiveState>(
                      builder: (context, state) {
                        return ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                            foregroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
                            minimumSize: const Size(double.infinity, 54),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          onPressed: state.status == OtpReceiveStatus.loading
                              ? null
                              : () {
                                  if (_otpController.text.length < 6) {
                                    UiUtils.showApiErrorPopup(context, "Please enter the full OTP");
                                    return;
                                  }
                                  context.read<OtpReceiveBloc>().add(
                                    OtpReceive(
                                      otp: _otpController.text,
                                      number: widget.number,
                                      languageCode: localizationState.locale.languageCode,
                                    ),
                                  );
                                },
                          child: switch (state.status) {
                            OtpReceiveStatus.loading =>
                              SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(color: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white, strokeWidth: 2.5),
                              ),
                            OtpReceiveStatus.failure => Text(
                              loc.translate("retry") ?? "Retry",
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            _ => Text(
                              loc.translate("continue") ?? "Verify & Continue",
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.translate("enter_the_otp_sent_to_you_at") ?? "Enter the OTP sent to",
                      style: GoogleFonts.poppins(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          widget.number,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Text(
                            loc.translate("change_number") ?? "Change",
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: AppColors.submitButton,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                              decorationColor: AppColors.submitButton,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    // inDrive style elevated card for the OTP input
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Secure Code",
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 20),
                          MaterialPinField(
                            length: 6,
                            pinController: _otpController,
                            keyboardType: TextInputType.number,
                            enableAutofill: true,
                            autofillHints: const [AutofillHints.oneTimeCode],
                            autoFocus: true,
                            theme: MaterialPinTheme(
                              textStyle: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
                              shape: MaterialPinShape.outlined,
                              cellSize: Size(cellWidth, cellHeight),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            onCompleted: (v) {
                              // Automatically trigger verify when 6 digits are entered
                              context.read<OtpReceiveBloc>().add(
                                OtpReceive(
                                  otp: _otpController.text,
                                  number: widget.number,
                                  languageCode: localizationState.locale.languageCode,
                                ),
                              );
                            },
                            onChanged: (value) {},
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
