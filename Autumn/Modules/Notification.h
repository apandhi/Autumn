//
//  NotificationManager.h
//  Autumn
//

#import <Foundation/Foundation.h>
#import "Module.h"

@protocol JSExport_Notification <JSExport>

+ (void) post:(JSValue*)options;

@end

@interface Notification : NSObject <JSExport_Notification, Module>

+ (void) deliverNotification:(NSUserNotification*)notification
                     onClick:(void(^)(void))clicked
                   forceShow:(BOOL)forceShow;

+ (void) removeNotifications;

@end
