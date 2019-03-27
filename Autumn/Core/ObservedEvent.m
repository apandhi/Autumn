//
//  ObservedEvent.m
//  Autumn
//

#import "ObservedEvent.h"
#import "AccessibilityObserver.h"

@implementation ObservedEvent {
    AccessibilityObserver* observer;
    CFStringRef _event;
    AXUIElementRef _element;
}

- (instancetype) initWithEvent:(CFStringRef)event ofElement:(AXUIElementRef)element {
    if (self = [super init]) {
        _event = event;
        _element = element;
    }
    return self;
}

- (void) changeObserving:(JSValue*)fn {
    _givenCallback = fn;
    
    [observer stopObserving];
    observer = nil;
    
    if ([fn isInstanceOf: fn.context[@"Function"]]) {
        observer = [[AccessibilityObserver alloc] initWithElement:_element eventName:_event handler:^(AXUIElementRef _Nonnull el) {
            [fn callWithArguments: @[]];
        }];
        [observer startObserving];
    }
}

@end
