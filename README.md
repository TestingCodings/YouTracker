# YouTracker

A Flutter application for tracking and analyzing YouTube comments. Replace the clunky and convoluted process for tracking and viewing comments, likes, and replies for YouTube.

## Features

- **Login Screen**: Email/password authentication with Google sign-in option
- **Dashboard**: Browse comments with search functionality and pagination
- **Comment Details**: View detailed comment information with interactions
- **Settings**: Configure theme, notifications, sync settings, and account management
- **Dark/Light Theme**: Toggle between dark and light modes
- **Local Storage**: Offline-first with Hive database
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
│   ├── api_service.dart      # API service with mock data
│   ├── auth_service.dart     # Authentication service
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

4. Run the app:
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

### Dev Dependencies
- **flutter_lints**: Linting rules
- **hive_generator**: Hive adapter generation
- **build_runner**: Code generation
- **riverpod_generator**: Riverpod code generation

## Architecture

The app follows a clean architecture pattern:

1. **Models**: Data structures with Hive adapters for local storage
2. **Services**: Business logic and API communication
3. **Providers**: Riverpod state management
4. **Screens**: UI pages
5. **Widgets**: Reusable UI components

### State Management

Using Riverpod for reactive state management:
- `StateNotifierProvider` for complex state (auth, comments, settings)
- `FutureProvider` for async data fetching
- `Provider` for dependency injection (router)

### Navigation

Using GoRouter for declarative routing:
- Type-safe route names
- Custom page transitions
- Authentication redirect logic
- Deep linking support

## Future Improvements

- [ ] Implement real YouTube API integration
- [ ] Add Firebase backend for user data
- [ ] Implement real push notifications
- [ ] Add analytics and charts
- [ ] Implement comment reply functionality
- [ ] Add export/share features
- [ ] Implement OAuth2 for YouTube authentication

## License

This project is open source and available under the MIT License.
