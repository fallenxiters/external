import Flutter
import UIKit

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
    // Adiciona uma view preta sobre a janela para impedir capturas de tela e gravações
    let shieldView = UIView(frame: UIScreen.main.bounds)
    shieldView.backgroundColor = UIColor.black
    shieldView.tag = 999 // Para facilitar a remoção posteriormente
    shieldView.isUserInteractionEnabled = false
    if let window = UIApplication.shared.windows.first {
      window.addSubview(shieldView)
    }
    
    // Desativa a gravação de tela
    UIScreen.main.isCaptured.addObserver(self, forKeyPath: "captured", options: .new, context: nil)
  }

  private func deactivateAntiGravacao() {
    // Remove a view preta
    if let window = UIApplication.shared.windows.first {
      if let shieldView = window.viewWithTag(999) {
        shieldView.removeFromSuperview()
      }
    }

    // Remove o observador de gravação de tela
    UIScreen.main.removeObserver(self, forKeyPath: "captured")
  }

  override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
    if keyPath == "captured" {
      if UIScreen.main.isCaptured {
        // A gravação de tela foi detectada
        if let window = UIApplication.shared.windows.first {
          let shieldView = UIView(frame: UIScreen.main.bounds)
          shieldView.backgroundColor = UIColor.black
          shieldView.tag = 999
          shieldView.isUserInteractionEnabled = false
          window.addSubview(shieldView)
        }
      } else {
        // A gravação de tela foi interrompida
        if let window = UIApplication.shared.windows.first {
          if let shieldView = window.viewWithTag(999) {
            shieldView.removeFromSuperview()
          }
        }
      }
    }
  }
}
