import Cocoa

class MasterViewController: NSViewController, MessageSubscriber {
    
    @IBOutlet weak var btnMasterBypass: EffectsUnitBypassButton!
    
    @IBOutlet weak var btnEQBypass: EffectsUnitTriStateBypassButton!
    @IBOutlet weak var btnPitchBypass: EffectsUnitTriStateBypassButton!
    @IBOutlet weak var btnTimeBypass: EffectsUnitTriStateBypassButton!
    @IBOutlet weak var btnReverbBypass: EffectsUnitTriStateBypassButton!
    @IBOutlet weak var btnDelayBypass: EffectsUnitTriStateBypassButton!
    @IBOutlet weak var btnFilterBypass: EffectsUnitTriStateBypassButton!
    
    // Presets menu
    @IBOutlet weak var masterPresets: NSPopUpButton!
    @IBOutlet weak var btnSavePreset: NSButton!
    
    private let graph: AudioGraphDelegateProtocol = ObjectGraph.getAudioGraphDelegate()
 
    override var nibName: String? {return "Master"}
    
    override func viewDidLoad() {
        
        initControls()
        SyncMessenger.subscribe(messageTypes: [.effectsUnitStateChangedNotification], subscriber: self)
    }
    
    private func initControls() {
        
        btnMasterBypass.onIf(!graph.isMasterBypass())
        
        btnEQBypass.stateFunction = {
            () -> EffectsUnitState in
            
            return self.graph.getEQState()
        }
        
//        btnPitchBypass.stateFunction = {
//            () -> EffectsUnitState in
//            
//            return graph.getPitchState()
//        }
//        
//        btnTimeBypass.stateFunction = {
//            () -> EffectsUnitState in
//            
//            return graph.getTimeSt
//        }
//        
//        btnReverbBypass.stateFunction = {
//            () -> EffectsButtonState in
//            
//            return self.graph.isMasterBypass() ? (self.graph.isReverbBypass() ? .off : .mixed) : (self.graph.isReverbBypass() ? .off : .on)
//        }
//        
//        btnDelayBypass.stateFunction = {
//            () -> EffectsButtonState in
//            
//            return self.graph.isMasterBypass() ? (self.graph.isDelayBypass() ? .off : .mixed) : (self.graph.isDelayBypass() ? .off : .on)
//        }
//        
//        btnFilterBypass.stateFunction = {
//            () -> EffectsButtonState in
//            
//            return self.graph.isMasterBypass() ? (self.graph.isFilterBypass() ? .off : .mixed) : (self.graph.isFilterBypass() ? .off : .on)
//        }
        
//        [btnEQBypass, btnPitchBypass, btnTimeBypass, btnReverbBypass, btnDelayBypass, btnFilterBypass].forEach({$0?.updateState()})
        
        btnEQBypass.updateState()
        
        // Initialize the menu with user-defined presets
//        MasterPresets.userDefinedPresets.forEach({eqPresets.insertItem(withTitle: $0.name, at: 0)})
        
        // Don't select any items from the EQ presets menu
        masterPresets.selectItem(at: -1)
    }
    
    @IBAction func masterBypassAction(_ sender: AnyObject) {
        
        // Toggle the master bypass state (simple on/off)
        let masterBypass = graph.toggleMasterBypass()
        btnMasterBypass.onIf(!masterBypass)
        
        // Update the bypass buttons for the effects units
        
        SyncMessenger.publishNotification(EffectsUnitStateChangedNotification(.master))
        SyncMessenger.publishNotification(EffectsUnitStateChangedNotification(.eq))
        SyncMessenger.publishNotification(EffectsUnitStateChangedNotification(.pitch))
        SyncMessenger.publishNotification(EffectsUnitStateChangedNotification(.time))
        SyncMessenger.publishNotification(EffectsUnitStateChangedNotification(.reverb))
        SyncMessenger.publishNotification(EffectsUnitStateChangedNotification(.delay))
        SyncMessenger.publishNotification(EffectsUnitStateChangedNotification(.filter))
        
//        [btnEQBypass, btnPitchBypass, btnTimeBypass, btnReverbBypass, btnDelayBypass, btnFilterBypass].forEach({$0?.updateState()})
        
        btnEQBypass.updateState()
    }
    
    @IBAction func masterPresetsAction(_ sender: AnyObject) {
        
        // Check if the preset is user-defined (tag == -1) or built-in
        
//        let preset = EQPresets.presetByName(eqPresets.titleOfSelectedItem!)
//        
//        graph.setEQBands(preset.bands)
//        updateAllEQSliders(preset.bands)
        
        // Don't select any of the items
        masterPresets.selectItem(at: -1)
    }
    
    @IBAction func eqBypassAction(_ sender: AnyObject) {
        _ = graph.toggleEQState()
        SyncMessenger.publishNotification(EffectsUnitStateChangedNotification(.eq))
        btnEQBypass.updateState()
    }
    
    // Activates/deactivates the Pitch effects unit
    @IBAction func pitchBypassAction(_ sender: AnyObject) {
        SyncMessenger.publishNotification(EffectsUnitStateChangedNotification(.pitch))
        btnPitchBypass.updateState()
    }
    
    // Activates/deactivates the Time stretch effects unit
    @IBAction func timeBypassAction(_ sender: AnyObject) {
        
        let newBypassState = graph.toggleTimeBypass()
        
        btnTimeBypass.updateState()
        SyncMessenger.publishNotification(EffectsUnitStateChangedNotification(.time))
        
        let newRate = newBypassState ? 1 : graph.getTimeRate().rate
        SyncMessenger.publishNotification(PlaybackRateChangedNotification(newRate))
    }
    
    // Activates/deactivates the Reverb effects unit
    @IBAction func reverbBypassAction(_ sender: AnyObject) {
        SyncMessenger.publishNotification(EffectsUnitStateChangedNotification(.reverb))
        btnReverbBypass.updateState()
    }
    
    // Activates/deactivates the Delay effects unit
    @IBAction func delayBypassAction(_ sender: AnyObject) {
        SyncMessenger.publishNotification(EffectsUnitStateChangedNotification(.delay))
        btnDelayBypass.updateState()
    }
    
    // Activates/deactivates the Filter effects unit
    @IBAction func filterBypassAction(_ sender: AnyObject) {
        SyncMessenger.publishNotification(EffectsUnitStateChangedNotification(.filter))
        btnFilterBypass.updateState()
    }
    
    // MARK: Message handling
    
    func getID() -> String {
        return self.className
    }
    
    func consumeNotification(_ notification: NotificationMessage) {
        
        if let message = notification as? EffectsUnitStateChangedNotification {
            
            switch message.effectsUnit {
                
            case .eq:   btnEQBypass.updateState()
                        btnMasterBypass.onIf(!graph.isMasterBypass())
                        SyncMessenger.publishNotification(EffectsUnitStateChangedNotification(.master))
                
//            case .pitch:   btnPitchBypass.updateState()
//                
//            case .time:   btnTimeBypass.updateState()
//                
//            case .reverb:   btnReverbBypass.updateState()
//                
//            case .delay:   btnDelayBypass.updateState()
//                
//            case .filter:   btnFilterBypass.updateState()
                
            default: return
                
            }
        }
    }
}
