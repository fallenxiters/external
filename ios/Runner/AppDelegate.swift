import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    let controller: FlutterViewController = window?.rootViewController as! FlutterViewController
    let antiGravacaoChannel = FlutterMethodChannel(name: "com.yourapp/antiGravacao", binaryMessenger: controller.binaryMessenger)
    
    antiGravacaoChannel.setMethodCallHandler({
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      if call.method == "activateAntiGravacao" {
        self.activateAntiGravacao()
        result(true)
      } else if call.method == "deactivateAntiGravacao" {
        self.deactivateAntiGravacao()
        result(true)
      } else {
        result(FlutterMethodNotImplemented)
      }
    })

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func activateAntiGravacao() {
    // Protege o conteúdo da captura de tela, sem mudar a tela visível
    if let window = UIApplication.shared.windows.first {
      window.isHidden = true // Isso protege o conteúdo contra gravação e captura de tela
      window.isHidden = false
    }

    // Observa as notificações de gravação de tela
    NotificationCenter.default.addObserver(self, selector: #selector(screenCaptureChanged), name: UIScreen.capturedDidChangeNotification, object: nil)
  }

  private func deactivateAntiGravacao() {
    // Remove o observador de gravação de tela
    NotificationCenter.default.removeObserver(self, name: UIScreen.capturedDidChangeNotification, object: nil)
  }

  @objc func screenCaptureChanged() {
    if UIScreen.main.isCaptured {
      print("Gravação ou captura de tela detectada.")
    } else {
      print("Gravação ou captura de tela interrompida.")
    }
  }
}
