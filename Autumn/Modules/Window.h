//
//  Window.h
//  Autumn
//

#import <Foundation/Foundation.h>
#import "Module.h"
#import "Size.h"
#import "Point.h"
#import "Rect.h"

@class App;
@class Window;
@class Screen;

@protocol JSExport_Window <JSExport>

+ (id) focusedWindow;
+ (id) windowUnderMouse;

+ (NSArray*) allWindows;
+ (NSArray*) visibleWindows;

@property NSNumber* id;
@property App* app;

- (NSArray*) otherWindows:(BOOL)onSameScreen;

- (NSArray*) windowsInDirection:(id)direction;

@property JSValue* onClosed;
@property JSValue* onMoved;
@property JSValue* onResized;
@property JSValue* onMinimized;
@property JSValue* onUnminimized;
@property JSValue* onTitleChanged;

- (void) focus;
- (id) focusNext:(id)direction;

- (NSString*) title;

- (Point2d*) position;
- (void) setPosition:(NSPoint)newPosition;

- (Size2d*) size;
- (void) setSize:(NSSize)newSize;

- (Rect2d*) frame;
- (void) setFrame:(NSRect)newFrame;

- (void) setCenterPoint:(NSPoint)point;

- (void) centerOnScreen:(Screen*)screen;

- (void) moveToPercentOfScreen:(NSRect)unit;

- (void) close;
- (void) setFullScreen:(BOOL)shouldBeFullScreen;
- (void) minimize;
- (void) unminimize;
- (void) maximize;

- (NSNumber*) isNormalWindow;
- (NSNumber*) isFullScreen;
- (NSNumber*) isMinimized;
- (NSNumber*) isVisible;
- (NSNumber*) isMainWindow;

- (Screen*) screen;

@end

@interface Window : NSObject <JSExport_Window, Module>

- (instancetype) initWithElement:(AXUIElementRef)element forApp:(App*)owner;

@property AXUIElementRef element;

// internal
- (void) becomeMain;

+ (void) windowOpened:(Window*)window;
+ (void) windowClosed:(Window*)window;

- (void) startObservingEvents;
- (void) stopObservingEvents;

@end
