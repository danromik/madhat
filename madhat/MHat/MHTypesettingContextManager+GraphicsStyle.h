//
//  MHTypesettingContextManager+GraphicsStyle.h
//  MadHat
//
//  Created by Dan Romik on 8/31/20.
//  Copyright © 2020 Dan Romik. All rights reserved.
//

#import <AppKit/AppKit.h>


#import "MHTypesettingContextManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface MHTypesettingContextManager (GraphicsStyle)

@property (readonly) MHDimensions graphicsCanvasDimensions;     // the value for this is set with a call to the -beginGraphicsCanvas: method
@property (readonly) MHGraphicsRectangle graphicsViewRectangle;     // the value for this is set with a call to the -beginGraphicsCanvas: method
@property NSColor *fillColor;
@property NSColor *strokeColor;
@property CGFloat lineThickness;
@property CGFloat markerScale;
@property MHGraphicsMarkerType markerType;

@property CGPoint penPosition;
@property CGPoint penDirection;
@property bool penEngaged;

- (void)rotatePenByAngle:(CGFloat)angle;


@end

NS_ASSUME_NONNULL_END
