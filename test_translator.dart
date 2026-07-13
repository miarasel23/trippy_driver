import 'package:translator/translator.dart';

void main() async {
  final translator = GoogleTranslator();
  try {
    final result = await translator.translate("412/1, 412 Senpara Parbata Ln, Dhaka 1216, Bangladesh", from: 'auto', to: 'bn');
    print("Success: ${result.text}");
  } catch (e) {
    print("Error: $e");
  }
}
