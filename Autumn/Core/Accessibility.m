//
//  Accessibility.m
//  Autumn
//

#import "Accessibility.h"

static BOOL enabled;
static NSMutableArray<AccessibilityStatusObserver>* observers;
static __weak id<AccessibilityWarner> _warner;

@implementation Accessibility

+ (void) setup {
    observers = [NSMutableArray<AccessibilityStatusObserver> array];
    
    [[NSDistributedNotificationCenter defaultCenter] addObserver:self
                                                        selector:@selector(accessibilityChanged:)
                                                            name:@"com.apple.accessibility.api"
                                                          object:nil];
    
    [self recache];
}

+ (void) addObserver:(id<AccessibilityStatusObserver>)observer {
    [observers addObject: observer];
    [observer accessibilityStatusChanged: Accessibility.enabled];
}

+ (void) removeObserver:(id<AccessibilityStatusObserver>)observer {
    dispatch_async(dispatch_get_main_queue(), ^{
        [observers removeObject: observer];
    });
}

+ (void) accessibilityChanged:(NSNotification*)note {
    [self recache];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self recache];
    });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.00 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self recache];
    });
}

+ (BOOL) enabled {
    return enabled;
}

+ (void) recache {
    BOOL lastEnabled = enabled;
    enabled = AXIsProcessTrustedWithOptions(NULL);
    if (lastEnabled != enabled) {
        for (id<AccessibilityStatusObserver> observer in observers) {
            [observer accessibilityStatusChanged: enabled];
        }
    }
}

+ (void) openPanel {
    NSDictionary *options = @{(__bridge id)kAXTrustedCheckOptionPrompt: @YES};
    AXIsProcessTrustedWithOptions((CFDictionaryRef)options);
}

+ (void) setWarner:(id<AccessibilityWarner>)warner {
    _warner = warner;
}

+ (BOOL) warn {
    if (enabled) return NO;
    [_warner accessibilityNeedsVisibleWarning];
    return YES;
}

@end
