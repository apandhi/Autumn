//
//  ObservedEvent.h
//  Autumn
//

#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface ObservedEvent : NSObject

- (instancetype) initWithEvent:(CFStringRef)event ofElement:(AXUIElementRef)element;

- (void) changeObserving:(nullable JSValue*)maybeCallback;
@property JSValue* givenCallback;

@end

NS_ASSUME_NONNULL_END
