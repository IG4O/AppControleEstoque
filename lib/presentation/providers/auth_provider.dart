import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/login_usecase.dart';

// Provedor do Repositório
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl();
});

// Provedor do Caso de Uso
final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return LoginUseCase(repository);
});

// Provedor do Usuário logado atualmente (null se não estiver logado)
final currentUserProvider = StateProvider<User?>((ref) => null);

// Provedor de Estado para a Tela de Login (carregando, sucesso, erro)
final authStateProvider = StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((ref) {
  final loginUseCase = ref.watch(loginUseCaseProvider);
  return AuthNotifier(loginUseCase, ref);
});

class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  final LoginUseCase _loginUseCase;
  final Ref _ref;

  AuthNotifier(this._loginUseCase, this._ref) : super(const AsyncData(null));

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    try {
      final user = await _loginUseCase(email, password);
      _ref.read(currentUserProvider.notifier).state = user;
      state = AsyncData(user);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  void logout() {
    _ref.read(currentUserProvider.notifier).state = null;
    state = const AsyncData(null);
  }
}
