//
//  GridWM.m
//  Autumn
//

#import <Cocoa/Cocoa.h>
#import "GridWM.h"
#import "Window.h"
#import "Screen.h"
#import "Accessibility.h"

/**
 * module GridWM
 *
 * Grid-based window manager class.
 *
 * Think of a GridWM as slicing your screen into a grid of this many equal rows and columns. It has the ability to align windows so they fit perfectly within one of the grid cells, and to move windows to adjacent or arbitrary cells on the grid.
 *
 * To use this class, create a new instance via `new`, set rows and cols, and use its methods within your own hotkey callbacks. See `Hotkey.activate` and the sample code for reference.
 */
@implementation GridWM

+ (void)startModule:(JSValue *)ctor {
    
}

+ (void)stopModule {
    
}

- (instancetype) init {
    if ([Accessibility warn]) return nil;
    if (self = [super init]) {
        cols = @3;
        rows = @2;
        padding = @0;
        margin = @0;
    }
    return self;
}







/** group Configuration */

/**
 * rows: number;
 *
 * The number of rows (height) in this grid.
 *
 * Defaults to 2
 */
@synthesize rows;

/**
 * cols: number;
 *
 * The number of columns (width) in this grid.
 *
 * Defaults to 3
 */
@synthesize cols;

/**
 * padding: number;
 *
 * (Deprecated.) The number of pixels each grid cell is padded by, to add a little spacing between windows.
 *
 * Defaults to 0
 */
@synthesize padding;

/**
 * margin: number;
 *
 * The number of pixels between grid cell, to add a little spacing between windows.
 *
 * Defaults to 0
 */
@synthesize margin;










/** group Aligning windows to the grid */

/**
 * align(win?: Window = Window.focusedWindow()): void;
 *
 * Align this window to the grid.
 */
- (void) align:(Window*)win {
    win = win ?: Window.focusedWindow;
    if ([win isEqual: [NSNull null]]) return;
    
    NSRect group = [self approximateCellGroup: win];
    [self moveToCellGroup:group :win :nil];
}

/**
 * alignAll(wins?: Window[] = Window.visibleWindows()): void;
 *
 * Align all given windows to the grid. Defaults to all visible windows.
 */
- (void) alignAll:(NSArray<Window*>*)wins {
    wins = wins ?: Window.visibleWindows;
    for (Window* win in wins) {
        [self align: win];
    }
}






/** group Moving windows */

/**
 * moveUp(win?: Window = Window.focusedWindow()): void;
 */
- (void) moveUp:(Window*)win {
    win = win ?: Window.focusedWindow;
    if ([win isEqual: [NSNull null]]) return;
    
    NSRect r = [self approximateCellGroup: win];
    r.origin.y = MAX(r.origin.y - 1, 0);
    [self moveToCellGroup:r :win :nil];
}

/**
 * moveDown(win?: Window = Window.focusedWindow()): void;
 */
- (void) moveDown:(Window*)win {
    win = win ?: Window.focusedWindow;
    if ([win isEqual: [NSNull null]]) return;
    
    NSRect r = [self approximateCellGroup: win];
    r.origin.y = MIN(r.origin.y + 1, rows.doubleValue - r.size.height);
    [self moveToCellGroup:r :win :nil];
}

/**
 * moveLeft(win?: Window = Window.focusedWindow()): void;
 */
- (void) moveLeft:(Window*)win {
    win = win ?: Window.focusedWindow;
    if ([win isEqual: [NSNull null]]) return;
    
    NSRect r = [self approximateCellGroup: win];
    r.origin.x = MAX(r.origin.x - 1, 0);
    [self moveToCellGroup:r :win :nil];
}

/**
 * moveRight(win?: Window = Window.focusedWindow()): void;
 */
- (void) moveRight:(Window*)win {
    win = win ?: Window.focusedWindow;
    if ([win isEqual: [NSNull null]]) return;
    
    NSRect r = [self approximateCellGroup: win];
    r.origin.x = MIN(r.origin.x + 1, cols.doubleValue - r.size.width);
    [self moveToCellGroup:r :win :nil];
}







