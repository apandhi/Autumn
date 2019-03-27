//
//  UiStyleManager.h
//  Autumn
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface UiStyleManager : NSObject

+ (instancetype) sharedManager;

- (void) setup;

@property BOOL useStatusMenu;

- (void) addCustomStatusMenuItems:(NSArray<NSMenuItem*>*)items;
- (void) removeCustomStatusMenuItems:(NSArray<NSMenuItem*>*)items;

@end

NS_ASSUME_NONNULL_END
