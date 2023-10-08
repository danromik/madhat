//
//  MHGraphicsCommand.m
//  MadHat
//
//  Created by Dan Romik on 7/17/20.
//  Copyright © 2020 Dan Romik. All rights reserved.
//

#import "MHGraphicsCommand.h"
#import "NSBezierPath+QuartzUtilities.h"
#import "MHGraphicsStyle.h"
#import "MHTypesettingContextManager+GraphicsStyle.h"

// Graphics formatting commands
NSString * const kMHGraphicsCommandLineThicknessName = @"line thickness";
NSString * const kMHGraphicsCommandMarkerTypeName = @"marker type";
NSString * const kMHGraphicsCommandMarkerScaleName = @"marker scale";
// the "strokecolor" and "fillcolor" commands are currently handled by the MHColorCommand class

// Graphics formatting/option commands
NSString * const kMHGraphicsCommandLineThicknessKey = @"linethickness";
NSString * const kMHGraphicsCommandMarkerTypeKey = @"markertype";
NSString * const kMHGraphicsCommandMarkerScaleKey = @"markerscale";


// User strings for specifying marker types with the markertype command
NSString * const kMHGraphicsMarkerTypeStringDisk = @"disk";
NSString * const kMHGraphicsMarkerTypeStringSquare = @"square";
NSString * const kMHGraphicsMarkerTypeStringDiamond = @"diamond";
NSString * const kMHGraphicsMarkerTypeStringStar = @"star";
NSString * const kMHGraphicsMarkerTypeStringTriangle = @"triangle";
//NSString * const kMHGraphicsMarkerTypeStringConcentricCircles = @"target";
//NSString * const kMHGraphicsMarkerTypeStringFlag = @"flag";
//NSString * const kMHGraphicsMarkerTypeStringPushpin = @"pushpin";
//NSString * const kMHGraphicsMarkerTypeStringCustom = @"custom";



typedef enum {
    MHGraphicsCommandLineThickness,
    MHGraphicsCommandMarkerScale,
    MHGraphicsCommandMarkerType,
} MHGraphicsCommandType;


@interface MHGraphicsCommand ()
{
    MHGraphicsCommandType _type;
    NSDictionary *_commandSpecificData;     // different commands have different data associated with them, so we store everything in a dictionary
}

@end

@implementation MHGraphicsCommand


#pragma mark - Constructors

+ (MHExpression *)commandNamed:(NSString *)name withParameters:(nullable NSDictionary *)parameters argument:(MHHorizontalLayoutContainer *)argument
{
    if ([name isEqualToString:kMHGraphicsCommandLineThicknessName]) {
        return [self lineThicknessCommand:argument.floatValue];
    }
    if ([name isEqualToString:kMHGraphicsCommandMarkerTypeName]) {
        NSString *markerTypeString = argument.stringValue;
        MHGraphicsMarkerType markerType = MHGraphicsMarkerTypeDisk;
//        if ([markerTypeString isEqualToString:kMHGraphicsMarkerTypeStringDisk])
//            markerType = MHGraphicsMarkerTypeDisk;
        if ([markerTypeString isEqualToString:kMHGraphicsMarkerTypeStringSquare])
            markerType = MHGraphicsMarkerTypeSquare;
        else if ([markerTypeString isEqualToString:kMHGraphicsMarkerTypeStringDiamond])
            markerType = MHGraphicsMarkerTypeDiamond;
        else if ([markerTypeString isEqualToString:kMHGraphicsMarkerTypeStringTriangle])
            markerType = MHGraphicsMarkerTypeTriangle;
        else if ([markerTypeString isEqualToString:kMHGraphicsMarkerTypeStringStar])
            markerType = MHGraphicsMarkerTypeStar;
        return [self markerTypeCommandWithType:markerType];
    }
    if ([name isEqualToString:kMHGraphicsCommandMarkerScaleName]) {
        return [self markerScaleCommand:argument.floatValue];
    }

    return nil;
}

