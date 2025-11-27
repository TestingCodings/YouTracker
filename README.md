# YouTracker

A Flutter application for tracking and analyzing YouTube comments. Replace the clunky and convoluted process for tracking and viewing comments, likes, and replies for YouTube.

## Features

- **YouTube OAuth Integration**: Sign in with Google to access your YouTube channel
- **Real YouTube Data API v3**: Fetch comments, videos, and channel data from YouTube
- **Offline-First Architecture**: Full bidirectional sync with conflict resolution
- **Login Screen**: Email/password authentication with Google sign-in option
- **Dashboard**: Browse comments with search functionality and pagination
- **Comment Details**: View detailed comment information with interactions
- **Settings**: Configure theme, notifications, sync settings, and account management
- **Dark/Light Theme**: Toggle between dark and light modes
- **Local Storage**: Hive database as single source of truth
- **Bidirectional Sync**: Push local changes and pull remote updates
- **Conflict Resolution**: Intelligent field-level merging with pluggable strategies
- **Delta Updates**: Efficient sync using ETags and updatedAfter timestamps
- **Persistent Sync Queue**: Reliable offline operations with retry logic
- **Rate Limit Handling**: Automatic retry with exponential backoff
- **Push Notifications**: Stub implementation for future backend integration
- **Background Sync**: Automatic data synchronization (configurable intervals)
- **Sync Status UI**: Real-time sync progress indicator and detailed status page
- **Riverpod State Management**: Reactive state management throughout the app
- **GoRouter Navigation**: Clean, type-safe routing

## Offline-First Architecture

YouTracker implements a full offline-first architecture with bidirectional sync:

### Core Components

1. **SyncEngine** (`lib/src/sync/sync_engine.dart`)
   - Main orchestrator for all sync operations
   - Handles push (local→remote) and pull (remote→local) flows
   - Manages background sync scheduling
   - Monitors network connectivity for automatic sync on reconnect

2. **SyncQueue** (`lib/src/sync/sync_queue.dart`)
   - Persistent queue using Hive for offline operations
   - Automatic retry with exponential backoff and jitter
   - Dead letter queue for failed operations
   - Cancellation of contradictory operations (e.g., create then delete)

3. **ConflictResolver** (`lib/src/sync/conflict_resolver.dart`)
   - Field-level merge for comment entities
   - Pluggable resolution strategies (remoteWins, localWins, lastWriteWins, fieldLevelMerge)
   - Tombstone handling for deletions
   - Preserves local-only state (bookmarks)

4. **RemoteDeltaClient** (`lib/src/sync/remote_delta_client.dart`)
   - Delta sync using ETags and If-None-Match headers
   - UpdatedAfter timestamps for incremental pulls
   - Caches sync state for efficient requests

