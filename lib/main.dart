// Flutter 측 구현 (main.dart)
import 'package:flutter/material.dart'; // 기본 Flutter 위젯을 위한 임포트
import 'package:flutter/services.dart'; // 네이티브 통신(MethodChannel)을 위한 임포트
import 'board_titles.dart'; // 게시판 제목 데이터 임포트

// 앱의 시작점
void main() {
  runApp(const MyApp());
}

// 앱의 루트 위젯
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '네이티브 리스트뷰',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const NativeListScreen(), // 네이티브 리스트 화면을 홈으로 설정
    );
  }
}

// 네이티브 리스트를 표시하는 화면 (StatefulWidget)
class NativeListScreen extends StatefulWidget {
  const NativeListScreen({super.key});

  @override
  State<NativeListScreen> createState() => _NativeListScreenState();
}

// NativeListScreen의 상태 관리 클래스
class _NativeListScreenState extends State<NativeListScreen> {
  // 네이티브 통신을 위한 Method Channel 설정
  // 'com.example.app/native_list'는 NativeListViewFactory.swift에서 동일하게 사용됨
  static const platform = MethodChannel('com.example.app/native_list');

  // 네이티브 뷰가 준비되었는지 추적하는 상태 변수
  bool _isNativeViewReady = false;

  @override
  void initState() {
    super.initState();

    // 네이티브에서 Flutter로 메시지를 보낼 때 처리할 핸들러 설정
    // 여기서는 리스트 아이템 클릭 이벤트를 처리함
    platform.setMethodCallHandler(_handleItemClick);

    // 약간의 지연 후 네이티브 리스트 초기화
    // 이 지연은 위젯 트리가 완전히 렌더링된 후 네이티브 통신을 시작하기 위함
    Future.delayed(const Duration(milliseconds: 100), () {
      _initNativeList();
    });
  }

  @override
  void dispose() {
    // 화면이 종료될 때 Method Channel 핸들러를 정리
    platform.setMethodCallHandler(null);
    super.dispose();
  }

  // 네이티브 리스트뷰 초기화 및 데이터 전달 메서드
  Future<void> _initNativeList() async {
    try {
      // Flutter에서 네이티브로 게시글 제목 데이터 전달
      // 이 메서드 호출은 NativeListViewFactory.swift의 setMethodCallHandler에서 처리됨
      await platform.invokeMethod('setListData', {
        'titles': BoardData.titles, // board_titles.dart에서 가져온 제목 리스트
      });

      // 데이터 전달이 성공하면 네이티브 뷰가 준비되었다고 상태 업데이트
      setState(() {
        _isNativeViewReady = true;
      });
    } catch (e) {
      // 네이티브 통신 중 오류 발생 시 콘솔에 출력
      print('네이티브 리스트 초기화 오류: $e');
    }
  }

  // 네이티브에서 Flutter로 전달되는 메시지 처리 핸들러
  Future<void> _handleItemClick(MethodCall call) async {
    // 네이티브 측에서 'onItemClick' 메서드를 호출했을 때
    // NativeListView.swift의 tableView(_:didSelectRowAt:) 메서드에서 호출됨
    if (call.method == 'onItemClick') {
      // 클릭된 항목의 인덱스 가져오기
      final int index = call.arguments['index'];

      // 위젯이 여전히 존재하는지 확인 (dispose 된 상태에서 setState 방지)
      if (mounted) {
        // 선택된 항목에 대한 피드백 표시
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
        title: const Text('네이티브 리스트뷰'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      // Stack을 사용하여 로딩 상태와 네이티브 뷰를 겹쳐서 표시
      body: Stack(
        children: [
          // 네이티브 뷰가 준비되었을 때만 표시
          if (_isNativeViewReady) _buildNativeListView(),

          // 네이티브 뷰가 준비되지 않았을 때 로딩 표시
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

  // 플랫폼별 네이티브 뷰 생성 메서드
  Widget _buildNativeListView() {
    // iOS인 경우
    if (Theme.of(context).platform == TargetPlatform.iOS) {
      // iOS에서는 UiKitView를 사용하여 네이티브 UITableView를 표시
      // 이 부분이 iOS의 네이티브 스크롤 동작(상태 표시줄 탭으로 맨 위 이동 등)을 가능하게 함
      return SizedBox(
        height: MediaQuery.of(context).size.height,
        child: const UiKitView(
          // 'native-list-view'는 AppDelegate.swift에서 등록한 viewType과 일치해야 함
          viewType: 'native-list-view',
          creationParams: <String, dynamic>{},
          creationParamsCodec: StandardMessageCodec(),
        ),
      );
    }
    // 안드로이드인 경우
    else {
      // 안드로이드에서는 AndroidView를 사용하여 네이티브 RecyclerView를 표시
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
