class ForgotPasswordResetArgs {
  final String phoneNumber;
  final String resetToken;

  const ForgotPasswordResetArgs({
    required this.phoneNumber,
    required this.resetToken,
  });
}
