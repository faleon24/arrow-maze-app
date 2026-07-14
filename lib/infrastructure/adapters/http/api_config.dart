/// ApiConfig — single source of truth for the backend base URL and
/// HTTP timeout budget.
///
/// The URL is provided at build time via `--dart-define=API_URL=...`
/// so a release build against a staging or production backend does not
/// require editing source or bundling secrets. In dev (no dart define)
/// it defaults to the locally running NestJS backend on port 3000 with
/// the /api prefix.
///
/// Before this file existed, every API class carried its own private
/// `_baseUrl` constant — three copies that would drift the moment a
/// backend was deployed anywhere but localhost. Centralizing it here
/// is the DRY prerequisite for typed API exceptions and secure storage
/// (the next two sub-blocks).
class ApiConfig {
  ApiConfig._();

  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:3000/api',
  );

  /// How long any single HTTP request may take before the client
  /// gives up. Ten seconds is long enough that a cold Prisma pool
  /// or a slow Chrome tab does not spuriously fail, short enough
  /// that a lost network does not hang the UI forever.
  static const Duration requestTimeout = Duration(seconds: 10);
}