### Data Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                        User Action                               │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Offline Repository                            │
│  - Write to Hive immediately (source of truth)                   │
│  - Enqueue SyncOperation if network needed                       │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                       SyncEngine                                 │
│  ┌─────────────────┐              ┌─────────────────────────┐   │
│  │   Push Flow     │              │      Pull Flow          │   │
│  │  - Process Queue│              │  - Fetch delta updates  │   │
│  │  - Retry failed │              │  - Resolve conflicts    │   │
│  │  - Update Hive  │              │  - Merge into Hive      │   │
│  └─────────────────┘              └─────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    YouTube Data API v3                           │
└─────────────────────────────────────────────────────────────────┘
```

### Conflict Resolution Strategy

When both local and remote have changes:

1. **Text fields**: User's local edits have priority (preserved)
2. **Counts (likes, replies)**: Use maximum value
3. **Timestamps**: Use most recent
4. **Bookmarks**: Always preserve local state (not synced)
5. **Deletions**: Remote tombstones are respected

### Sync Queue Configuration

Configure via `SyncQueueConfig`:

```dart
SyncQueueConfig(
  maxRetryAttempts: 5,          // Attempts before dead letter
  backoffBaseSeconds: 2,        // Initial retry delay
  maxBackoffSeconds: 300,       // Maximum delay cap
  jitterFactor: 0.25,           // Randomization factor
  maxConcurrentOperations: 3,   // Parallel operations limit
  autoProcess: true,            // Auto-process on enqueue
)
```

### SyncEngine Configuration

Configure via `SyncEngineConfig`:

```dart
SyncEngineConfig(
  syncInterval: Duration(minutes: 15),  // Background sync interval
  maxConcurrentPush: 3,                 // Parallel push operations
  maxRetryAttempts: 5,                  // Retry before failure
  backoffBaseSeconds: 2,                // Retry delay base
  enableBackgroundSync: true,           // Enable background sync
  syncOnReconnect: true,                // Sync when network returns
)
```

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
│   ├── comment.dart          # Comment model with Hive adapter
│   ├── interaction.dart      # Interaction model with Hive adapter
│   └── models.dart           # Barrel export
├── providers/                # Riverpod providers
│   ├── auth_provider.dart    # Authentication state
│   ├── comments_provider.dart # Comments state with pagination
│   ├── interactions_provider.dart # Interactions state
│   ├── settings_provider.dart # App settings and theme
│   ├── youtube_provider.dart # YouTube API providers
│   └── providers.dart        # Barrel export
├── routes/                   # Navigation
│   └── app_router.dart       # GoRouter configuration
├── screens/                  # UI screens
│   ├── login_screen.dart     # Login/authentication
│   ├── dashboard_screen.dart # Main dashboard with search
│   ├── comment_detail_screen.dart # Comment details
│   ├── settings_screen.dart  # App settings
│   └── screens.dart          # Barrel export
├── services/                 # Business logic
│   ├── api_service.dart      # CommentApiService with YouTube integration
│   ├── auth_service.dart     # Authentication service with YouTube OAuth
│   ├── auth/                 # Auth sub-services
│   │   ├── token_storage.dart # Secure token storage
│   │   └── youtube_auth_service.dart # YouTube OAuth service
│   ├── youtube/              # YouTube API services
│   │   ├── youtube_api_client.dart # HTTP client with retry/backoff
│   │   └── youtube_data_service.dart # YouTube Data API v3 service
│   ├── background_sync_service.dart # Background sync stub
│   ├── local_storage_service.dart # Hive local storage
│   ├── mock_data_service.dart # Mock data for development
│   ├── notification_service.dart # Push notification stub
│   └── services.dart         # Barrel export
├── src/                      # Offline-first architecture
│   ├── sync/                 # Sync engine components
│   │   ├── sync_engine.dart  # Main sync orchestrator
│   │   ├── sync_queue.dart   # Persistent operation queue
│   │   ├── conflict_resolver.dart # Conflict resolution
│   │   ├── hive_adapters.dart # Hive adapters for sync entities
│   │   ├── remote_delta_client.dart # Delta sync client
│   │   └── sync.dart         # Barrel export
│   ├── repositories/         # Offline-first repositories
│   │   ├── offline_comment_repository.dart # Comment repository
│   │   └── repositories.dart # Barrel export
│   ├── providers/            # Sync-related providers
│   │   ├── sync_status_provider.dart # Sync status state
│   │   └── providers.dart    # Barrel export
│   └── ui/                   # Sync UI components
│       ├── widgets/          # Sync widgets
│       │   ├── sync_status_indicator.dart # AppBar indicator
│       │   └── widgets.dart  # Barrel export
│       └── pages/            # Sync pages
│           ├── sync_status_page.dart # Detailed status page
│           └── pages.dart    # Barrel export
├── theme/                    # Theming
│   └── app_theme.dart        # Light and dark theme definitions
├── utils/                    # Utility functions
└── widgets/                  # Reusable UI components
    ├── comment_card.dart     # Comment list item
    ├── common_widgets.dart   # Loading, error, empty states
    ├── interaction_tile.dart # Interaction list item
    ├── pagination_controls.dart # Pagination UI
    ├── search_bar_widget.dart # Search input
    ├── settings_tile.dart    # Settings list items
    └── widgets.dart          # Barrel export
```

## Getting Started

### Prerequisites

- Flutter SDK (^3.5.0)
- Dart SDK (^3.5.0)
- Google Cloud Platform account (for YouTube API)

### Google Cloud Platform Setup

To use the YouTube Data API v3, you need to set up OAuth 2.0 credentials in Google Cloud Platform:

