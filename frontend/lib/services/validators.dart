class Validators {
  static String? validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return "Please enter a username";
    }
    if (value.length < 3) {
      return "Username must be at least 3 characters";
    }
    // Cannot start with a negative sign
    if (value.startsWith('-')) {
      return "Username cannot start with a negative sign";
    }
    // Special characters are not allowed in username
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
      return "Special characters are not allowed in username";
    }
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return "Please enter your email";
    }

    // Check for proper domain
    if (!value.toLowerCase().endsWith("@gmail.com") &&
        !value.toLowerCase().endsWith("@yahoo.com")) {
      return "Email must end with @gmail / yahoo";
    }

    final emailParts = value.split('@');
    final prefix = emailParts[0];

    // Cannot start with a negative sign
    if (prefix.startsWith('-')) {
      return "Email cannot start with negative sign";
    }

    // Special characters are not allowed in email prefix
    if (RegExp(r'[!@#$%^&*(),?":{}|<>]').hasMatch(prefix)) {
      return "Special characters are not allowed";
    }

    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return "Please enter a password";
    }
    if (value.length < 8) {
      return "Password must be at least 8 characters long";
    }
    // Special characters are mandatory
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
      return "One special character required";
    }
    // Cannot start with a negative sign
    if (value.startsWith('-')) {
      return "Cannot start with a negative sign";
    }
    return null;
  }

  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return "Please confirm your password";
    }
    if (value != password) {
      return "Passwords do not match";
    }
    return null;
  }
}
