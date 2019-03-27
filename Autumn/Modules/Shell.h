//
//  Shell.h
//  Autumn
//

#import <Foundation/Foundation.h>
#import "Module.h"

@protocol JSExport_Shell <JSExport>

+ (id) run:(NSString*)cmd;
+ (id) runSync:(NSString*)cmd;

@end

@interface Shell : NSObject <JSExport_Shell, Module>

@end
