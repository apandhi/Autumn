//
//  LoadingWordsBuilder.m
//  Autumn
//

#import "LoadingWordsBuilder.h"

@implementation LoadingWordsBuilder

+ (NSString*) makePhrase {
    
    NSArray* verbs = @[@"Loading",
                       @"Constructing",
                       @"Analyzing",
                       @"Deconstructing",
                       @"Validating",
                       @"Preparing",
                       @"Charging",
                       @"Building",
                       @"Establishing",
                       @"Assembling",
                       @"Initializing",
                       @"Implementing",
                       @"Applying"];
    
    NSArray* nouns = @[@"Widgets",
                       @"Components",
                       @"Modules",
                       @"Nodes",
                       @"Units",
                       @"Elements",
                       @"Segments",
                       @"Factors",
                       @"Items",
                       @"Apparatus",
                       @"Infrastructure",
                       @"System"];
    
    return [NSString stringWithFormat: @"%@ %@...",
            [self randomFrom: verbs],
            [self randomFrom: nouns].lowercaseString];
}

+ (NSString*) randomFrom:(NSArray*)list {
    return list[arc4random_uniform((uint32_t)list.count)];
}

@end
