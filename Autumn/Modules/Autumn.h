//
//  Autumn.h
//  Autumn
//

#import <Foundation/Foundation.h>
#import "Module.h"

@protocol JSExport_Autumn <JSExport>

+ (void) reloadUserScripts;
+ (void) stop;
+ (void) showWindow;
+ (void) setStatusMenuItems:(JSValue*)items;

@end

@interface Autumn : NSObject <JSExport_Autumn, Module>

@end
