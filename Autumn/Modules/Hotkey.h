//
//  Hotkey.h
//  Autumn
//

#import <Foundation/Foundation.h>
#import "Module.h"

@class Hotkey;

@protocol JSExport_Hotkey <JSExport>

+ (id) activate:(id)modifiers :(NSString*)keyCode :(JSValue*)callback;
+ (void) deactivate:(NSNumber*)uid;

@end

@interface Hotkey : NSObject <JSExport_Hotkey, Module>

@end
