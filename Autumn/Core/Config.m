//
//  Config.m
//  Autumn
//

#import "Config.h"
#import "DataUtils.h"

static NSString* latestConfig;

@implementation Config

+ (void) setShouldStoreInFile:(BOOL)should {
    // using 'userConfigLocation' here in case we later change it into an enum
    [[NSUserDefaults standardUserDefaults] setBool:should forKey:@"userConfigLocation"];
}

+ (BOOL) shouldStoreInFile {
    return [[NSUserDefaults standardUserDefaults] boolForKey: @"userConfigLocation"];
}

+ (NSString*) configPath {
    return @"~/.autumn.js".stringByStandardizingPath;
}

+ (NSString*) loadUserConfig {
    if (!latestConfig) {
        if ([self shouldStoreInFile]) {
            if ([[NSFileManager defaultManager] fileExistsAtPath: self.configPath]) {
                latestConfig = [NSString stringWithContentsOfFile:self.configPath encoding:NSUTF8StringEncoding error:NULL];
            }
        }
        else {
            latestConfig = [[NSUserDefaults standardUserDefaults] stringForKey: @"userConfig"];
        }
        
        if (!latestConfig) {
            latestConfig = [DataUtils fileAsString:@"sample.ts"];
        }
    }
    
    return latestConfig;
}

+ (NSString*) latestUserScript {
    return latestConfig;
}

+ (void) saveUserConfig:(NSString*)config {
    latestConfig = config;
    [self cancelPreviousPerformRequestsWithTarget:self selector:@selector(saveUserConfigImmediately) object:nil];
    [self performSelector:@selector(saveUserConfigImmediately) withObject:nil afterDelay:1.0];
}

+ (void) saveUserConfigImmediately {
    if ([self shouldStoreInFile]) {
        [latestConfig writeToFile: self.configPath atomically:YES encoding:NSUTF8StringEncoding error:NULL];
    }
    else {
        [[NSUserDefaults standardUserDefaults] setObject:latestConfig forKey:@"userConfig"];
    }
}

@end
