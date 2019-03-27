//
//  Window.m
//  Autumn
//

#import <AppKit/AppKit.h>
#import "Window.h"
#import "App.h"
#import "FnUtils.h"
#import "Screen.h"
#import "Accessibility.h"
#import "AppRegistrar.h"
#import "WindowRegistrar.h"
#import "ObservedEvent.h"
#import <Carbon/Carbon.h>

/**
 * module Window
 *
 * Functions for managing any open window.
 *
 * Note that Windows always resolve to the same object and can thus be compared with strict object equality (===).
 */
@implementation Window {
    NSNumber* _id;
    
    ObservedEvent* movedEvent;
    ObservedEvent* resizedEvent;
    ObservedEvent* minimizedEvent;
    ObservedEvent* unminimizedEvent;
    ObservedEvent* titleChangedEvent;
}

@synthesize element = _element;
@synthesize app;
@synthesize id = _id;

static JSValue* module;

+ (void)startModule:(JSValue *)ctor {
    module = ctor;
    
    module[@"onWindowOpened"] = [JSValue valueWithUndefinedInContext: module.context];
    module[@"onWindowClosed"] = [JSValue valueWithUndefinedInContext: module.context];
    
    JSValue* dir = module[@"Dir"] = [JSValue valueWithNewObjectInContext: module.context];
    dir[@"Right"] = @0;
    dir[@"Up"]    = @1;
    dir[@"Left"]  = @2;
    dir[@"Down"]  = @3;
}

+ (void)stopModule {
    module = nil;
    
    for (Window* win in Window.allWindows) {
        win.onClosed = nil;
        win.onMoved = nil;
        win.onResized = nil;
        win.onMinimized = nil;
        win.onUnminimized = nil;
        win.onTitleChanged = nil;
    }
}

- (instancetype) initWithElement:(AXUIElementRef)element forApp:(App*)owner {
    if (self = [super init]) {
        _element = CFRetain(element);
        app = owner;
        
        CGWindowID winid;
        extern AXError _AXUIElementGetWindow(AXUIElementRef, CGWindowID* out);
        AXError err = _AXUIElementGetWindow(_element, &winid);
        if (!err)  _id = @(winid);
    }
    return self;
}

- (void) dealloc {
    CFRelease(_element);
}






/** group Getting windows */

/**
 * static focusedWindow(): Window | null;
 *
 * Returns the window that currently has keyboard focus. Returns null sometimes, like if you minimize the focused window to the Dock.
 */
+ (id) focusedWindow {
    if ([Accessibility warn]) return nil;
    
    CFTypeRef winEl;
    AXError result = AXUIElementCopyAttributeValue(App.focusedApp.element, (CFStringRef)NSAccessibilityFocusedWindowAttribute, &winEl);
    if (result != kAXErrorSuccess) return [NSNull null];
    
    Window* win = [WindowRegistrar.sharedRegistrar windowForElement: winEl];
    CFRelease(winEl);
    return win;
}

/**
 * static windowUnderMouse(): Window | null;
 *
 * Returns the window currently under the mouse, if any.
 */
+ (id) windowUnderMouse {
    CGEventRef fakeEvent = CGEventCreate(NULL);
    CGPoint p = CGEventGetLocation(fakeEvent);
    CFRelease(fakeEvent);
    for (Window* win in Window.allWindows) {
        if ([win.frame containsPoint: p].boolValue) {
//            NSLog(@"returning %@", win);
            return win;
        }
    }
//    NSLog(@"nope");
    return [NSNull null];
}

/**
 * static allWindows(): Window[];
 *
 * Returns every window on all screens, ordered from frontmost to backmost.
 */
+ (NSArray*) allWindows {
    if ([Accessibility warn]) return nil;
    
    NSArray<Window*>* allWindows = [FnUtils flatMap:[App allApps] with:^NSArray*(App* app) {
        return [app allWindows];
    }];
    
    NSArray* winids = [self orderedWindowIDs];
    NSMutableArray<Window*>* orderedWindows = [NSMutableArray array];
    
    for (NSNumber* winid in winids) {
        Window* win = [FnUtils findIn:allWindows where:^BOOL(Window* win) {
            return [win.id isEqualToNumber: winid];
        }];
        
        if (win) {
            [orderedWindows addObject: win];
        }
    }
    
    for (Window* win in allWindows) {
        if (![orderedWindows containsObject: win]) {
            [orderedWindows addObject: win];
        }
    }
    
    return orderedWindows;
}

