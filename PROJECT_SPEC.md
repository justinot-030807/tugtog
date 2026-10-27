# PROJECT_SPEC.md: Tugtog

## 1. Project Overview
- **Name:** Tugtog
- **Platform:** Android (Primary), built with Flutter (stable, Dart sound null-safety).
- **Description:** A free, personal Spotify-like music player for Android.
- **Design Philosophy:** Sleek Spotify-inspired dark theme, smooth transitions, persistent mini player with full-screen expansion, and clean separation between UI and music streaming sources.

---

## 2. Core Goals & Feature Set
1. **Local Audio Playback:**
   - Scan and index device storage for audio files (`mp3`, `flac`, `m4a`, `ogg`).
   - Extract embedded metadata (title, artist, album, album art, duration).
   - Handle Android scoped storage and audio permissions gracefully via `permission_handler`.

2. **YouTube Music "Recently Played":**
   - Read-only history sync and display.
   - Seamless display of recently played tracks alongside local and discovered music.

3. **Free International Streaming:**
   - Integration with legal, free music services: **Audius API** and **Jamendo API**.
   - Browse trending, genre-based discovery, and unified search.

4. **Comprehensive Playback Engine:**
   - Continuous background audio playback via `just_audio` and `audio_session`.
   - Android notification controls with album art, track details, seek bar, and playback actions via `just_audio_background`.
   - Lock screen media controls.
   - Queue management (reordering, add next, remove).
   - Playback modes: Shuffle, Repeat (Off, All, One).
   - User-defined playlists and "Favorites" persistence.

---

## 3. Tech Stack & Dependencies
- **SDK & Language:** Flutter (latest stable channel), Dart 3 with sound null-safety.
- **State Management:** Riverpod (`flutter_riverpod`).
- **Audio Playback:**
  - `just_audio`: Audio player core.
  - `just_audio_background`: Background playback & system media notification service.
  - `audio_session`: Audio focus management (interruptions, headphone unplugged events).
- **Local Audio Discovery:**
  - `on_audio_query`: Android media store query for tracks, albums, artists, artwork.
  - `permission_handler`: Runtime permissions for storage and audio.
- **Database & Persistence:**
  - `drift` or `sqflite`: Local SQLite database for playlists, cached metadata, and playback history.
  - `flutter_secure_storage` / `shared_preferences`: App settings and secure token storage.
- **Networking & API:**
  - `dio`: HTTP client with interceptors, caching, and error handling.
  - `flutter_dotenv`: Environment variable loader for API keys and endpoints.

---

## 4. Architectural Blueprint

### Layered Directory Structure (`lib/`)
```
lib/
├── core/
│   ├── audio/              # AudioHandler, JustAudio wrappers, playback listeners
│   ├── constants/          # App constants, route names, API endpoints
│   ├── errors/             # Failure models and exception handling
│   ├── network/            # Dio client, interceptors
│   ├── theme/              # Spotify-like dark theme, colors, typography
│   └── utils/              # Formatters, loggers, helper extensions
├── data/
│   ├── db/                 # Drift / Sqflite database definitions and DAOs
│   ├── models/             # Data transfer objects (DTOs) and JSON mappers
│   ├── repositories/       # Concrete repository implementations
│   └── sources/            # Concrete MusicSource and StreamResolver implementations
│       ├── local/          # OnAudioQuery source & local file resolver
│       ├── audius/         # Audius REST API client & stream resolver
│       ├── jamendo/        # Jamendo REST API client & stream resolver
│       └── ytm/            # YouTube Music read-only scraper/API client
├── domain/
│   ├── models/             # Domain entities: Track, Album, Artist, Playlist, PlaybackState
│   ├── repositories/       # Abstract repository interfaces
│   └── sources/            # Abstract contracts for multi-source abstraction:
│       ├── music_source.dart      # Abstract MusicSource contract
│       └── stream_resolver.dart   # Abstract StreamResolver contract
├── features/
│   ├── home/               # Home screen (Recently Played, Discover, Trending)
│   ├── search/             # Unified search screen (Local + Audius + Jamendo)
│   ├── library/            # Library screen (Local tracks, Playlists, Artists, Albums)
│   ├── player/             # Mini player widget, Full Now Playing screen, Queue modal
│   └── settings/           # Settings screen (Audio quality, sources toggle, about)
└── main.dart               # App entry point, Riverpod ProviderScope, service initialization
```

### Abstraction Contracts
To allow any music source to be added or swapped without altering UI components, the architecture enforces two primary contracts:

1. **`MusicSource`** (`lib/domain/sources/music_source.dart`):
   ```dart
   abstract class MusicSource {
     String get sourceId;
     String get displayName;
     Future<List<Track>> search(String query);
     Future<List<Track>> getTrending({int page = 1, int limit = 20});
     Future<List<Track>> getRecentlyPlayed();
   }
   ```

2. **`StreamResolver`** (`lib/domain/sources/stream_resolver.dart`):
   ```dart
   abstract class StreamResolver {
     String get sourceId;
     Future<String> resolveStreamUrl(Track track);
   }
   ```

---

## 5. UI/UX Rules & Guidelines
- **Theme:** Strict dark mode palette inspired by Spotify (pure blacks `#121212`, card background `#181818`, accents `#1DB954` / clean whites).
- **Navigation Structure:**
  - Persistent Bottom Navigation Bar with 3 tabs: **Home**, **Search**, **Library**.
  - Persistent **Mini Player** docked right above the bottom navigation bar showing album art, title, artist, play/pause toggle, and seek progress bar.
  - Tapping the mini player smoothly expands it (e.g. via sliding panel or modal route) into the **Full Now Playing Screen** with high-res artwork, complete playback controls, queue access, and lyrics/info toggle.

---

## 6. Security, Configuration & Secrets
- **No Hardcoded Secrets:** API keys (Audius, Jamendo, etc.) must NEVER be committed to version control.
- **Environment Management:**
  - Secrets loaded from a root `.env` file using `flutter_dotenv`.
  - `.env` must always be listed in `.gitignore`.
  - Provide `.env.example` in the root repository displaying necessary variable keys without real secrets.

---

## 7. Developer Rules of Engagement
- **Scope Discipline:** Strictly implement only what the current prompt requests. Do not prematurely build or refactor unrelated files.
- **Code Quality:** Keep individual Dart files compact, focused on a single responsibility, and thoroughly commented.
- **Reporting Protocol:** After completing each task, provide:
  1. A clear list of created or modified files with summary of changes.
  2. Exact command-line instructions to run, test, and verify the changes.
