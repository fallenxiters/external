import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'websocket_service.dart';
import 'dashboard_section.dart';
import 'login_screen.dart';
import 'sidebar_menu.dart';
import 'funcoes_screen.dart';
import 'splash_screen.dart';
import 'metodos_screen.dart';
import 'gerar_sensibilidade_screen.dart';
import 'dashed_divider.dart'; // Verifique se este arquivo existe
import 'custom_header.dart'; // Importando o cabeçalho personalizado
import 'events_screen.dart'; // Importando a tela de eventos

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      supportedLocales: const [
        Locale('pt', 'BR'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          selectedItemColor: Colors.amber,
          unselectedItemColor: Colors.white,
          backgroundColor: Colors.transparent,
          type: BottomNavigationBarType.fixed,
        ),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      locale: WidgetsBinding.instance.window.locale,
      home: SplashScreen(),
      routes: {
        '/home': (context) => MyHomePage(
              keyValue: ModalRoute.of(context)!.settings.arguments as String,
            ),
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  final String keyValue;
  const MyHomePage({super.key, required this.keyValue});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;
  final List<String> _titles = ['Início', 'Funções', 'Métodos', 'Gerar Sensibilidade', 'Eventos'];
  late List<Widget> _screens;
  late WebSocketService webSocketService;
  final storage = FlutterSecureStorage();

  String? key;
  String? seller;
  String? expiryDate;

  late AnimationController _controller; // Controller para animação
  int _coins = 0; // Inicialização de moedas

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(); // Animação contínua

    _initializeWebSocketService();

    _screens = [
      DashboardSection(
        onRefresh: _onRefresh,
        keyValue: key ?? 'N/A',
        seller: seller ?? 'N/A',
        expiryDate: expiryDate ?? 'N/A',
        webSocketService: webSocketService,
      ),
      const FuncoesScreen(),
      const MetodosScreen(),
      const GerarSensibilidadeScreen(),
      const EventsScreen(), // Adicionando a tela de eventos
    ];
  }

  Future<void> _initializeWebSocketService() async {
    String? savedKey = widget.keyValue;

    if (savedKey != null) {
      setState(() {
        key = savedKey;
      });

      webSocketService = WebSocketService(
        keyValue: savedKey,
        onCoinsUpdated: (coins) {
          setState(() {
            _coins = coins; // Atualizando o número de moedas
          });
        },
        onError: (error) {
          // Lidar com erro
        },
        onUserDataUpdated: (key, seller, expiryDate, likeDislikeStatus) {
          setState(() {
            this.key = key;
            this.seller = seller;
            this.expiryDate = expiryDate;
          });
        },
        onMissionUpdate: (missionName, canClaim, timeRemaining) {
          // Atualização de missões
        },
      );
      webSocketService.connect();
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose(); // Dispose do controller de animação
    webSocketService.close();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _onRefresh() async {
    webSocketService.connect();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: SidebarMenu(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
        controller: _controller, // Passando o AnimationController
      ),
      appBar: CustomHeader(
        title: _titles[_selectedIndex],
        coins: _coins,
        onMenuTap: () {
          _scaffoldKey.currentState?.openDrawer(); // Abrindo o drawer via GlobalKey
        },
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
    );
  }
}
