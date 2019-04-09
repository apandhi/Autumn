//
//  Pasteboard.m
//  Autumn
//

#import <Cocoa/Cocoa.h>
#import "Pasteboard.h"

/**
 * module Pasteboard
 *
 * Access information in the pasteboard.
 */
@implementation Pasteboard

/**
 * static stringContents(): string;
 *
 * The most recent string in the pasteboard, or nil.
 */
+ (NSString*) stringContents {
    return [[NSPasteboard generalPasteboard] stringForType:NSPasteboardTypeString];
}

/**
 * static setStringContents(string: contents): boolean;
 *
 * Set the current contents of the clipboard.  Returns whether it succeeded.
 */
+ (NSNumber *) setStringContents:(NSString*)string {
    NSPasteboard* pasteboard = [NSPasteboard generalPasteboard];
    [pasteboard declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
    @try {
        return [pasteboard setString:string forType:NSPasteboardTypeString ] ? @YES : @NO;
    }
    @catch(NSException *) {
        return @NO;
    }
}

/**
 * static changeCount(): number;
 *
 * The number of times the pasteboard has changed so far.
 */
+ (NSNumber*) changeCount {
    return @([[NSPasteboard generalPasteboard] changeCount]);
}

+ (void)startModule:(JSValue *)ctor {
    
}

+ (void)stopModule {
    
}

@end
