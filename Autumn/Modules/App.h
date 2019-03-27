//
//  App.h
//  Autumn
//

#import <Foundation/Foundation.h>
#import "Module.h"

@class Window;
@class App;

@protocol JSExport_App <JSExport>

+ (NSArray<App*>*) allApps;
+ (NSArray<App*>*) allDaemons;
+ (App*) focusedApp;

+ (JSValue*) open:(NSString*)name;
+ (id) find:(NSString*)name;

@property JSValue* onHidden;
@property JSValue* onUnhidden;

- (id) mainWindow;
- (JSValue*) mainWindowPromise;
- (NSArray<Window*>*) allWindows;

@property NSString* name;
@property NSString* bundleId;
@property pid_t pid;
@property NSString* kind;

- (NSNumber*) isRunning;
- (NSNumber*) isFocused;

- (void) activate:(BOOL)allWindows;

- (void) hide;
- (void) unhide;

- (void) quit;
- (void) forceQuit;

- (NSNumber*) isHidden;
- (NSNumber*) isUnresponsive;

@property JSValue* onTermination;

@end

@interface App : NSObject <JSExport_App, Module>

- (void) internal_bringToFront:(BOOL)allWindows;

- (instancetype) initWithRunningApplication:(NSRunningApplication*)runningApp;

@property AXUIElementRef element;
@property NSRunningApplication* runningApp;

+ (void) appLaunched:(App*)app;
+ (void) appTerminated:(App*)app;

- (void) startObservingWindowsSeeding:(BOOL)isSeeding;
- (void) stopObservingWindows;
- (void) appIsTerminating;

@end