/** group Growing windows */

/**
 * growAbove(win?: Window = Window.focusedWindow()): void;
 */
- (void) growAbove:(Window*)win {
    win = win ?: Window.focusedWindow;
    if ([win isEqual: [NSNull null]]) return;
    
    NSRect r = [self approximateCellGroup: win];
    if (r.origin.y > 0) {
        r.size.height++;
        r.origin.y--;
        [self moveToCellGroup:r :win :nil];
    }
}

/**
 * growBelow(win?: Window = Window.focusedWindow()): void;
 */
- (void) growBelow:(Window*)win {
    win = win ?: Window.focusedWindow;
    if ([win isEqual: [NSNull null]]) return;
    
    NSRect r = [self approximateCellGroup: win];
    r.size.height = MIN(r.size.height + 1, rows.doubleValue - r.origin.y);
    [self moveToCellGroup:r :win :nil];
}

/**
 * growLeft(win?: Window = Window.focusedWindow()): void;
 */
- (void) growLeft:(Window*)win {
    win = win ?: Window.focusedWindow;
    if ([win isEqual: [NSNull null]]) return;
    
    NSRect r = [self approximateCellGroup: win];
    if (r.origin.x > 0) {
        r.size.width++;
        r.origin.x--;
        [self moveToCellGroup:r :win :nil];
    }
}

/**
 * growRight(win?: Window = Window.focusedWindow()): void;
 */
- (void) growRight:(Window*)win {
    win = win ?: Window.focusedWindow;
    if ([win isEqual: [NSNull null]]) return;
    
    NSRect r = [self approximateCellGroup: win];
    r.size.width = MIN(r.size.width + 1, cols.doubleValue - r.origin.x);
    [self moveToCellGroup:r :win :nil];
}

/**
 * fillCurrentColumn(win?: Window = Window.focusedWindow()): void;
 */
- (void) fillCurrentColumn:(Window*)win {
    win = win ?: Window.focusedWindow;
    if ([win isEqual: [NSNull null]]) return;
    
    NSRect r = [self approximateCellGroup: win];
    r.origin.y = 0;
    r.size.height = rows.doubleValue;
    [self moveToCellGroup:r :win :nil];
}

/**
 * fillCurrentRow(win?: Window = Window.focusedWindow()): void;
 */
- (void) fillCurrentRow:(Window*)win {
    win = win ?: Window.focusedWindow;
    if ([win isEqual: [NSNull null]]) return;
    
    NSRect r = [self approximateCellGroup: win];
    r.origin.x = 0;
    r.size.width = cols.doubleValue;
    [self moveToCellGroup:r :win :nil];
}









/** group Shrinking windows */

/**
 * shrinkFromAbove(win?: Window = Window.focusedWindow()): void;
 */
- (void) shrinkFromAbove:(Window*)win {
    win = win ?: Window.focusedWindow;
    if ([win isEqual: [NSNull null]]) return;
    
    NSRect r = [self approximateCellGroup: win];
    if (r.size.height > 1) {
        r.size.height--;
        r.origin.y++;
        [self moveToCellGroup:r :win :nil];
    }
}

/**
 * shrinkFromBelow(win?: Window = Window.focusedWindow()): void;
 */
- (void) shrinkFromBelow:(Window*)win {
    win = win ?: Window.focusedWindow;
    if ([win isEqual: [NSNull null]]) return;
    
    NSRect r = [self approximateCellGroup: win];
    if (r.size.height > 1) {
        r.size.height--;
        [self moveToCellGroup:r :win :nil];
    }
}

/**
 * shrinkFromLeft(win?: Window = Window.focusedWindow()): void;
 */
- (void) shrinkFromLeft:(Window*)win {
    win = win ?: Window.focusedWindow;
    if ([win isEqual: [NSNull null]]) return;
    
    NSRect r = [self approximateCellGroup: win];
    if (r.size.width > 1) {
        r.size.width--;
        r.origin.x++;
        [self moveToCellGroup:r :win :nil];
    }
}

