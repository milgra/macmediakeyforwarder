
    #import <Cocoa/Cocoa.h>
    #import <ScriptingBridge/ScriptingBridge.h>
    #import "iTunes.h"
    #import "Spotify.h"

    typedef NS_ENUM(NSInteger, MediaKeysPrioritize) {
        MediaKeysPrioritizeNone,    // Normal behavior (without priority; send events to iTunes and Spotify if both are open)
        MediaKeysPrioritizeITunes,  // If both apps are open, prioritize iTunes over Spotify
        MediaKeysPrioritizeSpotify  // If both apps are open, prioritize Spotify over iTunes
    };

    @interface AppDelegate : NSObject <NSApplicationDelegate>
        @property (assign, nonatomic, readonly) MediaKeysPrioritize mediaKeysPriority;
    @end

