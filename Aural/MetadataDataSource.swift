import Cocoa

/*
    Data source and delegate for the Detailed Track Info popover view
 */
class TrackInfoDataSource: NSObject, NSTableViewDataSource, NSTableViewDelegate {
    
    // The table view that displays the track info
    @IBOutlet weak var table: NSTableView!
    
    // Used to measure table row height
    @IBOutlet var virtualKeyField: NSTextField!
    @IBOutlet var virtualValueField: NSTextField!
    
    // Container for the key-value pairs of info displayed
    var info: [(key: String, value: String)] = [(key: String, value: String)]()
    
    // Cached playing track instance (to avoid reloading the same data)
    var displayedTrack: Track?
    
    var tableId: TrackInfoTab {return .metadata}
    
    // Constants used to calculate row height
    
    let keyColumnBounds: NSRect = NSMakeRect(CGFloat(0), CGFloat(0), Dimensions.trackInfoKeyColumnWidth, CGFloat(Float.greatestFiniteMagnitude))
    
    let valueColumnBounds: NSRect = NSMakeRect(CGFloat(0), CGFloat(0), Dimensions.trackInfoValueColumnWidth, CGFloat(Float.greatestFiniteMagnitude))
    
    let value_unknown: String = "<Unknown>"
    
    // Compares two tracks for equality. True if and only if both are non-nil and their file paths are the same.
    func compareTracks(_ track1: Track?, _ track2: Track?) -> Bool {
        
        if (track1 == nil || track2 == nil) {
            return false
        }
        
        return track1!.file.path == track2!.file.path
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        
        // If no track is playing, no rows to display
        
        let _track = DetailedTrackInfoViewController.shownTrack
        if (_track == nil) {
            return 0
        }
        
        // If it's the same track playing (as last time view was refreshed), no need to reload the track info
        if (compareTracks(_track, displayedTrack)) {
            return info.count
        }
        
        // A track is playing, add its info to the info array, as key-value pairs
        
        let track = _track!
        self.displayedTrack = _track!
        
        info.removeAll()
        info.append(contentsOf: infoForTrack(track))
        
        return info.count
    }
    
    // Each track info view row contains one key-value pair
    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        return DetailedTrackInfoRowView.fromKeyAndValue(info[row].key, info[row].value, .metadata)
    }
    
    // Adjust row height based on if the text wraps over to the next line
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        
        let keyText = info[row].key
        let valueText = info[row].value
        
        // Set the key and value within the virtual text fields (which are not displayed)
        virtualKeyField.stringValue = keyText
        virtualValueField.stringValue = valueText
        
        // And then compute row height from their cell sizes
        let keyHeight = virtualKeyField.cell!.cellSize(forBounds: keyColumnBounds).height
        let valueHeight = virtualValueField.cell!.cellSize(forBounds: valueColumnBounds).height
        
        // The desired row height is the maximum of the two heights, plus some padding
        return max(keyHeight, valueHeight) + 5
    }
    
    // Completely disable row selection
    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        return false
    }
    
    func infoForTrack(_ track: Track) -> [(key: String, value: String)] {
        return []
    }
}

// Place to hold a reference to the trackInfoView object (used in DetailedTrackInfoRowView class)
class TrackInfoViewHolder {
    
    static var tablesMap: [TrackInfoTab: NSTableView] = [:]
}

enum TrackInfoTab {
    
    case metadata
    case audio
    case fileSystem
}

class MetadataDataSource: TrackInfoDataSource {
    
    override var tableId: TrackInfoTab {return .metadata}
    
    override func awakeFromNib() {
        
        // Store a reference to trackInfoView that is easily accessible
        TrackInfoViewHolder.tablesMap[.metadata] = table
    }
    
    override func infoForTrack(_ track: Track) -> [(key: String, value: String)] {
        
        var trackInfo: [(key: String, value: String)] = []
        
        trackInfo.append((key: "Artist", value: track.displayInfo.artist ?? value_unknown))
        trackInfo.append((key: "Title", value: track.displayInfo.title ?? value_unknown))
        trackInfo.append((key: "Album", value: track.groupingInfo.album ?? value_unknown))
        trackInfo.append((key: "Genre", value: track.groupingInfo.genre ?? value_unknown))
        
        if let trackNum = track.groupingInfo.trackNumber {
            
            if let totalTracks = track.groupingInfo.totalTracks, totalTracks > 0 {
                trackInfo.append((key: "Track#", value: String(format: "%d / %d", trackNum, totalTracks)))
            } else {
                trackInfo.append((key: "Track#", value: String(trackNum)))
            }
        }
        
        if let discNum = track.groupingInfo.discNumber {
            
            if let totalDiscs = track.groupingInfo.totalDiscs, totalDiscs > 0 {
                trackInfo.append((key: "Disc#", value: String(format: "%d / %d", discNum, totalDiscs)))
            } else {
                trackInfo.append((key: "Disc#", value: String(discNum)))
            }
        }
        
        // TODO: Find a way to sort the generic metadata so that junk comes last (e.g. iTunesNORM and UPC's, etc)
        
        for (key, entry) in track.metadata {
            
            if entry.formattedKey().trim().isEmpty {
                continue
            }
            
            // Some tracks have a "Format" metadata entry ... ignore it
            if (key.lowercased() != "format") {
                trackInfo.append((key: entry.formattedKey(), value: entry.value))
            }
        }
        
        return trackInfo
    }
}