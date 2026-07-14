import 'dart:convert';
import 'package:http/http.dart' as http;

/// ApiException — the typed exception every data-layer HTTP client
/// throws on a non-success response. Carries the backend's message
/// verbatim (so the UI can show why) and the HTTP status (so callers
/// can react programmatically without string-matching on "Exception:"
/// prefixes — the code smell this class exists to kill).
///
/// The `toString()` override returns the message alone (no wrapper
/// like "Instance of 'ApiException'"): screens that print a caught
/// exception directly get the human message, not a class name.
class ApiException implements Exception {
  final String message;
  final int statusCode;
  const ApiException(this.message, this.statusCode);

  /// Build a typed exception from a failed HTTP response. Reads the
  /// backend's `message` field when the body is JSON with one; falls
  /// back to a generic HTTP-status line otherwise. If the status is
  /// 401, returns UnauthorizedException so a global handler (Fase
  /// 0.B.4) can force a sign-out without every call site inspecting
  /// status codes.
  factory ApiException.fromResponse(http.Response response) {
    final message =
        _extractMessage(response) ??
        'Request failed (HTTP ${response.statusCode})';
    if (response.statusCode == 401) {
      return UnauthorizedException(message);
    }
    return ApiException(message, response.statusCode);
  }
  @override
  String toString() => message;
}

/// UnauthorizedException — a 401 from the backend, or a missing local
/// token before the request even fires. Catching this separately is
/// the pattern PLAN-MASTER 0.B.4 will use to force a global sign-out
/// and return to the login screen; here we only surface it so that
/// catch site upstream is possible.
class UnauthorizedException extends ApiException {
  const UnauthorizedException(String message) : super(message, 401);
}

String? _extractMessage(http.Response response) {
  try {
    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic> && decoded['message'] != null) {
      return decoded['message'].toString();
    }
  } catch (_) {
    // Body wasn't JSON — fall through to null so the caller uses the
    // generic HTTP-status message.
  }
  return null;
}
