import Cocoa

class PlayingTrackFunctionsViewController: NSViewController, MessageSubscriber, ActionMessageSubscriber, AsyncMessageSubscriber, StringInputClient {
    
    // Button to display more details about the playing track
    @IBOutlet weak var btnMoreInfo: NSButton!
    
    // Button to show the currently playing track within the playlist
    @IBOutlet weak var btnShowPlayingTrackInPlaylist: NSButton!
    
    // Button to add/remove the currently playing track to/from the Favorites list
    @IBOutlet weak var btnFavorite: OnOffImageButton!
    
    // Button to bookmark current track and position
    @IBOutlet weak var btnBookmark: NSButton!
    
    @IBOutlet weak var seekSlider: NSSlider!
    @IBOutlet weak var seekSliderCell: SeekSliderCell!
    
    // Used to display the bookmark name prompt popover
    @IBOutlet weak var seekPositionMarker: NSView!
    
    // Delegate that conveys all seek and playback info requests to the player
    private let player: PlaybackInfoDelegateProtocol = ObjectGraph.getPlaybackInfoDelegate()
    
    // Delegate that provides access to History information
    private let favorites: FavoritesDelegateProtocol = ObjectGraph.getFavoritesDelegate()
    
    // Popover view that displays detailed info for the currently playing track
    private lazy var detailedInfoPopover: PopoverViewDelegate = ViewFactory.getDetailedTrackInfoPopover()
    
    // Popup view that displays a brief notification when the currently playing track is added/removed to/from the Favorites list
    private lazy var favoritesPopup: FavoritesPopupProtocol = ViewFactory.getFavoritesPopup()
    
    private lazy var bookmarks: BookmarksDelegateProtocol = ObjectGraph.getBookmarksDelegate()
    private lazy var bookmarkNamePopover: StringInputPopoverViewController = StringInputPopoverViewController.create(self)
    
    override func viewDidLoad() {
        initSubscriptions()
    }
    
    func activate() {
        initSubscriptions()
    }
    
    func deactivate() {
        removeSubscriptions()
    }
    
    private func initSubscriptions() {
        
        // Subscribe to various notifications
        
        AsyncMessenger.subscribe([.addedToFavorites, .removedFromFavorites], subscriber: self, dispatchQueue: DispatchQueue.main)
        
        SyncMessenger.subscribe(actionTypes: [.moreInfo, .bookmarkPosition, .bookmarkLoop], subscriber: self)
        
        SyncMessenger.subscribe(messageTypes: [.trackChangedNotification], subscriber: self)
    }
    
    private func removeSubscriptions() {
        
        AsyncMessenger.unsubscribe([.addedToFavorites, .removedFromFavorites], subscriber: self)
        
        SyncMessenger.unsubscribe(actionTypes: [.moreInfo, .bookmarkPosition, .bookmarkLoop], subscriber: self)
        
        SyncMessenger.unsubscribe(messageTypes: [.trackChangedNotification], subscriber: self)
    }
    
    // Shows a popover with detailed information for the currently playing track, if there is one
    @IBAction func moreInfoAction(_ sender: AnyObject) {
        
        let playingTrack = player.getPlayingTrack()
        
        // If there is a track currently playing, load detailed track info and toggle the popover view
        if (playingTrack != nil) {
            
            // TODO: This should be done through a delegate (TrackDelegate ???)
            playingTrack!.track.loadDetailedInfo()
            
            if btnMoreInfo.isVisible {
                detailedInfoPopover.toggle(playingTrack!.track, btnMoreInfo, NSRectEdge.maxX)
            } else {
                detailedInfoPopover.toggle(playingTrack!.track, self.view.window!.contentView!, NSRectEdge.maxX)
            }
        }
    }
    
    // Shows (selects) the currently playing track, within the playlist, if there is one
    @IBAction func showPlayingTrackAction(_ sender: Any) {
        SyncMessenger.publishActionMessage(PlaylistActionMessage(.showPlayingTrack, PlaylistViewState.current))
    }
    
