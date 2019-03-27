//
//  Keycodes.h
//  Autumn
//

#import <Foundation/Foundation.h>
#import "Module.h"

@protocol JSExport_Keyboard <JSExport>

+ (void) press:(NSString*)keyString :(NSArray*)mods :(JSValue*)opts;

@end

@interface Keyboard : NSObject <JSExport_Keyboard, Module>

+ (NSDictionary<NSString*, NSNumber*>*) keyCodes;

@end