+ (NSArray<NSNumber*>*) orderedWindowIDs {
    NSMutableArray<NSNumber*>* winids = [NSMutableArray array];
    
    CFArrayRef wins = CGWindowListCreate(kCGWindowListOptionOnScreenOnly | kCGWindowListExcludeDesktopElements, kCGNullWindowID);
    
    for (int i = 0; i < CFArrayGetCount(wins); i++) {
        int winid = (int)CFArrayGetValueAtIndex(wins, i);
        [winids addObject: @(winid)];
    }
    
    CFRelease(wins);
    
    return winids;
}

/**
 * static visibleWindows(): Window[];
 *
 * The same as Window.allWindows().filter(win => win.isVisible())
 */
+ (NSArray*) visibleWindows {
    if ([Accessibility warn]) return nil;
    
    return [FnUtils filter:[Window allWindows] with:^BOOL(Window* win) {
        return [win isVisible].boolValue;
    }];
}

static NSPoint RotateCounterClockwise(NSPoint point, NSPoint aroundPoint, int times) {
    NSPoint p = point;
    for (int i = 0; i < times; i++) {
        CGFloat px = p.x;
        p.x = (aroundPoint.x - (p.y - aroundPoint.y));
        p.y = (aroundPoint.y + (px - aroundPoint.x));
    }
    return p;
}


/**
 * windowsInDirection(direction: 'up' | 'down' | 'left' | 'right'): Window[];
 *
 * Returns ordered list of windows in the given direction.
 *
 * Note: This uses a ray-tracing algorithm to give a generally useful but inexact interpretation of windows in this direction.
 */
- (NSArray*) windowsInDirection:(id)direction {
    if ([Accessibility warn]) return nil;
    
    int dir = 0;
    if ([direction isKindOfClass: [NSNumber class]]) {
        dir = ((NSNumber*)direction).intValue;
    }
    else if ([direction isKindOfClass: [NSString class]]) {
        if      ([direction isEqualToString: @"right"]) dir = 0;
        else if ([direction isEqualToString: @"up"])    dir = 1;
        else if ([direction isEqualToString: @"left"])  dir = 2;
        else if ([direction isEqualToString: @"down"])  dir = 3;
    }
    
    // assume looking to east
    
    // use the score distance/cos(A/2), where A is the angle by which it
    // differs from the straight line in the direction you're looking
    // for. (may have to manually prevent division by zero.)
    
//    NSRect selfFrame = self.frame;
//    NSPoint startingPoint = NSZeroPoint;
//    if (direction.intValue == 0) /* Right */ startingPoint = NSMakePoint(NSMinX(selfFrame), NSMidY(selfFrame));
//    if (direction.intValue == 1) /* Up */    startingPoint = NSMakePoint(NSMidX(selfFrame), NSMaxY(selfFrame));
//    if (direction.intValue == 2) /* Left */  startingPoint = NSMakePoint(NSMaxX(selfFrame), NSMidY(selfFrame));
//    if (direction.intValue == 3) /* Down */  startingPoint = NSMakePoint(NSMidX(selfFrame), NSMinY(selfFrame));
    NSPoint startingPoint = self.frame.centerPoint.p;
    
    NSArray* otherWindows = [FnUtils filter:[Window allWindows] with:^BOOL(Window* win) {
        return (win.isVisible.boolValue && win.isNormalWindow.boolValue && self != win);
    }];
    
    NSMutableArray* orderedWindows = [NSMutableArray array];
    
    int position = 0;
    for (Window* win in otherWindows) {
        NSPoint otherPoint = RotateCounterClockwise(win.frame.centerPoint.p,
                                                    startingPoint,
                                                    dir);
        
        NSPoint delta = NSMakePoint(otherPoint.x - startingPoint.x,
                                    otherPoint.y - startingPoint.y);
        
        if (delta.x > 0) {
            double angle = atan2(delta.y, delta.x);
            double distance = hypot(delta.x, delta.y);
            double angleDiff = -angle;
            double score = (distance / cos(angleDiff / 2.0)) + (++position);
            
            [orderedWindows addObject: @{@"score": @(score),
                                         @"win": win}];
        }
        
    }
    
    [orderedWindows sortUsingComparator:^NSComparisonResult(NSDictionary* _Nonnull a, NSDictionary* _Nonnull b) {
        return [a[@"score"] compare: b[@"score"]];
    }];
    
    return [FnUtils map:orderedWindows with:^Window*(NSDictionary* dict) {
        return dict[@"win"];
    }];
}

