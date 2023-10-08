//
//  MHTypesettingContextManager+GraphicsStyle.m
//  MadHat
//
//  Created by Dan Romik on 8/31/20.
//  Copyright © 2020 Dan Romik. All rights reserved.
//

#import "MHTypesettingContextManager+GraphicsStyle.h"
#import "MHStyleIncludes.h"

#import <AppKit/AppKit.h>


@implementation MHTypesettingContextManager (GraphicsStyle)

- (MHDimensions)graphicsCanvasDimensions
{
    return _currentGraphicsStyle.dimensions;
}

- (MHGraphicsRectangle)graphicsViewRectangle
{
    return _currentGraphicsStyle.viewRectangle;
}

- (NSColor *)fillColor
{
    return _currentGraphicsStyle.fillColor;
}
- (void)setFillColor:(NSColor *)fillColor
{
    [self graphicsStyleWillChange];
    _currentGraphicsStyle.fillColor = fillColor;
}

- (NSColor *)strokeColor
{
    return _currentGraphicsStyle.strokeColor;
}
- (void)setStrokeColor:(NSColor *)strokeColor
{
    [self graphicsStyleWillChange];
    _currentGraphicsStyle.strokeColor = strokeColor;
}

- (CGFloat)lineThickness
{
    return _currentGraphicsStyle.lineThickness;
}
- (void)setLineThickness:(CGFloat)lineThickness
{
    [self graphicsStyleWillChange];
    _currentGraphicsStyle.lineThickness = lineThickness;
}

- (MHGraphicsMarkerType)markerType
{
    return _currentGraphicsStyle.markerType;
}
- (void)setMarkerType:(MHGraphicsMarkerType)markerType
{
    [self graphicsStyleWillChange];
    _currentGraphicsStyle.markerType = markerType;
}

- (CGFloat)markerScale
{
    return _currentGraphicsStyle.markerScale;
}
- (void)setMarkerScale:(CGFloat)markerScale
{
    [self graphicsStyleWillChange];
    _currentGraphicsStyle.markerScale = markerScale;
}

- (CGPoint)penPosition
{
    return _currentGraphicsStyle.penPosition;
}

- (void)setPenPosition:(CGPoint)penPosition
{
    [self graphicsStyleWillChange];
    _currentGraphicsStyle.penPosition = penPosition;
}

- (CGPoint)penDirection
{
    return _currentGraphicsStyle.penDirection;
}

- (void)setPenDirection:(CGPoint)penDirection
{
    [self graphicsStyleWillChange];
    _currentGraphicsStyle.penDirection = penDirection;
}

- (bool)penEngaged
{
    return _currentGraphicsStyle.penEngaged;
}

- (void)setPenEngaged:(bool)penEngaged
{
    [self graphicsStyleWillChange];
    _currentGraphicsStyle.penEngaged = penEngaged;
}

- (void)rotatePenByAngle:(CGFloat)angle
{
    [self graphicsStyleWillChange];
    [_currentGraphicsStyle rotatePenLeft:angle];
}


- (void)graphicsStyleWillChange
{
    // In our implementation of a stack of graphics styles with lazy copying, when the style is about to change is the time to actually copy the style, if there is an active graphics style
    if (_currentGraphicsStyle && _lastDepthWhenGraphicsStylePushed < _graphicsStylesStackDepthCounter) {
        MHGraphicsStyle *graphicsStyleCopy = [_currentGraphicsStyle copy];
        [_graphicsStylesStack addObject:_currentGraphicsStyle];
        _currentGraphicsStyle = graphicsStyleCopy;
        [_graphicsStyleChangeDepthIndicesStack addObject:[NSNumber numberWithShort:_lastDepthWhenGraphicsStylePushed]];
        _lastDepthWhenGraphicsStylePushed = _graphicsStylesStackDepthCounter;
    }
}



@end
