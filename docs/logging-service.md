# Logging Service Documentation

## Overview

The YATA Logging Service provides comprehensive logging functionality for the Flutter application with support for both development and production environments. It features bilingual logging (English/Japanese), buffered file writing, automatic log rotation, and configurable log levels.

## Architecture

The logging service follows a singleton pattern with the following key components:

- **LogService**: Main singleton class managing all logging operations
- **LogLevel**: Enum defining log severity levels (debug, info, warning, error)
- **LogMessage**: Interface for structured, bilingual log messages
- **Buffer Management**: Queue-based buffering for efficient file I/O
- **File Rotation**: Automatic rotation based on file size limits

## Key Features

### 1. Environment-Aware Logging

- **Development Mode**: All log levels output to console via `dart:developer`
- **Release Mode**: Only warning/error levels are persisted to files
- **Configurable Minimum Level**: Dynamic log level filtering

### 2. Buffered File Writing

- **Buffer Size**: 100 entries maximum to prevent memory issues
- **Flush Interval**: Automatic flush every 5 seconds
- **Immediate Flush**: Error-level logs are flushed immediately
- **Retry Logic**: Automatic retry on file write failures (up to 3 attempts)

### 3. File Management

- **Daily Rotation**: Log files are organized by date (YYYY-MM-DD-mixed.log)
- **Size-Based Rotation**: Files rotate automatically at 10MB limit
- **Automatic Cleanup**: Old log files removed after 30 days
- **Platform-Specific Paths**: Configurable via environment variables

### 4. Bilingual Support

- **Japanese Localization**: All log messages support Japanese translations
- **Message Formatting**: Automatic combination of English and Japanese messages
- **Structured Messages**: Template-based messages with parameter substitution

## Installation & Setup

### 1. Initialize the Service

```dart
import 'package:yata/core/utils/log_service.dart';
import 'package:yata/core/constants/enums.dart';

// Initialize at app startup
await LogService.initialize(
  minimumLevel: LogLevel.info  // Optional: set minimum log level
);
```

### 2. Environment Configuration

Create a `.env` file with platform-specific log paths:

```env
# Optional: Custom log directory paths
LOG_PATH_ANDROID=/storage/emulated/0/Android/data/com.example.yata/files/logs
LOG_PATH_IOS=/var/mobile/Containers/Data/Application/[UUID]/Documents/logs
LOG_PATH_WINDOWS=C:\Users\[User]\AppData\Local\yata\logs
LOG_PATH_MACOS=/Users/[User]/Library/Application Support/yata/logs
LOG_PATH_LINUX=/home/[user]/.local/share/yata/logs
```

If not specified, the service uses the default application documents directory.

## Usage Examples

### Basic Logging

```dart
import 'package:yata/core/utils/log_service.dart';

// Debug level (development only)
LogService.debug('ComponentName', 'Debug message');

// Info level
LogService.info('ComponentName', 'Operation completed');

// Warning level (persisted in release)
LogService.warning('ComponentName', 'Low memory detected');

// Error level (persisted in release, immediate flush)
LogService.error('ComponentName', 'Database connection failed', null, exception, stackTrace);
```

### Bilingual Logging

```dart
// English + Japanese messages
LogService.info('InventoryService', 'Stock updated', '在庫更新');
LogService.warning('PaymentService', 'Payment delayed', '決済遅延');
LogService.error('AuthService', 'Login failed', 'ログイン失敗', exception);
```

### Structured Message Logging

```dart
import 'package:yata/core/error/auth.dart';

// Using predefined message templates
LogService.infoWithMessage('AuthService', AuthInfo.loginSuccess, {
  'userId': '12345',
  'loginTime': DateTime.now().toIso8601String()
});

LogService.errorWithMessage('AuthService', AuthError.networkFailure, {
  'endpoint': '/api/login',
  'statusCode': '500'
}, exception, stackTrace);
```

### Dynamic Configuration

```dart
// Change minimum log level at runtime
LogService.setMinimumLevel(LogLevel.warning);

// Get logging statistics
final stats = await LogService.getLogStats();
print('Total log files: ${stats['totalFiles']}');
print('Total size: ${stats['totalSizeMB']} MB');
print('Buffer length: ${stats['bufferLength']}');

// Manual buffer flush
await LogService.flushBuffer();

// Cleanup old logs (custom retention)
await LogService.cleanupOldLogs(daysToKeep: 7);
```

## Log Levels

| Level | Priority | Development | Release | Japanese | Description |
|-------|----------|-------------|---------|----------|-------------|
| debug | 1 | Console | - | デバッグ | Development debugging only |
| info | 2 | Console | - | 情報 | General application flow |
| warning | 3 | Console | File | 警告 | Recoverable issues |
| error | 4 | Console | File (immediate) | エラー | Critical errors |

## File Structure

### Log File Naming

- **Daily Logs**: `YYYY-MM-DD-mixed.log`
- **Rotated Logs**: `YYYY-MM-DD-mixed.1.log`, `YYYY-MM-DD-mixed.2.log`, etc.

