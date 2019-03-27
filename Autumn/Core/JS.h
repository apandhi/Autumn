//
//  JavaScriptBridge.h
//  Autumn
//

#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>

@interface RunResult: NSObject
@property JSValue* object;
@property NSString* jsonInspectableObject;
@end

@interface JS : NSObject

- (JSValue*) addModule:(id)module;

- (RunResult*) runString:(NSString*)str source:(NSString*)source;
- (NSNumber*) saveResult:(JSValue*)result;

- (void) fixModules;

- (void) warnAndStop:(BOOL)avoidNotification;

@end
