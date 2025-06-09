# Authentication Usage Examples

This document provides practical examples of how to use the `SupabaseClientService` in your Flutter application.

## Basic Setup

### Application Initialization

Initialize the authentication service in your `main.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:yata/core/auth/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase client
  await SupabaseClientService.initialize();
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YATA',
      home: AuthWrapper(),
    );
  }
}
```

## Authentication Wrapper

Create a wrapper widget to handle authentication state:

```dart
import 'package:flutter/material.dart';
import 'package:yata/core/auth/auth_service.dart';

class AuthWrapper extends StatefulWidget {
  @override
  _AuthWrapperState createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    
    // Listen to authentication state changes
    SupabaseClientService.instance.authStateChanges.listen((state) {
      if (state.event == AuthChangeEvent.signedIn) {
        Navigator.pushReplacementNamed(context, '/home');
      } else if (state.event == AuthChangeEvent.signedOut) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isSignedIn = SupabaseClientService.instance.isSignedIn;
    return isSignedIn ? HomePage() : LoginPage();
  }
}
```

## Login Page Implementation

```dart
import 'package:flutter/material.dart';
import 'package:yata/core/auth/auth_service.dart';

class LoginPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Welcome to YATA',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _signInWithGoogle(context),
              icon: Icon(Icons.login),
              label: Text('Sign in with Google'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _signInWithGoogle(BuildContext context) async {
    try {
      final success = await SupabaseClientService.instance.signInWithGoogle();
      if (success) {
        // Authentication initiated successfully
        // User will be redirected to OAuth flow
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Redirecting to Google authentication...')),
        );
      } else {
        // Authentication failed or was cancelled
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Authentication cancelled or failed')),
        );
      }
    } on SupabaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Authentication error: ${e.message}')),
      );
    } on SupabaseClientException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Client error: ${e.message}')),
      );
    }
  }
}
```

## Home Page with User Information

```dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yata/core/auth/auth_service.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = SupabaseClientService.instance.currentUser;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('YATA Dashboard'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => _signOut(context),
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'User Information',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    SizedBox(height: 8),
                    Text('Email: ${user?.email ?? 'Unknown'}'),
                    Text('ID: ${user?.id ?? 'Unknown'}'),
                    Text('Last Sign In: ${user?.lastSignInAt ?? 'Unknown'}'),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            _buildSessionInfo(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionInfo(BuildContext context) {
    final session = SupabaseClientService.instance.currentSession;
    
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Session Information',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 8),
            if (session != null) ...[
              Text('Token Type: ${session.tokenType}'),
              Text('Expires At: ${DateTime.fromMillisecondsSinceEpoch(session.expiresAt! * 1000)}'),
              Text('Refresh Token: ${session.refreshToken?.substring(0, 20)}...'),
            ] else
              Text('No active session'),
          ],
        ),
      ),
    );
  }

  Future<void> _signOut(BuildContext context) async {
    try {
      await SupabaseClientService.instance.signOut();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Successfully signed out')),
      );
    } on SupabaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign out error: ${e.message}')),
      );
    } on SupabaseClientException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Client error: ${e.message}')),
      );
    }
  }
}
```

## Deep Link Handling

Handle OAuth callbacks in your app's main widget:

```dart
import 'package:flutter/material.dart';
import 'package:uni_links/uni_links.dart';
import 'package:yata/core/auth/auth_service.dart';

class AppDeepLinkHandler extends StatefulWidget {
  final Widget child;
  
  const AppDeepLinkHandler({Key? key, required this.child}) : super(key: key);

  @override
  _AppDeepLinkHandlerState createState() => _AppDeepLinkHandlerState();
}

class _AppDeepLinkHandlerState extends State<AppDeepLinkHandler> {
  StreamSubscription? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _initDeepLinkListener();
  }

  void _initDeepLinkListener() {
    _linkSubscription = linkStream.listen(
      (String link) {
        _handleDeepLink(link);
      },
      onError: (err) {
        print('Deep link error: $err');
      },
    );
  }

  Future<void> _handleDeepLink(String link) async {
    if (link.startsWith('io.supabase.flutterquickstart://login-callback/')) {
      try {
        final user = await SupabaseClientService.instance.handleAuthCallback(link);
        if (user != null) {
          print('User authenticated successfully: ${user.email}');
          // Navigate to home page or update UI
        }
      } catch (e) {
        print('Authentication callback error: $e');
      }
    }
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
```

## Authentication State Provider

Use a state management solution like Provider for more complex scenarios:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yata/core/auth/auth_service.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  bool _isLoading = false;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    _initAuthState();
  }

  void _initAuthState() {
    _user = SupabaseClientService.instance.currentUser;
    
    SupabaseClientService.instance.authStateChanges.listen((state) {
      _user = state.session?.user;
      notifyListeners();
    });
  }

  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    try {
      final success = await SupabaseClientService.instance.signInWithGoogle();
      return success;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    _setLoading(true);
    try {
      await SupabaseClientService.instance.signOut();
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}

// Usage in main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseClientService.initialize();
  
  runApp(
    ChangeNotifierProvider(
      create: (context) => AuthProvider(),
      child: MyApp(),
    ),
  );
}
```

## Error Handling Best Practices

```dart
class AuthErrorHandler {
  static void handleAuthError(BuildContext context, dynamic error) {
    String message;
    
    if (error is SupabaseAuthException) {
      message = 'Authentication failed: ${error.message}';
    } else if (error is SupabaseClientException) {
      message = 'Client error: ${error.message}';
    } else {
      message = 'An unexpected error occurred: ${error.toString()}';
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'Retry',
          onPressed: () {
            // Implement retry logic
          },
        ),
      ),
    );
  }
}

// Usage
try {
  await SupabaseClientService.instance.signInWithGoogle();
} catch (e) {
  AuthErrorHandler.handleAuthError(context, e);
}
```

## Testing Authentication

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:yata/core/auth/auth_service.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

void main() {
  group('SupabaseClientService Tests', () {
    test('should return true when user is signed in', () {
      // Mock the service and test authentication state
      // Implementation depends on your testing strategy
    });
    
    test('should handle sign out correctly', () async {
      // Test sign out functionality
    });
  });
}
```

## Advanced Usage

### Custom Authentication Flow

```dart
class CustomAuthFlow {
  static Future<void> handleCustomSignIn(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Signing in...'),
          ],
        ),
      ),
    );

    try {
      final success = await SupabaseClientService.instance.signInWithGoogle();
      Navigator.of(context).pop(); // Close loading dialog
      
      if (!success) {
        throw Exception('Authentication was cancelled');
      }
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      AuthErrorHandler.handleAuthError(context, e);
    }
  }
}
```

This completes the comprehensive usage examples for the authentication service. The examples cover basic setup, error handling, state management, and advanced usage patterns.