//
//  MHPenGraphicsCommand.m
//  MadHat
//
//  Created by Dan Romik on 8/6/20.
//  Copyright © 2020 Dan Romik. All rights reserved.
//

#import "MHPenGraphicsCommand.h"
#import "MHTypesettingContextManager+GraphicsStyle.h"

typedef enum {
    MHPenGraphicsSetPenAbsoluteDirectionCommand,
    MHPenGraphicsRotatePenCommand,
    MHPenGraphicsPenUpCommand,
    MHPenGraphicsPenDownCommand
} MHPenGraphicsCommandType;

NSString * const kMHPenGraphicsAbsoluteDirectionCommandName = @"pen direction";
NSString * const kMHPenGraphicsAbsoluteAngleCommandName = @"pen angle";
NSString * const kMHPenGraphicsRotateLeftCommandName = @"turn pen left";
NSString * const kMHPenGraphicsRotateRightCommandName = @"turn pen right";
NSString * const kMHPenGraphicsPenUpCommandName = @"pen up";
NSString * const kMHPenGraphicsPenDownCommandName = @"pen down";
NSString * const kMHPenGraphicsPointPenNorthCommandName = @"turn pen north";
NSString * const kMHPenGraphicsPointPenSouthCommandName = @"turn pen south";
NSString * const kMHPenGraphicsPointPenEastCommandName = @"turn pen east";
NSString * const kMHPenGraphicsPointPenWestCommandName = @"turn pen west";
NSString * const kMHPenGraphicsPointPenNorthEastCommandName = @"turn pen northeast";
NSString * const kMHPenGraphicsPointPenNorthWestCommandName = @"turn pen northwest";
NSString * const kMHPenGraphicsPointPenSouthEastCommandName = @"turn pen southeast";
NSString * const kMHPenGraphicsPointPenSouthWestCommandName = @"turn pen southwest";


@interface MHPenGraphicsCommand ()
{
    MHPenGraphicsCommandType _type;
//    NSDictionary *commandSpecificData;    // maybe use this later if I add enough commands to make it worth the added flexibility
    CGFloat _penRotationAngle;
    CGPoint _penDirection;
}

@end


@implementation MHPenGraphicsCommand


#pragma mark - Constructors

+ (instancetype)penGraphicsCommandWithSetPenAbsoluteDirection:(CGPoint)vector
{
    return [[self alloc] initWithSetPenAbsoluteDirection:vector];
}

- (instancetype)initWithSetPenAbsoluteDirection:(CGPoint)vector
{
    if (self = [super init]) {
        _type = MHPenGraphicsSetPenAbsoluteDirectionCommand;
        _penDirection = vector;
    }
    return self;
}

+ (instancetype)penGraphicsCommandWithRotatePenLeftByAngle:(CGFloat)angle
{
    return [[self alloc] initWithRotatePenLeftByAngle:angle];
}

- (instancetype)initWithRotatePenLeftByAngle:(CGFloat)angle
{
    if (self = [super init]) {
        _type = MHPenGraphicsRotatePenCommand;
        _penRotationAngle = angle;
    }
    return self;
}


+ (instancetype)penGraphicsCommandWithPenSetState:(bool)engaged
{
    return [[self alloc] initWithPenSetState:engaged];
}

- (instancetype)initWithPenSetState:(bool)engaged
{
    if (self = [super init]) {
        _type = (engaged ? MHPenGraphicsPenDownCommand : MHPenGraphicsPenUpCommand);
    }
    return self;
}



#pragma mark - MHCommand protocol

