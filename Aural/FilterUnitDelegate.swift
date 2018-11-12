import AVFoundation

class FilterUnitDelegate: FXUnitDelegate<FilterUnit> {

    var presets: FilterPresets {return unit.presets}
    
    var bands: [FilterBand] {
        
        get {return unit.bands}
        set(newValue) {unit.bands = newValue}
    }
    
    func addBand(_ band: FilterBand) -> Int {
        return unit.addBand(band)
    }
    
    func updateBand(_ index: Int, _ band: FilterBand) {
        unit.updateBand(index, band)
    }
    
    func removeBands(_ indexSet: IndexSet) {
        unit.removeBands(indexSet)
    }
    
    func removeAllBands() {
        unit.removeAllBands()
    }
    
    func getBand(_ index: Int) -> FilterBand {
        return unit.getBand(index)
    }
    
    override func savePreset(_ presetName: String) {
        unit.savePreset(presetName)
    }
    
    override func applyPreset(_ presetName: String) {
        unit.applyPreset(presetName)
    }
}