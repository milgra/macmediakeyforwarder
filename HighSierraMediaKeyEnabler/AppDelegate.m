
    #import "AppDelegate.h"

    @interface AppDelegate ()
    {
        NSStatusItem* statusItem;
        CFMachPortRef eventPort;
        CFRunLoopSourceRef eventPortSource;
    }

    @end

    @implementation AppDelegate

    static CGEventRef tapEventCallback(CGEventTapProxy proxy, CGEventType type, CGEventRef event, void *refcon)
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
            iTunesApplication* iTunes = [SBApplication applicationWithBundleIdentifier:@"com.apple.iTunes"];
            SpotifyApplication *spotify = [SBApplication applicationWithBundleIdentifier:@"com.spotify.client"];

            switch (keyCode) {
                case NX_KEYTYPE_PLAY:
                {
                    if ( [iTunes isRunning ] ) [iTunes playpause];
                    if ( [spotify isRunning ] ) [spotify playpause];
                    break;
                }
                case NX_KEYTYPE_FAST:
                {
                    if ( [iTunes isRunning ] ) [iTunes nextTrack];
                    if ( [spotify isRunning ] ) [spotify nextTrack];
                    break;
                }
                case NX_KEYTYPE_REWIND:
                {
                    if ( [iTunes isRunning ] ) [iTunes backTrack];
                    if ( [spotify isRunning ] ) [spotify previousTrack];
                    break;
                }
            }
        }
        // stop propagation
        return NULL;
    }

    - ( void ) applicationDidFinishLaunching : ( NSNotification*) theNotification
    {
        NSMenu *menu = [ [ NSMenu alloc ] init ];
        [ menu addItemWithTitle : @"Running" action : nil keyEquivalent : @"" ];
        [ menu addItem : [ NSMenuItem separatorItem ] ]; // A thin grey line
        [ menu addItemWithTitle : @"Donate if you like the app" action : @selector(support) keyEquivalent : @"" ];
        [ menu addItemWithTitle : @"Check for updates" action : @selector(update) keyEquivalent : @"" ];
        [ menu addItemWithTitle : @"Quit" action : @selector(terminate) keyEquivalent : @"" ];

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

    @end
