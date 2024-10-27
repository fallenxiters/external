import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'websocket_service.dart';
import 'dashboard_section.dart';
import 'login_screen.dart';
import 'sidebar_menu.dart';
import 'funcoes_screen.dart';
import 'splash_screen.dart';
import 'metodos_screen.dart';
import 'gerar_sensibilidade_screen.dart';
import 'events_screen.dart';
import 'custom_header.dart';

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
  final List<String> _titles = ['Início', 'Funções', 'Métodos', 'Gerar Sensibilidade', 'Eventos'];
  late WebSocketService webSocketService;
  final storage = FlutterSecureStorage();

  String? key;
  String? seller;
  String? expiryDate;
  String? game;

  late AnimationController _controller;
  int _coins = 0;
  bool isLoading = true;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();

    _initializeWebSocketService();
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
          if (mounted) {
            setState(() {
              _coins = coins;
              isLoading = false;
            });
          }
        },
        onError: (error) {
          if (mounted) {
            // Handle error if necessary
          }
        },
        onUserDataUpdated: (key, seller, expiryDate, game, likeDislikeStatus) {
          if (mounted) {
            setState(() {
              this.key = key;
              this.seller = seller;
              this.expiryDate = expiryDate;
              this.game = game is String ? game : 'N/A';
            });
          }
        },
        onMissionUpdate: (missionName, canClaim, timeRemaining) {
          if (mounted) {
            // Update missions if needed
          }
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
    _controller.dispose();
    webSocketService.close();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _screens = [
      DashboardSection(
        onRefresh: _initializeWebSocketService,
        keyValue: key ?? 'N/A',
        seller: seller ?? 'N/A',
        expiryDate: expiryDate ?? 'N/A',
        game: game ?? 'N/A',
        webSocketService: webSocketService,
      ),
      const FuncoesScreen(),
      const MetodosScreen(),
      const GerarSensibilidadeScreen(),
      const EventsScreen(),
    ];

    return Scaffold(
      key: _scaffoldKey,
      drawer: SidebarMenu(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
        controller: _controller,
      ),
      appBar: CustomHeader(
        title: _titles[_selectedIndex],
        coins: _coins,
        isLoading: isLoading,
        onMenuTap: () {
          _scaffoldKey.currentState?.openDrawer();
        },
        controller: _controller,
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
    );
  }
}
