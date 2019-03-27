//
//  Module.h
//  Autumn
//

#ifndef Module_h
#define Module_h

#import <JavaScriptCore/JavaScriptCore.h>

@protocol Module <NSObject>

+ (void) startModule:(JSValue*)ctor;
+ (void) stopModule;

@optional

+ (NSString*) overrideName;

@end

#endif /* Module_h */