    // Adds/removes the currently playing track to/from the "Favorites" list
    @IBAction func favoriteAction(_ sender: Any) {
        
        // Toggle the button state
        btnFavorite.toggle()
        
        // Assume there is a track playing (this function cannot be invoked otherwise)
        let playingTrack = (player.getPlayingTrack()?.track)!
        
        // Publish an action message to add/remove the item to/from Favorites
        if btnFavorite.isOn() {
            _ = favorites.addFavorite(playingTrack)
        } else {
            favorites.deleteFavoriteWithFile(playingTrack.file)
        }
    }
    
    // Adds/removes the currently playing track to/from the "Favorites" list
    @IBAction func bookmarkAction(_ sender: Any) {
        
        // Mark the playing track and position
        BookmarkContext.bookmarkedTrack = player.getPlayingTrack()!.track
        BookmarkContext.bookmarkedTrackStartPosition = player.getSeekPosition().timeElapsed
        BookmarkContext.bookmarkedTrackEndPosition = nil
        
        BookmarkContext.defaultBookmarkName = String(format: "%@ (%@)", BookmarkContext.bookmarkedTrack!.conciseDisplayName, StringUtils.formatSecondsToHMS(BookmarkContext.bookmarkedTrackStartPosition!))
        
        // Show popover
        let loc = getLocationForBookmarkPrompt()
        
        if loc.view.isVisible {
            bookmarkNamePopover.show(loc.view, loc.edge)
        } else if btnBookmark.isVisible {
            bookmarkNamePopover.show(btnBookmark, NSRectEdge.maxX)
        } else {
            bookmarkNamePopover.show(self.view.window!.contentView!, NSRectEdge.maxX)
        }
    }
    
    // When a bookmark menu item is clicked, the item is played
    private func bookmarkLoop() {
        
        // Mark the playing track and position
        BookmarkContext.bookmarkedTrack = player.getPlayingTrack()!.track
        if let loop = player.getPlaybackLoop() {
            
            if loop.isComplete() {
                
                BookmarkContext.bookmarkedTrackStartPosition = loop.startTime
                BookmarkContext.bookmarkedTrackEndPosition = loop.endTime
                
                let startTime = StringUtils.formatSecondsToHMS(loop.startTime)
                let endTime = StringUtils.formatSecondsToHMS(loop.endTime!)
                
                BookmarkContext.defaultBookmarkName = String(format: "%@ (%@ ⇄ %@)", BookmarkContext.bookmarkedTrack!.conciseDisplayName, startTime, endTime)
                
                // Show popover
                let loc = getLocationForBookmarkPrompt()
                
                if loc.view.isVisible {
                    bookmarkNamePopover.show(loc.view, loc.edge)
                } else if btnBookmark.isVisible {
                    bookmarkNamePopover.show(btnBookmark, NSRectEdge.maxX)
                } else {
                    bookmarkNamePopover.show(self.view.window!.contentView!, NSRectEdge.maxX)
                }
            }
        }
    }
    
    private func getLocationForBookmarkPrompt() -> (view: NSView, edge: NSRectEdge) {
        
        // Slider knob position
        let knobRect = seekSliderCell.knobRect(flipped: false)
        seekPositionMarker.setFrameOrigin(NSPoint(x: seekSlider.frame.origin.x + knobRect.minX + 2, y: seekSlider.frame.origin.y + knobRect.minY))
        
        return (seekPositionMarker, NSRectEdge.maxY)
    }
    
    // Responds to a notification that a track has been added to / removed from the Favorites list, by updating the UI to reflect the new state
    private func favoritesUpdated(_ message: FavoritesUpdatedAsyncMessage) {
        
        if let playingTrack = player.getPlayingTrack()?.track {
            
            // Do this only if the track in the message is the playing track
            if message.file.path == playingTrack.file.path {
                
                if (message.messageType == .addedToFavorites) {
                    
                    btnFavorite.on()
                    
                    if btnFavorite.isVisible {
                        favoritesPopup.showAddedMessage(btnFavorite, NSRectEdge.maxX)
                    } else {
                        favoritesPopup.showAddedMessage(self.view.window!.contentView!, NSRectEdge.maxX)
                    }
                    
                } else {
                    
                    btnFavorite.off()
                    
                    if btnFavorite.isVisible {
                        favoritesPopup.showRemovedMessage(btnFavorite, NSRectEdge.maxX)
                    } else {
                        favoritesPopup.showRemovedMessage(self.view.window!.contentView!, NSRectEdge.maxX)
                    }
                }
            }
        }
    }
    
