//
//  DataUtils.h
//  Autumn
//

#import <Foundation/Foundation.h>

@interface DataUtils : NSObject

+ (NSString*) fileAsString:(NSString*)filename;
+ (NSString*) jsonFromObject:(id)obj;

@end
