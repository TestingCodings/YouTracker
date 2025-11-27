# YouTracker

A Flutter application for tracking and analyzing YouTube comments. Replace the clunky and convoluted process for tracking and viewing comments, likes, and replies for YouTube.

## Features

- **YouTube OAuth Integration**: Sign in with Google to access your YouTube channel
- **Real YouTube Data API v3**: Fetch comments, videos, and channel data from YouTube
- **Login Screen**: Email/password authentication with Google sign-in option
- **Dashboard**: Browse comments with search functionality and pagination
- **Comment Details**: View detailed comment information with interactions
- **Settings**: Configure theme, notifications, sync settings, and account management
- **Dark/Light Theme**: Toggle between dark and light modes
- **Local Storage**: Offline-first with Hive database
- **Incremental Sync**: Only fetch new comments since last sync
- **Rate Limit Handling**: Automatic retry with exponential backoff
- **Push Notifications**: Stub implementation for future backend integration
- **Background Sync**: Automatic data synchronization (configurable intervals)
- **Riverpod State Management**: Reactive state management throughout the app
- **GoRouter Navigation**: Clean, type-safe routing

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
- [ ] Add Firebase backend for user data
- [ ] Implement real push notifications
- [ ] Add analytics and charts
- [ ] Implement comment reply functionality
- [ ] Add export/share features

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
