import AVFoundation

class ReverbUnit: FXUnit, ReverbUnitProtocol {
    
    private let node: AVAudioUnitReverb = AVAudioUnitReverb()
    let presets: ReverbPresets = ReverbPresets()
    
    init(_ appState: AudioGraphState) {
        
        let reverbState = appState.reverbUnitState
        
        avSpace = reverbState.space.avPreset
        super.init(.reverb, reverbState.unitState)
        
        amount = reverbState.amount
        presets.addPresets(reverbState.userPresets)
    }
    
    override var avNodes: [AVAudioNode] {return [node]}
    
    override func reset() {
        node.reset()
    }
    
    var avSpace: AVAudioUnitReverbPreset {
        didSet {node.loadFactoryPreset(avSpace)}
    }
    
    var space: ReverbSpaces {
        
        get {return ReverbSpaces.mapFromAVPreset(avSpace)}
        set(newValue) {avSpace = newValue.avPreset}
    }
    
    var amount: Float {
        
        get {return node.wetDryMix}
        set(newValue) {node.wetDryMix = newValue}
    }
    
    override func stateChanged() {
        
        super.stateChanged()
        node.bypass = !isActive
    }
    
    override func savePreset(_ presetName: String) {
        presets.addPreset(ReverbPreset(presetName, state, space, amount, false))
    }
    
    override func applyPreset(_ presetName: String) {
        
        if let preset = presets.presetByName(presetName) {
            applyPreset(preset)
        }
    }
    
    func applyPreset(_ preset: ReverbPreset) {
        
        state = preset.state
        space = preset.space
        amount = preset.amount
    }
    
    func getSettingsAsPreset() -> ReverbPreset {
        return ReverbPreset("reverbSettings", state, space, amount, false)
    }
    
    func persistentState() -> ReverbUnitState {

        let unitState = ReverbUnitState()

        unitState.unitState = state
        unitState.space = space
        unitState.amount = amount
        unitState.userPresets = presets.userDefinedPresets

        return unitState
    }
}