/**
 * otherWindows(onSameScreen: boolean = true): Window[];
 *
 * Returns all windows except this one, optionally limiting results to this window's screen.
 */
- (NSArray*) otherWindows:(BOOL)onSameScreen {
    if ([Accessibility warn]) return nil;
    
    return [FnUtils filter:[Window visibleWindows] with:^BOOL(Window* win) {
        if (onSameScreen) {
            return self != win && self.screen != win.screen;
        }
        else {
            return self != win;
        }
    }];
}










/** group Window events */

/**
 * static onWindowOpened: (win: Window) => void;
 *
 * Set a callback for when a new window opens.
 */
+ (void) windowOpened:(Window*)window {
    JSValue* fn = module[@"onWindowOpened"];
    if ([fn isInstanceOf: fn.context[@"Function"]]) {
        [fn callWithArguments: @[window]];
    }
}

/**
 * static onWindowClosed: (win: Window) => void;
 *
 * Set a callback for when any window closes.
 *
 * Note: This is probably only useful for comparing closed windows to ones you have stored, since most of its methods may return null at this point.
 */
+ (void) windowClosed:(Window*)window {
    JSValue* fn = module[@"onWindowClosed"];
    if ([fn isInstanceOf: fn.context[@"Function"]]) {
        [fn callWithArguments: @[window]];
    }
    
    JSValue* instanceFn = window.onClosed;
    if ([instanceFn isInstanceOf: instanceFn.context[@"Function"]]) {
        [instanceFn callWithArguments: @[]];
    }
}

/**
 * onClosed: () => void;
 *
 * Set a callback for when this window closes.
 *
 * Note: This is probably only useful for comparing closed windows to ones you have stored or releasing some resources, since most of its methods may return null at this point.
 */
@synthesize onClosed;

/**
 * onMoved: () => void;
 *
 * Set a callback for when this window is moved.
 */
- (JSValue *)onMoved { return movedEvent.givenCallback; }
- (void)setOnMoved:(JSValue *)callback { [movedEvent changeObserving: callback]; }

/**
 * onResized: () => void;
 *
 * Set a callback for when this window is resized.
 */
- (JSValue *)onResized { return resizedEvent.givenCallback; }
- (void)setOnResized:(JSValue *)callback { [resizedEvent changeObserving: callback]; }

/**
 * onMinimized: () => void;
 *
 * Set a callback for when this window is minimized.
 */
- (JSValue *)onMinimized { return minimizedEvent.givenCallback; }
- (void)setOnMinimized:(JSValue *)callback { [minimizedEvent changeObserving: callback]; }

/**
 * onUnminimized: () => void;
 *
 * Set a callback for when this window is unminimized.
 */
- (JSValue *)onUnminimized { return unminimizedEvent.givenCallback; }
- (void)setOnUnminimized:(JSValue *)callback { [unminimizedEvent changeObserving: callback]; }

/**
 * onTitleChanged: () => void;
 *
 * Set a callback for when this window's title changes.
 */
- (JSValue *)onTitleChanged { return titleChangedEvent.givenCallback; }
- (void)setOnTitleChanged:(JSValue *)callback { [titleChangedEvent changeObserving: callback]; }

- (void) startObservingEvents {
    movedEvent        = [[ObservedEvent alloc] initWithEvent:kAXWindowMovedNotification ofElement:_element];
    resizedEvent      = [[ObservedEvent alloc] initWithEvent:kAXWindowResizedNotification ofElement:_element];
    minimizedEvent    = [[ObservedEvent alloc] initWithEvent:kAXWindowMiniaturizedNotification ofElement:_element];
    unminimizedEvent  = [[ObservedEvent alloc] initWithEvent:kAXWindowDeminiaturizedNotification ofElement:_element];
    titleChangedEvent = [[ObservedEvent alloc] initWithEvent:kAXTitleChangedNotification ofElement:_element];
}