### Log Entry Format

```
[2024-01-15T10:30:45.123Z] [ComponentName] [LEVEL] Message content
Error: Exception details (if present)
StackTrace: Stack trace (if present)
---
```

### Directory Structure

```
Application Documents/
└── logs/
    ├── 2024-01-15-mixed.log
    ├── 2024-01-15-mixed.1.log
    ├── 2024-01-14-mixed.log
    └── ...
```

## Performance Considerations

### Buffer Management

- **Buffer Size**: Limited to 100 entries to prevent excessive memory usage
- **Flush Strategy**: Balanced between performance and data safety
- **Memory Efficiency**: Old entries are automatically removed when buffer is full

### File I/O Optimization

- **Asynchronous Operations**: All file operations are non-blocking
- **Batch Writing**: Multiple log entries are written in batches during flush
- **Retry Logic**: Automatic retry with exponential backoff for failed writes

### Production Optimizations

- **Selective Persistence**: Only warning/error levels are written to files
- **Immediate Error Handling**: Critical errors bypass buffering for immediate persistence
- **Automatic Cleanup**: Background cleanup prevents disk space issues

## Error Handling

### File System Errors

- **Write Failures**: Automatic retry with exponential backoff
- **Directory Issues**: Graceful fallback to default directories
- **Permission Problems**: Errors logged to console, application continues

### Memory Management

- **Buffer Overflow**: Automatic removal of oldest entries
- **Large Messages**: No artificial size limits, but rotation prevents excessive file sizes
- **Resource Cleanup**: Proper timer and resource disposal on app termination

## Best Practices

### 1. Initialization

```dart
// Initialize early in main()
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize logging before other services
  await LogService.initialize(minimumLevel: LogLevel.info);
  
  // Initialize other services...
  runApp(MyApp());
}
```

### 2. Service Disposal

```dart
// Properly dispose on app termination
class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    LogService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      LogService.dispose();
    }
  }
}
```

### 3. Component-Specific Logging

```dart
class InventoryService {
  static const String _component = 'InventoryService';
  
  Future<void> updateStock(String itemId, int quantity) async {
    LogService.info(_component, 'Updating stock for item $itemId');
    
    try {
      // Business logic...
      LogService.info(_component, 'Stock updated successfully', '在庫更新成功');
    } catch (e, stackTrace) {
      LogService.error(_component, 'Failed to update stock', '在庫更新失敗', e, stackTrace);
      rethrow;
    }
  }
}
```

### 4. Structured Error Messages

```dart
// Define error messages in core/error/ files
enum ServiceError implements LogMessage {
  connectionTimeout('Connection timeout occurred', 'タイムアウトが発生しました'),
  invalidData('Invalid data format received', '無効なデータ形式を受信しました'),
  authenticationFailed('Authentication failed', '認証に失敗しました');

  const ServiceError(this.message, this.messageJa);
  
  @override
  final String message;
  @override
  final String messageJa;
  
  @override
  String get combinedMessage => '$message ($messageJa)';
  
  @override
  String withParams(Map<String, String> params) {
    // Implement parameter substitution
    return combinedMessage;
  }
}
```

## Troubleshooting

### Common Issues

#### 1. Logs Not Appearing in Release

**Problem**: No log files generated in release mode
**Solution**: Ensure only warning/error levels are used, check file permissions

#### 2. High Memory Usage

**Problem**: Memory consumption increases over time
**Solution**: Verify buffer size limits, check for excessive logging frequency

#### 3. File Permission Errors

**Problem**: Cannot write to log directory
**Solution**: Check platform-specific permissions, verify directory paths

#### 4. Missing Log Entries

**Problem**: Some log entries don't appear in files
**Solution**: Ensure proper app disposal, call `LogService.dispose()` on termination

### Debugging Commands

```dart
// Check service status
final stats = await LogService.getLogStats();
print('Service status: $stats');

// Force buffer flush
await LogService.flushBuffer();

// Manual cleanup
await LogService.cleanupOldLogs(daysToKeep: 1);
```

## Integration with Other Services

### Authentication Service

The logging service is already integrated with the authentication service and provides comprehensive error tracking:

```dart
// Example from auth_service.dart
LogService.infoWithMessage('SupabaseClientService', AuthInfo.loginAttempt);
LogService.errorWithMessage('SupabaseClientService', AuthError.networkFailure, null, e);
```

### Future Feature Integration

When implementing new features, follow the established pattern:

1. Define error/info messages in `core/error/{feature}.dart`
2. Use component-specific logging with consistent naming
3. Include both English and Japanese messages for user-facing operations
4. Use appropriate log levels based on severity

## Related Files

- **Core Implementation**: `lib/core/utils/log_service.dart`
- **Log Levels**: `lib/core/constants/enums.dart`
- **Message Interface**: `lib/core/error/base.dart`
- **Auth Messages**: `lib/core/error/auth.dart`
- **Usage Example**: `lib/core/auth/auth_service.dart`