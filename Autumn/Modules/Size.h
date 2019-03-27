//
//  Size.h
//  Autumn
//

#import <Foundation/Foundation.h>
#import "Module.h"

@class Size2d;

@protocol JSExport_Size <JSExport>

+ (Size2d*) empty;
+ (Size2d*) from:(NSSize)size;

@property double width;
@property double height;

- (NSNumber*) equals:(NSSize)other;

@property (readonly) NSNumber* isValid;

- (Size2d*) resizedBy:(CGFloat)w :(CGFloat)h;

@end

NS_ASSUME_NONNULL_BEGIN

@interface Size2d : NSObject <JSExport_Size, Module>

@property NSSize s;

@end

NS_ASSUME_NONNULL_END
