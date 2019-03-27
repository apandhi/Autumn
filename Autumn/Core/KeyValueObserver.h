//
//  Observer.h
//  Autumn
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface KeyValueObserver : NSObject

- (void) observe:(NSString*)prop
              on:(id)on
        callback:(void(^)(void))fn;

@end

NS_ASSUME_NONNULL_END
