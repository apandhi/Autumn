//
//  WindowRegistrar.h
//  Autumn
//

#import <Cocoa/Cocoa.h>
#import "App.h"

NS_ASSUME_NONNULL_BEGIN

@interface AccessibilityObserver : NSObject

- (instancetype) initWithElement:(AXUIElementRef)element eventName:(CFStringRef)event handler:(void(^)(AXUIElementRef))handler;

- (void) startObserving;
- (void) stopObserving;

@end

NS_ASSUME_NONNULL_END
