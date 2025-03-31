import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../APIs/urls.dart';

class Configs {

  static bool hideRadarChart = false;
  static bool hideBlockAvgTable = true;
  static bool hideCorrectionsMessages = false;
  static bool hideGlobalAvgLabel = false;
  static bool hideThankYouSection = true;

  static Future<void> fetchConfig() async {
    try {
      final response = await http.post(Uri.parse("${URLs.baseURL}${URLs.getConfigURL}"),
          body: jsonEncode({"configName": "mobileapp.resultPage"}));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body)['data'];

        bool parseBool(dynamic item) {
          if (item is Map && item.containsKey('value') && item['value'] != null) {
            final str = item['value'].toString().toLowerCase();
            return str == 'true';
          }
          return false;
        }

        Map<String, dynamic>? getItem(String name) {
          return data.firstWhere(
                (item) => item['name'] == name,
            orElse: () => null,
          );
        }

        Configs.hideThankYouSection = parseBool(getItem('mobileapp.resultPage.hideThankYouSection'));
        Configs.hideRadarChart = parseBool(getItem('mobileapp.resultPage.hideRadarChart'));
        Configs.hideBlockAvgTable = parseBool(getItem('mobileapp.resultPage.hideBlockAvgTable'));
        Configs.hideCorrectionsMessages = parseBool(getItem('mobileapp.resultPage.hideCorrectionsMessages'));
        Configs.hideGlobalAvgLabel = parseBool(getItem('mobileapp.resultPage.hideGlobalAvgLabel'));

      } else {
        print("Config fetch failed: ${response.statusCode}");
      }
    } catch (e) {
      print("Exception during config fetch: $e");
    }
  }
}
