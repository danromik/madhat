//
//  MHGraphicsStyle.m
//  MadHat
//
//  Created by Dan Romik on 7/17/20.
//  Copyright © 2020 Dan Romik. All rights reserved.
//


#import "MHGraphicsStyle.h"

@interface MHGraphicsStyle ()
{
    CGPoint _penDirection;
}
@end

@implementation MHGraphicsStyle

+ (instancetype)defaultStyleWithDimensions:(MHDimensions)dimensions viewRectangle:(MHGraphicsRectangle)viewRectangle
{
    return [[self alloc] initWithDimensions:dimensions viewRectangle:viewRectangle];
}

- (instancetype)initWithDimensions:(MHDimensions)dimensions viewRectangle:(MHGraphicsRectangle)viewRectangle
{
    if (self = [super init]) {
        self.lineThickness = 1.0;
        self.markerScale = 1.0;
        self.markerType = MHGraphicsMarkerTypeDisk;
        self.fillColor = [NSColor blackColor];
        self.strokeColor = [NSColor blackColor];
        
        self.dimensions = dimensions;
        self.viewRectangle = viewRectangle;
        
        [self pointPenNorth];
        self.penPosition = CGPointMake((viewRectangle.maxX + viewRectangle.minX)/2.0, (viewRectangle.maxY + viewRectangle.minY)/2.0);
        
    }
    return self;
}



#pragma mark - Pen graphics commands


- (void)pointPenNorth
{
    _penDirection = CGPointMake(0.0, 1.0);
}

- (void)pointPenEast
{
    _penDirection = CGPointMake(1.0, 0.0);
}

- (void)pointPenSouth
{
    _penDirection = CGPointMake(0.0, -1.0);
}

- (void)pointPenWest
{
    _penDirection = CGPointMake(-1.0, 0.0);
}

- (void)pointPenNorthWest
{
    _penDirection = CGPointMake(-M_SQRT1_2, M_SQRT1_2);
}

- (void)pointPenNorthEast
{
    _penDirection = CGPointMake(M_SQRT1_2, M_SQRT1_2);
}

- (void)pointPenSouthWest
{
    _penDirection = CGPointMake(-M_SQRT1_2, -M_SQRT1_2);
}

- (void)pointPenSouthEast
{
    _penDirection = CGPointMake(M_SQRT1_2, -M_SQRT1_2);
}


- (void)rotatePenLeft:(CGFloat)rotationAngle
{
    CGFloat angleCosine = cos(rotationAngle);
    CGFloat angleSine = sin(rotationAngle);
    _penDirection = CGPointMake(angleCosine * _penDirection.x - angleSine * _penDirection.y,
                                angleSine * _penDirection.x + angleCosine * _penDirection.y);
}

- (void)rotatePenRight:(CGFloat)rotationAngle
{
    CGFloat angleCosine = cos(rotationAngle);
    CGFloat angleSine = sin(rotationAngle);
    _penDirection = CGPointMake(angleCosine * _penDirection.x + angleSine * _penDirection.y,
                                -angleSine * _penDirection.x + angleCosine * _penDirection.y);
}


- (CGPoint)penDirection
{
    return _penDirection;
}

- (void)setPenDirection:(CGPoint)newDirection
{
    CGFloat normSquared = newDirection.x*newDirection.x + newDirection.y*newDirection.y;
    if (normSquared > 0.0) {
        CGFloat norm = sqrt(normSquared);
        _penDirection = CGPointMake(newDirection.x / norm, newDirection.y / norm);
    }
}

- (void)rotatePenToAbsoluteDirection:(CGPoint)direction
{
    self.penDirection = direction;
}

- (void)rotatePenToAbsoluteAngle:(CGFloat)angle
{
    _penDirection = CGPointMake(cos(angle), sin(angle));
}





# pragma mark - NSCopying protocol

- (instancetype)copyWithZone:(NSZone *)zone
{
    MHGraphicsStyle *newStyle = [[[self class] alloc] init];
    newStyle.dimensions = self.dimensions;
    newStyle.viewRectangle = self.viewRectangle;
    newStyle.fillColor = self.fillColor;
    newStyle.strokeColor = self.strokeColor;
    newStyle.lineThickness = self.lineThickness;
    newStyle.markerScale = self.markerScale;
    newStyle.markerType = self.markerType;
    newStyle.penPosition = self.penPosition;
    newStyle.penDirection = self.penDirection;
    newStyle.penEngaged = self.penEngaged;

    return newStyle;
}



@end