+ (NSArray <NSString *> *)recognizedCommands
{
    return @[
        kMHGraphicsCommandLineThicknessName,
        kMHGraphicsCommandMarkerTypeName,
        kMHGraphicsCommandMarkerScaleName,
        kMHGraphicsCommandLineThicknessName,
        kMHGraphicsCommandMarkerTypeName,
        kMHGraphicsCommandMarkerScaleName
    ];
}



#pragma mark - Constructors

+ (instancetype)lineThicknessCommand:(CGFloat)lineThickness
{
    return [[self alloc] initWithLineThicknessCommand:(CGFloat)lineThickness];
}

- (instancetype)initWithLineThicknessCommand:(CGFloat)lineThickness
{
    if (self = [super init]) {
        _type = MHGraphicsCommandLineThickness;
        _commandSpecificData = @{ kMHGraphicsCommandLineThicknessKey : [NSNumber numberWithFloat:lineThickness] };
    }
    return self;
}

+ (instancetype)markerTypeCommandWithType:(MHGraphicsMarkerType)markerType
{
    return [[self alloc] initWithMarkerTypeCommandWithType:markerType];
}

- (instancetype)initWithMarkerTypeCommandWithType:(MHGraphicsMarkerType)markerType
{
    if (self = [super init]) {
        _type = MHGraphicsCommandMarkerType;
        _commandSpecificData = @{ kMHGraphicsCommandMarkerTypeKey : [NSNumber numberWithInt:markerType] };
    }
    return self;
}

+ (instancetype)markerScaleCommand:(CGFloat)markerScale
{
    return [[self alloc] initWithMarkerScaleCommand:markerScale];
}

- (instancetype)initWithMarkerScaleCommand:(CGFloat)markerScale
{
    if (self = [super init]) {
        _type = MHGraphicsCommandMarkerScale;
        _commandSpecificData = @{ kMHGraphicsCommandMarkerScaleKey : [NSNumber numberWithFloat:markerScale] };
    }
    return self;
}




#pragma mark - Properties

- (MHExpressionPresentationMode)presentationMode
{
    return MHExpressionPresentationModePublishing; // FIXME: temporarily disabling editing mode, need to do some refactoring/debugging to make this work without problems.
    // FIXME: Also disabled it in MHColorCommand
}

#pragma mark - Typesetting

- (void)typesetWithContextManager:(MHTypesettingContextManager *)contextManager
{
//    [super typesetWithContextManager:contextManager]; // FIXME: do we want to call super?

    if (_type == MHGraphicsCommandLineThickness) {
        NSNumber *lineThicknessNumber = _commandSpecificData[kMHGraphicsCommandLineThicknessKey];
        contextManager.lineThickness = [lineThicknessNumber floatValue];
        return;
    }
    if (_type == MHGraphicsCommandMarkerType) {
        NSNumber *markerTypeNumber = _commandSpecificData[kMHGraphicsCommandMarkerTypeKey];
        contextManager.markerType = [markerTypeNumber intValue];
        return;
    }
    if (_type == MHGraphicsCommandMarkerScale) {
        NSNumber *markerScaleNumber = _commandSpecificData[kMHGraphicsCommandMarkerScaleKey];
        contextManager.markerScale = [markerScaleNumber floatValue];
        return;
    }
}


#pragma mark - Expression copying

- (instancetype)logicalCopy
{
    MHGraphicsCommand *myCopy;
    switch (_type) {
        case MHGraphicsCommandLineThickness: {
            NSNumber *lineThicknessNumber = _commandSpecificData[kMHGraphicsCommandLineThicknessKey];
            myCopy = [[self class] lineThicknessCommand:[lineThicknessNumber floatValue]];
        }
            break;
        case MHGraphicsCommandMarkerScale: {
            NSNumber *markerScaleNumber = _commandSpecificData[kMHGraphicsCommandMarkerScaleKey];
            myCopy = [[self class] markerScaleCommand:[markerScaleNumber floatValue]];
        }
            break;
        case MHGraphicsCommandMarkerType: {
            NSNumber *markerTypeNumber = _commandSpecificData[kMHGraphicsCommandMarkerTypeKey];
            myCopy = [[self class]markerTypeCommandWithType:[markerTypeNumber intValue]];
        }
            break;
    }
    myCopy.codeRange = self.codeRange;
    return myCopy;
}



@end
