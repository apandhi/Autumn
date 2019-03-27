//
//  Files.h
//  Autumn
//

#import <Foundation/Foundation.h>
#import "Module.h"

@protocol JSExport_Files <JSExport>

+ (id) read:(NSString*)path;

+ (NSNumber*) write:(NSString*)path :(NSString*)str;

+ (NSNumber*) mkdir:(NSString*)path;

+ (id) ls:(NSString*)path;

@end

@interface Files : NSObject <JSExport_Files, Module>

@end
