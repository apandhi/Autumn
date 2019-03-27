//
//  Alert.h
//  Autumn
//

#import <Cocoa/Cocoa.h>

@interface Alert : NSWindowController

+ (void) show:(NSString*)msg duration:(CGFloat)duration;

@end
