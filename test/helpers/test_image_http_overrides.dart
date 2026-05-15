import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

final Uint8List kTestImagePngBytes = Uint8List.fromList(
  base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/p9sAAAAASUVORK5CYII=',
  ),
);

Future<T> runWithTestImageHttpOverrides<T>(Future<T> Function() body) {
  return HttpOverrides.runZoned<Future<T>>(
    body,
    createHttpClient: (_) => _TestImageHttpClient(),
  );
}

class _TestImageHttpClient extends Fake implements HttpClient {
  @override
  Future<HttpClientRequest> getUrl(Uri url) => openUrl('GET', url);

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async {
    return _TestImageHttpClientRequest(method: method, uri: url);
  }
}

class _TestImageHttpClientRequest extends Fake implements HttpClientRequest {
  _TestImageHttpClientRequest({required this.method, required this.uri});

  @override
  final String method;

  @override
  final Uri uri;

  @override
  final HttpHeaders headers = _TestImageHttpHeaders();

  @override
  bool bufferOutput = true;

  @override
  int contentLength = -1;

  @override
  Encoding encoding = utf8;

  @override
  bool followRedirects = true;

  @override
  int maxRedirects = 5;

  @override
  bool persistentConnection = true;

  @override
  List<Cookie> cookies = <Cookie>[];

  @override
  void add(List<int> data) {}

  @override
  void addError(Object error, [StackTrace? stackTrace]) {}

  @override
  Future<void> addStream(Stream<List<int>> stream) async {
    await stream.drain<void>();
  }

  @override
  void abort([Object? exception, StackTrace? stackTrace]) {}

  @override
  Future<HttpClientResponse> close() async => _TestImageHttpClientResponse();

  @override
  Future<HttpClientResponse> get done async => _TestImageHttpClientResponse();

  @override
  Future<void> flush() async {}

  @override
  void write(Object? obj) {}

  @override
  void writeAll(Iterable<Object?> objects, [String separator = '']) {}

  @override
  void writeCharCode(int charCode) {}

  @override
  void writeln([Object? obj = '']) {}
}

class _TestImageHttpClientResponse extends Stream<List<int>>
    implements HttpClientResponse {
  @override
  X509Certificate? get certificate => null;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  int get contentLength => kTestImagePngBytes.length;

  @override
  List<Cookie> get cookies => const <Cookie>[];

  @override
  HttpHeaders get headers => _TestImageHttpHeaders();

  @override
  bool get isRedirect => false;

  @override
  bool get persistentConnection => false;

  @override
  String get reasonPhrase => 'OK';

  @override
  List<RedirectInfo> get redirects => const <RedirectInfo>[];

  @override
  int get statusCode => HttpStatus.ok;

  @override
  Future<Socket> detachSocket() {
    throw UnsupportedError('Test image response does not expose a socket.');
  }

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.fromIterable(<List<int>>[
      kTestImagePngBytes,
    ]).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TestImageHttpHeaders extends Fake implements HttpHeaders {
  Map<String, List<String>> get _values => <String, List<String>>{
    HttpHeaders.contentLengthHeader: <String>[
      kTestImagePngBytes.length.toString(),
    ],
    HttpHeaders.contentTypeHeader: <String>['image/png'],
  };

  @override
  List<String>? operator [](String name) => _values[name.toLowerCase()];

  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {
    _values[name.toLowerCase()] = <String>[value.toString()];
  }

  @override
  void forEach(void Function(String name, List<String> values) action) {
    _values.forEach(action);
  }

  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {
    _values[name.toLowerCase()] = <String>[value.toString()];
  }

  @override
  String? value(String name) => this[name]?.join(',');
}
