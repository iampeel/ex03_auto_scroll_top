// Flutter 측 구현 (main.dart)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'board_titles.dart'; // 게시판 제목 데이터 임포트

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'auto_scroll_top',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const NativeListScreen(),
    );
  }
}

class NativeListScreen extends StatefulWidget {
  const NativeListScreen({super.key});

  @override
  State<NativeListScreen> createState() => _NativeListScreenState();
}

class _NativeListScreenState extends State<NativeListScreen> {
  // Method Channel 설정
  static const platform = MethodChannel('com.example.app/native_list');
  bool _isNativeViewReady = false;

  @override
  void initState() {
    super.initState();

    // 플랫폼 채널 핸들러 설정
    platform.setMethodCallHandler(_handleItemClick);

    // 약간의 지연 후 네이티브 리스트 초기화
    Future.delayed(const Duration(milliseconds: 100), () {
      _initNativeList();
    });
  }

  @override
  void dispose() {
    platform.setMethodCallHandler(null);
    super.dispose();
  }

  // 네이티브 리스트뷰 초기화 및 데이터 전달
  Future<void> _initNativeList() async {
    try {
      await platform.invokeMethod('setListData', {'titles': BoardData.titles});

      setState(() {
        _isNativeViewReady = true;
      });
    } catch (e) {
      print('네이티브 리스트 초기화 오류: $e');
    }
  }

  // 항목 클릭 처리 콜백
  Future<void> _handleItemClick(MethodCall call) async {
    if (call.method == 'onItemClick') {
      final int index = call.arguments['index'];
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('선택: ${BoardData.titles[index]}'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('auto_scroll_top'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          if (_isNativeViewReady) _buildNativeListView(),
          if (!_isNativeViewReady)
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('네이티브 뷰 로딩 중...'),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // 플랫폼별 네이티브 뷰 생성
  Widget _buildNativeListView() {
    // iOS인 경우
    if (Theme.of(context).platform == TargetPlatform.iOS) {
      return SizedBox(
        height: MediaQuery.of(context).size.height,
        child: const UiKitView(
          viewType: 'native-list-view',
          creationParams: <String, dynamic>{},
          creationParamsCodec: StandardMessageCodec(),
        ),
      );
    }
    // 안드로이드인 경우
    else {
      return SizedBox(
        height: MediaQuery.of(context).size.height,
        child: const AndroidView(
          viewType: 'native-list-view',
          creationParams: <String, dynamic>{},
          creationParamsCodec: StandardMessageCodec(),
        ),
      );
    }
  }
}
