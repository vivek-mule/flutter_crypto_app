import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

final loginProvider = StateNotifierProvider<LoginController, AsyncValue<void>>(
      (ref) => LoginController(),
);

class LoginController extends StateNotifier<AsyncValue<void>> {
  LoginController() : super(const AsyncData(null));

  Future<void> signIn(String email, String password) async {
    state = const AsyncLoading();
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      state = const AsyncData(null);
    } on FirebaseAuthException catch (e) {
      state = AsyncError(e.message ?? 'Login failed', StackTrace.current);
    } catch (e) {
      state = AsyncError('Something went wrong', StackTrace.current);
    }
  }
}
