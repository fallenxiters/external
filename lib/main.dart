import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'websocket_service.dart';
import 'dashboard_section.dart';
import 'login_screen.dart';
import 'footer_menu.dart';
import 'custom_header.dart'; // Certifique-se de que está importando o CustomHeader corretamente
import 'package:flutter_localizations/flutter_localizations.dart'; // Adicione esta linha
import 'funcoes_screen.dart'; // Importando a tela de Funções

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
        Locale('pt', 'BR'), // Português
        Locale('en', 'US'), // Inglês
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
        splashColor: Colors.transparent, // Remove qualquer splash
        highlightColor: Colors.transparent, // Remove o highlight
      ),
      locale: WidgetsBinding.instance.window.locale, // Usa o idioma do sistema do dispositivo
      home: const LoginScreen(),
      routes: {
        '/home': (context) => MyHomePage(keyValue: ModalRoute.of(context)!.settings.arguments as String),
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

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;
  final List<String> _titles = ['Início', 'Funções', 'Utilitários'];
  late List<Widget> _screens; // Adiciona uma lista de telas
  int? _coins;
  String? key;
  String? seller;
  String? expiryDate;
  bool canClaimMission = false;
  int missionTimeRemaining = 0;

  late WebSocketService webSocketService;
  final storage = FlutterSecureStorage();

  bool _isKeyLoaded = false;
  bool _isSellerLoaded = false;
  bool _isExpiryDateLoaded = false;
  bool _areCoinsLoaded = false;

  @override
  void initState() {
    super.initState();
    _initializeWebSocketService();

    // Inicializa as telas uma única vez, garantindo que elas mantenham o estado
    _screens = [
      DashboardSection(
        onRefresh: _onRefresh,
        keyValue: key ?? 'N/A',
        seller: seller ?? 'N/A',
        expiryDate: expiryDate ?? 'N/A',
        webSocketService: webSocketService,
      ),
      const FuncoesScreen(),
      Center(
        child: Text(
          'Utilitários',
          style: GoogleFonts.poppins(fontSize: 24, color: Colors.white),
        ),
      ),
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
          if (mounted) {
            setState(() {
              _coins = coins;
              _areCoinsLoaded = true;
              _checkIfLoadingComplete();
            });
          }
        },
        onError: (error) {
          if (mounted) {
            _handleError(error);
            _checkIfLoadingComplete();
          }
        },
        onUserDataUpdated: (key, seller, expiryDate) {
          if (mounted) {
            setState(() {
              this.key = key;
              this.seller = seller;
              this.expiryDate = expiryDate;
              _isKeyLoaded = true;
              _isSellerLoaded = true;
              _isExpiryDateLoaded = true;
              _checkIfLoadingComplete();
            });
          }
        },
        onMissionUpdate: (canClaim, timeRemaining) {
          if (mounted) {
            setState(() {
              canClaimMission = canClaim;
              missionTimeRemaining = timeRemaining;
            });
            _checkIfLoadingComplete();
          }
        },
      );
      webSocketService.connect();
    } else {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  void _checkIfLoadingComplete() {
    if (_isKeyLoaded && _isSellerLoaded && _isExpiryDateLoaded && _areCoinsLoaded) {
      // Lógica de carregamento completo
    }
  }

  void _handleError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Erro: $message'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  @override
  void dispose() {
    webSocketService.close();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 0) {
      _refreshMissionStatus();
    }
  }

  void _refreshMissionStatus() {
    webSocketService.connect();
  }

  Future<void> _onRefresh() async {
    webSocketService.connect();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: CustomHeader( // Usando o CustomHeader no lugar do AppBar
        title: _titles[_selectedIndex],
        coins: _coins ?? 0,
      ),
      bottomNavigationBar: FooterMenu(
        userKey: key ?? 'N/A',
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
    );
  }
}
