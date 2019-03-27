//
//  LoginLauncher.h
//  Autumn
//

#import <Foundation/Foundation.h>

@interface LoginLauncher : NSObject

+ (BOOL) isEnabled;
+ (void) setEnabled:(BOOL)opensAtLogin;

@end
