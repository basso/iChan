import 'dart:convert';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:iChan/blocs/post_bloc.dart';
import 'package:iChan/models/thread.dart';
import 'package:iChan/services/exports.dart';
import 'package:iChan/services/htmlz.dart';
import 'package:iChan/services/my.dart' as my;

import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;

class FourchanApi {
  FourchanApi({this.domain = 'https://a.4cdn.org'});
  String domain;
  static const defaultDomain = 'https://a.4cdn.org';
  static const imageDomain = 'https://is2.4chan.org';
  static const postUrl = 'https://sys.4chan.org';

  final webDomain = 'https://boards.4chan.org';

  Dio dio({List<String> cookies, int timeout}) {
    timeout ??= my.prefs.getBool('slow_connection') ? 15000 : 7000;

    final options = BaseOptions(
      baseUrl: domain,
      connectTimeout: timeout,
      receiveTimeout: timeout,
      sendTimeout: timeout,
      receiveDataWhenStatusError: true,
      responseType: ResponseType.plain,
    );

    final dio = Dio(options);
    if (cookies == null || cookies.isEmpty) {
      final cookieJar = PersistCookieJar(dir: Consts.appDocDir.path);
      dio.interceptors.add(CookieManager(cookieJar));
    } else {
      dio.options.headers['cookie'] = cookies.join("; ");
    }
    return dio;
  }

  Future<Map<String, dynamic>> fetchBoards() async {
    const cacheKey = '4chan/categories';
    final cachedBody = my.prefs.getJsonCache(cacheKey);

    if (cachedBody.isNotEmpty) {
      return json.decode(cachedBody) as Map<String, dynamic>;
    }

    final response = await http.get('$domain/boards.json');
    if (response.statusCode == 200) {
      my.prefs.putJsonCache(cacheKey, response.body);
    }

    return json.decode(response.body) as Map<String, dynamic>;
  }

  Future<String> fetchThreads({String boardName}) async {
    final uri = '$domain/$boardName/catalog.json';

    return await _safeRequest(uri);
  }

  Future<String> fetchThreadPosts(
      {String threadId, String boardName, String archiveDate = '', Thread thread}) async {
    if (thread != null) {
      threadId = thread.outerId;
      boardName = thread.boardName;
    }

    final String uri = '$domain/$boardName/thread/$threadId.json';
    return await _safeRequest(uri);
  }

  Future<Map<String, dynamic>> deletePost(Map<String, dynamic> formData,
      {List<String> cookies}) async {
    try {
      final options = BaseOptions(
        baseUrl: postUrl,
        connectTimeout: 15000,
        receiveTimeout: 15000,
        sendTimeout: 15000,
        receiveDataWhenStatusError: true,
        responseType: ResponseType.plain,
        contentType: 'multipart/form-data',
      );

      final _dio = Dio(options);
      if (cookies == null || cookies.isEmpty) {
        final cookieJar = PersistCookieJar(dir: Consts.appDocDir.path);
        _dio.interceptors.add(CookieManager(cookieJar));
      }

      final response = await _dio.post(
        "/${formData['board']}/imgboard.php",
        // cancelToken: cancelToken,
        data: FormData.fromMap(formData),
        onSendProgress: (int sent, int total) {
          my.postBloc.add(AddProgress(bytesSent: sent, bytesTotal: total));
        },
      );

      if (response.statusCode == 200) {
        try {
          return {"ok": true};
        } catch (e) {
          final error = RegExp(r'<span id="errmsg" style="color: red;">(.+)<\/span')
              .allMatches(response.data)
              .toList()[0];
          final message = Htmlz.strip(error.group(1)).replaceAll('[Learn More]', '');
          return {"ok": false, "error": message};
        }
      } else {
        return {"ok": false, "error": "Error"};
      }
    } on DioError catch (e) {
      print("Dio error is $e, message is ${e.message}");

      if (e.type == DioErrorType.CONNECT_TIMEOUT) {
        throw ConnectionTimeoutException();
      } else {
        throw MyException('Server error ${e?.response?.statusCode}');
      }
    }
  }

  Future<Map<String, dynamic>> createPost(
      {Map<String, dynamic> formData, List<String> cookies, CancelToken cancelToken}) async {
    try {
      final options = BaseOptions(
        baseUrl: postUrl,
        connectTimeout: 15000,
        receiveTimeout: 15000,
        sendTimeout: 15000,
        receiveDataWhenStatusError: true,
        responseType: ResponseType.plain,
        contentType: 'multipart/form-data',
      );

      final _dio = Dio(options);
      if (cookies == null || cookies.isEmpty) {
        final cookieJar = PersistCookieJar(dir: Consts.appDocDir.path);
        _dio.interceptors.add(CookieManager(cookieJar));
      }

      final response = await _dio.post(
        "/${formData['board']}/post",
        // cancelToken: cancelToken,
        data: FormData.fromMap(formData),
        onSendProgress: (int sent, int total) {
          my.postBloc.add(AddProgress(bytesSent: sent, bytesTotal: total));
        },
      );

      if (response.statusCode == 200) {
        String cookie = '';
        if (response.headers['set-cookie'] != null) {
          cookie = response.headers['set-cookie']
              .firstWhere((e) => e.startsWith('4chan_pass'), orElse: () => '')
              .split(";")[0];
          print('Got cookie: $cookie');
        } else {
          print("No cookie! Result is ${response.headers}");
        }
        String postId;
        try {
          postId = RegExp(r'<!-- thread:\d+,no:(\d+) -->').firstMatch(response.data)[1];
          return {"ok": true, "cookie": cookie, "postId": postId};
        } catch (e) {
          final error = RegExp(r'<span id="errmsg" style="color: red;">(.+)<\/span')
              .allMatches(response.data)
              .toList()[0];
          final message = Htmlz.strip(error.group(1)).replaceAll('[Learn More]', '');
          // print('Error is $error');
          return {"ok": false, "error": message};
        }
      } else {
        return {"ok": false, "error": "Error"};
      }
    } on DioError catch (e) {
      print("Dio error is $e, message is ${e.message}");

      if (e.type == DioErrorType.CONNECT_TIMEOUT) {
        throw ConnectionTimeoutException();
        // } else if (e.type == DioErrorType.RESPONSE && e.error) {

      } else {
        throw MyException('Server error ${e?.response?.statusCode}');
      }
    }
  }

  Future<String> _safeRequest(String uri) async {
    try {
      final response = await dio().get(uri);
      // print('response = ${response}');
      return Future.value(response.data as String);
    } on DioError catch (e) {
      print("Got dio error: ${e.toString()}");
      if (e.type == DioErrorType.DEFAULT) {
        if (e.message.startsWith("SocketException")) {
          throw NoConnectionException();
        } else {
          throw MyException('Server error: ${e.message}');
        }
      } else if (e.type == DioErrorType.CONNECT_TIMEOUT) {
        throw UnavailableException();
      } else if (e.type == DioErrorType.RESPONSE) {
        final response = e.response;

        if (response.statusCode == 403) {
          throw ForbiddenException();
        } else if (response.statusCode == 404) {
          throw NotFoundException();
        } else if (response.statusCode == 500) {
          throw ServerErrorException();
        } else if (response.statusCode == 503 || response.statusCode == 502) {
          print("Throwing UnavailableException");
          throw UnavailableException();
        } else {
          throw MyException('Server error: ${response?.statusCode}');
        }
      } else {
        throw MyException('Server error: ${e.toString()}');
      }
    }
  }
}
