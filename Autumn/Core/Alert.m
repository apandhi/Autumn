//
//  Alert.m
//  Autumn
//

#import "Alert.h"

static NSMutableArray* visibleAlerts;

@interface Alert () <NSWindowDelegate>
@end

@implementation Alert {
    NSWindow* win;
    NSTextField* textField;
    NSBox* box;
}

+ (void) show:(NSString*)msg duration:(CGFloat)duration {
    if (!visibleAlerts)
        visibleAlerts = [NSMutableArray array];
    
    CGFloat absoluteTop;
    
    NSScreen* currentScreen = [NSScreen mainScreen];
    
    if ([visibleAlerts count] == 0) {
        CGRect screenRect = [currentScreen frame];
        absoluteTop = screenRect.size.height / 1.55; // pretty good spot
    }
    else {
        Alert* ctrl = [visibleAlerts lastObject];
        absoluteTop = NSMinY([[ctrl window] frame]) - 3.0;
    }
    
    if (absoluteTop <= 0)
        absoluteTop = NSMaxY([currentScreen visibleFrame]);
    
    Alert* alert = [[Alert alloc] init];
    [alert loadWindow];
    [alert show:msg duration:duration pushDownBy:absoluteTop];
    [visibleAlerts addObject:alert];
}

- (NSWindow*) window {
    return win;
}

- (BOOL) isWindowLoaded {
    return win != nil;
}

- (void) loadWindow {
    BOOL animateOut = YES;
    
    win = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 209, 57)
                                           styleMask:NSWindowStyleMaskBorderless
                                             backing:NSBackingStoreBuffered
                                               defer:YES];
    [win setDelegate: self];
    
    box = [[NSBox alloc] initWithFrame: [[win contentView] bounds]];
    [box setBoxType: NSBoxCustom];
    [box setBorderType: NSLineBorder];
    [box setFillColor: [NSColor colorWithCalibratedWhite:0.0 alpha:0.50]];
    [box setBorderColor: [NSColor colorWithCalibratedWhite:1.0 alpha:0.40]];
    [box setBorderWidth: 1.0];
    [box setCornerRadius: 11.0];
    [box setContentViewMargins: NSMakeSize(0, 0)];
    [box setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
    [[win contentView] addSubview: box];
    
    textField = [[NSTextField alloc] initWithFrame: NSMakeRect(12, 11, 183, 33)];
    [textField setFont: [NSFont systemFontOfSize: 27]];
    [textField setTextColor: [NSColor colorWithCalibratedWhite:1.0 alpha:1.0]];
    [textField setDrawsBackground: NO];
    [textField setBordered: NO];
    [textField setEditable: NO];
    [textField setSelectable: NO];
//    [textField setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
    [box addSubview: textField];
    
    win.backgroundColor = [NSColor clearColor];
    win.opaque = NO;
    win.level = NSFloatingWindowLevel;
    win.ignoresMouseEvents = YES;
    win.animationBehavior = (animateOut ? NSWindowAnimationBehaviorAlertPanel : NSWindowAnimationBehaviorNone);
//    collectionBehavior = NSWindowCollectionBehaviorCanJoinAllSpaces | NSWindowCollectionBehaviorStationary;
}

- (void) show:(NSString*)oneLineMsg duration:(CGFloat)duration pushDownBy:(CGFloat)adjustment {
    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:0.01];
    [[[self window] animator] setAlphaValue:1.0];
    [NSAnimationContext endGrouping];
    
    [self useTitleAndResize:[oneLineMsg description]];
    [self setFrameWithAdjustment:adjustment];
    [self showWindow:self];
    [self performSelector: @selector(fadeWindowOut)
               withObject: nil
               afterDelay: duration];
}

- (void) setFrameWithAdjustment:(CGFloat)pushDownBy {
    NSScreen* currentScreen = [NSScreen mainScreen];
    CGRect screenRect = [currentScreen frame];
    CGRect winRect = [[self window] frame];
    
    winRect.origin.x = (screenRect.size.width / 2.0) - (winRect.size.width / 2.0);
    winRect.origin.y = pushDownBy - winRect.size.height;
    
    [win setFrame:winRect display:NO];
}

- (void) fadeWindowOut {
    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:0.15];
    [[[self window] animator] setAlphaValue:0.0];
    [NSAnimationContext endGrouping];
    
    [self performSelector: @selector(closeAndResetWindow)
               withObject: nil
               afterDelay: 0.15];
}

- (void) closeAndResetWindow {
    [[self window] orderOut:nil];
    [[self window] setAlphaValue:1.0];
    
    [visibleAlerts removeObject: self];
}

- (void) useTitleAndResize:(NSString*)title {
    [[self window] setTitle:title];
    
    textField.stringValue = title;
    [textField sizeToFit];
    
    NSRect windowFrame = [[self window] frame];
    windowFrame.size.width = [textField frame].size.width + 32.0;
    windowFrame.size.height = [textField frame].size.height + 24.0;
    [[self window] setFrame:windowFrame display:YES];
}

- (void) emergencyCancel {
    [[self class] cancelPreviousPerformRequestsWithTarget:self];
    [[self window] orderOut:nil];
    [visibleAlerts removeObject: self];
}

@end