- (void) stopObservingEvents {
    [movedEvent        changeObserving: nil];
    [resizedEvent      changeObserving: nil];
    [minimizedEvent    changeObserving: nil];
    [unminimizedEvent  changeObserving: nil];
    [titleChangedEvent changeObserving: nil];
}











/** group Window properties */

/**
 * id: number;
 *
 * Unique identifier for this window.
 *
 * Note: this is not strictly needed for comparison, since Windows can be compared with strict object equality (w1 === w2).
 */

/**
 * title(): string;
 *
 * Returns the current title of the window.
 */
- (NSString*) title {
    if ([Accessibility warn]) return nil;
    
    return [self getWindowProp: NSAccessibilityTitleAttribute];
}

/**
 * app: App;
 *
 * The app that the window belongs to.
 */

/**
 * screen(): Screen;
 *
 * Returns the screen that this window is mostly on.
 */
- (Screen*) screen {
    if ([Accessibility warn]) return nil;
    
    Rect2d* windowFrame = [self frame];
    
    CGFloat lastVolume = 0;
    Screen* lastScreen;
    
    for (Screen* screen in [Screen allScreens]) {
        Rect2d* screenFrame = [screen fullFrame];
        Rect2d* intersection = [windowFrame intersection: screenFrame.r];
        CGFloat volume = intersection.width * intersection.height;
        
        if (volume > lastVolume) {
            lastVolume = volume;
            lastScreen = screen;
        }
    }
    
    return lastScreen;
}







/** group Moving windows */

- (id) getWindowProp:(NSString*)propType {
    CFTypeRef _someProperty;
    if (AXUIElementCopyAttributeValue(_element, (CFStringRef)propType, &_someProperty) == kAXErrorSuccess)
        return CFBridgingRelease(_someProperty);
    
    return nil;
}

/**
 * position(): Point;
 *
 * Get the window's position, based on the top-left of the screen.
 */
- (Point2d*) position {
    if ([Accessibility warn]) return nil;
    
    AXValueRef positionStorage = NULL;
    AXError result = AXUIElementCopyAttributeValue(_element, (CFStringRef)NSAccessibilityPositionAttribute, (CFTypeRef*)&positionStorage);
    if (result == kAXErrorSuccess && positionStorage) {
        CGPoint position;
        AXValueGetValue(positionStorage, kAXValueCGPointType, &position);
        CFRelease(positionStorage);
        return [Point2d from: position];
    }
    return [Point2d empty];
}

/**
 * setPosition(position: PointLike): void;
 *
 * Set the window's position, based on the top-left of the screen.
 *
 * If the position being set contains NaN or Infinity, this is a no-op.
 */
- (void) setPosition:(NSPoint)point {
    if ([Accessibility warn]) return;
    
    Point2d* thePoint = [Point2d from: point];
    if (!thePoint.isValid.boolValue) return;
    
    CFTypeRef positionStorage = (CFTypeRef)(AXValueCreate(kAXValueCGPointType, (const void *)&point));
    AXUIElementSetAttributeValue(_element, (CFStringRef)NSAccessibilityPositionAttribute, positionStorage);
    CFRelease(positionStorage);
}

/**
 * size(): Size;
 *
 * Get the window's size.
 */
- (Size2d*) size {
    if ([Accessibility warn]) return nil;
    
    AXValueRef intermediate = NULL;
    AXError result = AXUIElementCopyAttributeValue(_element, (CFStringRef)NSAccessibilitySizeAttribute, (CFTypeRef*)&intermediate);
    if (result == kAXErrorSuccess && intermediate) {
        CGSize size;
        AXValueGetValue(intermediate, kAXValueCGSizeType, &size);
        CFRelease(intermediate);
        return [Size2d from: size];
    }
    return [Size2d empty];
}

/**
 * setSize(size: SizeLike): void;
 *
 * Set the window's size.
 *
 * If the size being set contains NaN or Infinity, this is a no-op.
 */
