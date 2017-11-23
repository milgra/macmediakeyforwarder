
    #import "AppDelegate.h"

    @interface AppDelegate ()
    {
        NSStatusItem* statusItem;
    }
    @end

    @implementation AppDelegate

    - ( void ) applicationDidFinishLaunching : ( NSNotification*) theNotification
    {
        NSMenu *menu = [ [ NSMenu alloc ] init ];
        [ menu addItemWithTitle : @"Running" action : nil keyEquivalent : @"" ];
        [ menu addItem : [ NSMenuItem separatorItem ] ]; // A thin grey line
        [ menu addItemWithTitle : @"Quit" action : @selector(terminate:) keyEquivalent : @"" ];

        NSImage* image = [ NSImage imageNamed : @"mak" ];
        [ image setTemplate : YES ];

        statusItem = [ [ NSStatusBar systemStatusBar ] statusItemWithLength : NSSquareStatusItemLength ];
        [ statusItem setToolTip : @"High Sierra Media Key Enabler" ];
        [ statusItem setMenu : menu ];
        [ statusItem setImage : image ];
        
        keyTap = [[SPMediaKeyTap alloc] initWithDelegate:self];
        if([SPMediaKeyTap usesGlobalMediaKeyTap])
            [keyTap startWatchingMediaKeys];
        else
            NSLog(@"Media key monitoring disabled");
        
    }

    -(void)mediaKeyTap:(SPMediaKeyTap*)keyTap receivedMediaKeyEvent:(NSEvent*)event;
    {
        iTunesApplication* iTunes = [SBApplication applicationWithBundleIdentifier:@"com.apple.iTunes"];
        SpotifyApplication *spotify = [SBApplication applicationWithBundleIdentifier:@"com.spotify.client"];
        NSAssert([event type] == NSSystemDefined && [event subtype] == SPSystemDefinedEventMediaKeys, @"Unexpected NSEvent in mediaKeyTap:receivedMediaKeyEvent:");
        // here be dragons...
        int keyCode = (([event data1] & 0xFFFF0000) >> 16);
        int keyFlags = ([event data1] & 0x0000FFFF);
        BOOL keyIsPressed = (((keyFlags & 0xFF00) >> 8)) == 0xA;
        
        if (keyIsPressed) {
            switch (keyCode) {
                case NX_KEYTYPE_PLAY:
                    if ( [iTunes isRunning ] ) [iTunes playpause];
                    if ( [spotify isRunning ] ) [spotify playpause];
                    break;
                    
                case NX_KEYTYPE_FAST:
                    if ( [iTunes isRunning ] ) [iTunes nextTrack];
                    if ( [spotify isRunning ] ) [spotify nextTrack];
                    break;
                    
                case NX_KEYTYPE_REWIND:
                    if ( [iTunes isRunning ] ) [iTunes backTrack];
                    if ( [spotify isRunning ] ) [spotify previousTrack];
                    break;
                default:
                    break;
                    // More cases defined in hidsystem/ev_keymap.h
            }
        }
    }

- ( void ) terminate
    {
        [ NSApp terminate : nil ];
    }

    @end
