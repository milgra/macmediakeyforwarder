//
//  GBLaunchAtLogin.h
//  GBLaunchAtLogin
//
//  Created by Luka Mirosevic on 04/03/2013.
//  Copyright (c) 2013 Goonbee. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GBLaunchAtLogin : NSObject

+(BOOL)isLoginItem;
+(void)addAppAsLoginItem;
+(void)removeAppFromLoginItems;

@end
