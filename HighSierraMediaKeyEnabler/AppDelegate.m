
    #import "AppDelegate.h"

    static NSString* const kSelectedApplication = @"selectedApplication";

    typedef enum : NSUInteger {
        iTunes = 1,
        Spotify = 2
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

    - (void)switchStandardApplication:(NSMenuItem*) menuItem {
        [self switchStandardApplicationTag:menuItem.tag];
    }

    - (void) switchStandardApplicationTag:(NSUInteger) tag {
        [[NSUserDefaults standardUserDefaults] setInteger:tag forKey:kSelectedApplication];
        
        if (tag == iTunes) {
            standardApplication = _iTunesApplication;
        } else if (tag == Spotify && spotifyApplication) {
            standardApplication = spotifyApplication;
        } else {
            tag = iTunes;
            standardApplication = _iTunesApplication;
        }
        
        for (NSMenuItem* item in statusItem.menu.itemArray) {
            if (item.tag == tag) {
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
        menu.autoenablesItems = NO;
        
        [menu addItemWithTitle : @"iTunes" action : @selector(switchStandardApplication:) keyEquivalent:@""];
        menu.itemArray.lastObject.tag = iTunes;
        
        [menu addItemWithTitle : @"Spotify" action : @selector(switchStandardApplication:) keyEquivalent:@""];
        menu.itemArray.lastObject.tag = Spotify;
        menu.itemArray.lastObject.enabled = (spotifyApplication != nil);

        [ menu addItem : [ NSMenuItem separatorItem ] ]; // A thin grey line
        NSString *appName = [NSBundle mainBundle].infoDictionary[@"CFBundleName"];
        [ menu addItemWithTitle : [NSString stringWithFormat: @"Quit %@", appName] action : @selector(terminate:) keyEquivalent : @"" ];

        NSImage* image = [ NSImage imageNamed : @"mak" ];
        [ image setTemplate : YES ];

        statusItem = [ [ NSStatusBar systemStatusBar ] statusItemWithLength : NSSquareStatusItemLength ];
        [ statusItem setToolTip : @"High Sierra Media Key Enabler" ];
        [ statusItem setMenu : menu ];
        [ statusItem setImage : image ];

        // This will default to 0, and switchStandardApplication will default to using iTunes
        NSInteger selectedApplicationTag = [[NSUserDefaults standardUserDefaults] integerForKey:kSelectedApplication];
        [self switchStandardApplicationTag:selectedApplicationTag];
        
        keyTap = [[SPMediaKeyTap alloc] initWithDelegate:self];
        if([SPMediaKeyTap usesGlobalMediaKeyTap])
            [keyTap startWatchingMediaKeys];
        else
            NSLog(@"Media key monitoring disabled");
    }


    -(void)mediaKeyTap:(SPMediaKeyTap*)keyTap receivedMediaKeyEvent:(NSEvent*)event;
    {
        NSAssert([event type] == NSSystemDefined && [event subtype] == SPSystemDefinedEventMediaKeys, @"Unexpected NSEvent in mediaKeyTap:receivedMediaKeyEvent:");
        // here be dragons...
        int keyCode = (([event data1] & 0xFFFF0000) >> 16);
        int keyFlags = ([event data1] & 0x0000FFFF);
        BOOL keyIsPressed = (((keyFlags & 0xFF00) >> 8)) == 0xA;
        
        if (keyIsPressed) {
            switch (keyCode) {
                case NX_KEYTYPE_PLAY:
                    [standardApplication playpause];
                    break;
                    
                case NX_KEYTYPE_FAST:
                    [standardApplication nextTrack];
                    break;
                    
                case NX_KEYTYPE_REWIND:
                    [standardApplication previousTrack];
                    break;

                default:
                    break;
                    // More cases defined in hidsystem/ev_keymap.h
            }
        }
    }

    @end
