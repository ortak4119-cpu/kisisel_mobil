import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import '../utils/theme_provider.dart';

class AppProviders {
  static List<SingleChildWidget> providers = [
    ChangeNotifierProvider(create: (_) => ThemeProvider()),
    // Diğer provider'larınızı buraya ekleyin
    // ChangeNotifierProvider(create: (_) => AuthProvider()),
    // ChangeNotifierProvider(create: (_) => UserProvider()),
  ];
}