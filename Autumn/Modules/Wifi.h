//
//  Wifi.h
//  Autumn
//

#import <Foundation/Foundation.h>
#import "Module.h"

@protocol JSExport_Wifi <JSExport>

+ (id) networkName;

@end

@interface Wifi : NSObject <JSExport_Wifi, Module>

@end
