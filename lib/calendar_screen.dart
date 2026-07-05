import 'package:flutter/material.dart';
import 'schedule_data.dart';
import 'meal_api.dart';
import 'd_day_widget.dart';
import 'memo_screen.dart'; // 4번 담당자 화면 파일
import 'notification_helper.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});
  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  // 2번 담당자의 PageView를 위한 컨트롤러 (시작 인덱스 500)
  final PageController _pageController = PageController(initialPage: 500);
  DateTime _focusedMonth =
      DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _selectedDay = DateTime.now();
  String _mealInfo = "날짜를 선택하면 급식이 나옵니다.";
  bool _isLoading = false;

  // 1번 담당자의 색상 팔레트와 커스텀 일정 데이터
  final List<Color> _colorPalette = [
    Colors.indigo,
    Colors.red,
    Colors.teal,
    Colors.orange,
    Colors.purple,
    Colors.green,
    Colors.pink
  ];
  final Map<String, Map<String, dynamic>> _customScheduleData = {};

  // ON/OFF 상태를 관리하는 수첩(장부)
  final Set<String> _activatedDDayKeys = {};

  @override
  void initState() {
    super.initState();
    _getMeal(_selectedDay);
  }

  Future<void> _getMeal(DateTime date) async {
    setState(() => _isLoading = true);
    String result = await MealApi.fetchMealInfo(date);
    setState(() {
      _mealInfo = result;
      _isLoading = false;
    });
  }

  // 1번 담당자가 구현한 일정 추가 팝업 함수
  void _showAddEventDialog() {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController descController = TextEditingController();
    Color selectedColor = _colorPalette[0];

    showDialog(
        context: context,
        builder: (context) => StatefulBuilder(
            builder: (context, setModalState) => AlertDialog(
                    title: const Text('일정 추가'),
                    content: SingleChildScrollView(
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                      TextField(
                          controller: titleController,
                          decoration: const InputDecoration(labelText: '제목')),
                      TextField(
                          controller: descController,
                          decoration: const InputDecoration(labelText: '내용')),
                      const SizedBox(height: 10),
                      Wrap(
                          spacing: 8,
                          children: _colorPalette
                              .map((color) => GestureDetector(
                                  onTap: () => setModalState(
                                      () => selectedColor = color),
                                  child: CircleAvatar(
                                      backgroundColor: color,
                                      radius: 15,
                                      child: selectedColor == color
                                          ? const Icon(Icons.check,
                                              size: 15, color: Colors.white)
                                          : null)))
                              .toList())
                    ])),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('취소')),
                      ElevatedButton(
                          onPressed: () {
                            if (titleController.text.isNotEmpty) {
                              setState(() {
                                String key =
                                    "${_selectedDay.year}${_selectedDay.month.toString().padLeft(2, '0')}${_selectedDay.day.toString().padLeft(2, '0')}";
                                _customScheduleData[key] = {
                                  "title": titleController.text,
                                  "desc": descController.text,
                                  "color": selectedColor
                                };
                              });
                              Navigator.pop(context);
                            }
                          },
                          child: const Text('확정'))
                    ])));
  }

  // 2번 담당자의 스와이프 시 월 변경 로직
  void _onPageChanged(int index) {
    int offset = index - 500;
    setState(() {
      _focusedMonth =
          DateTime(DateTime.now().year, DateTime.now().month + offset, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    String key =
        "${_selectedDay.year}${_selectedDay.month.toString().padLeft(2, '0')}${_selectedDay.day.toString().padLeft(2, '0')}";
    var event = ScheduleData.data[key];
    var customEvent = _customScheduleData[key]; // 사용자가 커스텀하게 추가한 일정 데이터
    DateTime now = DateTime.now();

    // 오늘 날짜 자정 기준값과 선택일 기준값 세팅 (과거 필터링용)
    DateTime todayOnly = DateTime(now.year, now.month, now.day);
    DateTime selectedOnly =
        DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day);
    bool isPastDay = selectedOnly.isBefore(todayOnly);

    return Scaffold(
      appBar: AppBar(
        title: const Text('이천고 학사일정',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        // 🔥 [앱바 어두워짐 버그 완벽 수정]: 하단 스크롤을 내려도 색상이 고정됩니다!
        scrolledUnderElevation: 0,
        actions: [
          // 👇 모바일/PC 둘 다 지원하는 만능 알림 버튼 유지!
          IconButton(
              icon: const Icon(Icons.notifications),
              onPressed: () {
                if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('🔔 [PC 버전] 알림 설정 기능이 작동했습니다!'),
                      duration: Duration(seconds: 2),
                      backgroundColor: Colors.indigo,
                    ),
                  );
                } else {
                  NotificationHelper.showTestNotification();
                }
              }),
          // 4번 담당자의 우측 상단 메모 아이콘 버튼
          IconButton(
            icon: const Icon(Icons.note_alt, size: 28),
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const MemoFolderScreen()));
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const AssetImage('assets/eagle.png'),
            fit: BoxFit.contain,
            colorFilter: ColorFilter.mode(
              Colors.white.withOpacity(0.9),
              BlendMode.dstATop,
            ),
          ),
        ),
        child: Column(
          children: [
            // 🔥 개조 완료된 상시 고정형 DDayWidget 연동!
            DDayWidget(
              activatedKeys: _activatedDDayKeys,
              customScheduleData: _customScheduleData,
            ),

            // 달력 상단 월 표시부
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () => _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.ease)),
                Text("${_focusedMonth.year}년 ${_focusedMonth.month}월",
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () => _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.ease)),
              ],
            ),

            // 요일 표시부
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: const [
                  Text('일',
                      style: TextStyle(
                          color: Colors.red, fontWeight: FontWeight.bold)),
                  Text('월'),
                  Text('화'),
                  Text('수'),
                  Text('목'),
                  Text('금'),
                  Text('토',
                      style: TextStyle(
                          color: Colors.blue, fontWeight: FontWeight.bold)),
                ],
              ),
            ),

            // 2번 담당자의 스와이프 가능한 PageView형 달력 그리드 영역 (flex 3 고정으로 화면 비율 보장)
            Expanded(
              flex: 3,
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemBuilder: (context, index) {
                  int offset = index - 500;
                  DateTime monthDate = DateTime(
                      DateTime.now().year, DateTime.now().month + offset, 1);
                  int days =
                      DateTime(monthDate.year, monthDate.month + 1, 0).day;
                  int first =
                      DateTime(monthDate.year, monthDate.month, 1).weekday % 7;

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: days + first,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 7, childAspectRatio: 0.8),
                    itemBuilder: (ctx, i) {
                      if (i < first) return const SizedBox();
                      int d = i - first + 1;
                      DateTime date =
                          DateTime(monthDate.year, monthDate.month, d);
                      String dKey =
                          "${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}";

                      bool isSelected = date.year == _selectedDay.year &&
                          date.month == _selectedDay.month &&
                          date.day == _selectedDay.day;
                      bool isToday = date.year == now.year &&
                          date.month == now.month &&
                          date.day == now.day;
                      var dEvent = ScheduleData.data[dKey];
                      var dCustom = _customScheduleData[dKey];

                      Color? weekendColor;
                      if (date.weekday == DateTime.sunday) {
                        weekendColor = Colors.red;
                      } else if (date.weekday == DateTime.saturday) {
                        weekendColor = Colors.blue;
                      }

                      return GestureDetector(
                        onTap: () {
                          setState(() => _selectedDay = date);
                          _getMeal(date);
                        },
                        child: Container(
                          margin: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color:
                                isSelected ? Colors.indigo.withAlpha(25) : null,
                            border: isToday
                                ? Border.all(color: Colors.black, width: 2)
                                : isSelected
                                    ? Border.all(color: Colors.indigo)
                                    : null,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              Text("$d",
                                  style: TextStyle(
                                      color: weekendColor,
                                      fontWeight: (isSelected || isToday)
                                          ? FontWeight.bold
                                          : null)),
                              const SizedBox(height: 4),

                              // 1번 담당자가 직접 추가한 유저 커스텀 일정
                              if (dCustom != null)
                                Container(
                                    width: double.infinity,
                                    color: dCustom['color'],
                                    child: Text(dCustom['title'],
                                        style: const TextStyle(
                                            color: Colors.white, fontSize: 8),
                                        textAlign: TextAlign.center,
                                        overflow: TextOverflow.ellipsis)),

                              // 기존 내장 학교 학사일정
                              if (dEvent != null)
                                Container(
                                    width: double.infinity,
                                    color: dEvent['type'] == 'exam'
                                        ? Colors.red
                                        : dEvent['type'] == 'holiday'
                                            ? Colors.grey
                                            : Colors.teal,
                                    child: Text(dEvent['title']!,
                                        style: const TextStyle(
                                            color: Colors.white, fontSize: 8),
                                        textAlign: TextAlign.center,
                                        overflow: TextOverflow.ellipsis)),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const Divider(),

            // 하단 정보 영역 (급식, 학사일정 정보 상세 및 메모장 버튼)
            Expanded(
              flex: 2,
              child: ListView(padding: const EdgeInsets.all(16), children: [
                Card(
                    child: ListTile(
                  title: const Text("오늘의 학사일정"),
                  subtitle: Text(
                      customEvent != null
                          ? customEvent['desc']
                          : (event != null ? event['desc']! : "일정이 없습니다."),
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  // 🔥 [과거 온오프 차단]: 오늘 포함 미래이고 일정이 있을 때만 토글 스위치 노출
                  trailing:
                      (!isPastDay && (customEvent != null || event != null))
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text("D-Day ",
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.grey)),
                                Switch.adaptive(
                                  value: _activatedDDayKeys.contains(key),
                                  activeColor: Colors.indigo,
                                  onChanged: (bool value) {
                                    setState(() {
                                      if (value) {
                                        _activatedDDayKeys.add(key);
                                      } else {
                                        _activatedDDayKeys.remove(key);
                                      }
                                    });
                                  },
                                ),
                              ],
                            )
                          : null,
                )),
                const SizedBox(height: 10),
                Card(
                    child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : Text(_mealInfo))),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const MemoFolderScreen()));
                    },
                    icon: const Icon(Icons.edit_note),
                    label: const Text("과목별 / 일반 메모장 열기"))
              ]),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddEventDialog,
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
