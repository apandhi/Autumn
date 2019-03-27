//
//  Mouse.h
//  Autumn
//

#import <Foundation/Foundation.h>
#import "Module.h"
#import "Point.h"

@protocol JSExport_Mouse <JSExport>

+ (Point2d*) position;
+ (void) move:(NSPoint)position;

@end

@interface Mouse : NSObject <JSExport_Mouse, Module>

@end
