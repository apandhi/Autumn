//
//  Accessibility.h
//  Autumn
//

#import <Foundation/Foundation.h>

@protocol AccessibilityStatusObserver <NSObject>
- (void) accessibilityStatusChanged:(BOOL)enabled;
@end

@protocol AccessibilityWarner <NSObject>
- (void) accessibilityNeedsVisibleWarning;
@end

@interface Accessibility : NSObject

+ (void) setup;

+ (void) addObserver:(id<AccessibilityStatusObserver>)observer;
+ (void) removeObserver:(id<AccessibilityStatusObserver>)observer;

+ (void) openPanel;
+ (BOOL) enabled;

+ (void) setWarner:(id<AccessibilityWarner>)warner;
+ (BOOL) warn;

@end
