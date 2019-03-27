//
//  Config.h
//  Autumn
//

#import <Foundation/Foundation.h>

@interface Config : NSObject

+ (NSString*) loadUserConfig;
+ (void) saveUserConfig:(NSString*)config;
+ (void) saveUserConfigImmediately;

+ (NSString*) latestUserScript;

+ (void) setShouldStoreInFile:(BOOL)should;
+ (BOOL) shouldStoreInFile;

+ (NSString*) configPath;

@end