- (void) setSize:(NSSize)size {
    if ([Accessibility warn]) return;
    
    Size2d* theSize = [Size2d from: size];
    if (!theSize.isValid.boolValue) return;
    
    BOOL isITerm = [app.bundleId isEqualToString: @"com.googlecode.iterm2"];
    
    if (isITerm) {
        CGEventSourceRef source = CGEventSourceCreate(kCGEventSourceStateCombinedSessionState);
        CGEventRef keyevent = CGEventCreateKeyboardEvent(source, kVK_Control, true);
        CGEventSetFlags(keyevent, kCGEventFlagMaskControl);
        CGEventPostToPid(app.pid, keyevent);
        CFRelease(keyevent);
        CFRelease(source);
    }
    
    CFTypeRef intermediate = (CFTypeRef)(AXValueCreate(kAXValueCGSizeType, (const void *)&size));
    AXUIElementSetAttributeValue(_element, (CFStringRef)NSAccessibilitySizeAttribute, intermediate);
    CFRelease(intermediate);
    
    if (isITerm) {
        CGEventSourceRef source = CGEventSourceCreate(kCGEventSourceStateCombinedSessionState);
        CGEventRef keyevent = CGEventCreateKeyboardEvent(source, kVK_Control, false);
        CGEventSetFlags(keyevent, kCGEventFlagMaskControl);
        CGEventPostToPid(app.pid, keyevent);
        CFRelease(keyevent);
        CFRelease(source);
    }
}

/**
 * frame(): Rect;
 *
 * Get the window's size and position.
 */
- (Rect2d*) frame {
    if ([Accessibility warn]) return nil;
    
    Size2d* s = self.size;
    Point2d* p = self.position;
    return [Rect2d from: NSMakeRect(p.x, p.y, s.width, s.height)];
}

/**
 * setFrame(frame: RectLike): void;
 *
 * Set the window's size and position.
 *
 * If the frame being set contains NaN or Infinity, this is a no-op.
 */
- (void) setFrame:(NSRect)frame {
    if ([Accessibility warn]) return;
    
    [self setSize: frame.size];
    [self setPosition: frame.origin];
    [self setSize: frame.size];
}

/**
 * moveToPercentOfScreen(unit: RectLike): void;
 *
 * Sets this window's position and size, where x, y, width and height are each between 0.0 and 1.0 of the window's current screen.
 */
- (void) moveToPercentOfScreen:(NSRect)unit {
    if ([Accessibility warn]) return;
    
    Rect2d* screenRect = [[self screen] innerFrame];
    NSRect newFrame = NSMakeRect(screenRect.x + (unit.origin.x * screenRect.width),
                                 screenRect.y + (unit.origin.y * screenRect.height),
                                 unit.size.width * screenRect.width,
                                 unit.size.height * screenRect.height);
    
    [self setFrame: newFrame];
}

/**
 * setCenterPoint(point: PointLike): void;
 *
 * Move this window so that its center is at `point`.
 *
 * Doesn't resize the window at all, even if that means it will be partly off-screen.
 */
- (void) setCenterPoint:(NSPoint)point {
    NSSize size = self.size.s;
    NSPoint newTopLeft = NSMakePoint(point.x - (size.width / 2.0),
                                     point.y - (size.height / 2.0));
    [self setPosition: newTopLeft];
}

/**
 * centerOnScreen(screen?: Screen = this.screen()): void;
 *
 * Move this window to the center of the screen without resizing it.
 *
 * @param screen Defaults to the window's current screen.
 */
- (void) centerOnScreen:(Screen*)screen {
    screen = screen ?: self.screen;
    NSRect winFrame = self.frame.r;
    NSRect screenFrame = screen.innerFrame.r;
    NSPoint position = winFrame.origin;
    position.x = screenFrame.origin.x + ((screenFrame.size.width - winFrame.size.width) / 2.0);
    position.y = screenFrame.origin.y + ((screenFrame.size.height - winFrame.size.height) / 2.0);
    [self setPosition: position];
}










/** group Window actions */

/**
 * focus(): void;
 *
 * Focus this window, focusing its app if necessary.
 */
- (void) focus {
    if ([Accessibility warn]) return;
    
    [self becomeMain];
    [self.app internal_bringToFront:NO];
}

/**
 * focusNext(direction: 'up' | 'down' | 'left' | 'right'): Window | null;
 *
 * Focuses the next window in the given direction, if any.
 *
 * Note: This uses a ray-tracing algorithm to give a generally useful but inexact interpretation of windows in this direction.
 */

- (id) focusNext:(id)direction {
    Window* win = [self windowsInDirection: direction].firstObject;
    [win focus];
    return win ?: [NSNull null];
}

