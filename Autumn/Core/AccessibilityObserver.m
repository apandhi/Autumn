//
//  WindowRegistrar.m
//  Autumn
//

#import "AccessibilityObserver.h"
#import "Window.h"

@implementation AccessibilityObserver {
    pid_t pid;
    AXUIElementRef _element;
    
    NSTimer* timer;
    int fails;
    
    CFStringRef eventName;
    void(^fn)(AXUIElementRef);
    AXObserverRef observer;
}

static void callback(AXObserverRef observer, AXUIElementRef element, CFStringRef notification, void * __nullable refcon) {
    AccessibilityObserver* self = (__bridge AccessibilityObserver*)refcon;
    [self eventTriggeredWithElement: element];
}

- (instancetype) initWithElement:(AXUIElementRef)element eventName:(CFStringRef)event handler:(void(^)(AXUIElementRef))handler {
    if (self = [super init]) {
        AXUIElementGetPid(element, &pid);
        _element = element;
        eventName = event;
        fn = handler;
    }
    return self;
}

- (void) startObserving {
    AXError err = AXObserverCreate(pid, callback, &observer);
    if (err != kAXErrorSuccess) {
        observer = nil;
        return;
    }
    
    __weak typeof(self)weakSelf=self;
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
        [weakSelf tryRegisteringForNotification];
    });
}

- (void) tryRegisteringForNotification {
    AXError err = AXObserverAddNotification(observer, _element, eventName, (__bridge void*)self);
    if (err == kAXErrorSuccess) {
        [timer invalidate];
        timer = nil;
        CFRunLoopAddSource(CFRunLoopGetMain(), AXObserverGetRunLoopSource(observer), kCFRunLoopDefaultMode);
    }
    else if (err == kAXErrorCannotComplete) {
        fails++;
        if (fails > 30) {
            // not working after 0.3 seconds; lets just bail
            return;
        }
        __weak typeof(self)weakSelf=self;
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf setTimer];
        });
    }
    else if (err == kAXErrorNotificationUnsupported) {
        NSLog(@"unsupported for %@", _element);
        // pretty common
    }
}

- (void) setTimer {
    __weak typeof(self)weakSelf=self;
    timer = [NSTimer scheduledTimerWithTimeInterval:0.01 repeats:NO block:^(NSTimer * _Nonnull timer) {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
            [weakSelf tryRegisteringForNotification];
        });
    }];
}

- (void) eventTriggeredWithElement:(AXUIElementRef)element {
    fn(element);
}

- (void) stopObserving {
    if (observer) {
        if (timer) {
            [timer invalidate];
        }
        else {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), AXObserverGetRunLoopSource(observer), kCFRunLoopDefaultMode);
            AXObserverRemoveNotification(observer, _element, eventName);
        }
        CFRelease(observer);
    }
}

@end
