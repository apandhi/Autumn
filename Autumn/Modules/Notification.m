//
//  NotificationManager.m
//  Autumn
//

#import "Notification.h"

@interface Notification ()

@property (copy) void(^onClick)(void);
@property BOOL forceShow;
@property NSUserNotification* original;

@end

@interface NotificationManager : NSObject <NSUserNotificationCenterDelegate>
@end

@implementation NotificationManager {
    NSMutableDictionary<NSString*, Notification*>* notes;
}

+ (NotificationManager*) sharedManager {
    static NotificationManager* singleton;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        singleton = [[NotificationManager alloc] init];
    });
    return singleton;
}

- (instancetype)init {
    if (self = [super init]) {
        notes = [NSMutableDictionary dictionary];
        [NSUserNotificationCenter defaultUserNotificationCenter].delegate = self;
    }
    return self;
}

- (void) deliver:(Notification*)note {
    if (!note.original.identifier) note.original.identifier = [NSUUID UUID].UUIDString;
    notes[note.original.identifier] = note;
    
    [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification: note.original];
}

- (void) removeNotifications {
    for (Notification* note in notes.allValues) {
        [[NSUserNotificationCenter defaultUserNotificationCenter] removeDeliveredNotification: note.original];
    }
    
    [notes removeAllObjects];
}

- (void)userNotificationCenter:(NSUserNotificationCenter *)center didActivateNotification:(NSUserNotification *)notification {
    Notification* note = notes[notification.identifier];
    if (note) note.onClick(); // may be stale note from another launch?
    [center removeDeliveredNotification: notification];
}

- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)notification {
    Notification* note = notes[notification.identifier];
    return note.forceShow;
}

@end

/**
 * module Notification
 *
 * Show notifications in Notification Center.
 */
@implementation Notification

+ (void) deliverNotification:(NSUserNotification*)notification onClick:(void(^)(void))clicked forceShow:(BOOL)forceShow {
    Notification* note = [[Notification alloc] init];
    note.original = notification;
    note.onClick = clicked;
    note.forceShow = forceShow;
    [[NotificationManager sharedManager] deliver: note];
}

/**
 * static post(options: {
 *   title: string,
 *   subtitle?: string,
 *   body?: string,
 *   onClick?: () => void
 * }): void;
 *
 * Show a notification in Apple's built-in Notification Center.
 */
+ (void) post:(JSValue*)options {
    NSString* title = options[@"title"].toString;
    JSValue* subtitle = options[@"subtitle"];
    JSValue* body = options[@"body"];
    JSValue* onClick = options[@"onClick"];
    
    NSUserNotification* note = [[NSUserNotification alloc] init];
    note.title = title;
    note.subtitle = subtitle.isString ? subtitle.toObject : nil;
    note.informativeText = body.isString ? body.toString : nil;
    
    [self deliverNotification:note
                      onClick:^{
                          if ([onClick isInstanceOf: onClick.context[@"Function"]]) {
                              [onClick callWithArguments: @[]];
                          }
                      }
                    forceShow:YES];
}

+ (void) removeNotifications {
    [[NotificationManager sharedManager] removeNotifications];
}

+ (void)startModule:(JSValue *)ctor {
}

+ (void)stopModule {
    [[NotificationManager sharedManager] removeNotifications];
}

@end
