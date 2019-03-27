//
//  Mouse.m
//  Autumn
//

#import "Mouse.h"
#import "Point.h"

/**
 * module Mouse
 *
 * Control the mouse.
 */
@implementation Mouse

/**
 * static position(): Point;
 *
 * Get the current position of the mouse cursor.
 */
+ (Point2d*) position {
    CGEventRef ourEvent = CGEventCreate(NULL);
    CGPoint p = CGEventGetLocation(ourEvent);
    CFRelease(ourEvent);
    return [Point2d from: p];
}

/**
 * static move(position: PointLike): void;
 *
 * Set the current position of the mouse cursor.
 */
+ (void) move:(NSPoint)position {
    CGWarpMouseCursorPosition(position);
}

static JSValue* _onMoved;
static CFMachPortRef port;
static CFRunLoopSourceRef source;

static CGEventRef callback(CGEventTapProxy  proxy, CGEventType type, CGEventRef event, void * __nullable userInfo) {
    CGPoint p = CGEventGetLocation(event);
    [_onMoved callWithArguments: @[[Point2d from: p]]];
    return NULL;
}

static void unregister(void) {
    if (!port) return;
    CFRunLoopRemoveSource(CFRunLoopGetMain(), source, kCFRunLoopCommonModes);
    CFMachPortInvalidate(port);
    CFRelease(source);
    CFRelease(port);
    port = NULL;
}

/**
 * static onMoved: (p: Point) => void;
 *
 * Set a callback for when the mouse is moved.
 */
static void useCallback(JSValue* fn) {
    _onMoved = fn;
    if ([_onMoved isInstanceOf: _onMoved.context[@"Function"]]) {
        if (!port) {
            port = CGEventTapCreate(kCGSessionEventTap, kCGTailAppendEventTap, kCGEventTapOptionListenOnly, CGEventMaskBit(kCGEventMouseMoved), callback, NULL);
            source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, port, 0);
            CFRunLoopAddSource(CFRunLoopGetMain(), source, kCFRunLoopCommonModes);
        }
    }
    else {
        unregister();
    }
}

+ (void)startModule:(JSValue *)ctor {
    [ctor defineProperty:@"onMoved"
              descriptor:@{JSPropertyDescriptorConfigurableKey: @YES,
                           JSPropertyDescriptorGetKey: ^() { return _onMoved; },
                           JSPropertyDescriptorSetKey: ^(JSValue* fn) { useCallback(fn); }}];
}

+ (void)stopModule {
    unregister();
    _onMoved = nil;
}

@end
