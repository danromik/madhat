//
//  MHBoxCommand.m
//  MadHat
//
//  Created by Dan Romik on 9/27/20.
//  Copyright © 2020 Dan Romik. All rights reserved.
//

#import "MHBoxCommand.h"
#import "MHStyleIncludes.h"

NSString * const kMHBoxCommandNameBeginBox = @"begin box";
NSString * const kMHBoxCommandNameEndBox = @"end box";
NSString * const kMHBoxCommandBoxDivider = @"box divider";      // FIXME: add this
NSString * const kMHBoxCommandFrameWidth = @"box frame thickness";


@interface MHBoxCommand ()
{
    MHBoxCommandType _type;
    CGFloat _floatArgument;
}

@end


@implementation MHBoxCommand


#pragma mark - MHCommand protocol


+ (instancetype)commandNamed:(NSString *)name withParameters:(NSDictionary *)parameters argument:(MHHorizontalLayoutContainer *)argument
{
    if ([name isEqualToString:kMHBoxCommandNameBeginBox]) {
        return [self beginBoxCommand];
    }
    else if ([name isEqualToString:kMHBoxCommandNameEndBox]) {
        return [self endBoxCommand];
    }
    else if ([name isEqualToString:kMHBoxCommandBoxDivider]) {
        return [self boxDividerCommand];
    }
    else if ([name isEqualToString:kMHBoxCommandFrameWidth]) {
        return [self boxFrameWidthCommand:[argument floatValue]];
    }
    
    return [super commandNamed:name withParameters:parameters argument:argument];
}

+ (NSArray <NSString *> *)recognizedCommands
{
    return @[
        kMHBoxCommandNameBeginBox,
        kMHBoxCommandNameEndBox,
//        kMHBoxCommandBoxDivider,      // FIXME: add this
        kMHBoxCommandFrameWidth
    ];
}


#pragma mark - Constructors

- (instancetype)initWithBoxCommandType:(MHBoxCommandType)type
{
    if (self = [super init]) {
        _type = type;
    }
    return self;
}

- (instancetype)initWithBoxCommandType:(MHBoxCommandType)type floatArgument:(CGFloat)floatArgument
{
    if (self = [super init]) {
        _type = type;
        _floatArgument = floatArgument;
    }
    return self;
}

+ (instancetype)beginBoxCommand
{
    return [[self alloc] initWithBoxCommandType:MHBoxCommandBeginBox];
}

+ (instancetype)endBoxCommand
{
    return [[self alloc] initWithBoxCommandType:MHBoxCommandEndBox];
}

+ (instancetype)boxDividerCommand
{
    return [[self alloc] initWithBoxCommandType:MHBoxCommandBoxDivider];
}

+ (instancetype)boxFrameWidthCommand:(CGFloat)frameWidth
{
    return [[self alloc] initWithBoxCommandType:MHBoxCommandBoxFrameWidth floatArgument:frameWidth];
}

#pragma mark - Typesetting

- (void)typesetWithContextManager:(MHTypesettingContextManager *)contextManager
{
    switch (_type) {
        case MHBoxCommandBeginBox:
            [contextManager beginBox];
            break;
        case MHBoxCommandEndBox:
            [contextManager endBox];
            break;
        case MHBoxCommandBoxDivider:
            [contextManager markBoxDivider];
            break;
        case MHBoxCommandBoxFrameWidth:
            [contextManager setParagraphFrameThickness:_floatArgument];
            break;
    }
}


#pragma mark - Expression copying

- (instancetype)logicalCopy
{
    return [[[self class] alloc] initWithBoxCommandType:_type floatArgument:_floatArgument];
}


@end
