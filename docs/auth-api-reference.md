# Authentication API Reference

## SupabaseClientService

A singleton service that manages Supabase client initialization and provides OAuth authentication functionality for the YATA application.

### Class Overview

The `SupabaseClientService` class follows Flutter/Dart conventions using the singleton pattern to ensure a single instance manages all Supabase interactions throughout the application lifecycle.

## Static Methods

### initialize()

Initializes the Supabase client. Must be called once during application startup.

```dart
static Future<void> initialize() async
```

**Returns:** `Future<void>`

**Throws:**
- `SupabaseClientException` - If initialization fails

**Example:**
```dart
await SupabaseClientService.initialize();
```

**Description:**
- Loads environment variables from `.env` file
- Initializes Supabase Flutter client with URL and anonymous key
- Sets up the internal client instance
- Logs initialization status

---

## Instance Properties

### client

Returns the initialized Supabase client instance.

```dart
static SupabaseClient get client
```

**Returns:** `SupabaseClient`

**Throws:**
- `StateError` - If client is not initialized

---

### instance

Returns the singleton instance of SupabaseClientService.

```dart
static SupabaseClientService get instance
```

**Returns:** `SupabaseClientService`

---

### currentUser

Returns the currently authenticated user.

```dart
User? get currentUser
```

**Returns:** `User?` - Current user or null if not authenticated

---

### isSignedIn

Checks if a user is currently signed in with a valid session.

```dart
bool get isSignedIn
```

**Returns:** `bool` - True if user is signed in with valid session

**Description:**
- Validates session expiration
- Automatically attempts session refresh if expiring within 5 minutes

---

### currentSession

Returns the current authentication session.

```dart
Session? get currentSession
```

**Returns:** `Session?` - Current session or null if not authenticated

---

### authStateChanges

Stream of authentication state changes.

```dart
Stream<AuthState> get authStateChanges
```

**Returns:** `Stream<AuthState>` - Stream of authentication events

**Usage:**
```dart
SupabaseClientService.instance.authStateChanges.listen((event) {
  if (event.event == AuthChangeEvent.signedIn) {
    // Handle sign in
  } else if (event.event == AuthChangeEvent.signedOut) {
    // Handle sign out
  }
});
```

---

## Instance Methods

### signInWithGoogle()

Initiates Google OAuth authentication flow.

```dart
Future<bool> signInWithGoogle() async
```

**Returns:** `Future<bool>` - True if authentication initiated successfully

**Throws:**
- `SupabaseAuthException` - If Google authentication fails
- `SupabaseClientException` - If unable to initiate authentication

**Features:**
- 30-second timeout protection
- Comprehensive error logging
- External application launch mode

**Example:**
```dart
final success = await SupabaseClientService.instance.signInWithGoogle();
if (success) {
  print('Authentication successful');
}
```

---

### handleAuthCallback()

Processes OAuth authentication callback and restores session.

```dart
Future<User?> handleAuthCallback(String callbackUrl) async
```

**Parameters:**
- `callbackUrl` (String) - OAuth callback URL containing authorization code

**Returns:** `Future<User?>` - Authenticated user or null if failed

**Throws:**
- `SupabaseAuthException` - If callback processing fails
- `SupabaseClientException` - If unable to process callback

**Example:**
```dart
final user = await SupabaseClientService.instance.handleAuthCallback(url);
if (user != null) {
  // User successfully authenticated
}
```

---

### signOut()

Signs out the current user and clears the session.

```dart
Future<void> signOut() async
```

**Returns:** `Future<void>`

**Throws:**
- `SupabaseAuthException` - If sign out fails
- `SupabaseClientException` - If error during sign out

**Example:**
```dart
await SupabaseClientService.instance.signOut();
```

---

## Private Methods

### _isSessionValid()

Validates current session and handles automatic refresh.

```dart
bool _isSessionValid()
```

**Returns:** `bool` - True if session is valid

**Features:**
- Checks session expiration
- Triggers refresh 5 minutes before expiration
- Returns false for expired sessions

---

### _refreshSessionIfNeeded()

Attempts to refresh the current session.

```dart
Future<void> _refreshSessionIfNeeded() async
```

**Returns:** `Future<void>`

**Description:**
- Called automatically when session is nearing expiration
- Logs refresh attempts and results
- Handles refresh failures gracefully

---

### _extractParamValue()

Helper method to extract URL parameters.

```dart
String? _extractParamValue(String url, String paramName)
```

**Parameters:**
- `url` (String) - URL to parse
- `paramName` (String) - Parameter name to extract

**Returns:** `String?` - Parameter value or null if not found

---

## Exception Classes

### SupabaseClientException

General exception for Supabase client operations.

```dart
class SupabaseClientException implements Exception {
  final String message;
  const SupabaseClientException(this.message);
}
```

### SupabaseAuthException

Specific exception for authentication-related errors.

```dart
class SupabaseAuthException implements Exception {
  final String message;
  const SupabaseAuthException(this.message);
}
```

---

## Environment Variables

The service requires the following environment variables:

| Variable | Required | Description |
|----------|----------|-------------|
| `SUPABASE_URL` | Yes | Supabase project URL |
| `SUPABASE_ANON_KEY` | Yes | Supabase anonymous key |
| `REDIRECT_URL` | No | OAuth redirect URL (defaults to Flutter quickstart URL) |

---

## Logging

All operations are logged using `dart:developer` with appropriate log levels:

- **Info (0):** Successful operations
- **Warning (900):** Authentication errors, timeouts
- **Severe (1000):** Critical failures, initialization errors

Log messages include:
- Operation start/completion
- Error details and context
- User IDs for successful operations
- Timeout and refresh notifications