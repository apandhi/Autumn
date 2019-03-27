//
//  DataUtils.m
//  Autumn
//

#import "DataUtils.h"

@implementation DataUtils

+ (NSString*) fileAsString:(NSString*)filename {
    NSString* name = [filename stringByDeletingPathExtension];
    NSString* ext = [filename pathExtension];
    NSURL* url = [[NSBundle mainBundle] URLForResource:name withExtension:ext];
    return [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:NULL];
}

+ (NSString*) jsonFromObject:(id)obj {
    NSData* json = [NSJSONSerialization dataWithJSONObject:obj options:0 error:NULL];
    return [[NSString alloc] initWithData:json encoding:NSUTF8StringEncoding];
}

@end
