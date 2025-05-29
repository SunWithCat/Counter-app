import 'package:counter_app/note_test/note_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'history_page.dart'; // 新增历史记录页面
import 'noti_page.dart';

/// 应用入口
/// 初始化主题设置并启动应用
void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // 确保Flutter绑定初始化完成（异步操作前必须）
  final prefs = await SharedPreferences.getInstance(); // 获取本地存储实例（用于持久化主题设置）
  final isDarkMode = prefs.getBool('isDarkMode') ?? false; // 从本地存储读取主题状态（默认浅色）
  await NoteService.instance.initNotification();
  print('Note service initialized in main');
  runApp(MyApp(isDarkMode: isDarkMode)); // 启动根组件MyApp，并传递初始主题状态
}

/// 主应用组件
/// 管理应用主题状态
class MyApp extends StatefulWidget {
  final bool isDarkMode; // 接收外部传入的初始主题状态
  const MyApp({super.key, required this.isDarkMode});
  @override
  State<MyApp> createState() => _MyAppState(); // 创建状态管理类
}

class _MyAppState extends State<MyApp> {
  bool _isDarkMode = false; // 当前主题状态（深色/浅色）

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.isDarkMode; // 使用父组件传入的初始值
  }

  /// 切换主题并保存状态到本地存储
  void _toggleTheme() async {
    setState(() {
      _isDarkMode = !_isDarkMode; // 切换主题状态（触发UI重建）
    });
    final prefs = await SharedPreferences.getInstance(); // 重新获取本地存储实例
    await prefs.setBool('isDarkMode', _isDarkMode); // 保存新主题状态到本地
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '计数器增强版',
      debugShowCheckedModeBanner: false, // 隐藏调试横幅
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light, // 根据状态选择主题模式
      theme: ThemeData(
        // 浅色主题配置
        primarySwatch: Colors.lightBlue, // 主色调
        brightness: Brightness.light, // 亮度模式
      ),
      darkTheme: ThemeData(
        // 深色主题配置
        primaryColor: Colors.black, // 主色
        brightness: Brightness.dark, // 亮度模式
        appBarTheme: AppBarTheme(
          // AppBar样式
          backgroundColor: Colors.black, // 背景色
          foregroundColor: Colors.white, // 前景色（文字/图标）
        ),
        textTheme: TextTheme(
          // 文本样式
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white),
        ),
      ),
      home: CounterPage(
        // 主页组件
        onToggleTheme: _toggleTheme, // 传递主题切换回调
        isDarkMode: _isDarkMode, // 传递当前主题状态
      ),
    );
  }
}

class CounterPage extends StatefulWidget {
  final VoidCallback onToggleTheme; // 主题切换回调（由MyApp传入）
  final bool isDarkMode; // 当前主题状态（由MyApp传入）
  const CounterPage({
    super.key,
    required this.onToggleTheme,
    required this.isDarkMode,
  });
  @override
  _CounterPageState createState() => _CounterPageState(); // 创建状态管理类
}

