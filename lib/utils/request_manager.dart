import 'package:dio/dio.dart';

class RequestManager {
  static final RequestManager _instance = RequestManager._internal();
  factory RequestManager() => _instance;
  RequestManager._internal();

  CancelToken? _currentRequestToken;
  final Dio _dio = Dio();

  /// Cancel request sebelumnya jika masih pending
  void cancelPending() {
    if (_currentRequestToken != null && 
        _currentRequestToken!.isCancelled == false) {
      _currentRequestToken!.cancel('Cancelled by new request');
    }
    _currentRequestToken = CancelToken();
  }

  /// GET request dengan auto-cancel
  Future<Response> get(String url, {Map<String, dynamic>? queryParameters}) async {
    cancelPending();
    return _dio.get(url, 
      queryParameters: queryParameters,
      cancelToken: _currentRequestToken,
    );
  }

  /// POST request dengan auto-cancel
  Future<Response> post(String url, {dynamic data}) async {
    cancelPending();
    return _dio.post(url, 
      data: data,
      options: Options(headers: {'Content-Type': 'application/json'}),
      cancelToken: _currentRequestToken,
    );
  }

  Dio get client => _dio;
}