//
//  ScreenRegistrar.m
//  Autumn
//

#import "ScreenRegistrar.h"

@implementation ScreenRegistrar {
    NSMapTable<NSScreen*,Screen*>* screenRegistry;
}

+ (ScreenRegistrar*) sharedRegistrar {
    static ScreenRegistrar* singleton;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        singleton = [[ScreenRegistrar alloc] init];
    });
    return singleton;
}

- (void) setup {
    screenRegistry = [NSMapTable strongToStrongObjectsMapTable];
    
    for (NSScreen* realScreen in [NSScreen screens]) {
        Screen* screen = [[Screen alloc] initWithRealScreen: realScreen];
        [screenRegistry setObject: screen
                           forKey: realScreen];
    }
    
    [NSNotificationCenter.defaultCenter
     addObserver:self
     selector:@selector(screensChanged:)
     name:NSApplicationDidChangeScreenParametersNotification
     object:nil];
}

- (void) screensChanged:(NSNotification*)note {
    NSArray* screens = [NSScreen screens];
    
    NSMutableArray* oldScreens = screenRegistry.keyEnumerator.allObjects.mutableCopy;
    [oldScreens removeObjectsInArray: screens];
    
    NSMutableArray* newScreens = screens.mutableCopy;
    [newScreens removeObjectsInArray: screenRegistry.keyEnumerator.allObjects];
    
    for (NSScreen* oldRealScreen in oldScreens) {
        Screen* oldScreen = [self screenForRealScreen: oldRealScreen];
        [screenRegistry removeObjectForKey: oldRealScreen];
        
        [Screen screenRemoved: oldScreen];
    }
    
    for (NSScreen* newRealScreen in newScreens) {
        Screen* newScreen = [[Screen alloc] initWithRealScreen: newRealScreen];
        [screenRegistry setObject: newScreen
                           forKey: newRealScreen];
        
        [Screen screenAdded: newScreen];
    }
    
    if (!oldScreens.count && !newScreens.count) {
        [Screen screensReconfigured];
    }
}

- (Screen*) screenForRealScreen:(NSScreen*)realScreen {
    return [screenRegistry objectForKey: realScreen];
}

@end
