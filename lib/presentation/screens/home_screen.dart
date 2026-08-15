import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import 'estoque_screen.dart';
import 'gerenciamento_screen.dart';
import 'login_screen.dart';
import 'logs_screen.dart';
import 'venda_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    // Se o usuário por algum motivo for nulo, volta pro login de segurança
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isAdmin = user.tipo == 'Admin';

    // Lista de telas disponíveis
    final List<Widget> screens = [
      const VendaScreen(),
      const EstoqueScreen(),
      const GerenciamentoScreen(), // Controle de lucros e gastos
      if (isAdmin) const LogsScreen(),
    ];

    final List<String> screenTitles = [
      'Venda',
      'Estoque',
      'Gerenciamento',
      if (isAdmin) 'Logs do Sistema',
    ];

    final List<IconData> screenIcons = [
      Icons.point_of_sale,
      Icons.inventory,
      Icons.attach_money,
      if (isAdmin) Icons.admin_panel_settings,
    ];

    void onMenuTap(int index) {
      setState(() {
        _currentIndex = index;
      });
      Navigator.of(context).pop(); // Fecha o drawer
    }

    void onLogout() {
      ref.read(authStateProvider.notifier).logout();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(screenTitles[_currentIndex]),
        centerTitle: true,
      ),
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(user.tipo),
              accountEmail: Text(user.email),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 40, color: Theme.of(context).colorScheme.primary),
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: screens.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: Icon(screenIcons[index]),
                    title: Text(screenTitles[index]),
                    selected: _currentIndex == index,
                    onTap: () => onMenuTap(index),
                  );
                },
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.exit_to_app, color: Colors.red),
              title: const Text('Sair', style: TextStyle(color: Colors.red)),
              onTap: onLogout,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      body: screens[_currentIndex],
    );
  }
}