#### 1. Create a Google Cloud Project

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Note your project ID

#### 2. Enable YouTube Data API v3

1. Go to **APIs & Services** > **Library**
2. Search for "YouTube Data API v3"
3. Click **Enable**

#### 3. Configure OAuth Consent Screen

1. Go to **APIs & Services** > **OAuth consent screen**
2. Select **External** user type (or Internal for Google Workspace)
3. Fill in the required fields:
   - App name: `YouTracker`
   - User support email: Your email
   - Developer contact email: Your email
4. Add scopes:
   - `https://www.googleapis.com/auth/youtube.readonly` - View YouTube account
   - `https://www.googleapis.com/auth/youtube.force-ssl` - Manage YouTube account
5. Add test users (your Google account email) during development

#### 4. Create OAuth 2.0 Credentials

1. Go to **APIs & Services** > **Credentials**
2. Click **Create Credentials** > **OAuth client ID**
3. Create credentials for each platform:

##### Android
- Application type: **Android**
- Name: `YouTracker Android`
- Package name: `com.example.you_tracker` (or your custom package name)
- SHA-1 certificate fingerprint:
  ```bash
  # Debug fingerprint
  keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
  
  # Release fingerprint
  keytool -list -v -keystore your-release-key.keystore -alias your-alias
  ```

##### iOS
- Application type: **iOS**
- Name: `YouTracker iOS`
- Bundle ID: `com.example.youTracker` (or your custom bundle ID)

##### Web
- Application type: **Web application**
- Name: `YouTracker Web`
- Authorized JavaScript origins: `http://localhost:5000` (for development)
- Authorized redirect URIs: `http://localhost:5000/callback`

#### 5. Configure Platform-Specific Files

##### Android (`android/app/src/main/res/values/strings.xml`)
Create this file if it doesn't exist:
```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="default_web_client_id">YOUR_WEB_CLIENT_ID.apps.googleusercontent.com</string>
</resources>
```

##### iOS (`ios/Runner/Info.plist`)
Add the following inside the `<dict>` tag:
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>com.googleusercontent.apps.YOUR_IOS_CLIENT_ID</string>
        </array>
    </dict>
