//
//  USB.h
//  Autumn
//

#import <Foundation/Foundation.h>
#import "Module.h"

@protocol JSExport_USB <JSExport>

@end

@interface USB : NSObject <JSExport_USB, Module>

@end
