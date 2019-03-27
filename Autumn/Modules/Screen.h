//
//  Screen.h
//  Autumn
//

#import <Cocoa/Cocoa.h>
#import "Module.h"
#import "Rect.h"

@class Screen;

@protocol JSExport_Screen <JSExport>

+ (NSNumber*) inDarkMode;

+ (NSArray*) allScreens;
+ (Screen*) currentScreen;

- (NSArray*) allWindows;
- (NSArray*) visibleWindows;

@property (readonly) NSNumber* id;
@property (readonly) NSString* name;

- (Rect2d*) fullFrame;
- (Rect2d*) innerFrame;

- (Screen*) nextScreen;
- (Screen*) previousScreen;

@end

@interface Screen : NSObject <JSExport_Screen, Module>

- (instancetype) initWithRealScreen:(NSScreen*)realScreen;

+ (void) screenAdded:(Screen*)screen;
+ (void) screenRemoved:(Screen*)screen;
+ (void) screensReconfigured;

@end
