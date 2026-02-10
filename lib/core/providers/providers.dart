import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:capyadoo/core/providers/app_state_provider.dart';
import 'package:capyadoo/core/providers/auth_provider.dart';

/// รายการ Provider ทั้งหมดของแอป
/// เพิ่ม Provider ใหม่ที่นี่แล้วใส่ใน [providers] ของ [appProviders]
final List<SingleChildWidget> appProviders = [
  ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
  ChangeNotifierProvider<AppStateProvider>(create: (_) => AppStateProvider()),
];
