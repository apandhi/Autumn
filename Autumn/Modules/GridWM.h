//
//  GridWM.h
//  Autumn
//

#import <Foundation/Foundation.h>
#import "Module.h"

@class Window;
@class Screen;

@protocol JSExport_GridWM <JSExport>

- (instancetype) init;

@property NSNumber* rows;
@property NSNumber* cols;
@property NSNumber* padding;
@property NSNumber* margin;

- (void) align:(Window*)window;
- (void) alignAll:(Window*)window;

- (void) moveUp:(Window*)win;
- (void) moveDown:(Window*)win;
- (void) moveLeft:(Window*)win;
- (void) moveRight:(Window*)win;

- (void) growAbove:(Window*)win;
- (void) growBelow:(Window*)win;
- (void) growLeft:(Window*)win;
- (void) growRight:(Window*)win;

- (void) fillCurrentColumn:(Window*)win;
- (void) fillCurrentRow:(Window*)win;

- (void) shrinkFromAbove:(Window*)win;
- (void) shrinkFromBelow:(Window*)win;
- (void) shrinkFromLeft:(Window*)win;
- (void) shrinkFromRight:(Window*)win;

- (void) moveToNextScreen:(Window*)win;
- (void) moveToPreviousScreen:(Window*)win;

- (void) moveToCellGroup:(NSRect)cellGroup :(Window*)win :(Screen*)screen;
- (NSRect) approximateCellGroup:(Window*)window;
- (NSRect) fullScreenCellGroup;

@end

@interface GridWM : NSObject <JSExport_GridWM, Module>

@end
