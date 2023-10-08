//
//  MHPenGraphicsPrimitive.m
//  MadHat
//
//  Created by Dan Romik on 8/6/20.
//  Copyright © 2020 Dan Romik. All rights reserved.
//

#import "MHPenGraphicsPrimitive.h"
#import "MHTypesettingContextManager+GraphicsStyle.h"

typedef enum {
    MHPenGraphicsMoveToAbsolutePointPrimitive,
    MHPenGraphicsLineToAbsolutePointPrimitive,
    MHPenGraphicsCurveWithAbsolutePointsPrimitive,
    MHPenGraphicsMovePenForward
} MHPenGraphicsPrimitiveSubtype;

// Command names
NSString * const kMHPenGraphicsMoveToCommandName = @"move to";
NSString * const kMHPenGraphicsLineToCommandName = @"line to";
NSString * const kMHPenGraphicsCurveToCommandName = @"curve to";
NSString * const kMHPenGraphicsPenForwardCommandName = @"pen forward";
NSString * const kMHPenGraphicsPenBackwardCommandName = @"pen backward";
// FIXME: Maybe add a "relative curveto" command later?
// FIXME: maybe add a "penmarker" command to show a marker with the pen position and direction


@interface MHPenGraphicsPrimitive ()
{
    MHPenGraphicsPrimitiveSubtype _subtype;
    CGFloat _units;
    CGPoint _point1;
    CGPoint _point2;
    CGPoint _point3;
}

@end


@implementation MHPenGraphicsPrimitive

#pragma mark - Constructors

+ (instancetype)penGraphicsWithMoveToAbsolutePoint:(CGPoint)point
{
    return [[self alloc] initWithMoveToAbsolutePoint:point];
}

- (instancetype)initWithMoveToAbsolutePoint:(CGPoint)point
{
    if (self = [super init]) {
        _type = MHGraphicsPrimitivePath; //MHGraphicsPrimitivePenSubprimitive;
        _subtype = MHPenGraphicsMoveToAbsolutePointPrimitive;
        _drawingMode = kCGPathStroke;
        _point3 = point;
    }
    return self;
}

+ (instancetype)penGraphicsWithLineToAbsolutePoint:(CGPoint)point
{
    return [[self alloc] initWithLineToAbsolutePoint:point];
}

- (instancetype)initWithLineToAbsolutePoint:(CGPoint)point
{
    if (self = [super init]) {
        _type = MHGraphicsPrimitivePath; //MHGraphicsPrimitivePenSubprimitive;
        _subtype = MHPenGraphicsLineToAbsolutePointPrimitive;
        _drawingMode = kCGPathStroke;
        _point3 = point;
    }
    return self;
}

+ (instancetype)penGraphicsWithCurveWithAbsolutePoints:(CGPoint)point1  :(CGPoint)point2  :(CGPoint)point3
{
    return [[self alloc] initWithCurveWithAbsolutePoints:point1  :point2  :point3];
}

- (instancetype)initWithCurveWithAbsolutePoints:(CGPoint)point1  :(CGPoint)point2  :(CGPoint)point3
{
    if (self = [super init]) {
        _type = MHGraphicsPrimitivePath; //MHGraphicsPrimitivePenSubprimitive;
        _subtype = MHPenGraphicsCurveWithAbsolutePointsPrimitive;
        _drawingMode = kCGPathStroke;
        _point1 = point1;
        _point2 = point2;
        _point3 = point3;
    }
    return self;
}

+ (instancetype)penGraphicsWithPenMoveForward:(CGFloat)units
{
    return [[self alloc] initWithPenMoveForward:units];
}

- (instancetype)initWithPenMoveForward:(CGFloat)units
{
    if (self = [super init]) {
        _type = MHGraphicsPrimitivePenSubprimitive;
        _subtype = MHPenGraphicsMovePenForward;
        _drawingMode = kCGPathStroke;
        _units = units;
    }
    return self;
}



#pragma mark - MHCommand protocol

+ (instancetype)commandNamed:(NSString *)name withParameters:(nullable NSDictionary *)parameters argument:(MHHorizontalLayoutContainer *)argument
{
    if ([name isEqualToString:kMHPenGraphicsMoveToCommandName]) {
        CGPoint point = argument.pointValue;
        return [[self class] penGraphicsWithMoveToAbsolutePoint:point];
    }

    if ([name isEqualToString:kMHPenGraphicsLineToCommandName]) {
        CGPoint point = argument.pointValue;
        return [[self class] penGraphicsWithLineToAbsolutePoint:point];
    }

    if ([name isEqualToString:kMHPenGraphicsCurveToCommandName]) {
        NSArray *points = [argument arrayOfPointValues];
        if (points.count < 3)
            return nil;
        CGPoint point1 = [((NSValue *)points[0]) pointValue];
        CGPoint point2 = [((NSValue *)points[1]) pointValue];
        CGPoint point3 = [((NSValue *)points[2]) pointValue];
        return [[self class] penGraphicsWithCurveWithAbsolutePoints:point1 :point2 :point3];
    }

    bool isPenForward;
    bool isPenBackward;
    if ((isPenForward = [name isEqualToString:kMHPenGraphicsPenForwardCommandName])
        || (isPenBackward = [name isEqualToString:kMHPenGraphicsPenBackwardCommandName])) {
        CGFloat units = argument.floatValue;
        return [[self class] penGraphicsWithPenMoveForward:(isPenForward ? units : -units)];
    }

    return nil;
}

