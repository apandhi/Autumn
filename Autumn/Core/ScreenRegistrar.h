//
//  ScreenRegistrar.h
//  Autumn
//

#import <Cocoa/Cocoa.h>
#import "Screen.h"

NS_ASSUME_NONNULL_BEGIN

@interface ScreenRegistrar : NSObject

+ (ScreenRegistrar*) sharedRegistrar;
- (void) setup;

- (Screen*) screenForRealScreen:(NSScreen*)realScreen;

@end

NS_ASSUME_NONNULL_END
