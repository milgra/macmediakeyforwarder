GBLaunchAtLogin
============

Add your app as a login item on Mac OS X.

Usage
------------

Make your app launch at login:

```objective-c
[GBLaunchAtLogin addAppAsLoginItem];
```

Check if the app has been added as a login item:

```objective-c
[GBLaunchAtLogin isLoginItem];		//Returns: YES or NO
```

Remove app from login items:

```objective-c
[GBLaunchAtLogin removeAppFromLoginItems];
```

Don't forget to import header first.

```objective-c
#import <GBLaunchAtLogin/GBLaunchAtLogin.h>
```

Integration
------------

1. Add GBLaunchAtLogin as a subproject (by dragging the .xcodeproj file from Finder into the Xcode Project Navigator, or using the "Add Files" menu)
2. Add project dependency to your target (in "Target Dependencies" under "Build Phases")
3. Link library to your target (in "Link Binary With Libraries" under "Build Phases")

Copyright & License
------------

Copyright 2013 Luka Mirosevic

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this work except in compliance with the License. You may obtain a copy of the License in the LICENSE file, or at:

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.

[![Bitdeli Badge](https://d2weczhvl823v0.cloudfront.net/lmirosevic/gblaunchatlogin/trend.png)](https://bitdeli.com/free "Bitdeli Badge")
