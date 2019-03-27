//
//  App.m
//  Autumn
//

#import <AppKit/AppKit.h>
#import "App.h"
#import "Window.h"
#import "FnUtils.h"
#import "Accessibility.h"
#import "KeyValueObserver.h"
#import "AppRegistrar.h"
#import "WindowRegistrar.h"
#import "ObservedEvent.h"

#define CHECK_WINDOWS_TIMES_PER_SECOND (4)

/**
 * module App
 *
 * Control running applications.
 *
 * Note that Apps always resolve to the same object and can thus be compared with strict object equality (===).
 */
@implementation App {
    NSTimer* windowWatcherTimer;
    int checkForNewWindowsCallCount;
    NSArray* currentWindowElements;
    NSMutableArray<Window*>* currentWindows;
    
    ObservedEvent* hiddenEvent;
    ObservedEvent* unhiddenEvent;
    
    NSMutableArray* firstMainWindowResolvers;
}

static JSValue* module;

+ (void)startModule:(JSValue *)ctor {
    module = ctor;
    module[@"onAppLaunched"] = [JSValue valueWithUndefinedInContext: module.context];
    module[@"onFocusedAppChanged"] = [JSValue valueWithUndefinedInContext: module.context];
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [NSWorkspace.sharedWorkspace.notificationCenter addObserver:self
                                                           selector:@selector(focusedAppChanged:)
                                                               name:NSWorkspaceDidActivateApplicationNotification
                                                             object:nil];
    });
}

+ (void)stopModule {
    module = nil;
    
    for (App* app in App.allApps) {
        app.onHidden = nil;
        app.onUnhidden = nil;
        app.onTermination = nil;
    }
}

@synthesize name;
@synthesize bundleId;
@synthesize pid=_pid;
@synthesize kind;

- (instancetype) initWithRunningApplication:(NSRunningApplication*)runningApp {
    if (self = [super init]) {
        _runningApp = runningApp;
        _pid = _runningApp.processIdentifier;
        _element = AXUIElementCreateApplication(_pid);
        name = [_runningApp localizedName];
        bundleId = [_runningApp bundleIdentifier];
        currentWindows = [NSMutableArray array];
        
        switch ([_runningApp activationPolicy]) {
            case NSApplicationActivationPolicyAccessory:  kind = @"no-dock"; break;
            case NSApplicationActivationPolicyProhibited: kind = @"no-gui"; break;
            case NSApplicationActivationPolicyRegular:    kind = @"dock"; break;
        }
    }
    return self;
}

- (void) dealloc {
    CFRelease(_element);
}

- (void) startObservingWindowsSeeding:(BOOL)isSeeding {
    if ([kind isEqualToString: @"no-gui"]) return;
    
    hiddenEvent = [[ObservedEvent alloc] initWithEvent:kAXApplicationHiddenNotification ofElement:_element];
    unhiddenEvent = [[ObservedEvent alloc] initWithEvent:kAXApplicationShownNotification ofElement:_element];
    
    if (isSeeding) {
        currentWindowElements = [self getWindowElements];
        [currentWindows addObjectsFromArray: [WindowRegistrar.sharedRegistrar seedWithWindowElements: currentWindowElements
                                                                                              forApp: self]];
    }
    
    __weak typeof(self) weakSelf = self;
    windowWatcherTimer = [NSTimer scheduledTimerWithTimeInterval:(1.0 / CHECK_WINDOWS_TIMES_PER_SECOND) repeats:YES block:^(NSTimer * _Nonnull timer) {
        [weakSelf checkForNewWindows];
    }];
}

- (void) checkForNewWindows {
    checkForNewWindowsCallCount++;
    if (checkForNewWindowsCallCount >= (10 * CHECK_WINDOWS_TIMES_PER_SECOND)) {
        checkForNewWindowsCallCount = 0;
        [self checkManuallyForNewWindows];
    }
    else {
        CFIndex windowCount = -1;
        AXError err = AXUIElementGetAttributeValueCount(_element, kAXWindowsAttribute, &windowCount);
        if (err == kAXErrorSuccess) {
            if (windowCount != currentWindowElements.count) {
                [self checkManuallyForNewWindows];
            }
        }
    }
}

- (NSArray*) getWindowElements {
    AXError err;
    
    CFIndex windowCount;
    err = AXUIElementGetAttributeValueCount(_element, kAXWindowsAttribute, &windowCount);
    if (err != kAXErrorSuccess) return nil;
    
    CFArrayRef wins;
    err = AXUIElementCopyAttributeValues(_element, kAXWindowsAttribute, 0, windowCount, &wins);
    if (err != kAXErrorSuccess) return nil;
    
    return (__bridge_transfer NSArray*)wins;
}

