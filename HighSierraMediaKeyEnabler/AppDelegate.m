
    #import "AppDelegate.h"

    // NSUserDefaults key for the last user-chosen priority option
    static NSString *kUserDefaultsPriorityOptionKey = @"user_priority_option";

    @interface AppDelegate ()
    {
        NSStatusItem* statusItem;
        CFMachPortRef eventPort;
        CFRunLoopSourceRef eventPortSource;
        NSArray<NSMenuItem *> *priorityOptionItems;
    }

    @end

    @implementation AppDelegate

    static CGEventRef tapEventCallback(CGEventTapProxy proxy, CGEventType type, CGEventRef event, void *refcon)
    {
        @autoreleasepool
        {
            AppDelegate *self = (__bridge id)refcon;

            if(type == kCGEventTapDisabledByTimeout)
            {
                CGEventTapEnable(self->eventPort, TRUE);
                return event;
            }
            else if(type == kCGEventTapDisabledByUserInput)
            {
                return event;
            }
            
            NSEvent *nsEvent = nil;
            @try
            {
                nsEvent = [NSEvent eventWithCGEvent:event];
            }
            @catch (NSException * e) {
                return event;
            }

            if (type != NX_SYSDEFINED || [nsEvent subtype] != 8)
                return event;

            int keyCode = (([nsEvent data1] & 0xFFFF0000) >> 16);
            if (keyCode != NX_KEYTYPE_PLAY && keyCode != NX_KEYTYPE_FAST && keyCode != NX_KEYTYPE_REWIND && keyCode != NX_KEYTYPE_PREVIOUS && keyCode != NX_KEYTYPE_NEXT)
                return event;
            
            int keyFlags = ([nsEvent data1] & 0x0000FFFF);
            BOOL keyIsPressed = (((keyFlags & 0xFF00) >> 8)) == 0xA;

            if (keyIsPressed)
            {
                switch ( self.mediaKeysPriority ) {
                    case MediaKeysPrioritizeITunes:
                    {
                        iTunesApplication* iTunes = [SBApplication applicationWithBundleIdentifier:@"com.apple.iTunes"];
                        switch (keyCode) {
                            // Play/pause
                            case NX_KEYTYPE_PLAY:[iTunes playpause];break;
                            
                            // Fast forward
                            case NX_KEYTYPE_NEXT:
                            case NX_KEYTYPE_FAST:[iTunes nextTrack];break;
                                
                            // Rewind
                            case NX_KEYTYPE_PREVIOUS:
                            case NX_KEYTYPE_REWIND:[iTunes backTrack];break;
                        }
                        break;
                    }
                    case MediaKeysPrioritizeSpotify:
                    {
                        SpotifyApplication *spotify = [SBApplication applicationWithBundleIdentifier:@"com.spotify.client"];
                        switch (keyCode) {
                            // Play/pause
                            case NX_KEYTYPE_PLAY:[spotify playpause];break;
                            
                            // Fast forward
                            case NX_KEYTYPE_NEXT:
                            case NX_KEYTYPE_FAST:[spotify nextTrack];break;
                               
                            // Rewind
                            case NX_KEYTYPE_PREVIOUS:
                            case NX_KEYTYPE_REWIND:[spotify previousTrack];break;
                        }
                        break;
                    }
                    default:
                    {
                        iTunesApplication* iTunes = [SBApplication applicationWithBundleIdentifier:@"com.apple.iTunes"];
                        SpotifyApplication *spotify = [SBApplication applicationWithBundleIdentifier:@"com.spotify.client"];
                        // legacy behaviour
                        switch (keyCode) {
                            // Play/pause
                            case NX_KEYTYPE_PLAY:
                            {
                                if ( [spotify isRunning ] ) [spotify playpause];
                                if ( [iTunes isRunning ] ) [iTunes playpause];
                                break;
                            }
                               
                            // Fast forward
                            case NX_KEYTYPE_NEXT:
                            case NX_KEYTYPE_FAST:
                            {
                                if ( [spotify isRunning ] ) [spotify nextTrack];
                                if ( [iTunes isRunning ] ) [iTunes nextTrack];
                                break;
                            }
                               
                            // Rewind
                            case NX_KEYTYPE_PREVIOUS:
                            case NX_KEYTYPE_REWIND:
                            {
                                if ( [spotify isRunning ] ) [spotify previousTrack];
                                if ( [iTunes isRunning ] ) [iTunes backTrack];
                                break;
                            }
                        }
                        break;
                    }
                }
            }
            // stop propagation
            return NULL;
        }
    }

    - ( void ) applicationDidFinishLaunching : ( NSNotification*) theNotification
    {
        
        // We'll save references to the items that define player priority
        NSMutableArray<NSMenuItem *> *priorityItems = [@[] mutableCopy];
        
        // Version string
        NSDictionary *bundleInfo = [[NSBundle mainBundle] infoDictionary];
        NSString *versionString = [NSString stringWithFormat:@"Version %@ (build %@)",
                                   bundleInfo[@"CFBundleShortVersionString"],
                                   bundleInfo[@"CFBundleVersion"]
                                   ];
        
        NSMenu *menu = [ [ NSMenu alloc ] init ];
        [ menu addItemWithTitle : versionString action : nil keyEquivalent : @"" ];
        [ menu addItem : [ NSMenuItem separatorItem ] ]; // A thin grey line
        
        [priorityItems addObject:[ menu addItemWithTitle: NSLocalizedString(@"Send events to both players", @"Send events to both players") action : @selector(prioritizeNone) keyEquivalent : @"" ]];
        [priorityItems addObject:[ menu addItemWithTitle: NSLocalizedString(@"Prioritize iTunes", @"Prioritize iTunes") action : @selector(prioritizeITunes) keyEquivalent : @"" ]];
        [priorityItems addObject:[ menu addItemWithTitle: NSLocalizedString(@"Prioritize Spotify", @"Prioritize Spotify") action : @selector(prioritizeSpotify) keyEquivalent : @"" ]];
        [ menu addItem : [ NSMenuItem separatorItem ] ]; // A thin grey line
        [ menu addItemWithTitle : NSLocalizedString(@"Donate if you like the app", @"Donate if you like the app") action : @selector(support) keyEquivalent : @"" ];
        [ menu addItemWithTitle : NSLocalizedString(@"Check for updates", @"Check for updates") action : @selector(update) keyEquivalent : @"" ];
        [ menu addItemWithTitle : NSLocalizedString(@"Quit", @"Quit") action : @selector(terminate) keyEquivalent : @"" ];
        
        priorityOptionItems = [priorityItems copy];
        priorityItems = nil;
        
        [self refreshItemTick]; // Update the "tick" for the selected option
        
        NSImage* image = [ NSImage imageNamed : @"icon" ];
        [ image setTemplate : YES ];

        statusItem = [ [ NSStatusBar systemStatusBar ] statusItemWithLength : NSVariableStatusItemLength ];
        [ statusItem setToolTip : @"High Sierra Media Key Enabler" ];
        [ statusItem setMenu : menu ];
        [ statusItem setImage : image ];
        
        eventPort = CGEventTapCreate( kCGSessionEventTap, kCGHeadInsertEventTap, kCGEventTapOptionDefault, CGEventMaskBit(NX_SYSDEFINED), tapEventCallback, (__bridge void * _Nullable)(self));
        eventPortSource = CFMachPortCreateRunLoopSource( kCFAllocatorSystemDefault, eventPort, 0 );
        
        CFRunLoopAddSource( CFRunLoopGetCurrent(), eventPortSource, kCFRunLoopCommonModes );
        CFRunLoopRun();
    }

    - ( void ) terminate
    {
        [ NSApp terminate : nil ];
    }

    - ( void ) support
    {
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString: @"https://paypal.me/milgra"]];
    }

    - ( void ) update
    {
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString: @"http://milgra.com/high-sierra-media-key-enabler.html"]];
    }



    #pragma mark - App priorization
    #pragma mark Handlers
    - (void)prioritizeNone {
        _mediaKeysPriority = MediaKeysPrioritizeNone;
        [[NSUserDefaults standardUserDefaults] setObject:@(_mediaKeysPriority)
                                                  forKey:kUserDefaultsPriorityOptionKey];
        [self refreshItemTick];
    }

    - (void)prioritizeITunes {
        _mediaKeysPriority = MediaKeysPrioritizeITunes;
        [[NSUserDefaults standardUserDefaults] setObject:@(_mediaKeysPriority)
                                                  forKey:kUserDefaultsPriorityOptionKey];
        [self refreshItemTick];
    }

    - (void)prioritizeSpotify {
        _mediaKeysPriority = MediaKeysPrioritizeSpotify;
        [[NSUserDefaults standardUserDefaults] setObject:@(_mediaKeysPriority)
                                                  forKey:kUserDefaultsPriorityOptionKey];
        [self refreshItemTick];
    }

    #pragma mark UI refresh
    - (void)refreshItemTick {
        // Verify if a choice was selected, otherwise mark "None" as the default
        NSNumber *option = [[NSUserDefaults standardUserDefaults] valueForKey:kUserDefaultsPriorityOptionKey];
        if ( option ) {
            _mediaKeysPriority = [option integerValue];
        }
        else {
            [self prioritizeNone]; // This will message refreshItemTick again, so we'll just return after this
            return;
        }
        
        // Mark with a tick the selected item from priority options
        for ( NSUInteger i = 0, num = priorityOptionItems.count; i < num; i++ ) {
            NSMenuItem *item = priorityOptionItems[i];
            [item setState:( i == _mediaKeysPriority ? NSControlStateValueOn : NSControlStateValueOff )];
        }
    }
    @end
