import 'dart:io';

import 'package:dio/dio.dart';

/// Simple retry interceptor: retries once on network/connection errors.
class RetryOnConnectionChangeInterceptor extends Interceptor {
  final Dio dio;

  RetryOnConnectionChangeInterceptor({required this.dio});

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (_shouldRetry(err)) {
      try {
        final requestOptions = err.requestOptions;

        // You can add a small delay if you want:
        // await Future.delayed(const Duration(seconds: 1));

        final Response response = await dio.fetch(requestOptions);
        return handler.resolve(response);
      } catch (e) {
        // If retry also fails, pass the original error forward.
        return handler.next(err);
      }
    }

    // If we decided not to retry, just forward the error.
    return handler.next(err);
  }

  bool _shouldRetry(DioException err) {
    // Typical network issues:
    if (err.error is SocketException) {
      return true;
    }

    // Dio 5 enum: connectionError / unknown are often network-related.
    if (err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.unknown) {
      return true;
    }

    return false;
  }
}
