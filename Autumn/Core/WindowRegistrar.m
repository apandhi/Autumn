//
//  WindowRegistrar.m
//  Autumn
//

#import "WindowRegistrar.h"
#import "Accessibility.h"
#import "App.h"

@interface WindowRegistrar () <AccessibilityStatusObserver>
@end

@implementation WindowRegistrar {
    NSMapTable<id,Window*>* windowRegistry;
}

+ (WindowRegistrar*) sharedRegistrar {
    static WindowRegistrar* singleton;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        singleton = [[WindowRegistrar alloc] init];
    });
    return singleton;
}

- (void) setup {
    windowRegistry = [NSMapTable weakToStrongObjectsMapTable];
    [Accessibility addObserver: self];
}

- (NSArray<Window*>*) seedWithWindowElements:(NSArray*)windowElements forApp:(App*)owner {
    NSMutableArray* windows = [NSMutableArray array];
    
    for (id winEl in windowElements) {
        Window* win = [[Window alloc] initWithElement: (AXUIElementRef)winEl forApp:owner];
        [windows addObject: win];
        
        [windowRegistry setObject: win
                           forKey: winEl];
        
        [win startObservingEvents];
    }
    
    return windows;
}

- (Window*) windowElementOpened:(AXUIElementRef)winEl forApp:(App*)owner {
    Window* win = [[Window alloc] initWithElement: winEl forApp:owner];
    [windowRegistry setObject: win
                       forKey: (__bridge id)winEl];
    [win startObservingEvents];
    return win;
}

- (Window*) windowElementClosed:(AXUIElementRef)winEl {
    Window* win = [self windowForElement: winEl];
    [win stopObservingEvents];
    [windowRegistry removeObjectForKey: (__bridge id)winEl];
    return win;
}

- (void)accessibilityStatusChanged:(BOOL)enabled {
    if (!enabled) {
        for (Window* win in windowRegistry.objectEnumerator) {
            [win stopObservingEvents];
        }
        [windowRegistry removeAllObjects];
    }
}

- (Window*) windowForElement:(AXUIElementRef)winEl {
    return [windowRegistry objectForKey: (__bridge id)winEl];
}

- (NSArray<Window*>*) allWindows {
    return windowRegistry.objectEnumerator.allObjects;
}

@end
