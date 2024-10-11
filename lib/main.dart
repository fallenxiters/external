import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'websocket_service.dart';
import 'dashboard_section.dart';
import 'login_screen.dart';
import 'sidebar_menu.dart';
import 'custom_header.dart';
import 'funcoes_screen.dart';
import 'splash_screen.dart';
import 'gerar_sensibilidade_screen.dart'; // Importe a nova tela "Gerar Sensibilidade"
import 'package:flutter_localizations/flutter_localizations.dart'; // Adicione esta linha

void main() {
  runApp(MyApp());
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

class _MyHomePageState extends State<MyHomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>(); // Chave para o Scaffold
  int _selectedIndex = 0;
  final List<String> _titles = ['Início', 'Funções', 'Métodos', 'Gerar Sensibilidade']; // Ajuste nos títulos
  late List<Widget> _screens;
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
          'Métodos',
          style: GoogleFonts.poppins(fontSize: 24, color: Colors.white),
        ),
      ),
      const GerarSensibilidadeScreen(), // Adiciona a tela de Gerar Sensibilidade
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
      key: _scaffoldKey, // Usando o GlobalKey
      drawer: SidebarMenu(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
        keyData: key ?? 'Chave não definida', // Passando a chave
        expiryDate: expiryDate ?? 'Data não definida', // Passando a data de validade
        profileImageUrl: 'https://example.com/your-profile-image.jpg', // URL da imagem de perfil
      ),
      appBar: CustomHeader(
        title: _titles[_selectedIndex], // Garantindo que o título corresponde ao índice correto
        coins: _coins ?? 0,
        onMenuTap: () {
          _scaffoldKey.currentState?.openDrawer(); // Abrindo o drawer via GlobalKey
        },
      ),
      body: IndexedStack(
        index: _selectedIndex, // Mantém o estado de cada aba
        children: _screens,
      ),
    );
  }
}
