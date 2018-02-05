
    #import "AppDelegate.h"
    #import "iTunes.h"
    #import "Spotify.h"
    #import <MediaPlayer/MediaPlayer.h>
    #import <ScriptingBridge/ScriptingBridge.h>

    typedef NS_ENUM(NSInteger, MediaKeysPrioritize)
    {
        // Normal behavior (without priority; send events to iTunes and Spotify if both are open)
        MediaKeysPrioritizeNone,
        // If both apps are open, prioritize iTunes over Spotify
        MediaKeysPrioritizeITunes,
        // If both apps are open, prioritize Spotify over iTunes
        MediaKeysPrioritizeSpotify
    };

    typedef NS_ENUM(NSInteger, PauseState)
    {
        // pause app
        PauseStateNone,
        // pause app
        PauseStatePause,
        // pause app automatically when iTunes and Spotify is not running
        PauseStateAutomatic,
    };

    typedef NS_ENUM(NSInteger, KeyHoldState)
    {
        KeyHoldStateNone,
        KeyHoldStateWaiting,
        KeyHoldStateHolding
    };

    static NSString *kUserDefaultsPriorityOptionKey = @"user_priority_option";
    static NSString *kUserDefaultsPauseOptionKey = @"user_pause_option";

    PauseState pauseState;
    KeyHoldState keyHoldStatus;
    MediaKeysPrioritize mediaKeysPriority;

    @interface AppDelegate ()
    {
        NSStatusItem* statusItem;
        CFMachPortRef eventPort;
        CFRunLoopSourceRef eventPortSource;
        NSMutableArray *priorityOptionItems;
        NSMutableArray *pauseOptionItems;
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
            
            if(type == kCGEventTapDisabledByUserInput)
            {
                return event;
            }

            if(type != NX_SYSDEFINED )
            {
                return event;
            }

            NSEvent *nsEvent = nil;
            @try
            {
                nsEvent = [NSEvent eventWithCGEvent:event];
            }
            @catch (NSException * e)
            {
                return event;
            }

            if([nsEvent subtype] != 8)
            {
                return event;
            }

            iTunesApplication *iTunes = [SBApplication applicationWithBundleIdentifier:@"com.apple.iTunes"];
            SpotifyApplication *spotify = [SBApplication applicationWithBundleIdentifier:@"com.spotify.client"];

            if ( pauseState == PauseStatePause )
            {
                return event;
            }
            
            if ( pauseState == PauseStateAutomatic )
            {
                if (![spotify isRunning ] && ![iTunes isRunning ] )
                {
                    return event;
                }
            }

            int keyCode = (([nsEvent data1] & 0xFFFF0000) >> 16);
            
            if (keyCode != NX_KEYTYPE_PLAY &&
                keyCode != NX_KEYTYPE_FAST &&
                keyCode != NX_KEYTYPE_REWIND &&
                keyCode != NX_KEYTYPE_PREVIOUS &&
                keyCode != NX_KEYTYPE_NEXT)
                {
                    return event;
                }
            
            int keyFlags = ([nsEvent data1] & 0x0000FFFF);
            BOOL keyIsPressed = (((keyFlags & 0xFF00) >> 8)) == 0xA;
            
            if (keyIsPressed)
            {
                switch ( mediaKeysPriority )
                {
                    case MediaKeysPrioritizeITunes:
                    {
                        switch (keyCode)
                        {
                            case NX_KEYTYPE_PLAY:
                            {
                                [iTunes playpause];
                                break;
                            }
                            default:
                            {
                                if (keyHoldStatus == KeyHoldStateNone)
                                {
                                    keyHoldStatus = KeyHoldStateWaiting;
                                }
                                else if (keyHoldStatus == KeyHoldStateWaiting)
                                {
                                    keyHoldStatus = KeyHoldStateHolding;
                                    switch (keyCode)
                                    {
                                        case NX_KEYTYPE_NEXT:
                                        case NX_KEYTYPE_FAST:
                                        {
                                            [iTunes fastForward];
                                            break;
                                        }
                                        case NX_KEYTYPE_PREVIOUS:
                                        case NX_KEYTYPE_REWIND:
                                        {
                                            [iTunes rewind];
                                            break;
                                        }
                                    }
                                }
                            }
                        }
                        break;
                    }
                    case MediaKeysPrioritizeSpotify:
                    {
                        switch (keyCode)
                        {
                            case NX_KEYTYPE_PLAY:
                            {
                                [spotify playpause];
                                break;
                            }
                            case NX_KEYTYPE_NEXT:
                            case NX_KEYTYPE_FAST:
                            {
                                [spotify nextTrack];
                                break;
                            };
                            case NX_KEYTYPE_PREVIOUS:
                            case NX_KEYTYPE_REWIND:
                            {
                                [spotify previousTrack];
                                break;
                            }
                        }
                        break;
                    }                        
                    case MediaKeysPrioritizeNone:
                    {
                        switch (keyCode)
                        {
                            case NX_KEYTYPE_PLAY:
                            {
                                if ( [spotify isRunning ] ) [spotify playpause];
                                if ( [iTunes isRunning ] ) [iTunes playpause];
                                break;
                            }
                            case NX_KEYTYPE_NEXT:
                            case NX_KEYTYPE_FAST:
                            {
                                if ( [spotify isRunning ] ) [spotify nextTrack];
                                if ( [iTunes isRunning ] ) [iTunes nextTrack];
                                break;
                            }
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
            else
            {
                switch (keyHoldStatus)
                {
                    case KeyHoldStateWaiting:
                    {
                        if (mediaKeysPriority == MediaKeysPrioritizeITunes)
                        {
                            switch (keyCode)
                            {
                                case NX_KEYTYPE_NEXT:
                                case NX_KEYTYPE_FAST:
                                {
                                    [iTunes nextTrack];
                                    break;
                                }
                                case NX_KEYTYPE_PREVIOUS:
                                case NX_KEYTYPE_REWIND:
                                {
                                    [iTunes backTrack];
                                    break;
                                }
                            }
                        }
                        break;
                    }
                    case KeyHoldStateHolding:
                    {
                        // Stop fast forwarding / rewinding
                        
                        if (mediaKeysPriority == MediaKeysPrioritizeITunes)
                        {
                            [iTunes resume];
                        }
                        break;
                    }
                    case KeyHoldStateNone:
                    {
                        break;
                    }
                }
                keyHoldStatus = KeyHoldStateNone;
            }
            
            // stop propagation
            
            return NULL;
        }
    }

    - ( void ) applicationDidFinishLaunching : ( NSNotification*) theNotification
    {
        // init containers
        
        priorityOptionItems = [[NSMutableArray alloc] init];
        pauseOptionItems = [[NSMutableArray alloc] init];
        
        // init states

        pauseState = PauseStateNone;
        keyHoldStatus = KeyHoldStateNone;
        mediaKeysPriority = MediaKeysPrioritizeNone;
        
        NSNumber *option = [[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsPriorityOptionKey];
        if ( option )
        {
            mediaKeysPriority = [option integerValue];
        }
        
        option = [[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsPauseOptionKey];
        if ( option )
        {
            pauseState = [option integerValue];
        }

        // Always return success when system media control is sent to the app.
        // This will prevent unexpected behavior when the headphone button is pressed.
        
        [[MPRemoteCommandCenter sharedCommandCenter].togglePlayPauseCommand addTargetWithHandler: ^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent *event)
            {
                return MPRemoteCommandHandlerStatusSuccess;
            }];

        // Version string
        
        NSDictionary *bundleInfo = [[NSBundle mainBundle] infoDictionary];
        NSString *versionString = [NSString stringWithFormat:@"Version %@ (build %@)",
                                   bundleInfo[@"CFBundleShortVersionString"],
                                   bundleInfo[@"CFBundleVersion"] ];
        
        NSMenu *menu = [ [ NSMenu alloc ] init ];
        [ menu addItemWithTitle : versionString action : nil keyEquivalent : @"" ];
        [ menu addItem : [ NSMenuItem separatorItem ] ]; // A thin grey line

        [pauseOptionItems addObject:[ menu addItemWithTitle: NSLocalizedString(@"Pause", @"Pause") action : @selector(manualPause) keyEquivalent : @"" ]];
        [pauseOptionItems addObject:[ menu addItemWithTitle: NSLocalizedString(@"Pause if no player is running", @"Pause if no player is running") action : @selector(autoPause) keyEquivalent : @"" ]];

        [ menu addItem : [ NSMenuItem separatorItem ] ]; // A thin grey line

        [priorityOptionItems addObject:[ menu addItemWithTitle: NSLocalizedString(@"Send events to both players", @"Send events to both players") action : @selector(prioritizeNone) keyEquivalent : @"" ]];
        [priorityOptionItems addObject:[ menu addItemWithTitle: NSLocalizedString(@"Prioritize iTunes", @"Prioritize iTunes") action : @selector(prioritizeITunes) keyEquivalent : @"" ]];
        [priorityOptionItems addObject:[ menu addItemWithTitle: NSLocalizedString(@"Prioritize Spotify", @"Prioritize Spotify") action : @selector(prioritizeSpotify) keyEquivalent : @"" ]];
        
        [ menu addItem : [ NSMenuItem separatorItem ] ]; // A thin grey line
        
        [ menu addItemWithTitle : NSLocalizedString(@"Donate if you like the app", @"Donate if you like the app") action : @selector(support) keyEquivalent : @"" ];
        [ menu addItemWithTitle : NSLocalizedString(@"Check for updates", @"Check for updates") action : @selector(update) keyEquivalent : @"" ];
        [ menu addItemWithTitle : NSLocalizedString(@"Quit", @"Quit") action : @selector(terminate) keyEquivalent : @"" ];
        
        NSImage* image = [ NSImage imageNamed : @"icon" ];
        [ image setTemplate : YES ];

        statusItem = [ [ NSStatusBar systemStatusBar ] statusItemWithLength : NSVariableStatusItemLength ];
        [ statusItem setToolTip : @"High Sierra Media Key Enabler" ];
        [ statusItem setMenu : menu ];
        [ statusItem setImage : image ];

        [self updatePauseState];
        [self updateOptionState];

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

    - (void)prioritizeNone
    {
        mediaKeysPriority = MediaKeysPrioritizeNone;
        [[NSUserDefaults standardUserDefaults] setObject:@(mediaKeysPriority) forKey:kUserDefaultsPriorityOptionKey];
        [self updateOptionState];
    }

    - (void)prioritizeITunes
    {
        mediaKeysPriority = MediaKeysPrioritizeITunes;
        [[NSUserDefaults standardUserDefaults] setObject:@(mediaKeysPriority) forKey:kUserDefaultsPriorityOptionKey];
        [self updateOptionState];
    }

    - (void)prioritizeSpotify
    {
        mediaKeysPriority = MediaKeysPrioritizeSpotify;
        [[NSUserDefaults standardUserDefaults] setObject:@(mediaKeysPriority) forKey:kUserDefaultsPriorityOptionKey];
        [self updateOptionState];
    }

    - (void)manualPause
    {
        if ( pauseState != PauseStatePause )
        {
            pauseState = PauseStatePause;
        }
        else
        {
            pauseState = PauseStateNone;
        }
        [[NSUserDefaults standardUserDefaults] setObject:@(pauseState) forKey:kUserDefaultsPauseOptionKey];
        [self updatePauseState];
    }

    - (void)autoPause
    {
        if ( pauseState != PauseStateAutomatic )
        {
            pauseState = PauseStateAutomatic;
        }
        else
        {
            pauseState = PauseStateNone;
        }
        [[NSUserDefaults standardUserDefaults] setObject:@(pauseState) forKey:kUserDefaultsPauseOptionKey];
        [self updatePauseState];
    }

    #pragma mark UI refresh

    - (void)updateOptionState
    {
        // Verify if a choice was selected, otherwise mark "None" as the default
        
        NSNumber *option = [[NSUserDefaults standardUserDefaults] valueForKey:kUserDefaultsPriorityOptionKey];
        if ( option )
        {
            mediaKeysPriority = [option integerValue];
        }
        
        // Mark with a tick the selected item from priority options
        
        for ( NSUInteger index = 0, num = priorityOptionItems.count; index < num; index++ )
        {
            NSMenuItem *item = priorityOptionItems[index];
            [item setState:( index == mediaKeysPriority ? NSControlStateValueOn : NSControlStateValueOff )];
        }
    }

    - (void)updatePauseState
    {
        NSMenuItem *item0 = pauseOptionItems[0];
        NSMenuItem *item1 = pauseOptionItems[1];
        
        [item0 setState: pauseState == PauseStatePause ? NSControlStateValueOn : NSControlStateValueOff];
        [item1 setState: pauseState == PauseStateAutomatic ? NSControlStateValueOn : NSControlStateValueOff];
    }

    @end