- (void) checkManuallyForNewWindows {
    NSArray* windowElements = [self getWindowElements];
    
    NSMutableArray* oldWindowElements = currentWindowElements.mutableCopy;
    [oldWindowElements removeObjectsInArray: windowElements];
    
    NSMutableArray* newWindowElements = windowElements.mutableCopy;
    [newWindowElements removeObjectsInArray: currentWindowElements];
    
    currentWindowElements = windowElements;
    
    for (id winEl in oldWindowElements) {
        [self windowClosed: (AXUIElementRef)winEl];
    }
    
    for (id winEl in newWindowElements) {
        [self windowOpened: (AXUIElementRef)winEl];
    }
}

- (void) appIsTerminating {
    for (id winEl in currentWindowElements) {
        [self windowClosed: (AXUIElementRef)winEl];
    }
}

- (void) windowOpened:(AXUIElementRef)winEl {
    Window* win = [WindowRegistrar.sharedRegistrar windowElementOpened: winEl
                                                                forApp: self];
    [currentWindows addObject: win];
    [Window windowOpened: win];
    
    if (firstMainWindowResolvers && win.isMainWindow.boolValue) {
        for (JSValue* resolve in firstMainWindowResolvers) {
            [resolve callWithArguments: @[win]];
        }
        firstMainWindowResolvers = nil;
    }
}

- (void) windowClosed:(AXUIElementRef)winEl {
    Window* win = [WindowRegistrar.sharedRegistrar windowElementClosed: winEl];
    [currentWindows removeObject: win];
    [Window windowClosed: win];
}

- (void) stopObservingWindows {
    [hiddenEvent changeObserving: nil];
    [unhiddenEvent changeObserving: nil];
    
    [windowWatcherTimer invalidate];
    currentWindowElements = nil;
}





/** group Getting or creating apps */

/**
 * static allApps(): App[];
 *
 * Returns all currently running apps, where app.kind === 'dock'.
 */
+ (NSArray<App*>*) allApps {
    if ([Accessibility warn]) return nil;
    
    return [FnUtils filter:AppRegistrar.sharedRegistrar.apps with:^BOOL(App* app) {
        return [app.kind isEqualToString: @"dock"];
    }];
}

/**
 * static allDaemons(): App[];
 *
 * Returns all currently running apps, where kind !== 'dock'.
 */
+ (NSArray<App*>*) allDaemons {
    if ([Accessibility warn]) return nil;
    
    return [FnUtils filter:AppRegistrar.sharedRegistrar.apps with:^BOOL(App* app) {
        return ![app.kind isEqualToString: @"dock"];
    }];
}

/**
 * static focusedApp(): App;
 *
 * Returns the app that currently has keyboard focus.
 */
+ (App*) focusedApp {
    if ([Accessibility warn]) return nil;
    
    return [FnUtils findIn:AppRegistrar.sharedRegistrar.apps where:^BOOL(App* app) {
        return app.isFocused.boolValue;
    }];
}

/**
 * static open(name: string): Promise<App | null>;
 *
 * Opens the app with the given name, or makes it the current app if it's already running.
 *
 * The name doesn't need the full path or .app extension, but both are allowed.
 *
 * Returns a promise that resolves to the app, or null if the app doesn't exist or can't be opened.
 */
+ (JSValue*) open:(NSString*)name {
    if ([Accessibility warn]) return nil;
    
    JSValue* Promise = JSContext.currentContext[@"Promise"];
    
    BOOL success = [[NSWorkspace sharedWorkspace] launchApplication: name];
    if (!success) return [Promise invokeMethod:@"resolve" withArguments:@[[NSNull null]]];
    
    App* found = [FnUtils findIn:AppRegistrar.sharedRegistrar.apps where:^BOOL(App* app) {
        return ([app.runningApp.bundleURL.path isEqualToString: name] ||
                [app.runningApp.bundleURL.path.lastPathComponent isEqualToString: name] ||
                [app.runningApp.bundleURL.path.lastPathComponent.stringByDeletingPathExtension isEqualToString: name]);
    }];
    if (found) return [Promise invokeMethod:@"resolve" withArguments:@[found]];
    
    __weak NSNotificationCenter* wsCenter = NSWorkspace.sharedWorkspace.notificationCenter;
    __block JSValue* resolve = nil;
    __block id observer =
    [wsCenter addObserverForName:NSWorkspaceDidLaunchApplicationNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        [wsCenter removeObserver: observer];
        
        NSRunningApplication* runningApp = note.userInfo[NSWorkspaceApplicationKey];
        App* app = [AppRegistrar.sharedRegistrar appForRunningApp: runningApp];
        [resolve callWithArguments: @[app]];
    }];
    
    return [Promise constructWithArguments:@[^(JSValue* r) { resolve = r; }]];
}