    private func newTrackStarted(_ track: Track) {
        
        self.view.showIf_elseHide(PlayerViewState.showPlayingTrackFunctions)
        btnFavorite.onIf(favorites.favoriteWithFileExists(track.file))
    }
    
    private func noTrackPlaying() {
        
        detailedInfoPopover.close()
        self.view.hide()
    }
    
    private func trackChanged(_ notification: TrackChangedNotification) {
        trackChanged(notification.newTrack, notification.errorState)
    }
    
    // The "errorState" arg indicates whether the player is in an error state (i.e. the new track cannot be played back). If so, update the UI accordingly.
    private func trackChanged(_ newTrack: IndexedTrack?, _ errorState: Bool = false) {
        
        if (newTrack != nil) {
            
            newTrackStarted(newTrack!.track)
            
            if (!errorState) {
                
                if (detailedInfoPopover.isShown()) {
                    
                    player.getPlayingTrack()!.track.loadDetailedInfo()
                    detailedInfoPopover.refresh(player.getPlayingTrack()!.track)
                }
            }
            
        } else {
            
            // No track playing, clear the info fields
            noTrackPlaying()
        }
    }
    
    // MARK: Message handling
    
    func getID() -> String {
        return self.className
    }
    
    func consumeNotification(_ notification: NotificationMessage) {
        
        switch notification.messageType {
            
        case .trackChangedNotification:
            
            trackChanged(notification as! TrackChangedNotification)

        default: return
            
        }
    }
    
    // Consume asynchronous messages
    func consumeAsyncMessage(_ message: AsyncMessage) {
        
        switch message.messageType {
            
        case .addedToFavorites, .removedFromFavorites:
            
            favoritesUpdated(message as! FavoritesUpdatedAsyncMessage)
            
        default: return
            
        }
    }
    
    func consumeMessage(_ message: ActionMessage) {
        
        switch message.actionType {
            
        case .moreInfo: moreInfoAction(self)
        
        case .bookmarkPosition: bookmarkAction(self)
            
        case .bookmarkLoop: bookmarkLoop()

         default: return
            
        }
    }
    
    // MARK - StringInputClient functions
    
    func getInputPrompt() -> String {
        return "Enter a bookmark name:"
    }
    
    func getDefaultValue() -> String? {
        return BookmarkContext.defaultBookmarkName!
    }
    
    func validate(_ string: String) -> (valid: Bool, errorMsg: String?) {
        
        let valid = !bookmarks.bookmarkWithNameExists(string)
        
        if (!valid) {
            return (false, "A bookmark with this name already exists !")
        } else {
            return (true, nil)
        }
    }
    
    // Receives a new EQ preset name and saves the new preset
    func acceptInput(_ string: String) {
        
        if (BookmarkContext.bookmarkedTrackEndPosition == nil) {
            
            // Track position
            _ = bookmarks.addBookmark(string, BookmarkContext.bookmarkedTrack!.file, BookmarkContext.bookmarkedTrackStartPosition!)
            
        } else {
            
            // Loop
            _ = bookmarks.addBookmark(string, BookmarkContext.bookmarkedTrack!.file, BookmarkContext.bookmarkedTrackStartPosition!, BookmarkContext.bookmarkedTrackEndPosition!)
        }
    }
}

class BookmarkContext {
    
    // Changes whenever a bookmark is added
    static var defaultBookmarkName: String?
    static var bookmarkedTrack: Track?
    static var bookmarkedTrackStartPosition: Double?
    static var bookmarkedTrackEndPosition: Double?
}