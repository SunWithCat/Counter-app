import 'package:flutter/material.dart';

class HistoryPage extends StatefulWidget {
  final List<Map<String, dynamic>> history;

  const HistoryPage({super.key, required this.history});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  late List<Map<String, dynamic>> _history;

  @override
  void initState() {
    super.initState();
    _history = List.from(widget.history);
  }

  void _removeItem(int index) {
    setState(() {
      _history.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('操作历史'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _clearHistory(context),
          ),
        ],
      ),
      body:
          _history.isEmpty
              ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.history,
                      size: 64,
                      color: Color.fromRGBO(189, 189, 189, 1),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '暂无历史记录',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color.fromRGBO(117, 117, 117, 1),
                      ),
                    ),
                  ],
                ),
              )
              : ListView.builder(
                itemCount: _history.length,
                itemBuilder: (context, index) {
                  final record = _history[index];
                  return Dismissible(
                    key: Key(record['time']),
                    background: Container(
                      color: Color.fromRGBO(239, 83, 80, 1),
                      margin: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 16),
                      child: const Icon(
                        Icons.delete_sweep,
                        color: Colors.white,
                      ),
                    ),
                    direction: DismissDirection.endToStart,
                    confirmDismiss: (direction) async {
                      return await showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('确认删除'),
                            content: const Text('是否删除这条记录？'),
                            actions: [
                              TextButton(
                                onPressed:
                                    () => Navigator.of(context).pop(false),
                                child: const Text('取消'),
                              ),
                              FilledButton(
                                onPressed:
                                    () => Navigator.of(context).pop(true),
                                style: FilledButton.styleFrom(
                                  backgroundColor: Color.fromRGBO(
                                    244,
                                    67,
                                    54,
                                    1,
                                  ),
                                ),
                                child: const Text('删除'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    onDismissed: (direction) => _removeItem(index),
                    child: Hero(
                      tag: record['time'],
                      child: Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        elevation: 2,
                        child: InkWell(
                          onTap: () => _showDetail(context, record),
                          child: ListTile(
                            leading: _getActionIcon(record['action']),
                            title: Text(
                              '${record['action']}到 ${record['value']}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              _formatTime(record['time']),
                              style: TextStyle(
                                color: Color.fromRGBO(117, 117, 117, 1),
                              ),
                            ),
                            trailing: _getActionColor(record['action']),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
    );
  }

  Widget _getActionIcon(String action) {
    IconData iconData;
    Color color;

    switch (action) {
      case '增加':
        iconData = Icons.add_circle;
        color = Color.fromRGBO(76, 175, 80, 1); // Green
        break;
      case '减少':
        iconData = Icons.remove_circle;
        color = Color.fromRGBO(244, 67, 54, 1); // Red
        break;
      default:
        iconData = Icons.autorenew;
        color = Color.fromRGBO(33, 150, 243, 1); // Blue
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Color.fromRGBO(
          color.r.round(),
          color.g.round(),
          color.b.round(),
          0.1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(iconData, color: color),
    );
  }

  Widget _getActionColor(String action) {
    Color color;
    switch (action) {
      case '增加':
        color = Color.fromRGBO(76, 175, 80, 1); // Green
        break;
      case '减少':
        color = Color.fromRGBO(244, 67, 54, 1); // Red
        break;
      default:
        color = Color.fromRGBO(33, 150, 243, 1); // Blue
    }

    return Container(
      width: 4,
      height: 40,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  String _formatTime(String time) {
    final dateTime = DateTime.parse(time);
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} 天前';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} 小时前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} 分钟前';
    } else {
      return '刚刚';
    }
  }

  void _showDetail(BuildContext context, Map<String, dynamic> record) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                _getActionIcon(record['action']),
                const SizedBox(width: 8),
                Text('操作详情'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('操作类型：${record['action']}'),
                const SizedBox(height: 8),
                Text('操作值：${record['value']}'),
                const SizedBox(height: 8),
                Text('操作时间：${DateTime.parse(record['time']).toString()}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('关闭'),
              ),
            ],
          ),
    );
  }

  void _clearHistory(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.warning, color: Color.fromRGBO(255, 152, 0, 1)),
                SizedBox(width: 8),
                Text('清除历史'),
              ],
            ),
            content: const Text('确定要清除所有操作记录吗？\n此操作无法撤销。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () {
                  setState(() {
                    _history.clear();
                  });
                  Navigator.pop(context);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: Color.fromRGBO(244, 67, 54, 1),
                ),
                child: const Text('清除'),
              ),
            ],
          ),
    );
  }
}