+ (NSArray <NSString *> *)recognizedCommands
{
    return @[
        kMHPenGraphicsMoveToCommandName,
        kMHPenGraphicsLineToCommandName,
        kMHPenGraphicsCurveToCommandName,
        kMHPenGraphicsPenForwardCommandName
    ];
}



#pragma mark - Typesetting

- (void)typesetWithContextManager:(MHTypesettingContextManager *)contextManager
{
    switch (_subtype) {
        case MHPenGraphicsMoveToAbsolutePointPrimitive: {
            _path = CGPathCreateMutable();
            CGPoint currentPenPosition = contextManager.penPosition;
            CGPathMoveToPoint(_path, nil, _point3.x, _point3.y);

            // now set the new pen position and direction
            contextManager.penPosition = _point3;
            CGPoint translationVector;
            translationVector.x = _point3.x - currentPenPosition.x;
            translationVector.y = _point3.y - currentPenPosition.y;
            contextManager.penDirection = translationVector;
        }
            break;
        case MHPenGraphicsLineToAbsolutePointPrimitive: {
            _path = CGPathCreateMutable();
            CGPoint currentPenPosition = contextManager.penPosition;
            CGPathMoveToPoint(_path, nil, currentPenPosition.x, currentPenPosition.y);
            CGPathAddLineToPoint(_path, nil, _point3.x, _point3.y);

            // now set the new pen position and direction
            contextManager.penPosition = _point3;
            CGPoint translationVector;
            translationVector.x = _point3.x - currentPenPosition.x;
            translationVector.y = _point3.y - currentPenPosition.y;
            contextManager.penDirection = translationVector;
        }
            break;
        case MHPenGraphicsCurveWithAbsolutePointsPrimitive: {
            _path = CGPathCreateMutable();
            CGPoint currentPenPosition = contextManager.penPosition;
            CGPathMoveToPoint(_path, nil, currentPenPosition.x, currentPenPosition.y);
            CGPathAddCurveToPoint(_path, nil, _point1.x, _point1.y, _point2.x, _point2.y, _point3.x, _point3.y);
            
            // now set the new pen position and direction
            contextManager.penPosition = _point3;
            CGPoint tangentVectorAtEndOfBezierCurve;
            tangentVectorAtEndOfBezierCurve.x =_point3.x - _point2.x;
            tangentVectorAtEndOfBezierCurve.y =_point3.y - _point2.y;
            contextManager.penDirection = tangentVectorAtEndOfBezierCurve;
        }
            break;
        case MHPenGraphicsMovePenForward: {
            bool penEngaged = contextManager.penEngaged;
            _path = CGPathCreateMutable();
            
            CGPoint penPosition = contextManager.penPosition;
            CGPoint penDirection = contextManager.penDirection;
            
            CGPoint translationVector;
            
            translationVector.x = _units * penDirection.x;
            translationVector.y = _units * penDirection.y;
            
            CGPoint newPenPosition = CGPointMake(penPosition.x + translationVector.x, penPosition.y + translationVector.y);
            
            if (penEngaged) {
                CGPoint currentPenPosition = contextManager.penPosition;
                CGPathMoveToPoint(_path, nil, currentPenPosition.x, currentPenPosition.y);
                CGPathAddLineToPoint(_path, nil, newPenPosition.x, newPenPosition.y);
            }
            else {
                CGPathMoveToPoint(_path, nil, newPenPosition.x, newPenPosition.y);
            }
            
            // update the pen position (the pen direction remains unchanged)
            contextManager.penPosition = newPenPosition;
        }
            break;
    }
    
    // Now that we prepared the path, the superclass typesetting method will do the rest
    
    [super typesetWithContextManager:contextManager];
}



#pragma mark - Copying

// This constructor is not publicly exposed, but is currently used only by the logicalCopy method
- (instancetype)initWithSubtype:(MHPenGraphicsPrimitiveSubtype)subtype drawingMode:(CGPathDrawingMode)drawingMode
                        path:(CGPathRef)path units:(CGFloat)units
                      point1:(CGPoint)point1 point2:(CGPoint)point2 point3:(CGPoint)point3
{
    if (self = [super init]) {
        _type = MHGraphicsPrimitivePath; //MHGraphicsPrimitivePenSubprimitive;
        _subtype = subtype;
        _drawingMode = drawingMode;
        _path = CGPathCreateMutableCopy(path);
        _units = units;
        _point1 = point1;
        _point2 = point2;
        _point3 = point3;
    }
    return self;
}

- (instancetype)logicalCopy
{
    MHPenGraphicsPrimitive *myCopy = [[[self class] alloc] initWithSubtype:_subtype
                                                               drawingMode:_drawingMode
                                                                      path:_path
                                                                     units:_units
                                                                    point1:_point1
                                                                    point2:_point2
                                                                    point3:_point3];
    myCopy.codeRange = self.codeRange;
    return myCopy;
}




@end
