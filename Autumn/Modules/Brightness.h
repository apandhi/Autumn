//
//  Brightness.h
//  Autumn
//

#import <Foundation/Foundation.h>
#import "Module.h"

@protocol JSExport_Brightness <JSExport>

+ (NSNumber*) getLevel;
+ (void) setLevel:(NSNumber*)percentages;

@end

@interface Brightness : NSObject <JSExport_Brightness, Module>

@end
