//
//  MHGraphicsPrimitive.h
//  MadHat
//
//  Created by Dan Romik on 7/25/20.
//  Copyright © 2020 Dan Romik. All rights reserved.
//

#import "MHExpression.h"
#import "MHCommand.h"
#import "MHGraphicsCanvas.h"
#import "MHSlideTransition.h"

NS_ASSUME_NONNULL_BEGIN


typedef enum {
    MHGraphicsPrimitivePath,
    MHGraphicsPrimitiveMarker,
    MHGraphicsPrimitiveRectangle,
    MHGraphicsPrimitiveLine,
    MHGraphicsPrimitivePolygon,
    MHGraphicsPrimitiveCircle,
    MHGraphicsPrimitiveArc,
    MHGraphicsPrimitiveEllipse,
    MHGraphicsPrimitiveArrow,
    MHGraphicsPrimitiveGrid,
    MHGraphicsPrimitiveFrame,
    MHGraphicsPrimitiveAxes,
    MHGraphicsPrimitiveCubicBezier,
    MHGraphicsPrimitivePenSubprimitive,
    MHGraphicsPrimitivePlotSubprimitive
} MHGraphicsPrimitiveType;

typedef struct {
    CGPoint firstCorner;
    CGPoint secondCorner;
} MHOrderedRectangle;


@interface MHGraphicsPrimitive : MHExpression <MHCommand, MHGraphicsExpressionWithPath, MHSlideTransitionAnimatablePropertyExpression>
{
@protected
    MHGraphicsPrimitiveType _type;
    CGMutablePathRef _path;     // this is the path represented by the primitive, in the canvas coordinate system
    CGPathDrawingMode _drawingMode;
    NSDictionary *_primitiveSpecificData;     // different primitives have different data associated with them, so we store everything
    NSDictionary *_primitiveSpecificDataForInitialState;    // FIXME: this is used in the MHGraphicsPlottingPrimitiveClass, but I don't like that it's exposed to subclasses. Need to improve the design so this can be kept private
    
    // these instance variables are used in the MHGraphicsPlottingPrimitiveClass. FIXME: I'm also not sure if it's the best idea to expose them like this - the only reason I'm doing it is to enable drawing an error image when trying to plot an ill-formed formula. Think if this setup can be improved.
    MHDimensions _canvasDimensions;
    MHGraphicsRectangle _viewRectangle;
    MHGraphicsMarkerType _markerType;
    CGFloat _markerScale;
    NSColor *_strokeColor;
    NSColor *_fillColor;
    CGFloat _lineThickness;
}

+ (instancetype)graphicsFrameWithDrawingMode:(CGPathDrawingMode)drawingMode;
+ (instancetype)gridGraphicsWithPeriodicity:(CGPoint)periodicity;
+ (instancetype)lineGraphicsWithPoints:(NSArray <NSValue *> *)points drawingMode:(CGPathDrawingMode)drawingMode;
+ (instancetype)polygonGraphicsWithPoints:(NSArray <NSValue *> *)points drawingMode:(CGPathDrawingMode)drawingMode;
+ (instancetype)markerGraphicsWithPosition:(CGPoint)position;
+ (instancetype)circleGraphicsWithCenter:(CGPoint)center radius:(CGFloat)radius drawingMode:(CGPathDrawingMode)drawingMode;
+ (instancetype)ellipseGraphicsWithCenter:(CGPoint)center
                                  xRadius:(CGFloat)xRadius
                                  yRadius:(CGFloat)yRadius
                              drawingMode:(CGPathDrawingMode)drawingMode;

+ (instancetype)arcGraphicsWithCenter:(CGPoint)center
                               radius:(CGFloat)radius
                           startAngle:(CGFloat)startAngle               // the angle is measured in radians
                             endAngle:(CGFloat)endAngle                 // the angle is measured in radians
                          drawingMode:(CGPathDrawingMode)drawingMode;

+ (instancetype)rectangleGraphicsWithRect:(CGRect)rect drawingMode:(CGPathDrawingMode)drawingMode;
+ (instancetype)rectangleGraphicsWithOrderedRect:(MHOrderedRectangle)rect drawingMode:(CGPathDrawingMode)drawingMode;
+ (instancetype)arrowGraphicsWithStart:(CGPoint)startPoint end:(CGPoint)endPoint;


- (void)createGraphicsWithPrimitiveSpecificData:(NSDictionary *)primitiveSpecificData;  // do not call this method directly. It can be overridden by subclasses to implement drawing with animatable properties FIXME: document how this should be implemented exactly

@end

NS_ASSUME_NONNULL_END
