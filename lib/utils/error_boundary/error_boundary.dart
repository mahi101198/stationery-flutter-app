import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rps_stationery/services/error_handling_service.dart';

/// Error boundary widget that catches and handles UI errors gracefully
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final String? fallbackTitle;
  final String? fallbackMessage;
  final Widget? fallbackWidget;
  final VoidCallback? onError;

  const ErrorBoundary({
    super.key,
    required this.child,
    this.fallbackTitle,
    this.fallbackMessage,
    this.fallbackWidget,
    this.onError,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  bool hasError = false;
  String? errorMessage;
  Function(FlutterErrorDetails)? _previousOnError;

  @override
  void initState() {
    super.initState();
    // Chain into the existing error handler so we don't swallow stacks/Crashlytics
    _previousOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      // First, let Flutter (and any global handlers) log the error
      _previousOnError?.call(details);
      FlutterError.dumpErrorToConsole(details);
      // Then handle at the boundary for a graceful fallback UI
      _handleError(details.exception, details.stack);
    };
  }

  @override
  void dispose() {
    // Restore the previous handler to avoid leaking a global override
    if (_previousOnError != null) {
      FlutterError.onError = _previousOnError;
    }
    super.dispose();
  }

  void _handleError(dynamic error, StackTrace? stackTrace) {
    if (mounted) {
      setState(() {
        hasError = true;
        errorMessage = error.toString();
      });

      // Report error to error handling service (if available)
      try {
        if (Get.isRegistered<ErrorHandlingService>()) {
          ErrorHandlingService.instance.handleError(
            error,
            userMessage: widget.fallbackMessage ?? 'Something went wrong. Please try again.',
            showSnackBar: false, // We'll show our own error UI
          );
        } else {
          // Fallback logging when service not available
          debugPrint('ErrorBoundary: ErrorHandlingService not available yet');
          debugPrint('Error: $error');
        }
      } catch (serviceError) {
        // Don't let error handling cause more errors
        debugPrint('ErrorBoundary: Failed to report error - $serviceError');
        debugPrint('Original error: $error');
      }

      // Call custom error handler if provided
      widget.onError?.call();
    }
  }

  void _retry() {
    setState(() {
      hasError = false;
      errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (hasError) {
      return _buildErrorWidget();
    }

    return widget.child;
  }

  Widget _buildErrorWidget() {
    if (widget.fallbackWidget != null) {
      return widget.fallbackWidget!;
    }

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 24),
              Text(
                widget.fallbackTitle ?? 'Oops! Something went wrong',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                widget.fallbackMessage ?? 
                'We encountered an unexpected error. Please try again or contact support if the problem persists.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              if (errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Error details: $errorMessage',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _retry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try Again'),
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton.icon(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Go Back'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Error boundary for specific widgets that might fail
class SafeWidget extends StatelessWidget {
  final Widget child;
  final Widget? fallback;
  final String? errorMessage;

  const SafeWidget({
    super.key,
    required this.child,
    this.fallback,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    return ErrorBoundary(
      fallbackWidget: fallback ?? _buildDefaultFallback(context),
      fallbackMessage: errorMessage,
      child: child,
    );
  }

  Widget _buildDefaultFallback(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.warning_outlined,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 8),
          Text(
            'Unable to load content',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Error boundary for async operations
class AsyncErrorBoundary extends StatefulWidget {
  final Future<Widget> Function() futureBuilder;
  final Widget? loadingWidget;
  final Widget? errorWidget;
  final String? errorMessage;

  const AsyncErrorBoundary({
    super.key,
    required this.futureBuilder,
    this.loadingWidget,
    this.errorWidget,
    this.errorMessage,
  });

  @override
  State<AsyncErrorBoundary> createState() => _AsyncErrorBoundaryState();
}

class _AsyncErrorBoundaryState extends State<AsyncErrorBoundary> {
  late Future<Widget> _future;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _future = widget.futureBuilder();
  }

  void _retry() {
    setState(() {
      _hasError = false;
      _errorMessage = null;
      _future = widget.futureBuilder();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return widget.loadingWidget ?? 
            const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          _hasError = true;
          _errorMessage = snapshot.error.toString();
          
          // Report error (if service available)
          try {
            if (Get.isRegistered<ErrorHandlingService>()) {
              ErrorHandlingService.instance.handleError(
                snapshot.error!,
                userMessage: widget.errorMessage ?? 'Failed to load content',
                showSnackBar: false,
              );
            } else {
              debugPrint('AsyncErrorBoundary: ErrorHandlingService not available yet');
              debugPrint('Error: ${snapshot.error}');
            }
          } catch (serviceError) {
            debugPrint('AsyncErrorBoundary: Failed to report error - $serviceError');
            debugPrint('Original error: ${snapshot.error}');
          }

          return widget.errorWidget ?? _buildDefaultErrorWidget(context);
        }

        return snapshot.data ?? const SizedBox.shrink();
      },
    );
  }

  Widget _buildDefaultErrorWidget(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load content',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            widget.errorMessage ?? 'Please try again',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _retry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
