
    #import <Cocoa/Cocoa.h>
    #import "SPMediaKeyTap.h"
    #import <ScriptingBridge/ScriptingBridge.h>
    #import "iTunes.h"
    #import "Spotify.h"

    @interface AppDelegate : NSObject <NSApplicationDelegate>
    {
        SPMediaKeyTap *keyTap;
    }

    @end

