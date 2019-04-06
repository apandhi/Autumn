//
//  Pasteboard.h
//  Autumn
//

#import <Foundation/Foundation.h>
#import "Module.h"

@protocol JSExport_Pasteboard <JSExport>

+ (NSString*) stringContents;
+ (NSNumber *) setStringContents:(NSString*)string;
+ (NSNumber*) changeCount;

@end

@interface Pasteboard : NSObject <JSExport_Pasteboard, Module>

@end
