import CallKit
import AVFoundation
import VonageClientSDKVoice

final class ProviderDelegate: NSObject {
    private let provider: CXProvider
    private let callController = CXCallController()
    private var activeCall: UUID? = nil
    
    override init() {
        provider = CXProvider(configuration: ProviderDelegate.providerConfiguration)
        super.init()
        provider.setDelegate(self, queue: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    static var providerConfiguration: CXProviderConfiguration = {
        let providerConfiguration = CXProviderConfiguration()
        providerConfiguration.maximumCallsPerCallGroup = 1
        providerConfiguration.supportedHandleTypes = [.generic, .phoneNumber]
        return providerConfiguration
    }()
    
    /*
     This function, called when the voip push notification arrives,
     reports the incoming call to the system. This triggers the CallKit UI.
     */
    func reportCall(_ callID: String, caller: String, completion: @escaping () -> Void) {
        activeCall = UUID(uuidString: callID)
        let update = CXCallUpdate()
        update.localizedCallerName = caller
        
        provider.reportNewIncomingCall(with: activeCall!, update: update) { error in
            if error == nil {
                completion()
            }
        }
    }
    
    func didReceiveHangup(_ callID: String) {
        let uuid = UUID(uuidString: callID)!
        provider.reportCall(with: uuid, endedAt: Date.now, reason: .remoteEnded)
    }
    
    func reportFailedCall(_ callID: String) {
        let uuid = UUID(uuidString: callID)!
        provider.reportCall(with: uuid, endedAt: Date.now, reason: .failed)
    }
    
    private func hangup(action: CXEndCallAction) {
        if activeCall == nil {
            endCallTransaction(action: action)
        } else {
            ClientManager.shared.reject(activeCall!.uuidString.lowercased()) { error in
                if error == nil {
                    self.endCallTransaction(action: action)
                }
            }
        }
    }
    
    /*
     When a call is ended,
     the callController.request function completes the action.
     */
    private func endCallTransaction(action: CXEndCallAction) {
        self.callController.request(CXTransaction(action: action)) { error in
            if error == nil {
                self.activeCall = nil
                action.fulfill()
            } else {
                action.fail()
            }
        }
    }
}

extension ProviderDelegate: CXProviderDelegate {
    
    func providerDidReset(_ provider: CXProvider) {
        activeCall = nil
    }
    
    /*
     When the call is answered via the CallKit UI, this function is called.
     */
    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        ClientManager.shared.answer(activeCall!.uuidString.lowercased()) { error in
            if error == nil {
                action.fulfill()
            } else {
                action.fail()
            }
        }
    }
    
    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        hangup(action: action)
    }
    
    func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
        VGVoiceClient.enableAudio(audioSession)
        
    }
    
    func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {
        VGVoiceClient.disableAudio(audioSession)
    }
}
