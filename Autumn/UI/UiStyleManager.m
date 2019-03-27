//
//  UiStyleManager.m
//  Autumn
//

#import "UiStyleManager.h"

#define DEFAULTS_KEY @"showStatusMenu"


@implementation UiStyleManager {
    BOOL _useStatusMenu;
    
    NSStatusItem* statusItem;
    
    IBOutlet NSMenu* statusMenu;
    IBOutlet __weak NSMenuItem* startingStatusItem;
}

+ (instancetype) sharedManager {
    return [[self alloc] init];
}

- (instancetype) init {
    static UiStyleManager* singleton;
    if (singleton) return singleton;
    
    if (self = [super init]) {
        singleton = self;
    }
    return self;
}

- (void) setup {
    self.useStatusMenu = [NSUserDefaults.standardUserDefaults boolForKey: DEFAULTS_KEY];
}

- (BOOL)useStatusMenu {
    return [NSUserDefaults.standardUserDefaults boolForKey: DEFAULTS_KEY];
}

- (void)setUseStatusMenu:(BOOL)useStatusMenu {
    if (_useStatusMenu == useStatusMenu) return;
    
    _useStatusMenu = useStatusMenu;
    [NSUserDefaults.standardUserDefaults setBool: _useStatusMenu
                                          forKey: DEFAULTS_KEY];
    
    if (_useStatusMenu) {
        [NSApp setActivationPolicy: NSApplicationActivationPolicyAccessory];
        
        statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength: NSSquareStatusItemLength];
        statusItem.button.image = [NSImage imageNamed:@"StatusIcon"];
        statusItem.menu = statusMenu;
    }
    else {
        [NSApp setActivationPolicy: NSApplicationActivationPolicyRegular];
        
        [[NSStatusBar systemStatusBar] removeStatusItem: statusItem];
        statusItem = nil;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [NSApp deactivate];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [NSApp activateIgnoringOtherApps:YES];
        });
    });
}

- (void) addCustomStatusMenuItems:(NSArray<NSMenuItem*>*)items {
    NSInteger i = [statusMenu indexOfItem: startingStatusItem];
    for (NSMenuItem* item in items) {
        [statusMenu insertItem:item atIndex:i++];
    }
}

- (void) removeCustomStatusMenuItems:(NSArray<NSMenuItem*>*)items {
    for (NSMenuItem* item in items) {
        [statusMenu removeItem: item];
    }
}

@end
