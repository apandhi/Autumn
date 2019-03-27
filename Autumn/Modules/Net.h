//
//  Net.h
//  Autumn
//

#import <Foundation/Foundation.h>
#import "Module.h"

@protocol JSExport_Net <JSExport>

+ (JSValue*) get:(NSString*)url;
+ (id) getSync:(NSString*)url;

@end

@interface Net : NSObject <JSExport_Net, Module>

@end
