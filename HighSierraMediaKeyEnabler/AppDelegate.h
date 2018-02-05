
    #import <Cocoa/Cocoa.h>
    #import <ScriptingBridge/ScriptingBridge.h>
    #import "iTunes.h"
    #import "Spotify.h"

    typedef NS_ENUM(NSInteger, MediaKeysPrioritize) {
        MediaKeysPrioritizeNone,    // Normal behavior (without priority; send events to iTunes and Spotify if both are open)
        MediaKeysPrioritizeNoneAndCheck,    // Normal behavior, but forward event to macOS 10.13 default behavior if no media player is running (without priority; send events to iTunes and Spotify if both are open, default behavior if not)
        MediaKeysPrioritizeITunes,  // If both apps are open, prioritize iTunes over Spotify
        MediaKeysPrioritizeSpotify,  // If both apps are open, prioritize Spotify over iTunes
        MediaKeysPause  // Pause tool and use default macOS behavior

    };

    @interface AppDelegate : NSObject <NSApplicationDelegate>
        @property (assign, nonatomic, readonly) MediaKeysPrioritize mediaKeysPriority;
    @end

