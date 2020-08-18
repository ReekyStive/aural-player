import Cocoa
import AVFoundation

class TrackMetadata {
    
    var defaultDisplayName: String
    
    var duration: Double = 0

    var title: String?
    var artist: String?
    var album: String?
    var genre: String?
    
    var art: CoverArt?
    
    var trackNumber: Int?
    var totalTracks: Int?
    
    var discNumber: Int?
    var totalDiscs: Int?
    
    var lyrics: String?
    
    // Generic metadata
    var genericMetadata: [String: MetadataEntry] = [:]
    
    var chapters: [Chapter] = []
    var hasChapters: Bool {!chapters.isEmpty}
    
    var hasPrimaryMetadata: Bool = false
    
    init(for file: URL) {
        self.defaultDisplayName = file.deletingPathExtension().lastPathComponent
    }
    
    func setPrimaryMetadata(_ metadata: PrimaryMetadata) {
        
        self.duration = metadata.duration
        
        self.title = metadata.title
        self.artist = metadata.artist
        self.album = metadata.album
        self.genre = metadata.genre
        
        self.art = metadata.coverArt
        
        hasPrimaryMetadata = true
    }
    
    func setSecondaryMetadata(_ metadata: SecondaryMetadata) {
        
        self.trackNumber = metadata.trackNumber
        self.totalTracks = metadata.totalTracks
        
        self.discNumber = metadata.discNumber
        self.totalDiscs = metadata.totalDiscs
        
        self.lyrics = metadata.lyrics
        
        self.chapters = metadata.chapters
    }
    
    func setGenericMetadata(_ metadata: [String: MetadataEntry]) {
        self.genericMetadata = metadata
    }
}

class CoverArt {
    
    var image: NSImage
    var metadata: ImageMetadata?
    
    init(_ image: NSImage, _ metadata: ImageMetadata?) {
        
        self.image = image
        self.metadata = metadata
    }
}

class ImageMetadata {
    
    // e.g. JPEG/PNG
    var type: String? = nil
    
    // e.g. 1680x1050
    var dimensions: NSSize? = nil
    
    // e.g. 72x72 DPI
    var resolution: NSSize? = nil
    
    // e.g. RGB
    var colorSpace: String? = nil
    
    // e.g. "sRGB IEC61966-2.1"
    var colorProfile: String? = nil
    
    // e.g. 8 bit
    var bitDepth: Int? = nil

    // True for transparent images like PNGs
    var hasAlpha: Bool? = nil
}

class AudioInfo {
    
    // The total number of frames in the track
    // TODO: This should be of type AVAudioFrameCount?
    var frames: AVAudioFramePosition?
    
    // The sample rate of the track (in Hz)
    var sampleRate: Double?
    
    // Number of audio channels
    var numChannels: Int?
    
    // Bit rate (in kbps)
    var bitRate: Int?
    
    // Audio format (e.g. "mp3", "aac", or "lpcm")
    var format: String?
    
    var codec: String?
    
    var channelLayout: String?
}

class FileSystemInfo {
    
    // The filesystem file that contains the audio track represented by this object
    let file: URL
    let fileName: String
    
    init(_ file: URL) {
        self.file = file
        self.fileName = file.deletingPathExtension().lastPathComponent
    }
    
    // Filesystem size
    var size: Size?
    var lastModified: Date?
    var creationDate: Date?
    var kindOfFile: String?
    var lastOpened: Date?
}

// Encapsulates a single metadata entry
class MetadataEntry {
    
    // Type: e.g. ID3 or iTunes
    var type: MetadataType
    
    // Key or "tag"
    let key: String
    
    let value: String
    
    init(_ type: MetadataType, _ key: String, _ value: String) {
        
        self.type = type
        self.key = key
        self.value = value
    }
}

/*
    Represents a single chapter marking within a track
 */
class Chapter {
    
    // Title may be changed / corrected after chapter object is created
    var title: String
    
    // Time bounds of this chapter
    let startTime: Double
    let endTime: Double
    let duration: Double
    
    init(_ title: String, _ startTime: Double, _ endTime: Double, _ duration: Double? = nil) {
        
        self.title = title
        
        self.startTime = startTime
        self.endTime = endTime
        
        // Use duration if provided. Otherwise, compute it from the start and end times.
        self.duration = duration == nil ? max(endTime - startTime, 0) : duration!
    }
    
    // Convenience function to determine if a given track position lies within this chapter's time bounds
    func containsTimePosition(_ seconds: Double) -> Bool {
        return seconds >= startTime && seconds <= endTime
    }
}

// Wrapper around Chapter that includes its parent track and chronological index
class IndexedChapter: Equatable {
    
    // The track to which this chapter belongs
    let track: Track
    
    // The chapter this object represents
    let chapter: Chapter
    
    // The chronological index of this chapter within the track
    let index: Int
    
    init(_ track: Track, _ chapter: Chapter, _ index: Int) {
        
        self.track = track
        self.chapter = chapter
        self.index = index
    }
    
    static func == (lhs: IndexedChapter, rhs: IndexedChapter) -> Bool {
        return lhs.track == rhs.track && lhs.index == rhs.index
    }
    
    func hash(into hasher: inout Hasher) {
        
        hasher.combine(track.file.path)
        hasher.combine(index)
    }
}