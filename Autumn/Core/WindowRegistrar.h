//
//  WindowRegistrar.h
//  Autumn
//

#import <Cocoa/Cocoa.h>
#import "Window.h"

NS_ASSUME_NONNULL_BEGIN

@interface WindowRegistrar : NSObject

+ (WindowRegistrar*) sharedRegistrar;

- (Window*) windowForElement:(AXUIElementRef)winEl;
- (NSArray<Window*>*) allWindows;

// internal

- (void) setup;

- (NSArray<Window*>*) seedWithWindowElements:(NSArray*)windowElements forApp:(App*)owner;
- (Window*) windowElementOpened:(AXUIElementRef)winEl forApp:(App*)owner;
- (Window*) windowElementClosed:(AXUIElementRef)winEl;

@end

NS_ASSUME_NONNULL_END