</array>
<key>GIDClientID</key>
<string>YOUR_IOS_CLIENT_ID.apps.googleusercontent.com</string>
```

##### Web (`web/index.html`)
Add this in the `<head>` section:
```html
<meta name="google-signin-client_id" content="YOUR_WEB_CLIENT_ID.apps.googleusercontent.com">
```

### Required YouTube API Scopes

The app requests the following OAuth scopes:

| Scope | Description |
|-------|-------------|
| `youtube.readonly` | View your YouTube account |
| `youtube.force-ssl` | Manage your YouTube account (required for secure API calls) |

### Installation

1. Clone the repository:
```bash
git clone https://github.com/TestingCodings/YouTracker.git
cd YouTracker
```

2. Install dependencies:
```bash
flutter pub get
```

3. Generate Hive adapters (if needed):
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

4. Configure Google OAuth (see above)

5. Run the app:
```bash
flutter run
```

### Running Tests

```bash
flutter test
```

## Dependencies

### Main Dependencies
- **flutter_riverpod**: State management
- **go_router**: Navigation and routing
- **hive_flutter**: Local storage
- **google_fonts**: Custom typography
- **connectivity_plus**: Network status
- **shared_preferences**: Simple key-value storage
- **firebase_messaging**: Push notifications (stub)
- **flutter_local_notifications**: Local notifications (stub)
- **google_sign_in**: Google OAuth 2.0 authentication
- **googleapis**: Google APIs library
- **http**: HTTP client for API calls
- **flutter_secure_storage**: Secure token storage
- **retry**: Exponential backoff helper

### Dev Dependencies
- **flutter_lints**: Linting rules
- **hive_generator**: Hive adapter generation
- **build_runner**: Code generation
- **riverpod_generator**: Riverpod code generation

## Architecture

The app follows a clean architecture pattern:

1. **Models**: Data structures with Hive adapters for local storage
2. **Services**: Business logic and API communication
   - `YouTubeAuthService`: Handles Google OAuth with YouTube scopes
   - `TokenStorage`: Securely stores OAuth tokens
   - `YouTubeApiClient`: HTTP client with retry/backoff for rate limits
   - `YouTubeDataService`: YouTube Data API v3 integration
   - `CommentApiService`: Unified API with mock fallback
3. **Providers**: Riverpod state management
4. **Screens**: UI pages
5. **Widgets**: Reusable UI components

### State Management

Using Riverpod for reactive state management:
- `StateNotifierProvider` for complex state (auth, comments, settings)
- `FutureProvider` for async data fetching
- `Provider` for dependency injection (router, services)

### YouTube API Integration

The app uses the YouTube Data API v3 with the following features:

- **OAuth 2.0 Authentication**: Sign in with Google to access YouTube data
- **Automatic Token Refresh**: Tokens are refreshed transparently when expired
- **Rate Limit Handling**: Automatic retry with exponential backoff (429, 403 quota errors)
- **Pagination**: Full support for YouTube API pagination tokens
- **Incremental Sync**: Only fetch new comments using `publishedAfter` timestamps
- **Local Search**: Client-side filtering with server-side search when available

### Navigation

Using GoRouter for declarative routing:
- Type-safe route names
- Custom page transitions
- Authentication redirect logic
- Deep linking support

## Rate Limits

The YouTube Data API v3 has quotas:
- **Default quota**: 10,000 units per day
- **Each request costs** 1-100 units depending on the endpoint

The app handles rate limits with:
- Exponential backoff (1s, 2s, 4s, up to 32s)
- Jitter to prevent thundering herd
- Maximum 3 retry attempts

## Future Improvements

- [x] Implement real YouTube API integration
- [x] Implement OAuth2 for YouTube authentication
- [x] Add rate limit handling with exponential backoff
- [x] Add incremental sync for comments
- [x] Implement offline-first architecture with bidirectional sync
- [x] Add conflict resolution with field-level merging
- [x] Add persistent sync queue with retry logic
- [x] Add sync status UI indicator
- [ ] Add Firebase backend for user data
- [ ] Implement real push notifications
- [ ] Add analytics and charts
- [ ] Implement comment reply functionality
- [ ] Add export/share features
- [ ] Add Workmanager/background_fetch for native background sync

## Migration Notes

### Upgrading to Offline-First Architecture

The offline-first architecture is backward compatible with existing installations:

1. **Automatic Migration**: On first launch after upgrade, the app automatically:
   - Creates new Hive boxes (`syncQueueBox`, `metadataBox`, `syncableEntityBox`)
   - Migrates existing comments to include sync metadata
   - Sets migration flag to prevent repeated migrations

2. **No Data Loss**: All existing local data is preserved during migration.

3. **Recovery Mode**: If local state becomes corrupt, use the "Force Full Sync" option in Settings > Sync Status to rebuild from remote.

### Configuration Flags

Environment variables or config file options:

| Setting | Default | Description |
|---------|---------|-------------|
| `syncInterval` | 15 min | Background sync interval |
| `maxConcurrentPush` | 3 | Parallel push operations |
| `maxRetryAttempts` | 5 | Retries before dead letter |
| `backoffBase` | 2 sec | Exponential backoff base |
| `enableBackgroundSync` | true | Enable background sync |

### Background Sync Setup (Future)

Background sync will be implemented using:
- **Android**: Workmanager for periodic background work
- **iOS**: background_fetch / BackgroundTasks framework

Platform setup will require:
- Android: `android/app/src/main/AndroidManifest.xml` configuration
- iOS: Enable Background Modes capability in Xcode

## Troubleshooting

### Common Issues

1. **"Sign in failed" error**
   - Verify OAuth credentials are correctly configured
   - Check that SHA-1 fingerprint matches (Android)
   - Ensure bundle ID matches (iOS)
   - Verify the user is added as a test user in OAuth consent screen

2. **"Quota exceeded" error**
   - You've hit the daily API quota limit
   - Wait until the quota resets (midnight Pacific Time)
   - Request higher quota in Google Cloud Console

3. **"Invalid scope" error**
   - Enable YouTube Data API v3 in Google Cloud Console
   - Add required scopes to OAuth consent screen

## License

This project is open source and available under the MIT License.