/**
 * static find(name: string): App | null;
 *
 * Like App.open(name), except it returns the app if it's already running or null, without trying to open it.
 */
+ (id) find:(NSString*)name {
    if ([Accessibility warn]) return nil;
    
    App* found = [FnUtils findIn:AppRegistrar.sharedRegistrar.apps where:^BOOL(App* app) {
        return ([app.runningApp.bundleURL.path isEqualToString: name] ||
                [app.runningApp.bundleURL.path.lastPathComponent isEqualToString: name] ||
                [app.runningApp.bundleURL.path.lastPathComponent.stringByDeletingPathExtension isEqualToString: name]);
    }];
    if (!found) return [NSNull null];
    return found;
}







/** group App events */

/**
 * static onAppLaunched: (app: App) => void;
 *
 * Set a callback for when an app opens.
 */
+ (void) appLaunched:(App*)app {
    JSValue* fn = module[@"onAppLaunched"];
    if ([fn isInstanceOf: fn.context[@"Function"]]) {
        [fn callWithArguments: @[app]];
    }
}

/**
 * static onFocusedAppChanged: (app: App) => void;
 *
 * Set a callback for when a new app becomes the focused app.
 */
+ (void) focusedAppChanged:(NSNotification*)note {
    JSValue* fn = module[@"onFocusedAppChanged"];
    if ([fn isInstanceOf: fn.context[@"Function"]]) {
        NSRunningApplication* runningApp = note.userInfo[NSWorkspaceApplicationKey];
        App* app = [AppRegistrar.sharedRegistrar appForRunningApp: runningApp];
        [fn callWithArguments: @[app]];
    }
}

/**
 * onTermination: () => void;
 *
 * Set a callback for when an app quits.
 */
@synthesize onTermination;
+ (void) appTerminated:(App*)app {
    JSValue* fn = app.onTermination;
    if ([fn isInstanceOf: fn.context[@"Function"]]) {
        [fn callWithArguments: @[]];
    }
}


/**
 * onHidden: () => void;
 *
 * Set a callback for when this app is hidden.
 */
- (JSValue *)onHidden { return hiddenEvent.givenCallback; }
- (void)setOnHidden:(JSValue *)callback { [hiddenEvent changeObserving: callback]; }

/**
 * onUnhidden: () => void;
 *
 * Set a callback for when this app is unhidden.
 */
- (JSValue *)onUnhidden { return unhiddenEvent.givenCallback; }
- (void)setOnUnhidden:(JSValue *)callback { [unhiddenEvent changeObserving: callback]; }








/** group Getting windows from apps */

/**
 * mainWindow(): Window;
 *
 * Returns the main window of the given app, or nil.
 */
- (id) mainWindow {
    if ([Accessibility warn]) return nil;
    
    CFTypeRef winEl;
    AXError err = AXUIElementCopyAttributeValue(_element, kAXMainWindowAttribute, &winEl);
    if (err != kAXErrorSuccess) return [NSNull null];
    
    Window* win = [WindowRegistrar.sharedRegistrar windowForElement: winEl];
    CFRelease(winEl);
    return win;
}

/**
 * mainWindowPromise(): Promise<Window>;
 *
 * Returns a promise that will resolve to the main window of this app as soon as there is one.
 */
- (JSValue*) mainWindowPromise {
    JSValue* Promise = JSContext.currentContext[@"Promise"];
    
    id mainWindow = [self mainWindow];
    if ([mainWindow isKindOfClass: Window.class]) {
        return [Promise invokeMethod:@"resolve" withArguments: @[mainWindow]];
    }
    
    return [Promise constructWithArguments: @[^(JSValue* resolve) {
        if (!self->firstMainWindowResolvers) {
            self->firstMainWindowResolvers = [NSMutableArray array];
        }
        
        [self->firstMainWindowResolvers addObject: resolve];
    }]];
}

/**
 * allWindows(): Window[];
 *
 * Returns all open windows owned by the given app.
 */
- (NSArray<Window*>*) allWindows {
    if ([Accessibility warn]) return nil;
    
    return currentWindows;
}









/** group App properties */

