import 'package:http/http.dart' as http;
import 'dart:convert';

class MealApi {
  static const String apiKey = "f5087f41c05744a1b5b7f2903f9759d4";
  static const String officeCode = "J10";
  static const String schoolCode = "7530081";

  // TODO (3번 담당자): 급식 API 에러 안 나게 잘 관리하기!
  static Future<String> fetchMealInfo(DateTime date) async {
    final dateStr =
        "${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}";
    final url = Uri.parse(
        "https://open.neis.go.kr/hub/mealServiceDietInfo?KEY=$apiKey&Type=json&ATPT_OFCDC_SC_CODE=$officeCode&SD_SCHUL_CODE=$schoolCode&MLSV_YMD=$dateStr");
    try {
      final response = await http.get(url);
      final data = jsonDecode(response.body);
      if (data['mealServiceDietInfo'] != null) {
        return data['mealServiceDietInfo'][1]['row'][0]['DDISH_NM']
            .replaceAll("<br/>", "\n")
            .replaceAll(RegExp(r'[0-9.()]'), "")
            .trim();
      } else {
        return "급식 정보가 없습니다.";
      }
    } catch (e) {
      return "급식 정보를 가져올 수 없습니다.";
    }
  }
}
