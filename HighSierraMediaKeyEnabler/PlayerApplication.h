//
//  PlayerApplication.h
//  HighSierraMediaKeyEnabler
//
//  Created by Michael Dorner on 29.10.17.
//  Copyright © 2017 Milan Toth. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol PlayerApplication

@required
- (void)playpause;
- (void)nextTrack;
- (void)previousTrack;

@end