/**
 * name: string;
 *
 * The name of the app, e.g. "Safari" or "Finder".
 */

/**
 * bundleId: string | undefined;
 *
 * The bundle identifier of the app, like "com.apple.finder".
 *
 * Note: some processes don't have this, mainly some of Apple's own daemons.
 */

/**
 * pid: number;
 *
 * The app's process identifier.
 *
 * Note: this is not strictly needed for comparison, since Apps can be compared with strict object equality (a1 === a2).
 */

/**
 * kind: 'dock' | 'no-dock' | 'no-gui';
 *
 * The string 'dock' means the app is in the dock, 'no-dock' isn't, and 'no-gui' means it can't even have GUI elements if it wanted to.
 */

/**
 * isRunning: boolean;
 *
 * Returns whether the app is still running or has already quit.
 */
- (NSNumber*) isRunning {
    return _runningApp.terminated ? @NO : @YES;
}

/**
 * isFocused: boolean;
 *
 * Returns whether the app is the front-most app.
 */
- (NSNumber*) isFocused {
    return _runningApp.active ? @YES : @NO;
}

/**
 * isHidden(): boolean;
 *
 * Returns whether the app is currently hidden.
 */
- (NSNumber*) isHidden {
    if ([Accessibility warn]) return nil;
    
    CFBooleanRef isHidden;
    AXUIElementCopyAttributeValue(_element, (CFStringRef)NSAccessibilityHiddenAttribute, (CFTypeRef*)&isHidden);
    return (__bridge_transfer NSNumber*)isHidden;
}

/**
 * isUnresponsive(): boolean;
 *
 * True if the app has the spinny circle of death.
 */
- (NSNumber*) isUnresponsive {
    // lol apple
    typedef int CGSConnectionID;
    CG_EXTERN CGSConnectionID CGSMainConnectionID(void);
    bool CGSEventIsAppUnresponsive(CGSConnectionID cid, const ProcessSerialNumber *psn);
    // srsly come on now
    
    ProcessSerialNumber psn;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    GetProcessForPID(_pid, &psn);
#pragma clang diagnostic pop
    
    CGSConnectionID conn = CGSMainConnectionID();
    return CGSEventIsAppUnresponsive(conn, &psn) ? @YES : @NO;
}








/** group App actions */

/**
 * activate(allWindows: boolean = false): boolean;
 *
 * Tries to activate the app (make its key window focused) and returns whether it succeeded.
 *
 * @param allWindows Whether all windows are brought to the front.
 */
- (void) activate:(BOOL)allWindows {
    if ([Accessibility warn]) return;
    
    if ([self isUnresponsive].boolValue)
        return;
    
    Window* win = [self internal_focusedWindow];
    if (win) {
        [win becomeMain];
        [self internal_bringToFront:allWindows];
    }
    else {
        [self internal_activate: allWindows];
    }
}

/**
 * hide(): boolean;
 *
 * Hides the app (and all its windows).
 */
- (void) hide {
    if ([Accessibility warn]) return;
    
    AXUIElementSetAttributeValue(_element, (CFStringRef)NSAccessibilityHiddenAttribute, kCFBooleanTrue);
}

/**
 * unhide(): boolean;
 *
 * Unhides the app (and all its windows) if it's hidden.
 */
- (void) unhide {
    if ([Accessibility warn]) return;
    
    AXUIElementSetAttributeValue(_element, (CFStringRef)NSAccessibilityHiddenAttribute, kCFBooleanFalse);
}

/**
 * quit(): void;
 *
 * Tries to terminate the app.
 */
- (void) quit {
    [_runningApp terminate];
}

/**
 * forceQuit(): void;
 *
 * Terminates the app.
 *
 * Note: this may cause loss of data!
 */
- (void) forceQuit {
    [_runningApp forceTerminate];
}

// a few private methods for -activate

- (BOOL) internal_activate:(BOOL)allWindows {
    return [_runningApp activateWithOptions:NSApplicationActivateIgnoringOtherApps | (allWindows ? NSApplicationActivateAllWindows : 0)];
}

- (Window*) internal_focusedWindow {
    CFTypeRef winEl;
    AXError err = AXUIElementCopyAttributeValue(_element, (CFStringRef)NSAccessibilityFocusedWindowAttribute, &winEl);
    if (err != kAXErrorSuccess) return nil;
    return [WindowRegistrar.sharedRegistrar windowForElement: winEl];
}

- (void) internal_bringToFront:(BOOL)allWindows {
    [_runningApp activateWithOptions: (allWindows ? NSApplicationActivateAllWindows : 0)];
}

@end
