import 'package:flutter/material.dart';
import 'schedule_data.dart';

class DDayWidget extends StatelessWidget {
  final Set<String> activatedKeys;
  final Map<String, Map<String, dynamic>> customScheduleData;

  const DDayWidget({
    super.key,
    required this.activatedKeys,
    required this.customScheduleData,
  });

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> activeDDayList = [];
    DateTime today =
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

    // 1. 활성화된 키들을 돌며 정보 수집 및 D-Day 계산
    for (String key in activatedKeys) {
      String? title;

      if (customScheduleData.containsKey(key)) {
        title = customScheduleData[key]?['title'];
      } else if (ScheduleData.data.containsKey(key)) {
        title = ScheduleData.data[key]?['title'];
      }

      if (title == null) continue;

      try {
        int year = int.parse(key.substring(0, 4));
        int month = int.parse(key.substring(4, 6));
        int day = int.parse(key.substring(6, 8));
        DateTime targetDate = DateTime(year, month, day);
        int diff = targetDate.difference(today).inDays;

        // 과거 일정은 패스
        if (diff < 0) continue;

        activeDDayList.add({
          "title": title,
          "diff": diff,
          "text": diff == 0 ? "Today" : "D-$diff"
        });
      } catch (_) {}
    }

    // 🔥 [정렬 기능]: D-Day(diff) 숫자가 가장 작은 순서(가장 가까운 날짜 순)로 정렬
    activeDDayList
        .sort((a, b) => (a["diff"] as int).compareTo(b["diff"] as int));

    // 배지 위젯 생성
    List<Widget> dDayChips = activeDDayList.map((item) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.indigo.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.indigo.shade200),
        ),
        child: Text(
          "${item['title']} ${item['text']}",
          style: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.bold, color: Colors.indigo),
        ),
      );
    }).toList();

    // 🔥 [구조 개조]: 일정이 없어도 '주요일정 :' 타이틀은 100% 항상 유지하여 꿀렁임 방지
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: SizedBox(
        height: 32, // 일정한 높이를 강제로 고정해서 달력 위치를 고정시킵니다.
        child: Row(
          children: [
            const Text(
              "주요일정 : ",
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.black87),
            ),
            Expanded(
              child: dDayChips.isEmpty
                  ? const Text("설정된 주요일정이 없습니다.",
                      style: TextStyle(fontSize: 12, color: Colors.grey))
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(children: dDayChips),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