class _CounterPageState extends State<CounterPage>
    with SingleTickerProviderStateMixin {
  int _count = 0;
  int _maxCount = 10;
  String _statusMessage = '';
  Timer? _incrementTimer;
  Timer? _decrementTimer;
  List<Map<String, dynamic>> _history = [];

  // 添加动画控制器
  late final AnimationController _controller = AnimationController(
    duration: const Duration(milliseconds: 300),
    vsync: this,
  );

  // 添加数字缩放动画
  late final Animation<double> _animation = TweenSequence<double>([
    TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.2), weight: 1.0),
    TweenSequenceItem(tween: Tween<double>(begin: 1.2, end: 1.0), weight: 1.0),
  ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void dispose() {
    _incrementTimer?.cancel(); // 组件销毁时取消定时器
    _decrementTimer?.cancel();
    _controller.dispose(); // 销毁动画控制器
    super.dispose();
  }

  /// 弹出对话框设置最大值
  Future<void> _showMaxCountDialog() async {
    final newMax = await showDialog<int>(
      context: context,
      builder: (context) {
        int tempMax = _maxCount;
        return AlertDialog(
          title: Text('设置最大值'),
          content: TextField(
            keyboardType: TextInputType.number,
            onChanged: (value) {
              tempMax = int.tryParse(value) ?? _maxCount;
            },
            decoration: InputDecoration(hintText: '当前最大值: $_maxCount'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, tempMax),
              child: Text('确认'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('取消'),
            ),
          ],
        );
      },
    );

    if (newMax != null && newMax >= 0) {
      setState(() {
        _maxCount = newMax;
        _statusMessage = '最大值已设置为$_maxCount';
        if (_count > _maxCount) {
          _count = _maxCount;
          _statusMessage = '最大值已设置为$_maxCount，当前计数已调整';
        }
      });
    }
  }

  /// 增加计数值（不超过最大值）
  void _increment() {
    setState(() {
      if (_count < _maxCount) {
        _count++;
        _statusMessage = '增加成功';
        _addHistory('增加');
        _controller.forward(from: 0.0); // 从头开始播放动画
      } else {
        _statusMessage = '已达到最大值 $_maxCount';
      }
    });
  }

  // 新增：添加历史记录
  void _addHistory(String action) {
    _history.insert(0, {
      'action': action,
      'value': _count,
      'time': DateTime.now().toString(),
    });
  }

  /// 减少计数值（不低于0）
  void _decrement() {
    setState(() {
      if (_count > 0) {
        _count--;
        _statusMessage = '减少成功';
        _addHistory('减少');
        _controller.forward(from: 0.0); // 从头开始播放动画
      } else {
        _statusMessage = '已是最小值 0';
      }
    });
  }

  /// 重置计数器到0
  void _reset() {
    setState(() {
      _count = 0;
      _statusMessage = '已重置为 0';
      _addHistory('重置');
      _controller.forward(from: 0.0); // 从头开始播放动画
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;
    return Scaffold(
      appBar: AppBar(
        // 顶部导航栏
        title: Text('计算器增强版', style: TextStyle(fontSize: 20)), // 标题
        centerTitle: true, // 标题居中
        actions: [
          // 右侧操作按钮
          IconButton(
            icon: Icon(isDark ? Icons.dark_mode : Icons.light_mode), // 根据主题切换图标
            onPressed: widget.onToggleTheme, // 触发主题切换回调
          ),
        ],
        elevation: 4, // 阴影高度
      ),
      body: Container(
        // 页面主体
        decoration: BoxDecoration(
          // 背景渐变
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors:
                isDark // 根据主题选择渐变颜色
                    ? [Colors.black, Colors.grey.shade900] // 深色渐变
                    : [Colors.lightBlue.shade100, Colors.white], // 浅色渐变
          ),
        ),
        child: Padding(
          // 内边距容器
          padding: const EdgeInsets.all(20.0),
          child: Column(
            // 垂直布局
            mainAxisAlignment: MainAxisAlignment.center, // 内容居中
            children: [
              ScaleTransition(
                scale: _animation,
                child: Text(
                  '当前计数：$_count',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        offset: Offset(2.0, 2.0),
                        blurRadius: 3.0,
                        color: Color.fromRGBO(0, 0, 0, 0.2),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16), // 间隔
              Text(
                // 状态提示信息
                _statusMessage,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              SizedBox(height: 40), // 间隔
              ElevatedButton(
                onPressed:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HistoryPage(history: _history),
                      ),
                    ),
                style: _buttonStyle(),
                child: Icon(Icons.history),
              ),
              SizedBox(height: 20), // 间隔
              Row(
                // 操作按钮行
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onLongPress: () {
                      _increment(); // 长按立即触发一次
                      // 每200ms触发一次增加操作
                      _incrementTimer = Timer.periodic(
                        const Duration(milliseconds: 200),
                        (_) => _increment(),
                      );
                    },
                    onLongPressUp: () => _incrementTimer?.cancel(), // 松开时停止
                    child: ElevatedButton(
                      // 增加按钮
                      onPressed: _increment, // 绑定增加逻辑
                      style: _buttonStyle(),
                      child: Icon(Icons.add),
                    ),
                  ),
                  SizedBox(width: 16), // 间隔
                  GestureDetector(
                    onLongPress: () {
                      _decrement(); // 长按立即触发一次
                      // 每200ms触发一次减少操作
                      _decrementTimer = Timer.periodic(
                        const Duration(milliseconds: 200),
                        (_) => _decrement(),
                      );
                    },
                    onLongPressUp: () => _decrementTimer?.cancel(), // 松开时停止
                    child: ElevatedButton(
                      onPressed: _decrement,
                      style: _buttonStyle(),
                      child: Icon(Icons.remove),
                    ),
                  ),
                  SizedBox(width: 16), // 间隔
                  ElevatedButton(
                    // 重置按钮
                    onPressed: _reset, // 绑定重置逻辑
                    style: _buttonStyle(), // 使用统一样式
                    child: Icon(Icons.refresh), // 图标
                  ),
                  SizedBox(width: 20), // 间隔
                  ElevatedButton(
                    onPressed: _showMaxCountDialog,
                    style: _buttonStyle(),
                    child: Icon(Icons.settings),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),

      floatingActionButton: FloatingActionButton(
        // 浮动操作按钮（测试导航）
        onPressed: () {
          Navigator.push(
            // 导航到TestPage
            context,
            MaterialPageRoute(builder: (_) => TestPage()),
          );
        },
        backgroundColor:
            isDark ? Colors.black : Colors.lightBlue.shade100, // 按钮背景色
        child: Icon(Icons.add), // 图标
        tooltip: '测试', // 长按提示
      ),
    );
  }
}

ButtonStyle _buttonStyle() {
  return ElevatedButton.styleFrom(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(27)),
    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
    elevation: 4, // 添加阴影
    animationDuration: Duration(milliseconds: 200), // 动画持续时间
  ).copyWith(
    overlayColor: WidgetStateProperty.resolveWith<Color?>((
      Set<WidgetState> states,
    ) {
      if (states.contains(WidgetState.pressed)) {
        return Color.fromRGBO(255, 255, 255, 0.3); // 按下时的高亮效果
      }
      return null;
    }),
  );
}

class TestPage extends StatelessWidget {
  const TestPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: Text('测试页面')), body: NotiPage());
  }
}
