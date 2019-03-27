//
//  Screen.m
//  Autumn
//

#import "Screen.h"
#import "FnUtils.h"
#import "Math.h"
#import "ScreenRegistrar.h"
#import "Window.h"

static JSValue* module;

/**
 * module Screen
 *
 * Information about each screen per monitor.
 *
 * Note that Screens always resolve to the same object and can thus be compared with strict object equality (===).
 */
@implementation Screen {
    NSScreen* _screen;
}

@synthesize id = _id;
@synthesize name;

+ (void)startModule:(JSValue *)ctor {
    module = ctor;
    module[@"onScreenConnected"] = [JSValue valueWithUndefinedInContext: module.context];
    module[@"onScreenDisconnected"] = [JSValue valueWithUndefinedInContext: module.context];
    module[@"onScreensReconfigured"] = [JSValue valueWithUndefinedInContext: module.context];
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [NSWorkspace.sharedWorkspace.notificationCenter
         addObserver:self
         selector:@selector(darkModeChanged:)
         name:@"NSWorkspaceMenuBarAppearanceDidChangeNotification"
         object:nil];
    });
}

+ (void)stopModule {
    module = nil;
}

- (instancetype) initWithRealScreen:(NSScreen*)realScreen {
    if (self = [super init]) {
        _screen = realScreen;
        _id = _screen.deviceDescription[@"NSScreenNumber"];
        
        CGDirectDisplayID screen_id = [[self id] intValue];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        NSDictionary *deviceInfo = (__bridge_transfer NSDictionary*)IODisplayCreateInfoDictionary(CGDisplayIOServicePort(screen_id), kIODisplayOnlyPreferredName);
#pragma clang diagnostic pop
        NSDictionary *localizedNames = deviceInfo[@(kDisplayProductName)];
        name = localizedNames.allValues.firstObject ?: @"";
    }
    return self;
}









/** group Getting screens */

/**
 * static allScreens(): Screen[];
 *
 * Returns an array of every screen, representing attached monitors.
 *
 * Note: This array starts with the screen that has the menu bar and Dock, or if you're using mirroring, the screen with the best resolution.
 */
+ (NSArray*) allScreens {
    return [FnUtils map:[NSScreen screens] with:^Screen*(NSScreen* screen) {
        return [ScreenRegistrar.sharedRegistrar screenForRealScreen: screen];
    }];
}

/**
 * static currentScreen(): Screen;
 *
 * Returns the screen that contains the currently active window.
 */
+ (Screen*) currentScreen {
    return [ScreenRegistrar.sharedRegistrar screenForRealScreen: [NSScreen mainScreen]];
}

/**
 * nextScreen(): Screen;
 *
 * Get the screen after `this` in the `allScreens()` array.
 */
- (Screen*) nextScreen {
    NSArray* screens = [Screen allScreens];
    NSInteger i = [screens indexOfObject: self] + 1;
    if (i >= screens.count) i = 0;
    return screens[i];
}

/**
 * previousScreen(): Screen;
 *
 * Get the screen before `this` in the `allScreens()` array.
 */
- (Screen*) previousScreen {
    NSArray* screens = [Screen allScreens];
    NSInteger i = [screens indexOfObject: self] - 1;
    if (i < 0) i = screens.count - 1;
    return screens[i];
}






/** group Getting windows */

/**
 * allWindows(): Window[];
 *
 * Returns Window.allWindows filtered where win.screen === this
 */
- (NSArray*) allWindows {
    return [FnUtils filter:Window.allWindows with:^BOOL(Window* win) {
        return win.screen == self;
    }];
}

/**
 * visibleWindows(): Window[];
 *
 * Returns Window.visibleWindows filtered where win.screen === this
 */
- (NSArray*) visibleWindows {
    return [FnUtils filter:Window.visibleWindows with:^BOOL(Window* win) {
        return win.screen == self;
    }];
}




/** group Screen events */

/**
 * static onScreenConnected: (screen: Screen) => void;
 *
 * Set a callback for when a screen is added.
 */
+ (void) screenAdded:(Screen*)screen {
    JSValue* fn = module[@"onScreenConnected"];
    if ([fn isInstanceOf: module.context[@"Function"]]) {
        [fn callWithArguments: @[screen]];
    }
}

/**
 * static onScreenDisconnected: (screen: Screen) => void;
 *
 * Set a callback for when a screen is removed.
 */
+ (void) screenRemoved:(Screen*)screen {
    JSValue* fn = module[@"onScreenDisconnected"];
    if ([fn isInstanceOf: module.context[@"Function"]]) {
        [fn callWithArguments: @[screen]];
    }
}

/**
 * static onScreensReconfigured: (screen: Screen) => void;
 *
 * Set a callback for when a screen is reconfigured.
 */
+ (void) screensReconfigured {
    JSValue* fn = module[@"onScreensReconfigured"];
    if ([fn isInstanceOf: module.context[@"Function"]]) {
        [fn callWithArguments: @[]];
    }
}





/** group Screen properties */

/**
 * id: number;
 *
 * Unique, persistent identifier for this screen.
 *
 * Note: this is not strictly needed for comparison, since Screens can be compared with strict object equality (s1 === s2).
 */

/**
 * name: string;
 *
 * The name of this screen.
 */

/**
 * fullFrame(): Rect;
 *
 * Returns this screen's frame, including any space the Dock and menu bar might be taking up.
 */
- (Rect2d*) fullFrame {
    Screen* primaryScreen = [Screen allScreens].firstObject;
    NSRect f = _screen.frame;
    f.origin.y = primaryScreen->_screen.frame.size.height - f.size.height - f.origin.y;
    return [Rect2d from: f];
}

/**
 * innerFrame(): Rect;
 *
 * Returns this screen's frame, excluding any space the Dock and menu bar might be taking up.
 */
- (Rect2d*) innerFrame {
    Screen* primaryScreen = [Screen allScreens].firstObject;
    NSRect f = _screen.visibleFrame;
    f.origin.y = primaryScreen->_screen.frame.size.height - f.size.height - f.origin.y;
    return [Rect2d from: f];
}





/** group Dark mode */

/** static inDarkMode(): boolean; */

+ (NSNumber*) inDarkMode {
    if (@available(macOS 10.14, *)) {
        return [NSApp.effectiveAppearance.name isEqualToString: NSAppearanceNameDarkAqua] ? @YES : @NO;
    }
    return @NO;
}

/**
 * static darkModeChanged: () => void;
 *
 * Set a callback for when dark mode is turned on or off.
 */
+ (void) darkModeChanged:(NSNotification*)note {
    JSValue* fn = module[@"darkModeChanged"];
    if ([fn isInstanceOf: module.context[@"Function"]]) {
        [fn callWithArguments: @[]];
    }
}




@end
