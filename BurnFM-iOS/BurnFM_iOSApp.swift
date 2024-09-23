//
//  BurnFM_iOSApp.swift
//  BurnFM-iOS
//
//  Created by Bradley Cable on 19/10/2023.
//

import SwiftUI
import AVFAudio
import OneSignalFramework

@main
struct BurnFM_iOSApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .spokenAudio, options: [.defaultToSpeaker, .allowAirPlay, .allowBluetoothA2DP])
      
            print("Playback OK")
        
            try AVAudioSession.sharedInstance().setActive(true)
    
            print("Session is Active")
        } catch {
            print(error)
        }
        
        application.beginReceivingRemoteControlEvents()
        
        OneSignal.Debug.setLogLevel(.LL_VERBOSE)
          
          // OneSignal initialization
          OneSignal.initialize("c2dd5947-24ba-4cc4-83ec-6c603a46bf02", withLaunchOptions: launchOptions)
          
          // requestPermission will show the native iOS notification permission prompt.
          // We recommend removing the following code and instead using an In-App Message to prompt for notification permission
          OneSignal.Notifications.requestPermission({ accepted in
            print("User accepted notifications: \(accepted)")
          }, fallbackToSettings: true)
        
        return true
    }
}
