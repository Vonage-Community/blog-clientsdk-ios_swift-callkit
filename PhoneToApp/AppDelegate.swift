//
//  AppDelegate.swift
//  PhoneToApp
//
//  Created by Abdulhakim Ajetunmobi on 06/07/2020.
//  Copyright © 2020 Vonage. All rights reserved.
//

import UIKit
import PushKit
import AVFoundation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    private let clientManager = ClientManager.shared
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        /*
         When the device is locked, the AVAudioSession needs to be configured.
         You can read more about this issue here https://forums.developer.apple.com/thread/64544
         */
        try? AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playAndRecord, mode: AVAudioSession.Mode.voiceChat, options: .allowBluetooth)
        AVAudioSession.sharedInstance().requestRecordPermission { (granted:Bool) in
            print("VPush: Allow microphone use. Response: \(granted)")
        }
        registerForVoIPPushes()
        clientManager.login()
        return true
    }
    
    // MARK: UISceneSession Lifecycle
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {}
}

extension AppDelegate: PKPushRegistryDelegate {
    
    /*
     Register for voip push notifications.
     */
    private func registerForVoIPPushes() {
        let voipRegistry = PKPushRegistry(queue: nil)
        voipRegistry.delegate = self
        voipRegistry.desiredPushTypes = [PKPushType.voIP]
    }
    
    /*
     This provides the client manager with the push notification token.
     */
    func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for type: PKPushType) {
        clientManager.pushToken = pushCredentials.token
    }
    
    /*
     If the push notification token becomes invalid,
     the client manager needs to remove it.
     */
    func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenFor type: PKPushType) {
        clientManager.invalidatePushToken(nil)
    }
    
    /*
     When an incoming VoIP push is received, check if it
     from Vonage, if from Vonage, it will process the push payload
     */
    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {
        if clientManager.isVonagePush(with: payload.dictionaryPayload) {
            clientManager.login(isPushLogin: true)
            _ = clientManager.processPushPayload(with: payload.dictionaryPayload, pushKitCompletion: completion)
        }
    }
}
