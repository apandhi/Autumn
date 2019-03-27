//
//  Observer.m
//  Autumn
//

#import "KeyValueObserver.h"

@implementation KeyValueObserver {
    void(^_fn)(void);
}

- (void) observe:(NSString*)prop
              on:(id)on
        callback:(void(^)(void))fn
{
    _fn = fn;
    
    [on addObserver:self
         forKeyPath:prop
            options:0
            context:NULL];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSKeyValueChangeKey,id> *)change
                       context:(void *)context
{
    _fn();
}

@end