+ (MHExpression *)commandNamed:(NSString *)name withParameters:(NSDictionary *)parameters argument:(MHHorizontalLayoutContainer *)argument
{
    if ([name isEqualToString:kMHPenGraphicsAbsoluteDirectionCommandName]) {
        CGPoint direction = argument.pointValue;
        return [self penGraphicsCommandWithSetPenAbsoluteDirection:direction];
    }

    if ([name isEqualToString:kMHPenGraphicsAbsoluteAngleCommandName]) {
        CGFloat angle = argument.floatValue * M_PI / 180;   // convert from degrees to radians
        CGPoint direction = CGPointMake(cos(angle), sin(angle));
        return [self penGraphicsCommandWithSetPenAbsoluteDirection:direction];
    }

    bool isRotateLeft;
    bool isRotateRight;
    if ((isRotateLeft = [name isEqualToString:kMHPenGraphicsRotateLeftCommandName])
        || (isRotateRight = [name isEqualToString:kMHPenGraphicsRotateRightCommandName])) {
        CGFloat angle = argument.floatValue * M_PI / 180.0;         // convert from degrees to radians
        return [self penGraphicsCommandWithRotatePenLeftByAngle:(isRotateLeft ? angle : -angle)];
    }
    
    bool isPenDown;
    bool isPenUp;
    if ((isPenDown = [name isEqualToString:kMHPenGraphicsPenDownCommandName])
        || (isPenUp = [name isEqualToString:kMHPenGraphicsPenUpCommandName])) {
        return [self penGraphicsCommandWithPenSetState:isPenDown];
    }
    
    if ([name isEqualToString:kMHPenGraphicsPointPenNorthCommandName]) {
        return [self penGraphicsCommandWithSetPenAbsoluteDirection:CGPointMake(0.0, 1.0)];
    }
    if ([name isEqualToString:kMHPenGraphicsPointPenSouthCommandName]) {
        return [self penGraphicsCommandWithSetPenAbsoluteDirection:CGPointMake(0.0, -1.0)];
    }
    if ([name isEqualToString:kMHPenGraphicsPointPenEastCommandName]) {
        return [self penGraphicsCommandWithSetPenAbsoluteDirection:CGPointMake(1.0, 0.0)];
    }
    if ([name isEqualToString:kMHPenGraphicsPointPenWestCommandName]) {
        return [self penGraphicsCommandWithSetPenAbsoluteDirection:CGPointMake(-1.0, 0.0)];
    }
    if ([name isEqualToString:kMHPenGraphicsPointPenNorthEastCommandName]) {
        return [self penGraphicsCommandWithSetPenAbsoluteDirection:CGPointMake(M_SQRT1_2, M_SQRT1_2)];
    }
    if ([name isEqualToString:kMHPenGraphicsPointPenNorthWestCommandName]) {
        return [self penGraphicsCommandWithSetPenAbsoluteDirection:CGPointMake(-M_SQRT1_2, M_SQRT1_2)];
    }
    if ([name isEqualToString:kMHPenGraphicsPointPenSouthEastCommandName]) {
        return [self penGraphicsCommandWithSetPenAbsoluteDirection:CGPointMake(M_SQRT1_2, -M_SQRT1_2)];
    }
    if ([name isEqualToString:kMHPenGraphicsPointPenSouthWestCommandName]) {
        return [self penGraphicsCommandWithSetPenAbsoluteDirection:CGPointMake(-M_SQRT1_2, -M_SQRT1_2)];
    }


    return nil;
}

+ (NSArray <NSString *> *)recognizedCommands
{
    return @[
        kMHPenGraphicsAbsoluteDirectionCommandName,
        kMHPenGraphicsAbsoluteAngleCommandName,
        kMHPenGraphicsRotateLeftCommandName,
        kMHPenGraphicsRotateRightCommandName,
        kMHPenGraphicsPenUpCommandName,
        kMHPenGraphicsPenDownCommandName,
        kMHPenGraphicsPointPenNorthCommandName,
        kMHPenGraphicsPointPenSouthCommandName,
        kMHPenGraphicsPointPenEastCommandName,
        kMHPenGraphicsPointPenWestCommandName,
        kMHPenGraphicsPointPenNorthEastCommandName,
        kMHPenGraphicsPointPenNorthWestCommandName,
        kMHPenGraphicsPointPenSouthEastCommandName,
        kMHPenGraphicsPointPenSouthWestCommandName
    ];
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
//    [super typesetWithContextManager:contextManager];     // FIXME: do we want to call super?
    
    switch (_type) {
        case MHPenGraphicsSetPenAbsoluteDirectionCommand:
            contextManager.penDirection = _penDirection;
            break;
        case MHPenGraphicsRotatePenCommand:
            [contextManager rotatePenByAngle:_penRotationAngle];
            break;
        case MHPenGraphicsPenUpCommand:
            contextManager.penEngaged = false;
            break;
        case MHPenGraphicsPenDownCommand:
            contextManager.penEngaged = true;
            break;
    }
}


#pragma mark - Expression copying

- (instancetype)logicalCopy
{
    MHPenGraphicsCommand *myCopy;
    switch (_type) {
        case MHPenGraphicsSetPenAbsoluteDirectionCommand:
            myCopy = [[self class] penGraphicsCommandWithSetPenAbsoluteDirection:_penDirection];
            break;
        case MHPenGraphicsRotatePenCommand:
            myCopy = [[self class] penGraphicsCommandWithRotatePenLeftByAngle:_penRotationAngle];
            break;
        case MHPenGraphicsPenUpCommand:
            myCopy = [[self class] penGraphicsCommandWithPenSetState:false];
            break;
        case MHPenGraphicsPenDownCommand:
            myCopy = [[self class] penGraphicsCommandWithPenSetState:true];
            break;
    }
    myCopy.codeRange = self.codeRange;
    return myCopy;
}



@end
