
    #import "AppDelegate.h"

    typedef enum : NSUInteger {
        iTunes = 0,
        Spotify = 1
    } PlayerApplicationTag;


    @interface AppDelegate ()
    {
        NSStatusItem* statusItem;
        SBApplication <PlayerApplication>* standardApplication;
        SBApplication <PlayerApplication>* _iTunesApplication;
        SBApplication <PlayerApplication>* spotifyApplication;
    }
    @end

    @implementation AppDelegate

    - (void) switchStandardApplication:(NSMenuItem*) toSwitchItem {
        if (toSwitchItem.tag == iTunes) {
            standardApplication = _iTunesApplication;
            NSLog(@"Use iTunes");
        } else if (toSwitchItem.tag == Spotify && spotifyApplication) {
            standardApplication = spotifyApplication;
            NSLog(@"Use Spotify");
        } else {
            //something went really wrong
            standardApplication = _iTunesApplication;
        }
        for (NSMenuItem* item in statusItem.menu.itemArray) {
            if (item == toSwitchItem) {
                item.state = NSOnState;
            } else {
                item.state = NSOffState;
            }
        }
    }

    - ( void ) applicationDidFinishLaunching : ( NSNotification*) theNotification
    {
        _iTunesApplication = [SBApplication applicationWithBundleIdentifier:@"com.apple.iTunes"];
        spotifyApplication = [SBApplication applicationWithBundleIdentifier:@"com.spotify.client"];
        standardApplication = _iTunesApplication;
        
        NSMenu *menu = [ [ NSMenu alloc ] init ];
        [menu insertItemWithTitle : @"iTunes" action : @selector(switchStandardApplication:) keyEquivalent:@"" atIndex: iTunes];
        menu.itemArray[iTunes].tag = iTunes;
        menu.itemArray[iTunes].state = NSOnState;
        
        if (spotifyApplication) {
            [menu insertItemWithTitle : @"Spotify" action : @selector(switchStandardApplication:) keyEquivalent:@"" atIndex: Spotify];
            menu.itemArray[Spotify].tag = Spotify;
            menu.itemArray[Spotify].state = NSOffState;
        } /*else {
            // for a consistent GUI we may need this line
            [menu addItemWithTitle:@"Spotify not installed" action:nil keyEquivalent:@""];
        }*/


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
        //iTunesApplication* iTunesApplication = [SBApplication applicationWithBundleIdentifier:@"com.apple.iTunes"];
        //SpotifyApplication *spotifyApplication = [SBApplication applicationWithBundleIdentifier:@"com.spotify.client"];
        NSAssert([event type] == NSSystemDefined && [event subtype] == SPSystemDefinedEventMediaKeys, @"Unexpected NSEvent in mediaKeyTap:receivedMediaKeyEvent:");
        // here be dragons...
        int keyCode = (([event data1] & 0xFFFF0000) >> 16);
        int keyFlags = ([event data1] & 0x0000FFFF);
        BOOL keyIsPressed = (((keyFlags & 0xFF00) >> 8)) == 0xA;
        
        if (keyIsPressed) {
            switch (keyCode) {
                case NX_KEYTYPE_PLAY:
                    [standardApplication playpause];
                    //if (defaultPlayer == iTunes) [iTunesApplication playpause];
                    //if ( [iTunesApplication isRunning ] && defaultPlayer == iTunes) [iTunesApplication playpause];
                    //if ( [spotifyApplication isRunning ] ) [spotifyApplication playpause];
                    break;
                    
                case NX_KEYTYPE_FAST:
                    [standardApplication nextTrack];
                    //if ( [iTunesApplication isRunning ] && defaultPlayer == iTunes) [iTunesApplication nextTrack];
                    //if ( [spotifyApplication isRunning ] ) [spotifyApplication nextTrack];
                    break;
                    
                case NX_KEYTYPE_REWIND:
                    [standardApplication previousTrack];
                    //if ( [iTunesApplication isRunning ] && defaultPlayer == iTunes) [iTunesApplication previousTrack];
                    //if ( [spotifyApplication isRunning ] ) [spotifyApplication previousTrack];
                    break;
                default:
                    break;
                    // More cases defined in hidsystem/ev_keymap.h
            }
        }
    }

    @end
