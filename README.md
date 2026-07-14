# Arrow Maze — Flutter App

Mobile puzzle game: clear a board of arrows by tapping them in the right order. Each arrow fires a ray in its direction; a tap is valid only if that ray reaches the board edge without hitting another arrow or wall. Clear every arrow within the move budget to win the level and earn stars.

Companion of the [`arrow-maze-backend`](https://github.com/faleon24/arrow-maze-backend) NestJS API (auth, level catalog, progress, leaderboard, shop).

---

## Architecture

Hexagonal (ports + adapters) with a `get_it` service locator:

```
lib/
  main.dart                       # composition root: setupDI(); runApp(...)
  core/
    di/service_locator.dart       # every getIt binding
  domain/
    models/                       # pure entities and value objects
    ports/                        # interfaces (framework-agnostic)
    services/                     # pure domain logic
  application/
    usecases/                     # orchestrators over ports
      auth/ level/ progress/
      game/ wallet/ lives/
  infrastructure/
    adapters/
      http/                       # NestJS backend clients
      local/                      # SharedPreferences persistence
      platform/                   # Flutter services (haptics, audio)
    dto/                          # transport shapes + toDomain() mappers
  presentation/
    screens/                      # StatefulWidgets, resolve deps via getIt<T>()
    widgets/                      # visuals (BoardPainter, CellWidget)
    auth_guard.dart               # global 401 -> sign-out handler
```

Dependency rule: `presentation -> application -> domain`, `infrastructure -> domain`. Domain and application never import `package:flutter`, `package:http`, or `package:shared_preferences`. Enforced by grep sanity checks in every architectural commit.

---

## Features

- Email/password auth, JWT persisted in SharedPreferences (session expiry validated locally on launch)
- Level catalog with server-side stars per level, cross-referenced against the signed-in player
- Puzzle board with continuous arrow paths (bent L/U/S/zigzag shapes), tap-to-fire ray mechanics
- Pinch-to-zoom + two-finger pan on the board (`InteractiveViewer`)
- Haptic + audio feedback on activation, block, level clear, and level fail
- Power-ups: hint (reveal an activatable arrow) and grid highlight (show an arrow's ray without firing)
- Coin wallet + inventory persisted locally (SharedPreferences), server-adapter-ready
- Global lives system: -1 life per failed or abandoned run, purchasable with coins (20 = 1 life)

---

## Getting started

Requires Flutter SDK 3.x and a connected device or emulator.

```bash
git clone git@github.com:faleon24/arrow-maze-app.git
cd arrow-maze-app
flutter pub get
```

Run with the bundled dev fixture (no backend needed):

```bash
flutter run --dart-define=USE_DEV_LEVELS=true
```

Run against the backend (default, no flag needed):

```bash
flutter run                                                # http://localhost:3000/api
flutter run --dart-define=API_URL=https://api.example.com  # any URL
```

The backend must be running for level fetch and progress. See the [backend README](https://github.com/faleon24/arrow-maze-backend#readme).

---

## Tests

```bash
flutter analyze              # must show 0 issues
flutter test                 # domain + application + fixture tests
```

96 tests across `test/domain/`, `test/application/`, `test/infrastructure/`, `test/fixtures/`.

---

## Compile-time flags

| Flag | Effect |
|---|---|
| `USE_DEV_LEVELS=true` | Binds `ILevelRepository` to the bundled fixture instead of HTTP |
| `API_URL=<url>` | Base URL for backend calls (default `http://localhost:3000/api`) |

Both consumed via `String.fromEnvironment` / `bool.fromEnvironment` inside `ApiConfig` and `setupDI`.

---

## Project conventions

- Conventional Commits in English
- Tests in AAA style + `should_x_when_y` naming
- No enums (whitelisted string constants when discrimination is needed)
- Domain and application layers stay framework-agnostic
