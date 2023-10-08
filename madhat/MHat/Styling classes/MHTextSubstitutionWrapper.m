//
//  MHTextSubstitutionWrapper.m
//  MadHat
//
//  Created by Dan Romik on 8/5/21.
//  Copyright © 2021 Dan Romik. All rights reserved.
//

#import "MHTextSubstitutionWrapper.h"
#import "MHStyleIncludes.h"

NSString * const kMHTextSubstitutionLowercaseCommandName = @"lowercase";
NSString * const kMHTextSubstitutionUppercaseCommandName = @"uppercase";
NSString * const kMHTextSubstitutionRedactCommandName = @"redact";
NSString * const kMHTextSubstitutionObfuscateCommandName = @"obfuscate";

@interface MHTextSubstitutionWrapper ()
{
    MHTextSubstitutionType _substitutionType;
}

@end


@implementation MHTextSubstitutionWrapper


#pragma mark - Constructors


+ (instancetype)textSubstitutionWrapperWithSubstitutionType:(MHTextSubstitutionType)substitutionType contents:(MHExpression *)contents
{
    return [[self alloc] initWithSubstitutionType:substitutionType contents:contents];
}

- (instancetype)initWithSubstitutionType:(MHTextSubstitutionType)substitutionType contents:(MHExpression *)contents
{
    if (self = [super initWithContents:contents]) {
        _substitutionType = substitutionType;
    }
    return self;
}




#pragma mark - MHCommand protocol

+ (MHExpression *)commandNamed:(NSString *)name
                withParameters:(nullable NSDictionary *)parameters
                      argument:(MHHorizontalLayoutContainer *)argument
{
    if ([name isEqualToString:kMHTextSubstitutionLowercaseCommandName]) {
        return [self textSubstitutionWrapperWithSubstitutionType:MHTextSubstitutionLowercase contents:argument];
    }
    if ([name isEqualToString:kMHTextSubstitutionUppercaseCommandName]) {
        return [self textSubstitutionWrapperWithSubstitutionType:MHTextSubstitutionUppercase contents:argument];
    }
    if ([name isEqualToString:kMHTextSubstitutionRedactCommandName]) {
        return [self textSubstitutionWrapperWithSubstitutionType:MHTextSubstitutionRedacted contents:argument];
    }
    if ([name isEqualToString:kMHTextSubstitutionObfuscateCommandName]) {
        return [self textSubstitutionWrapperWithSubstitutionType:MHTextSubstitutionObfuscated contents:argument];
    }
    return nil;
}

+ (NSArray <NSString *> *)recognizedCommands
{
    return @[
        kMHTextSubstitutionLowercaseCommandName,
        kMHTextSubstitutionUppercaseCommandName,
        kMHTextSubstitutionRedactCommandName,
        kMHTextSubstitutionObfuscateCommandName
    ];
}




#pragma mark - Typesetting

- (void)typesetWithContextManager:(MHTypesettingContextManager *)contextManager
{

//    [contextManager beginLocalScope];   // FIXME: do we need this?

    MHTextSubstitutionType currentSubstitutionType = contextManager.textSubstitutionType;
    contextManager.textSubstitutionType = _substitutionType;
    [super typesetWithContextManager:contextManager];
    contextManager.textSubstitutionType = currentSubstitutionType;

//    [contextManager endLocalScope];   // FIXME: do we need this?
}




#pragma mark - Expression copying

- (instancetype)logicalCopy
{
    MHTextSubstitutionWrapper *myCopy = [[self class] textSubstitutionWrapperWithSubstitutionType:_substitutionType
                                                                                         contents:[self.contents logicalCopy]];
    myCopy.codeRange = self.codeRange;
    return myCopy;
}




@end