/**
 * close(): void;
 *
 * Same as clicking the close button on the window. May prompt and leave the window open, if it has unsaved data.
 */
- (void) close {
    if ([Accessibility warn]) return;
    
//    BOOL worked = NO;
    AXUIElementRef button = NULL;
    
    if (AXUIElementCopyAttributeValue(_element, kAXCloseButtonAttribute, (CFTypeRef*)&button) != kAXErrorSuccess) goto cleanup;
    if (AXUIElementPerformAction(button, kAXPressAction) != kAXErrorSuccess) goto cleanup;
//    worked = YES;
    
cleanup:
    if (button) CFRelease(button);
//    return worked;
}

/**
 * setFullScreen(shouldBeFullScreen: boolean): void;
 *
 * Toggles whether the window should be full screen.
 */
- (void) setFullScreen:(BOOL)shouldBeFullScreen {
    if ([Accessibility warn]) return;
    
    AXUIElementSetAttributeValue(_element, CFSTR("AXFullScreen"), shouldBeFullScreen ? kCFBooleanTrue : kCFBooleanFalse);
}

/**
 * minimize(): void;
 *
 * Minimizes the window to the Dock.
 */
- (void) minimize {
    if ([Accessibility warn]) return;
    
    AXUIElementSetAttributeValue(_element, (CFStringRef)(NSAccessibilityMinimizedAttribute), kCFBooleanTrue);
}

/**
 * unminimize(): void;
 *
 * Unminimizes the window from the Dock.
 */
- (void) unminimize {
    if ([Accessibility warn]) return;
    
    AXUIElementSetAttributeValue(_element, (CFStringRef)(NSAccessibilityMinimizedAttribute), kCFBooleanFalse);
}

/**
 * maximize(): void;
 *
 * Sets the window's frame to the maximum size on its current screen.
 *
 * Note: this does not make the window full screen, use `setFullScreen` for that.
 */
- (void) maximize {
    if ([Accessibility warn]) return;
    
    Rect2d* screenRect = self.screen.innerFrame;
    [self setFrame: screenRect.r];
}

/**
 * isNormalWindow(): boolean;
 *
 * Returns whether the window is not a panel and not minized.
 */
- (NSNumber*) isNormalWindow {
    if ([Accessibility warn]) return nil;
    
    return [[self getWindowProp: NSAccessibilitySubroleAttribute] isEqualToString: (NSString*)kAXStandardWindowSubrole] ? @YES : @NO;
}

/**
 * isFullScreen(): boolean;
 *
 * Returns whether the window is full screen.
 */
- (NSNumber*) isFullScreen {
    if ([Accessibility warn]) return nil;
    
    CFBooleanRef fullscreen;
    if (AXUIElementCopyAttributeValue(_element, CFSTR("AXFullScreen"), (CFTypeRef*)&fullscreen) != kAXErrorSuccess) return nil;
    return (__bridge NSNumber*)fullscreen;
}

/**
 * isMinimized(): boolean;
 *
 * Returns whether the window is minimized to the Dock.
 */
- (NSNumber*) isMinimized {
    if ([Accessibility warn]) return nil;
    
    CFBooleanRef isMinimized;
    if (AXUIElementCopyAttributeValue(_element, (CFStringRef)(NSAccessibilityMinimizedAttribute), (CFTypeRef*)&isMinimized) != kAXErrorSuccess) return nil;
    return (__bridge NSNumber*)isMinimized;
}

/**
 * isVisible(): boolean;
 *
 * Returns true if the app is not hidden and the window is not minimized.
 */
- (NSNumber*) isVisible {
    if ([Accessibility warn]) return nil;
    
    return (!self.app.isHidden.boolValue && !self.isMinimized.boolValue) ? @YES : @NO;
}

- (void) becomeMain {
    AXUIElementSetAttributeValue(_element, kAXMainAttribute, kCFBooleanTrue);
}

/**
 * isMainWindow(): boolean;
 *
 * Returns true if this is currently the main window of the app it belongs to.
 */
- (NSNumber*) isMainWindow {
    CFBooleanRef boolean;
    AXError err = AXUIElementCopyAttributeValue(_element, kAXMainAttribute, (CFTypeRef*)&boolean);
    if (err != kAXErrorSuccess) return @NO;
    return (__bridge_transfer NSNumber*)boolean;
}

@end