/**
 * shrinkFromRight(win?: Window = Window.focusedWindow()): void;
 */
- (void) shrinkFromRight:(Window*)win {
    win = win ?: Window.focusedWindow;
    if ([win isEqual: [NSNull null]]) return;
    
    NSRect r = [self approximateCellGroup: win];
    if (r.size.width > 1) {
        r.size.width--;
        [self moveToCellGroup:r :win :nil];
    }
}








/** group Moving to other screens */

/**
 * moveToNextScreen(win? Window = Window.focusedWindow()): void;
 */
- (void) moveToNextScreen:(Window*)win {
    win = win ?: Window.focusedWindow;
    if ([win isEqual: [NSNull null]]) return;
    
    [self moveToCellGroup: [self approximateCellGroup: win]
                         : win
                         : win.screen.nextScreen];
}

/**
 * moveToPreviousScreen(win? Window = Window.focusedWindow()): void;
 */
- (void) moveToPreviousScreen:(Window*)win {
    win = win ?: Window.focusedWindow;
    if ([win isEqual: [NSNull null]]) return;
    
    [self moveToCellGroup: [self approximateCellGroup: win]
                         : win
                         : win.screen.previousScreen];
}








/** group Advanced functionality */

/**
 * moveToCellGroup(cellGroup: RectLike, win?: Window, screen?: Screen): void;
 *
 * A cell group is a Rect of the upper-left to bottom-right cells.
 *
 * @param win The window to move, defaults to Window.focusedWindow() if omitted.
 *
 * @param screen The screen to move the window to, defaults to win.screen() if omitted.
 */
- (void) moveToCellGroup:(NSRect)cellGroup :(Window*)win :(Screen*)screen {
    win = win ?: Window.focusedWindow;
    if ([win isEqual: [NSNull null]]) return;
    
    screen = screen ?: win.screen;
    Rect2d* screenRect = [screen.innerFrame insetByX:margin.doubleValue/2.0 Y:margin.doubleValue/2.0];
    
    CGFloat cellWidth = screenRect.width / cols.doubleValue;
    CGFloat cellHeight = screenRect.height / rows.doubleValue;
    
    CGFloat x = (cellGroup.origin.x * cellWidth) + screenRect.leftX;
    CGFloat y = (cellGroup.origin.y * cellHeight) + screenRect.topY;
    CGFloat width = cellGroup.size.width * cellWidth;
    CGFloat height = cellGroup.size.height * cellHeight;
    
    Rect2d* newFrame = [Rect2d from: NSMakeRect(x, y, width, height)];
    newFrame = [newFrame insetByX:padding.doubleValue Y:padding.doubleValue];
    newFrame = [newFrame insetByX:margin.doubleValue/2.0 Y:margin.doubleValue/2.0];
    newFrame = newFrame.integralRect;
    [win setFrame: newFrame.r];
}

/**
 * approximateCellGroup(win: Window): Rect;
 *
 * Returns the Rect representing the cell group that the window currently fits best on.
 */
- (NSRect) approximateCellGroup:(Window*)win {
    if ([win isEqual: [NSNull null]]) return NSZeroRect;
    
    Rect2d* winFrame = win.frame;
    Rect2d* screenRect = win.screen.innerFrame;
    
    CGFloat cellWidth = screenRect.width / cols.doubleValue;
    CGFloat cellHeight = screenRect.height / rows.doubleValue;
    
    NSRect cellFrame;
    cellFrame.origin.x = round((winFrame.x - screenRect.leftX) / cellWidth);
    cellFrame.origin.y = round((winFrame.y - screenRect.topY) / cellHeight);
    cellFrame.size.width = MAX(round(winFrame.width / cellWidth), 1);
    cellFrame.size.height = MAX(round(winFrame.height / cellHeight), 1);
    return cellFrame;
}

/**
 * fullScreenCellGroup(): Rect;
 *
 * Returns a cell group that fits the full screen, based on the current rows and cols.
 */
- (NSRect) fullScreenCellGroup {
    return NSMakeRect(0, 0, cols.doubleValue, rows.doubleValue);
}

@end
