//
//  Files.m
//  Autumn
//

#import "Files.h"

/**
 * module Files
 *
 * Read and write files.
 */
@implementation Files

+ (void)startModule:(JSValue *)ctor {
}

+ (void)stopModule {
}

/**
 * static read(path: string): string | null;
 *
 * Returns the contents of a file as a UTF8 string or nil if anything went wrong.
 *
 * You can use ~ to represent $HOME.
 */
+ (id) read:(NSString*)path {
    NSString* str = [NSString stringWithContentsOfFile:path.stringByStandardizingPath
                                              encoding:NSUTF8StringEncoding
                                                 error:nil];
    return str ?: [NSNull null];
}

/**
 * static write(path: string, contents: string): boolean;
 *
 * Writes the string to the given path, overriding anything that may be there already. Assumes data is UTF8. Returns whether it succeeded.
 *
 * You can use ~ to represent $HOME.
 */
+ (NSNumber*) write:(NSString*)path :(NSString*)str {
    return [str writeToFile:path.stringByStandardizingPath atomically:YES encoding:NSUTF8StringEncoding error:nil] ? @YES : @NO;
}

/**
 * static mkdir(path: string): boolean;
 *
 * Same as `mkdir -p path`. Returns whether it succeeded.
 *
 * You can use ~ to represent $HOME.
 */

+ (NSNumber*) mkdir:(NSString*)path {
    return ([[NSFileManager defaultManager] createDirectoryAtPath:path.stringByStandardizingPath
                                      withIntermediateDirectories:YES
                                                       attributes:nil
                                                            error:nil]
            ? @YES
            : @NO);
}

/**
 * static ls(path: string): string[] | null;
 *
 * Returns an array of filenames inside the directory at path, or null if anything went wrong (e.g. path doesn't exist or is a file).
 *
 * You can use ~ to represent $HOME.
 */

+ (id) ls:(NSString*)path {
    NSArray* files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path.stringByStandardizingPath
                                                                         error:nil];
    return files ?: [NSNull null];
}

@end
