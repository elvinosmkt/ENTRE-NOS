import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserState {
  final String name;
  final String? myCode;
  final String? partnerCode;
  final bool isConnected;

  const UserState({
    this.name = '',
    this.myCode,
    this.partnerCode,
    this.isConnected = false,
  });

  UserState copyWith({
    String? name,
    String? myCode,
    String? partnerCode,
    bool? isConnected,
  }) {
    return UserState(
      name: name ?? this.name,
      myCode: myCode ?? this.myCode,
      partnerCode: partnerCode ?? this.partnerCode,
      isConnected: isConnected ?? this.isConnected,
    );
  }
}

class UserNotifier extends AsyncNotifier<UserState> {
  @override
  Future<UserState> build() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load or generate my code
    String? myCode = prefs.getString('my_invite_code');
    if (myCode == null) {
      const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
      final random = DateTime.now().microsecondsSinceEpoch;
      myCode = List.generate(6, (i) => chars[(random ~/ (i + 1)) % chars.length]).join();
      await prefs.setString('my_invite_code', myCode);
    }
    
    return UserState(
      name: prefs.getString('user_name') ?? '',
      myCode: myCode,
      partnerCode: prefs.getString('partner_code'),
      isConnected: prefs.getBool('is_connected') ?? false,
    );
  }

  Future<void> setName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', name);
    state = AsyncValue.data(state.value!.copyWith(name: name));
  }

  Future<void> connect(String partnerCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_connected', true);
    await prefs.setString('partner_code', partnerCode);
    state = AsyncValue.data(state.value!.copyWith(
      isConnected: true,
      partnerCode: partnerCode,
    ));
  }

  Future<void> disconnect() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    state = const AsyncValue.data(UserState());
  }
}

final userProvider = AsyncNotifierProvider<UserNotifier, UserState>(() {
  return UserNotifier();
});
