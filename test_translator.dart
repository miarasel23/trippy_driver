import 'package:translator/translator.dart';

void main() async {
  final translator = GoogleTranslator();
  try {
    var translation = await translator.translate("Gulshan 1, Dhaka", from: 'en', to: 'bn');
    print("SUCCESS: ${translation.text}");
  } catch (e) {
    print("ERROR: $e");
  }
}
