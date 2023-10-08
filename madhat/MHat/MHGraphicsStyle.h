//
//  MHGraphicsStyle.h
//  MadHat
//
//  Created by Dan Romik on 7/17/20.
//  Copyright © 2020 Dan Romik. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MadHat.h"

#import "MHStyle.h"

NS_ASSUME_NONNULL_BEGIN

// FIXME: things to add: marker type and scale, line dashing parameters (including multicolor line dashing?), affine transform

typedef enum {
    MHGraphicsMarkerTypeDisk,
    MHGraphicsMarkerTypeSquare,
    MHGraphicsMarkerTypeDiamond,
    MHGraphicsMarkerTypeTriangle,
    MHGraphicsMarkerTypeStar,
    MHGraphicsMarkerTypeFlag,
    MHGraphicsMarkerTypePushPin,
    MHGraphicsMarkerTypeCustom,
} MHGraphicsMarkerType;



@interface MHGraphicsStyle : MHStyle

@property MHDimensions dimensions;
@property MHGraphicsRectangle viewRectangle;

@property NSColor *fillColor;
@property NSColor *strokeColor;
@property CGFloat lineThickness;
@property CGFloat markerScale;
@property MHGraphicsMarkerType markerType;

// Properties for a "pen graphics" (aka "turtle graphics") drawing model
@property bool penEngaged;          // FIXME: maybe extend later to allow multiple possible customizable pen states, with different colors, line thicknesses, dashing patterns etc?
@property CGPoint penPosition;
@property CGPoint penDirection;


+ (instancetype)defaultStyleWithDimensions:(MHDimensions)dimensions viewRectangle:(MHGraphicsRectangle)viewRectangle;

- (void)rotatePenToAbsoluteDirection:(CGPoint)direction;     // does the same thing as the setPenDirection: property accessor
- (void)rotatePenToAbsoluteAngle:(CGFloat)angle;
- (void)rotatePenLeft:(CGFloat)rotationAngle;
- (void)rotatePenRight:(CGFloat)rotationAngle;
- (void)pointPenNorth;
- (void)pointPenEast;
- (void)pointPenSouth;
- (void)pointPenWest;
- (void)pointPenNorthWest;
- (void)pointPenNorthEast;
- (void)pointPenSouthWest;
- (void)pointPenSouthEast;

@end

NS_ASSUME_NONNULL_END
