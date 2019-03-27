//
//  AppRegistrar.h
//  Autumn
//

#import <Cocoa/Cocoa.h>
#import "App.h"

NS_ASSUME_NONNULL_BEGIN

@interface AppRegistrar : NSObject

+ (AppRegistrar*) sharedRegistrar;

- (void) setup;

- (NSArray<App*>*) apps;
- (App*) appForRunningApp:(NSRunningApplication*)runningApp;

@end

NS_ASSUME_NONNULL_END
