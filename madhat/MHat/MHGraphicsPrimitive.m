//
//  MHGraphicsPrimitive.m
//  MadHat
//
//  Created by Dan Romik on 7/25/20.
//  Copyright © 2020 Dan Romik. All rights reserved.
//

#import "MHGraphicsPrimitive.h"
#import "MHTypesettingContextManager+GraphicsStyle.h"


// Graphics primitive commands
static NSString * const kMHGraphicsCommandGraphicsFrameName = @"frame";
static NSString * const kMHGraphicsCommandGraphicsFilledFrameName = @"filled frame";
static NSString * const kMHGraphicsCommandGraphicsFilledStrokedFrameName = @"filled stroked frame";
static NSString * const kMHGraphicsCommandGraphicsAxesName = @"axes";
static NSString * const kMHGraphicsCommandLineName = @"line";
static NSString * const kMHGraphicsCommandPolygonName = @"polygon";
static NSString * const kMHGraphicsCommandFilledPolygonName = @"filled polygon";
static NSString * const kMHGraphicsCommandFilledStrokedPolygonName = @"filled stroked polygon";
static NSString * const kMHGraphicsCommandRectangleName = @"rectangle";
static NSString * const kMHGraphicsCommandFilledRectangleName = @"filled rectangle";
static NSString * const kMHGraphicsCommandFilledStrokedRectangleName = @"filled stroked rectangle";
static NSString * const kMHGraphicsCommandCircleName = @"circle";
static NSString * const kMHGraphicsCommandDiskName = @"disk";
static NSString * const kMHGraphicsCommandCircleDiskName = @"circle disk";
static NSString * const kMHGraphicsCommandArcName = @"arc";
static NSString * const kMHGraphicsCommandEllipseName = @"ellipse";
static NSString * const kMHGraphicsCommandFilledEllipseName = @"filled ellipse";
static NSString * const kMHGraphicsCommandFilledStrokedEllipseName = @"filled stroked ellipse";
static NSString * const kMHGraphicsCommandArrowName = @"arrow";
static NSString * const kMHGraphicsCommandMarkerName = @"marker";
static NSString * const kMHGraphicsCommandGridName = @"grid";
static NSString * const kMHGraphicsCommandBezierCurveName = @"bezier";
//NSString * const kMHGraphicsCommandPutName = @"annotation";      // Implemented in MHTransformedExpression class


// Keys for animatable and non-animatable properties

// Animatable properties for circles
static NSString * const kMHGraphicsCircleCenterKey = @"center";
static NSString * const kMHGraphicsCircleRadiusKey = @"radius";

// Animatable properties for rectangles
static NSString * const kMHGraphicsRectangleFirstCornerKey = @"corner 1";
static NSString * const kMHGraphicsRectangleSecondCornerKey = @"corner 2";

// Animatable properties for arrows
static NSString * const kMHGraphicsArrowStartingPointKey = @"start";
static NSString * const kMHGraphicsArrowEndingPointKey = @"end";

// Animatable properties for arcs
static NSString * const kMHGraphicsCircularArcCenterKey = @"center";
static NSString * const kMHGraphicsCircularArcRadiusKey = @"radius";
static NSString * const kMHGraphicsCircularArcStartAngleKey = @"start angle";
static NSString * const kMHGraphicsCircularArcEndAngleKey = @"end angle";

// Animatable properties for ellipses
static NSString * const kMHGraphicsEllipseCenterKey = @"center";
static NSString * const kMHGraphicsEllipseXRadiusKey = @"x radius";
static NSString * const kMHGraphicsEllipseYRadiusKey = @"y radius";

// Animatable properties for cubic Bezier curves
static NSString * const kMHGraphicsBezierFirstPointKey = @"point 1";
static NSString * const kMHGraphicsBezierSecondPointKey = @"point 2";
static NSString * const kMHGraphicsBezierThirdPointKey = @"point 3";
static NSString * const kMHGraphicsBezierFourthPointKey = @"point 4";

// Animatable properties for lines and polygons
static NSString * const kMHGraphicsLinePointsKey = @"points";   // the property is a concatenation of the x and y coordinates of all the points in the line. FIXME: maybe add the ability to animate individual points, by changing "property k" where "k" is the point index? This could be easily implemented by adding a special case check in the changeProperty:to: method


// Properties for markers
static NSString * const kMHGraphicsMarkerPositionKey = @"position-nonanimatable";   // the marker position can be animated using a "move on transition" attribute, so it does not seem necessary to make it animatable

// Properties for a grid
static NSString * const kMHGraphicsGridPeriodicityKey = @"periodicity-nonanimatable";   // FIXME: might make sense to make this animatable later on, and to add an "origin" property that can fix an offset for the grid, but this doesn't seem too urgent so leaving it nonanimatable for now



// FIXME: more things I could add in the future
// Dashed line patterns
// Line caps, miters etc
// Function plotting
// Inputting bezier curves as SVG strings
// Double sided arrows
// Bezier arrows (including double sided)
// Axes

NSString * const kMHGraphicsPrimitiveShapeNodeName = @"MHGraphicsPrimitiveShapeNode";




NSArray <NSNumber *> *weightedAverageOfTwoDoubleFloatArrays(CGFloat weight, NSArray <NSNumber *> *valuesArray1, NSArray <NSNumber *> *valuesArray2)
{
    NSMutableArray *averageArray = [[NSMutableArray alloc] initWithCapacity:0];
    NSUInteger numberOfValues1 = valuesArray1.count;
    NSUInteger numberOfValues2 = valuesArray2.count;
    NSUInteger maxNumberOfValues = numberOfValues1 > numberOfValues2 ? numberOfValues1 : numberOfValues2;
    for (NSUInteger index = 0; index < maxNumberOfValues; index++) {
        double valueFromArray1 = (index >= numberOfValues1 ? 0.0 : [(NSNumber *)valuesArray1[index] doubleValue]);
        double valueFromArray2 = (index >= numberOfValues2 ? 0.0 : [(NSNumber *)valuesArray2[index] doubleValue]);
        double weightedAverage = (1-weight) * valueFromArray1 + weight * valueFromArray2;
        NSNumber *weightedAverageNumber = [NSNumber numberWithDouble:weightedAverage];
        [averageArray addObject:weightedAverageNumber];
    }
    return averageArray;
}





@interface MHGraphicsPrimitive ()
{
//    NSDictionary *_primitiveSpecificDataForInitialState;
    NSMutableDictionary *_primitiveSpecificDataDuringPropertyChangeBlock;
    
    NSTimer *_propertyChangeAnimationTimer;
    double _fractionOfAnimationElapsed;      // changes from 0 to 1, at which point the animation ends
    
//    MHDimensions _canvasDimensions;
//    MHGraphicsRectangle _viewRectangle;
//    MHGraphicsMarkerType _markerType;
//    CGFloat _markerScale;
//    NSColor *_strokeColor;
//    NSColor *_fillColor;
//    CGFloat _lineThickness;
}

@end



@implementation MHGraphicsPrimitive



#pragma mark - MHCommand protocol

+ (NSArray <NSString *> *)recognizedCommands
{
    return @[
        kMHGraphicsCommandGraphicsFrameName,
        kMHGraphicsCommandGraphicsFilledFrameName,
        kMHGraphicsCommandGraphicsFilledStrokedFrameName,
        kMHGraphicsCommandGraphicsAxesName,
        kMHGraphicsCommandLineName,
        kMHGraphicsCommandPolygonName,
        kMHGraphicsCommandFilledPolygonName,
        kMHGraphicsCommandFilledStrokedPolygonName,
        kMHGraphicsCommandRectangleName,
        kMHGraphicsCommandFilledRectangleName,
        kMHGraphicsCommandFilledStrokedRectangleName,
        kMHGraphicsCommandCircleName,
        kMHGraphicsCommandDiskName,
        kMHGraphicsCommandCircleDiskName,
        kMHGraphicsCommandArcName,
        kMHGraphicsCommandEllipseName,
        kMHGraphicsCommandFilledEllipseName,
        kMHGraphicsCommandFilledStrokedEllipseName,
        kMHGraphicsCommandArrowName,
        kMHGraphicsCommandMarkerName,
        kMHGraphicsCommandGridName,
        kMHGraphicsCommandBezierCurveName
    ];
}


+ (MHExpression *)commandNamed:(NSString *)name withParameters:(nullable NSDictionary *)parameters argument:(MHHorizontalLayoutContainer *)argument
{
    if ([name isEqualToString:kMHGraphicsCommandMarkerName]) {
        NSArray <NSArray <MHExpression *> *> *delimitedBlockTable = [argument delimitedBlockTable];
        NSArray <MHExpression *> *pointExpression = delimitedBlockTable[0];
        NSUInteger numberOfExpressions = pointExpression.count;
        MHExpression *xCoordinateExpression = (numberOfExpressions > 0 ? pointExpression[0] : nil);
        MHExpression *yCoordinateExpression = (numberOfExpressions > 1 ? pointExpression[1] : nil);
        CGFloat xCoord = [xCoordinateExpression floatValue];
        CGFloat yCoord = [yCoordinateExpression floatValue];
        NSPoint markerPosition = NSMakePoint(xCoord, yCoord);
        return [self markerGraphicsWithPosition:markerPosition];
    }
    
    bool isLine = false;
    bool isPolygon = false;
    bool isFilledPolygon = false;
    bool isFilledStrokedPolygon = false;
    NSPoint firstPoint = NSZeroPoint;
    if ((isLine = [name isEqualToString:kMHGraphicsCommandLineName])
        || (isPolygon = [name isEqualToString:kMHGraphicsCommandPolygonName])
        || (isFilledPolygon = [name isEqualToString:kMHGraphicsCommandFilledPolygonName])
        || (isFilledStrokedPolygon = [name isEqualToString:kMHGraphicsCommandFilledStrokedPolygonName])) {
        NSArray <NSArray <MHExpression *> *> *delimitedListOfPoints = [argument delimitedBlockTable];
        NSMutableArray *pointsArray = [[NSMutableArray alloc] initWithCapacity:delimitedListOfPoints.count];
        bool isFirstPoint = true;
        for (NSArray <MHExpression *> *pointExpression in delimitedListOfPoints) {
            NSUInteger numberOfExpressions = pointExpression.count;
            MHExpression *xCoordinateExpression = (numberOfExpressions > 0 ? pointExpression[0] : nil);
            MHExpression *yCoordinateExpression = (numberOfExpressions > 1 ? pointExpression[1] : nil);
            CGFloat xCoord = [xCoordinateExpression floatValue];
            CGFloat yCoord = [yCoordinateExpression floatValue];
            NSPoint point = NSMakePoint(xCoord, yCoord);
            [pointsArray addObject:[NSValue valueWithPoint:point]];
            if (isFirstPoint) {    // for a polygon, we add the initial point again at the end
                isFirstPoint = false;
                firstPoint = point;
            }
        }
        CGPathDrawingMode drawingMode = (isLine || isPolygon ? kCGPathStroke : (isFilledPolygon ? kCGPathFill : kCGPathFillStroke));
        
        return [self lineGraphicsWithPoints:pointsArray drawingMode:drawingMode closedLineFlag:(isPolygon || isFilledPolygon || isFilledStrokedPolygon)];
    }
    
    bool isCircle = false;
    bool isDisk = false;
    bool isCircleDisk = false;
    bool isArc = false;
    if ((isCircle = [name isEqualToString:kMHGraphicsCommandCircleName]) || (isDisk=[name isEqualToString:kMHGraphicsCommandDiskName])
        || (isCircleDisk=[name isEqualToString:kMHGraphicsCommandCircleDiskName])
        || (isArc=[name isEqualToString:kMHGraphicsCommandArcName])) {
        NSArray <NSArray <MHExpression *> *> *delimitedBlockTable = [argument delimitedBlockTable];
        NSArray <MHExpression *> *pointExpression = delimitedBlockTable[0];
        NSUInteger numberOfExpressions = pointExpression.count;
        MHExpression *xCoordinateExpression = (numberOfExpressions > 0 ? pointExpression[0] : nil);
        MHExpression *yCoordinateExpression = (numberOfExpressions > 1 ? pointExpression[1] : nil);
        CGFloat xCoord = [xCoordinateExpression floatValue];
        CGFloat yCoord = [yCoordinateExpression floatValue];
        NSPoint center = NSMakePoint(xCoord, yCoord);
        
        CGFloat radius = 0.0;
        if (delimitedBlockTable.count > 1) {
            NSArray <MHExpression *> *radiusExpressionBlock = delimitedBlockTable[1];
            if (radiusExpressionBlock.count > 0) {
                MHExpression *radiusExpression = radiusExpressionBlock[0];
                radius = [radiusExpression floatValue];
            }
        }
        
        CGFloat startAngle = 0.0, endAngle = 0.0;
        bool drawingArc = false;
        if (isArc && delimitedBlockTable.count > 2) {
            NSArray <MHExpression *> *anglesRangeExpressionBlock = delimitedBlockTable[2];
            if (anglesRangeExpressionBlock.count > 1) {
                MHExpression *startAngleExpression = anglesRangeExpressionBlock[0];
                startAngle = [startAngleExpression floatValue] * M_PI / 180.0;
                MHExpression *endAngleExpression = anglesRangeExpressionBlock[1];
                endAngle = [endAngleExpression floatValue] * M_PI / 180.0;
                drawingArc = true;
            }
        }

        CGPathDrawingMode drawingMode = (isCircle || isArc ? kCGPathStroke : (isDisk ? kCGPathFill : kCGPathFillStroke));
        
        if (drawingArc)
            return [self arcGraphicsWithCenter:center radius:radius startAngle:startAngle endAngle:endAngle drawingMode:drawingMode];
        
        return [self circleGraphicsWithCenter:center radius:radius drawingMode:drawingMode];
    }

    bool isRectangle = false;
    bool isFilledRectangle = false;
    bool isFilledStrokedRectangle = false;
    if ((isRectangle = [name isEqualToString:kMHGraphicsCommandRectangleName]) || (isFilledRectangle=[name isEqualToString:kMHGraphicsCommandFilledRectangleName])
        || (isFilledStrokedRectangle=[name isEqualToString:kMHGraphicsCommandFilledStrokedRectangleName])) {
        MHOrderedRectangle rect;
        NSArray <NSArray <MHExpression *> *> *delimitedBlockTable = [argument delimitedBlockTable];
        NSArray <MHExpression *> *firstCornerExpression = delimitedBlockTable[0];
        NSUInteger numberOfExpressions = firstCornerExpression.count;
        MHExpression *xCoordinateExpression = (numberOfExpressions > 0 ? firstCornerExpression[0] : nil);
        MHExpression *yCoordinateExpression = (numberOfExpressions > 1 ? firstCornerExpression[1] : nil);
        CGFloat xCoord = [xCoordinateExpression floatValue];
        CGFloat yCoord = [yCoordinateExpression floatValue];
        rect.firstCorner = CGPointMake(xCoord, yCoord);
        if (delimitedBlockTable.count > 1) {
            NSArray <MHExpression *> *secondCornerExpression = delimitedBlockTable[1];
            numberOfExpressions = secondCornerExpression.count;
            xCoordinateExpression = (numberOfExpressions > 0 ? secondCornerExpression[0] : nil);
            yCoordinateExpression = (numberOfExpressions > 1 ? secondCornerExpression[1] : nil);
            xCoord = [xCoordinateExpression floatValue];
            yCoord = [yCoordinateExpression floatValue];
            rect.secondCorner = CGPointMake(xCoord, yCoord);
        }
        else {
            rect.secondCorner = rect.firstCorner;
        }
        
        CGPathDrawingMode drawingMode = (isRectangle ? kCGPathStroke : (isFilledRectangle ? kCGPathFill : kCGPathFillStroke));
        return [self rectangleGraphicsWithOrderedRect:rect drawingMode:drawingMode];
    }
    
    bool isEllipse = false;
    bool isFilledEllipse = false;
    bool isFilledStrokedEllipse = false;
    if ((isEllipse = [name isEqualToString:kMHGraphicsCommandEllipseName]) || (isFilledEllipse=[name isEqualToString:kMHGraphicsCommandFilledEllipseName])
        || (isFilledStrokedEllipse=[name isEqualToString:kMHGraphicsCommandFilledStrokedEllipseName])) {
        NSArray <NSArray <MHExpression *> *> *delimitedBlockTable = [argument delimitedBlockTable];
        NSArray <MHExpression *> *pointExpression = delimitedBlockTable[0];
        NSUInteger numberOfExpressions = pointExpression.count;
        MHExpression *xCoordinateExpression = (numberOfExpressions > 0 ? pointExpression[0] : nil);
        MHExpression *yCoordinateExpression = (numberOfExpressions > 1 ? pointExpression[1] : nil);
        CGFloat xCoord = [xCoordinateExpression floatValue];
        CGFloat yCoord = [yCoordinateExpression floatValue];
        NSPoint center = NSMakePoint(xCoord, yCoord);
        
        CGFloat xRadius = 0.0;
        CGFloat yRadius = 0.0;
        if (delimitedBlockTable.count > 1) {
            NSArray <MHExpression *> *radiusExpressionBlock = delimitedBlockTable[1];
            NSUInteger numberOfRadiusExpressions = radiusExpressionBlock.count;
            if (numberOfRadiusExpressions > 0) {
                MHExpression *radiusExpression = radiusExpressionBlock[0];
                xRadius = [radiusExpression floatValue];
            }
            if (numberOfRadiusExpressions > 1) {
                MHExpression *radiusExpression = radiusExpressionBlock[1];
                yRadius = [radiusExpression floatValue];
            }
        }
        
        CGPathDrawingMode drawingMode = (isEllipse ? kCGPathStroke : (isFilledEllipse ? kCGPathFill : kCGPathFillStroke));
        return [self ellipseGraphicsWithCenter:center xRadius:xRadius yRadius:yRadius drawingMode:drawingMode];
    }
    
    if ([name isEqualToString:kMHGraphicsCommandArrowName]) {
        NSArray <NSArray <MHExpression *> *> *delimitedBlockTable = [argument delimitedBlockTable];

        NSArray <MHExpression *> *startPointExpression = delimitedBlockTable[0];
        NSUInteger numberOfExpressions = startPointExpression.count;
        MHExpression *xCoordinateExpression = (numberOfExpressions > 0 ? startPointExpression[0] : nil);
        MHExpression *yCoordinateExpression = (numberOfExpressions > 1 ? startPointExpression[1] : nil);
        CGFloat xCoord = [xCoordinateExpression floatValue];
        CGFloat yCoord = [yCoordinateExpression floatValue];
        CGPoint startPoint = CGPointMake(xCoord, yCoord);

        CGPoint endPoint;
        if (delimitedBlockTable.count > 1) {
            NSArray <MHExpression *> *endPointExpression = delimitedBlockTable[1];
            numberOfExpressions = endPointExpression.count;
            xCoordinateExpression = (numberOfExpressions > 0 ? endPointExpression[0] : nil);
            yCoordinateExpression = (numberOfExpressions > 1 ? endPointExpression[1] : nil);
            xCoord = [xCoordinateExpression floatValue];
            yCoord = [yCoordinateExpression floatValue];
            endPoint = CGPointMake(xCoord, yCoord);
        }
        else {
            endPoint = startPoint;
        }
        
        return [self arrowGraphicsWithStart:startPoint end:endPoint];
    }
    
    if ([name isEqualToString:kMHGraphicsCommandGraphicsFrameName]) {
        return [self graphicsFrameWithDrawingMode:kCGPathStroke];
    }
    if ([name isEqualToString:kMHGraphicsCommandGraphicsFilledFrameName]) {
        return [self graphicsFrameWithDrawingMode:kCGPathFill];
    }
    if ([name isEqualToString:kMHGraphicsCommandGraphicsFilledStrokedFrameName]) {
        return [self graphicsFrameWithDrawingMode:kCGPathFillStroke];
    }

    if ([name isEqualToString:kMHGraphicsCommandGridName]) {
        NSArray <NSArray <MHExpression *> *> *delimitedBlockTable = [argument delimitedBlockTable];
        NSArray <MHExpression *> *periodicityExpression = delimitedBlockTable[0];
        NSUInteger numberOfExpressions = periodicityExpression.count;
        MHExpression *xPeriodicityExpression = (numberOfExpressions > 0 ? periodicityExpression[0] : nil);
        MHExpression *yPeriodicityExpression = (numberOfExpressions > 1 ? periodicityExpression[1] : nil);
        CGFloat xPeriodicity = [xPeriodicityExpression floatValue];
        CGFloat yPeriodicity = [yPeriodicityExpression floatValue];
        NSPoint periodicity = NSMakePoint(xPeriodicity, yPeriodicity);
        return [self gridGraphicsWithPeriodicity:periodicity];
    }
    
    if ([name isEqualToString:kMHGraphicsCommandBezierCurveName]) {
        NSArray <NSArray <MHExpression *> *> *delimitedBlockTable = [argument delimitedBlockTable];
        NSUInteger numberOfPoints = delimitedBlockTable.count;
        CGPoint points[4];
        NSUInteger index;
        for (index = 0; index < 4; index++) {
            if (index < numberOfPoints) {
                NSArray <MHExpression *> *pointCoordinateExpressions = delimitedBlockTable[index];
                NSUInteger numberOfCoordinates = pointCoordinateExpressions.count;
                MHExpression *xCoordinateExpression = (numberOfCoordinates > 0 ? pointCoordinateExpressions[0] : nil);
                MHExpression *yCoordinateExpression = (numberOfCoordinates > 1 ? pointCoordinateExpressions[1] : nil);
                CGFloat xCoordinate = xCoordinateExpression.floatValue;
                CGFloat yCoordinate = yCoordinateExpression.floatValue;
                points[index] = CGPointMake(xCoordinate, yCoordinate);
            }
            else {
                points[index] = CGPointZero;
            }
        }

        return [self bezierCurveGraphicsWithControlPoints:points];
    }
    
    if ([name isEqualToString:kMHGraphicsCommandGraphicsAxesName]) {
        return [self graphicsAxes];
    }

    
    return nil;
}



#pragma mark - Constructors


// This constructor is not publicly exposed, but is currently used only by the logicalCopy method
- (instancetype)initWithType:(MHGraphicsPrimitiveType)type
                 drawingMode:(CGPathDrawingMode)drawingMode
                        path:(nullable CGPathRef)path
       primitiveSpecificData:(NSDictionary *)data
{
    if (self = [super init]) {
        _type = type;
        _drawingMode = drawingMode;
        if (path)
            _path = CGPathCreateMutableCopy(path);
        _primitiveSpecificData = data;  // the data dict is copied in the logicalCopy method, so no need to copy it again
        _primitiveSpecificDataForInitialState = _primitiveSpecificData;
    }
    return self;
}


+ (instancetype)graphicsFrameWithDrawingMode:(CGPathDrawingMode)drawingMode
{
    return [[self alloc] initWithGraphicsFrameWithDrawingMode:drawingMode];
}

- (instancetype)initWithGraphicsFrameWithDrawingMode:(CGPathDrawingMode)drawingMode
{
    if (self = [super init]) {
        _type = MHGraphicsPrimitiveFrame;
        _drawingMode = drawingMode;
    }
    return self;
}

+ (instancetype)graphicsAxes
{
    return [[self alloc] initWithGraphicsAxes];
}

- (instancetype)initWithGraphicsAxes
{
    if (self = [super init]) {
        _type = MHGraphicsPrimitiveAxes;
        _drawingMode = kCGPathStroke;
    }
    return self;
}

+ (instancetype)lineGraphicsWithPoints:(NSArray <NSValue *> *)points drawingMode:(CGPathDrawingMode)drawingMode
{
    return [[self alloc] initWithLineGraphicsWithPoints:points drawingMode:drawingMode closedLineFlag:false];
}

+ (instancetype)polygonGraphicsWithPoints:(NSArray <NSValue *> *)points drawingMode:(CGPathDrawingMode)drawingMode
{
    return [[self alloc] initWithLineGraphicsWithPoints:points drawingMode:drawingMode closedLineFlag:true];
}

+ (instancetype)lineGraphicsWithPoints:(NSArray <NSValue *> *)points
                           drawingMode:(CGPathDrawingMode)drawingMode
                        closedLineFlag:(bool)closedLineFlag
{
    return [[self alloc] initWithLineGraphicsWithPoints:points drawingMode:drawingMode closedLineFlag:closedLineFlag];
}

- (instancetype)initWithLineGraphicsWithPoints:(NSArray <NSValue *> *)points
                                   drawingMode:(CGPathDrawingMode)drawingMode
                                closedLineFlag:(bool)closedLineFlag
{
    if (self = [super init]) {
        
        _type = closedLineFlag ? MHGraphicsPrimitivePolygon : MHGraphicsPrimitiveLine;
        _drawingMode = drawingMode;
        
        NSMutableArray *flattenedPointsArray = [[NSMutableArray alloc] initWithCapacity:0];
        for (NSValue *pointValue in points) {
            CGPoint point = [pointValue pointValue];
            NSNumber *pointXNumber = [NSNumber numberWithDouble:point.x];
            NSNumber *pointYNumber = [NSNumber numberWithDouble:point.y];
            [flattenedPointsArray addObject:pointXNumber];
            [flattenedPointsArray addObject:pointYNumber];
        }
        _primitiveSpecificData = @{ kMHGraphicsLinePointsKey : flattenedPointsArray };
        _primitiveSpecificDataForInitialState = _primitiveSpecificData;
    }
    return self;
}

+ (instancetype)markerGraphicsWithPosition:(CGPoint)position
{
    return [[self alloc] initWithMarkerGraphicsWithPosition:(CGPoint)position];
}

- (instancetype)initWithMarkerGraphicsWithPosition:(CGPoint)position
{
    if (self = [super init]) {
        _type = MHGraphicsPrimitiveMarker;
        _drawingMode = kCGPathFill;
        _primitiveSpecificData = @{ kMHGraphicsMarkerPositionKey : [NSValue valueWithPoint:position] };
        _primitiveSpecificDataForInitialState = _primitiveSpecificData;
    }
    return self;
}

+ (instancetype)circleGraphicsWithCenter:(CGPoint)center radius:(CGFloat)radius drawingMode:(CGPathDrawingMode)drawingMode
{
    return [[self alloc] initWithCircleGraphicsWithCenter:(CGPoint)center radius:(CGFloat)radius drawingMode:drawingMode];
}

- (instancetype)initWithCircleGraphicsWithCenter:(CGPoint)center radius:(CGFloat)radius drawingMode:(CGPathDrawingMode)drawingMode
{
    if (self = [super init]) {
        _type = MHGraphicsPrimitiveCircle;
        _drawingMode = drawingMode;
        
        _primitiveSpecificData = @{
            kMHGraphicsCircleCenterKey : @[ [NSNumber numberWithDouble:center.x], [NSNumber numberWithDouble:center.y]],
            kMHGraphicsCircleRadiusKey : @[ [NSNumber numberWithDouble:radius] ]
        };
        _primitiveSpecificDataForInitialState = _primitiveSpecificData;
    }
    return self;
}

+ (instancetype)arcGraphicsWithCenter:(CGPoint)center
                               radius:(CGFloat)radius
                           startAngle:(CGFloat)startAngle
                             endAngle:(CGFloat)endAngle
                          drawingMode:(CGPathDrawingMode)drawingMode
{
    return [[self alloc] initWithArcGraphicsWithCenter:center
                                                radius:radius
                                            startAngle:startAngle
                                              endAngle:endAngle
                                           drawingMode:drawingMode];
}

- (instancetype)initWithArcGraphicsWithCenter:(CGPoint)center
                                       radius:(CGFloat)radius
                                   startAngle:(CGFloat)startAngle
                                     endAngle:(CGFloat)endAngle
                                  drawingMode:(CGPathDrawingMode)drawingMode
{
    if (self = [super init]) {
        _type = MHGraphicsPrimitiveArc;
        _drawingMode = drawingMode;
        
        _primitiveSpecificData = @{
            kMHGraphicsCircularArcCenterKey : @[ [NSNumber numberWithDouble:center.x], [NSNumber numberWithDouble:center.y]],
            kMHGraphicsCircularArcRadiusKey : @[ [NSNumber numberWithDouble:radius] ],
            //
            // angles are converted to degrees at this point since they are properties whose value the user can change, and we want the user to specify the angle in degrees
            kMHGraphicsCircularArcStartAngleKey : @[ [NSNumber numberWithDouble:startAngle / M_PI * 180.0] ],
            kMHGraphicsCircularArcEndAngleKey : @[ [NSNumber numberWithDouble:endAngle / M_PI * 180.0] ]
            //
        };
        _primitiveSpecificDataForInitialState = _primitiveSpecificData;
    }
    return self;
}


+ (instancetype)ellipseGraphicsWithCenter:(CGPoint)center
                                  xRadius:(CGFloat)xRadius
                                  yRadius:(CGFloat)yRadius
                              drawingMode:(CGPathDrawingMode)drawingMode
{
    return [[self alloc] initWithEllipseGraphicsWithCenter:(CGPoint)center
                                                   xRadius:(CGFloat)xRadius
                                                   yRadius:(CGFloat)yRadius
                                               drawingMode:drawingMode];
}

- (instancetype)initWithEllipseGraphicsWithCenter:(CGPoint)center
                                          xRadius:(CGFloat)xRadius
                                          yRadius:(CGFloat)yRadius
                                      drawingMode:(CGPathDrawingMode)drawingMode
{
    if (self = [super init]) {
        _type = MHGraphicsPrimitiveEllipse;
        _drawingMode = drawingMode;
        
        _primitiveSpecificData = @{
            kMHGraphicsEllipseCenterKey : @[ [NSNumber numberWithDouble:center.x], [NSNumber numberWithDouble:center.y]],
            kMHGraphicsEllipseXRadiusKey : @[ [NSNumber numberWithDouble:xRadius] ],
            kMHGraphicsEllipseYRadiusKey : @[ [NSNumber numberWithDouble:yRadius] ]
        };
        _primitiveSpecificDataForInitialState = _primitiveSpecificData;
    }
    return self;
}

+ (instancetype)rectangleGraphicsWithRect:(CGRect)rect drawingMode:(CGPathDrawingMode)drawingMode;
{
    MHOrderedRectangle orderedRect;
    orderedRect.firstCorner = rect.origin;
    orderedRect.secondCorner = CGPointMake(rect.origin.x + rect.size.width, rect.origin.y + rect.size.height);
    return [[self alloc] initWithRectangleGraphicsWithOrderedRect:orderedRect drawingMode:drawingMode];
}

+ (instancetype)rectangleGraphicsWithOrderedRect:(MHOrderedRectangle)rect drawingMode:(CGPathDrawingMode)drawingMode;
{
    return [[self alloc] initWithRectangleGraphicsWithOrderedRect:rect drawingMode:drawingMode];
}

- (instancetype)initWithRectangleGraphicsWithOrderedRect:(MHOrderedRectangle)rect drawingMode:(CGPathDrawingMode)drawingMode
{
    if (self = [super init]) {
        _type = MHGraphicsPrimitiveRectangle;
        _drawingMode = drawingMode;
        _primitiveSpecificData = @{
            kMHGraphicsRectangleFirstCornerKey : @[ [NSNumber numberWithDouble:rect.firstCorner.x], [NSNumber numberWithDouble:rect.firstCorner.y]],
            kMHGraphicsRectangleSecondCornerKey : @[ [NSNumber numberWithDouble:rect.secondCorner.x], [NSNumber numberWithDouble:rect.secondCorner.y]],
        };
        _primitiveSpecificDataForInitialState = _primitiveSpecificData;
    }
    return self;
}

+ (instancetype)arrowGraphicsWithStart:(CGPoint)startPoint end:(CGPoint)endPoint
{
    return [[self alloc] initWithArrowGraphicsWithStart:startPoint end:endPoint];
}

- (instancetype)initWithArrowGraphicsWithStart:(CGPoint)startPoint end:(CGPoint)endPoint
{
    if (self = [super init]) {
        _type = MHGraphicsPrimitiveArrow;
        _path = CGPathCreateMutable();
        _drawingMode = kCGPathFillStroke;
        
        _primitiveSpecificData = @{
            kMHGraphicsArrowStartingPointKey : @[ [NSNumber numberWithDouble:startPoint.x], [NSNumber numberWithDouble:startPoint.y]],
            kMHGraphicsArrowEndingPointKey : @[ [NSNumber numberWithDouble:endPoint.x], [NSNumber numberWithDouble:endPoint.y]]
        };
        _primitiveSpecificDataForInitialState = _primitiveSpecificData;
    }
    return self;
}


+ (instancetype)gridGraphicsWithPeriodicity:(CGPoint)periodicity
{
    return [[self alloc] initWithGridGraphicsWithPeriodicity:periodicity];
}

- (instancetype)initWithGridGraphicsWithPeriodicity:(CGPoint)periodicity
{
    if (self = [super init]) {
        _type = MHGraphicsPrimitiveGrid;
        _drawingMode = kCGPathStroke;
        NSPoint sanitizedPeriodicity = periodicity;
        if (sanitizedPeriodicity.x <= 0.0)
            sanitizedPeriodicity.x = 1.0;
        if (sanitizedPeriodicity.y <= 0.0)
            sanitizedPeriodicity.y = 1.0;
        _primitiveSpecificData = @{ kMHGraphicsGridPeriodicityKey : [NSValue valueWithPoint:sanitizedPeriodicity] };
        _primitiveSpecificDataForInitialState = _primitiveSpecificData;
    }
    return self;
}

+ (instancetype)bezierCurveGraphicsWithControlPoints:(CGPoint *)points
{
    return [[self alloc] initBezierCurveGraphicsWithControlPoints:points];
}

- (instancetype)initBezierCurveGraphicsWithControlPoints:(CGPoint *)points
{
    if (self = [super init]) {
        _type = MHGraphicsPrimitiveCubicBezier;
        _drawingMode = kCGPathStroke;
        
        _primitiveSpecificData = @{
            kMHGraphicsBezierFirstPointKey : @[ [NSNumber numberWithDouble:points[0].x], [NSNumber numberWithDouble:points[0].y] ],
            kMHGraphicsBezierSecondPointKey : @[ [NSNumber numberWithDouble:points[1].x], [NSNumber numberWithDouble:points[1].y] ],
            kMHGraphicsBezierThirdPointKey : @[ [NSNumber numberWithDouble:points[2].x], [NSNumber numberWithDouble:points[2].y] ],
            kMHGraphicsBezierFourthPointKey : @[ [NSNumber numberWithDouble:points[3].x], [NSNumber numberWithDouble:points[3].y] ]
        };
        _primitiveSpecificDataForInitialState = _primitiveSpecificData;
    }
    return self;
}



#pragma mark - Typesetting



- (void)typesetWithContextManager:(MHTypesettingContextManager *)contextManager
{
    // save the necessary parameters from the current graphics state
    _canvasDimensions = contextManager.graphicsCanvasDimensions;
    _viewRectangle = contextManager.graphicsViewRectangle;   // the view rectangle represents the canvas coordinate system used by graphics primitives. The path in the _path variable is given in that coordinate system. But all actual drawing will be done in the screen/node coordinate system, so we'll be doing a lot of conversion between the two coordinate systems
    _markerType = contextManager.markerType;
    _markerScale = contextManager.markerScale;
    _strokeColor = contextManager.strokeColor;
    _fillColor = contextManager.fillColor;
    _lineThickness = contextManager.lineThickness;

    [self createGraphics];
}

- (void)createGraphics
{
    [self createGraphicsWithPrimitiveSpecificData:_primitiveSpecificData];
}

- (void)createGraphicsWithPrimitiveSpecificData:(NSDictionary *)primitiveSpecificData
{
    CGAffineTransform affineTransform = CGAffineTransformIdentity;
    affineTransform = CGAffineTransformScale(affineTransform, _canvasDimensions.width/(_viewRectangle.maxX-_viewRectangle.minX),
                                             _canvasDimensions.height/(_viewRectangle.maxY-_viewRectangle.minY));
    affineTransform = CGAffineTransformTranslate(affineTransform, -_viewRectangle.minX, -_viewRectangle.minY);
    
    // FIXME: convert the succession of if's to a switch statement
    
    if (_type == MHGraphicsPrimitiveRectangle) {
        MHOrderedRectangle orderedRect;
        
        NSArray <NSNumber *> *firstCornerCoordinates = primitiveSpecificData[kMHGraphicsRectangleFirstCornerKey];
        NSUInteger numberOfFirstCornerCoordinates = firstCornerCoordinates.count;
                
        orderedRect.firstCorner.x = (numberOfFirstCornerCoordinates >= 1
                                     ? [(NSNumber *)(firstCornerCoordinates[0]) doubleValue] : 0.0);
        orderedRect.firstCorner.y = (numberOfFirstCornerCoordinates >= 2
                                     ? [(NSNumber *)(firstCornerCoordinates[1]) doubleValue] : 0.0);

        NSArray <NSNumber *> *secondCornerCoordinates = primitiveSpecificData[kMHGraphicsRectangleSecondCornerKey];
        NSUInteger numberOfSecondCornerCoordinates = secondCornerCoordinates.count;
                
        orderedRect.secondCorner.x = (numberOfSecondCornerCoordinates >= 1
                                     ? [(NSNumber *)(secondCornerCoordinates[0]) doubleValue] : 0.0);
        orderedRect.secondCorner.y = (numberOfSecondCornerCoordinates >= 2
                                     ? [(NSNumber *)(secondCornerCoordinates[1]) doubleValue] : 0.0);

        if (_path)
            CGPathRelease(_path);
        _path = CGPathCreateMutable();
        
        // Convert the ordered rectangle into an ordinary CGRect
        CGRect rect;
        if (orderedRect.firstCorner.x < orderedRect.secondCorner.x) {
            rect.origin.x = orderedRect.firstCorner.x;
            rect.size.width = orderedRect.secondCorner.x - orderedRect.firstCorner.x;
        }
        else {
            rect.origin.x = orderedRect.secondCorner.x;
            rect.size.width = orderedRect.firstCorner.x - orderedRect.secondCorner.x;
        }
        if (orderedRect.firstCorner.y < orderedRect.secondCorner.y) {
            rect.origin.y = orderedRect.firstCorner.y;
            rect.size.height = orderedRect.secondCorner.y - orderedRect.firstCorner.y;
        }
        else {
            rect.origin.y = orderedRect.secondCorner.y;
            rect.size.height = orderedRect.firstCorner.y - orderedRect.secondCorner.y;
        }
        
        // draw the rect into the path
        CGPathAddRect(_path, nil, rect);
    }
    else if (_type == MHGraphicsPrimitiveCircle) {
        NSArray <NSNumber *> *centerCoordinates = primitiveSpecificData[kMHGraphicsCircleCenterKey];
        NSUInteger numberOfCenterCoordinates = centerCoordinates.count;
                
        CGPoint center;
        center.x = (numberOfCenterCoordinates >= 1 ? [(NSNumber *)(centerCoordinates[0]) doubleValue] : 0.0);
        center.y = (numberOfCenterCoordinates >= 2 ? [(NSNumber *)(centerCoordinates[1]) doubleValue] : 0.0);
        
        NSArray <NSNumber *> *radiusCoordinates = primitiveSpecificData[kMHGraphicsCircleRadiusKey];
        CGFloat radius = (radiusCoordinates.count > 0 ? [(NSNumber *)(radiusCoordinates[0]) doubleValue] : 0.0);

        if (_path)
            CGPathRelease(_path);
        _path = CGPathCreateMutable();
        
        // FIXME: CoreGraphics doesn't render "ellipses" as actual ellipses, but uses a rather crude Bezier curve-based approximation.
        // See this discussion:
        // https://stackoverflow.com/questions/18492170/why-the-circle-path-of-the-cashapelayer-is-not-so-round
        //
        // In my testing, by NSLogging the path I found that each quarter ellipse is rendered as a single cubic Bezier curve.
        // The page https://pomax.github.io/bezierinfo/#circles_cubic goes into some detail discussing  how accurate this kind
        // of approximation is.
        //
        // For my application I need better precision, so need to implement more precise ellipse-drawing algorithms at some point
        CGPathAddEllipseInRect(_path, nil, CGRectMake(center.x-radius, center.y-radius, 2*radius, 2*radius));
    }
    else if (_type == MHGraphicsPrimitiveEllipse) {
        NSArray <NSNumber *> *centerCoordinates = primitiveSpecificData[kMHGraphicsEllipseCenterKey];
        NSUInteger numberOfCenterCoordinates = centerCoordinates.count;
                
        CGPoint center;
        center.x = (numberOfCenterCoordinates >= 1 ? [(NSNumber *)(centerCoordinates[0]) doubleValue] : 0.0);
        center.y = (numberOfCenterCoordinates >= 2 ? [(NSNumber *)(centerCoordinates[1]) doubleValue] : 0.0);
        
        NSArray <NSNumber *> *xRadiusCoordinates = primitiveSpecificData[kMHGraphicsEllipseXRadiusKey];
        CGFloat xRadius = (xRadiusCoordinates.count > 0 ? [(NSNumber *)(xRadiusCoordinates[0]) doubleValue] : 0.0);

        NSArray <NSNumber *> *yRadiusCoordinates = primitiveSpecificData[kMHGraphicsEllipseYRadiusKey];
        CGFloat yRadius = (yRadiusCoordinates.count > 0 ? [(NSNumber *)(yRadiusCoordinates[0]) doubleValue] : 0.0);


        if (_path)
            CGPathRelease(_path);
        _path = CGPathCreateMutable();
        
        // FIXME: CoreGraphics doesn't render "ellipses" as actual ellipses, but uses a rather crude Bezier curve-based approximation.
        // See this discussion:
        // https://stackoverflow.com/questions/18492170/why-the-circle-path-of-the-cashapelayer-is-not-so-round
        //
        // In my testing, by NSLogging the path I found that each quarter ellipse is rendered as a single cubic Bezier curve.
        // The page https://pomax.github.io/bezierinfo/#circles_cubic goes into some detail discussing  how accurate this kind
        // of approximation is.
        //
        // For my application I need better precision, so need to implement more precise ellipse-drawing algorithms at some point
        CGPathAddEllipseInRect(_path, nil, CGRectMake(center.x-xRadius, center.y-yRadius, 2*xRadius, 2*yRadius));
    }
    else if (_type == MHGraphicsPrimitiveArc) {
        NSArray <NSNumber *> *centerCoordinates = primitiveSpecificData[kMHGraphicsCircularArcCenterKey];
        NSUInteger numberOfCenterCoordinates = centerCoordinates.count;
                
        CGPoint center;
        center.x = (numberOfCenterCoordinates >= 1 ? [(NSNumber *)(centerCoordinates[0]) doubleValue] : 0.0);
        center.y = (numberOfCenterCoordinates >= 2 ? [(NSNumber *)(centerCoordinates[1]) doubleValue] : 0.0);
        
        NSArray <NSNumber *> *radiusCoordinates = primitiveSpecificData[kMHGraphicsCircularArcRadiusKey];
        CGFloat radius = (radiusCoordinates.count > 0 ? [(NSNumber *)(radiusCoordinates[0]) doubleValue] : 0.0);

        NSArray <NSNumber *> *startAngleCoordinates = primitiveSpecificData[kMHGraphicsCircularArcStartAngleKey];
        CGFloat startAngleInDegrees = (startAngleCoordinates.count > 0 ? [(NSNumber *)(startAngleCoordinates[0]) doubleValue] : 0.0);

        NSArray <NSNumber *> *endAngleCoordinates = primitiveSpecificData[kMHGraphicsCircularArcEndAngleKey];
        CGFloat endAngleInDegrees = (endAngleCoordinates.count > 0 ? [(NSNumber *)(endAngleCoordinates[0]) doubleValue] : 360.0);
        
        CGFloat startAngleInRadians = startAngleInDegrees / 180.0 * M_PI;
        CGFloat endAngleInRadians = endAngleInDegrees / 180.0 * M_PI;

        if (_path)
            CGPathRelease(_path);
        _path = CGPathCreateMutable();
        
        // FIXME: CoreGraphics doesn't render "ellipses" as actual ellipses, but uses a rather crude Bezier curve-based approximation.
        // See this discussion:
        // https://stackoverflow.com/questions/18492170/why-the-circle-path-of-the-cashapelayer-is-not-so-round
        //
        // In my testing, by NSLogging the path I found that each quarter ellipse is rendered as a single cubic Bezier curve.
        // The page https://pomax.github.io/bezierinfo/#circles_cubic goes into some detail discussing  how accurate this kind
        // of approximation is.
        //
        // For my application I need better precision, so need to implement more precise ellipse-drawing algorithms at some point
        CGPathAddArc(_path, nil, center.x, center.y, radius, startAngleInRadians, endAngleInRadians, endAngleInRadians < startAngleInRadians);
    }
    else if (_type == MHGraphicsPrimitiveCubicBezier) {
        NSArray <NSNumber *> *firstPointCoordinates = primitiveSpecificData[kMHGraphicsBezierFirstPointKey];
        NSUInteger numberOfFirstPointCoordinates = firstPointCoordinates.count;
        CGPoint firstPoint;
        firstPoint.x = (numberOfFirstPointCoordinates >= 1 ? [(NSNumber *)(firstPointCoordinates[0]) doubleValue] : 0.0);
        firstPoint.y = (numberOfFirstPointCoordinates >= 2 ? [(NSNumber *)(firstPointCoordinates[1]) doubleValue] : 0.0);

        NSArray <NSNumber *> *secondPointCoordinates = primitiveSpecificData[kMHGraphicsBezierSecondPointKey];
        NSUInteger numberOfSecondPointCoordinates = secondPointCoordinates.count;
        CGPoint secondPoint;
        secondPoint.x = (numberOfSecondPointCoordinates >= 1 ? [(NSNumber *)(secondPointCoordinates[0]) doubleValue] : 0.0);
        secondPoint.y = (numberOfSecondPointCoordinates >= 2 ? [(NSNumber *)(secondPointCoordinates[1]) doubleValue] : 0.0);

        NSArray <NSNumber *> *thirdPointCoordinates = primitiveSpecificData[kMHGraphicsBezierThirdPointKey];
        NSUInteger numberOfThirdPointCoordinates = thirdPointCoordinates.count;
        CGPoint thirdPoint;
        thirdPoint.x = (numberOfThirdPointCoordinates >= 1 ? [(NSNumber *)(thirdPointCoordinates[0]) doubleValue] : 0.0);
        thirdPoint.y = (numberOfThirdPointCoordinates >= 2 ? [(NSNumber *)(thirdPointCoordinates[1]) doubleValue] : 0.0);

        NSArray <NSNumber *> *fourthPointCoordinates = primitiveSpecificData[kMHGraphicsBezierFourthPointKey];
        NSUInteger numberOfFourthPointCoordinates = fourthPointCoordinates.count;
        CGPoint fourthPoint;
        fourthPoint.x = (numberOfFourthPointCoordinates >= 1 ? [(NSNumber *)(fourthPointCoordinates[0]) doubleValue] : 0.0);
        fourthPoint.y = (numberOfFourthPointCoordinates >= 2 ? [(NSNumber *)(fourthPointCoordinates[1]) doubleValue] : 0.0);

        if (_path)
            CGPathRelease(_path);
        _path = CGPathCreateMutable();
        
        CGPathMoveToPoint(_path, nil, firstPoint.x, firstPoint.y);
        CGPathAddCurveToPoint(_path, nil, secondPoint.x, secondPoint.y, thirdPoint.x, thirdPoint.y, fourthPoint.x, fourthPoint.y);
    }
    else if (_type == MHGraphicsPrimitiveLine || _type == MHGraphicsPrimitivePolygon) {
        NSArray <NSNumber *> *flattenedPointsArray = primitiveSpecificData[kMHGraphicsLinePointsKey];
        NSUInteger numberOfPointCoordinates = flattenedPointsArray.count;
                
        if (_path)
            CGPathRelease(_path);
        _path = CGPathCreateMutable();

        for (NSUInteger index = 0; index+1 < numberOfPointCoordinates; index += 2) {
            CGPoint point;
            point.x = [(NSNumber *)(flattenedPointsArray[index]) doubleValue];
            point.y = [(NSNumber *)(flattenedPointsArray[index+1]) doubleValue];
            if (index == 0)
                CGPathMoveToPoint(_path, nil, point.x, point.y);
            else
                CGPathAddLineToPoint(_path, nil, point.x, point.y);
        }
        if (_type == MHGraphicsPrimitivePolygon)
            CGPathCloseSubpath(_path);
    }
    else if (_type == MHGraphicsPrimitiveMarker) {
        // For markers, the path needs to be constructed during typesetting instead of during initialization based on the current marker type
        
        if (_path != nil)
            CGPathRelease(_path);
        _path = CGPathCreateMutable();
        
        CGFloat markerSize;
        CGPoint markerPosition = [(NSValue *)primitiveSpecificData[kMHGraphicsMarkerPositionKey] pointValue];
        CGFloat xScaling = (_viewRectangle.maxX - _viewRectangle.minX) / _canvasDimensions.width;
        CGFloat yScaling = (_viewRectangle.maxY - _viewRectangle.minY) / _canvasDimensions.height;

        switch (_markerType) {
            case MHGraphicsMarkerTypeSquare:
                markerSize = _markerScale*4.0;   // Default size for a square marker
                CGPathAddRect(_path, nil, CGRectMake(markerPosition.x - xScaling * markerSize, markerPosition.y - yScaling * markerSize,
                                                     2*xScaling*markerSize, 2*yScaling*markerSize));
                break;
            case MHGraphicsMarkerTypeDiamond: {
                CGFloat diamondHalfWidth = xScaling*_markerScale*5.0;     // default size parameters for a diamond marker
                CGFloat diamondHalfHeight = yScaling*_markerScale*6.0;    // default size parameters for a diamond marker
                CGPathMoveToPoint(_path, nil, markerPosition.x+diamondHalfWidth, markerPosition.y);
                CGPathAddLineToPoint(_path, nil, markerPosition.x, markerPosition.y+diamondHalfHeight);
                CGPathAddLineToPoint(_path, nil, markerPosition.x-diamondHalfWidth, markerPosition.y);
                CGPathAddLineToPoint(_path, nil, markerPosition.x, markerPosition.y-diamondHalfHeight);
                CGPathCloseSubpath(_path);
            }
                break;
            case MHGraphicsMarkerTypeTriangle: {
                markerSize = _markerScale*6.0;   // Default size for a square marker
                CGPathMoveToPoint(_path, nil, markerPosition.x, markerPosition.y + yScaling*markerSize);
                CGPathAddLineToPoint(_path, nil, markerPosition.x - 0.86602540378443864676*xScaling*markerSize, markerPosition.y - yScaling*markerSize/2.0);
                CGPathAddLineToPoint(_path, nil, markerPosition.x + 0.86602540378443864676*xScaling*markerSize, markerPosition.y - yScaling*markerSize/2.0);
                CGPathCloseSubpath(_path);
            }
                break;
            case MHGraphicsMarkerTypeStar: {
                CGFloat innerCircleRadius = _markerScale*2.5;
                CGFloat outerCircleRadius = _markerScale*6.0;
                NSUInteger i;
                for (i=0; i < 5; i++) {
                    CGFloat x, y;
                    x = markerPosition.x + outerCircleRadius * xScaling * cos(2*M_PI*(i+0.25)/5.0);
                    y = markerPosition.y + outerCircleRadius * yScaling * sin(2*M_PI*(i+0.25)/5.0);
                    if (i==0)
                        CGPathMoveToPoint(_path, nil, x, y);
                    else
                        CGPathAddLineToPoint(_path, nil, x, y);
                    x = markerPosition.x + innerCircleRadius * xScaling * cos(2*M_PI*(i+0.25)/5.0 + 2*M_PI/10);
                    y = markerPosition.y + innerCircleRadius * yScaling * sin(2*M_PI*(i+0.25)/5.0 + 2*M_PI/10);
                    CGPathAddLineToPoint(_path, nil, x, y);
                }
                CGPathCloseSubpath(_path);
            }
                break;
            case MHGraphicsMarkerTypeDisk:
            default:        // the default marker type is a disk
                markerSize = _markerScale*4.0;   // Default radius for a disk marker
                CGPathAddEllipseInRect(_path, nil, CGRectMake(markerPosition.x - xScaling * markerSize, markerPosition.y - yScaling * markerSize,
                                                              2*xScaling*markerSize, 2*yScaling*markerSize));
                break;
                // Default marker
                break;
        }
    }
    else if (_type == MHGraphicsPrimitiveFrame) {
        // For a frame primitive, the path needs to be constructed during typesetting instead of during initialization based on the view rectangle
        if (_path != nil)
            CGPathRelease(_path);
        _path = CGPathCreateMutable();
        CGPathAddRect(_path, nil, CGRectMake(_viewRectangle.minX, _viewRectangle.minY, _viewRectangle.maxX-_viewRectangle.minX, _viewRectangle.maxY-_viewRectangle.minY));
    }
    else if (_type == MHGraphicsPrimitiveAxes) {
        // FIXME: add more options: tick marks, axis labels etc
        if (_path != nil)
            CGPathRelease(_path);
        _path = CGPathCreateMutable();
        CGPathMoveToPoint(_path, nil, _viewRectangle.minX, 0.0);
        CGPathAddLineToPoint(_path, nil, _viewRectangle.maxX, 0.0);
        CGPathMoveToPoint(_path, nil, 0.0, _viewRectangle.minY);
        CGPathAddLineToPoint(_path, nil, 0.0, _viewRectangle.maxY);
    }
    else if (_type == MHGraphicsPrimitiveGrid) {
        if (_path != nil)
            CGPathRelease(_path);
        _path = CGPathCreateMutable();
        CGPoint periodicity = [(NSValue *)primitiveSpecificData[kMHGraphicsGridPeriodicityKey] pointValue];
        CGFloat x, y;
        
        for (x = _viewRectangle.minX; x <= _viewRectangle.maxX+0.0000001; x += periodicity.x) {
            CGPathMoveToPoint(_path, nil, x, _viewRectangle.minY);
            CGPathAddLineToPoint(_path, nil, x, _viewRectangle.maxY);
        }
        for (y = _viewRectangle.minY; y <= _viewRectangle.maxY+0.0000001; y += periodicity.y) {
            CGPathMoveToPoint(_path, nil, _viewRectangle.minX, y);
            CGPathAddLineToPoint(_path, nil, _viewRectangle.maxX, y);
        }
    }
    else if (_type == MHGraphicsPrimitiveArrow) {
        NSArray <NSNumber *> *canvasCoordinatesStartPointValueCoordinates = primitiveSpecificData[kMHGraphicsArrowStartingPointKey];
        NSUInteger numberOfStartPointCoordinates = canvasCoordinatesStartPointValueCoordinates.count;
        
        NSArray <NSNumber *> *canvasCoordinatesEndPointValueCoordinates = primitiveSpecificData[kMHGraphicsArrowEndingPointKey];
        NSUInteger numberOfEndPointCoordinates = canvasCoordinatesEndPointValueCoordinates.count;
        
        CGPoint canvasCoordinatesStartPoint;
        canvasCoordinatesStartPoint.x = (numberOfStartPointCoordinates >= 1 ? [(NSNumber *)(canvasCoordinatesStartPointValueCoordinates[0]) doubleValue] : 0.0);
        canvasCoordinatesStartPoint.y = (numberOfStartPointCoordinates >= 2 ? [(NSNumber *)(canvasCoordinatesStartPointValueCoordinates[1]) doubleValue] : 0.0);

        CGPoint canvasCoordinatesEndPoint;
        canvasCoordinatesEndPoint.x = (numberOfEndPointCoordinates >= 1 ? [(NSNumber *)(canvasCoordinatesEndPointValueCoordinates[0]) doubleValue] : 0.0);
        canvasCoordinatesEndPoint.y = (numberOfEndPointCoordinates >= 2 ? [(NSNumber *)(canvasCoordinatesEndPointValueCoordinates[1]) doubleValue] : 0.0);
        
        // For arrow graphics, it is most convenient to do the calculations in node coordinates, so transform to that coordinate system
        // (this conversion can also be done by calling the convertPointFromCanvasToNodeCoordinates method)
        CGPoint startPoint = CGPointApplyAffineTransform(canvasCoordinatesStartPoint, affineTransform);
        CGPoint endPoint = CGPointApplyAffineTransform(canvasCoordinatesEndPoint, affineTransform);

        CGMutablePathRef transformedPath = CGPathCreateMutable();

        if (endPoint.x != startPoint.x || endPoint.y != startPoint.y) {

            // these values are somewhat arbitrary, can be made customizable if desired
            CGFloat arrowheadLength = 12.0;
            CGFloat arrowheadWidth = 3.0;
            CGFloat arrowWidth = 0.01;
            
            CGFloat arrowLength = sqrt((endPoint.x-startPoint.x)*(endPoint.x-startPoint.x)+(endPoint.y-startPoint.y)*(endPoint.y-startPoint.y));

            CGPoint normalizedVector = CGPointMake((endPoint.x-startPoint.x)/arrowLength, (endPoint.y-startPoint.y)/arrowLength);
            CGPoint orthogonalVector = CGPointMake(normalizedVector.y, -normalizedVector.x);
            
            CGPoint point1 = CGPointMake(startPoint.x - arrowWidth * orthogonalVector.x,
                                         startPoint.y - arrowWidth * orthogonalVector.y);
            CGPoint point2 = CGPointMake(startPoint.x + arrowWidth * orthogonalVector.x,
                                         startPoint.y + arrowWidth * orthogonalVector.y);
            CGPoint point3 = CGPointMake(endPoint.x - arrowheadLength * normalizedVector.x + arrowWidth * orthogonalVector.x,
                                         endPoint.y - arrowheadLength * normalizedVector.y + arrowWidth * orthogonalVector.y);

            CGPoint point4 = CGPointMake(endPoint.x - arrowheadLength * normalizedVector.x + arrowheadWidth * orthogonalVector.x,
                                         endPoint.y - arrowheadLength * normalizedVector.y + arrowheadWidth * orthogonalVector.y);

            CGPoint point5 = endPoint;

            CGPoint point6 = CGPointMake(endPoint.x - arrowheadLength * normalizedVector.x - arrowheadWidth * orthogonalVector.x,
                                         endPoint.y - arrowheadLength * normalizedVector.y - arrowheadWidth * orthogonalVector.y);

            CGPoint point7 = CGPointMake(endPoint.x - arrowheadLength * normalizedVector.x - arrowWidth * orthogonalVector.x,
                                         endPoint.y - arrowheadLength * normalizedVector.y - arrowWidth * orthogonalVector.y);


            CGPathMoveToPoint(transformedPath, nil, point1.x, point1.y);
            CGPathAddLineToPoint(transformedPath, nil, point2.x, point2.y);
            CGPathAddLineToPoint(transformedPath, nil, point3.x, point3.y);
            CGPathAddLineToPoint(transformedPath, nil, point4.x, point4.y);
            CGPathAddLineToPoint(transformedPath, nil, point5.x, point5.y);
            CGPathAddLineToPoint(transformedPath, nil, point6.x, point6.y);
            CGPathAddLineToPoint(transformedPath, nil, point7.x, point7.y);
            CGPathCloseSubpath(transformedPath);
        }
        
        // The transformedPath is actually the one we want to use for the node, but it's also good to store the path in the original coordinate system (could be used for curved text layout and possibly other things), so compute it by applying the inverse transform
        CGAffineTransform inverseAffineTransform = CGAffineTransformInvert(affineTransform);
        
        if (_path)
            CGPathRelease(_path);
        _path = CGPathCreateMutableCopyByTransformingPath(transformedPath, &inverseAffineTransform);
        
        CGPathRelease(transformedPath);
    }
    
    // Now that we are sure the path has been constructed for all recognized graphics primitives, we can create the associated shape node
    SKNode *spriteKitNode = self.spriteKitNode;
    [spriteKitNode removeAllChildren];

    // The path was calculated in the canvas coordinate system, but we need it in the node coordinates, so apply the appropriate affine transformation
    CGPathRef transformedPath;
    transformedPath = CGPathCreateCopyByTransformingPath(_path, &affineTransform);
    SKShapeNode *shapeNode = [SKShapeNode shapeNodeWithPath:transformedPath];
    CGPathRelease(transformedPath);
    
    shapeNode.strokeColor = ((_drawingMode == kCGPathStroke || _drawingMode == kCGPathFillStroke) ? _strokeColor : [NSColor clearColor]);
    shapeNode.fillColor = ((_drawingMode == kCGPathFill || _drawingMode == kCGPathFillStroke) ?
                          (_type == MHGraphicsPrimitiveArrow ? _strokeColor : _fillColor)
                          : [NSColor clearColor]);
    shapeNode.lineWidth = _lineThickness;
    shapeNode.name = kMHGraphicsPrimitiveShapeNodeName;
    [spriteKitNode addChild:shapeNode];
}



#pragma mark - Properties

- (CGPathRef)graphicsPath
{
    return _path;
}



#pragma mark - MHSlideTransitionAnimatablePropertyExpression protocol

- (void)beginPropertyChangeBlock
{
    if (_propertyChangeAnimationTimer) {    // there is an animation currently in progress, so wrap it up before proceeding
        _fractionOfAnimationElapsed = 1.0;
        [self propertyChangeAnimationTimerAction:nil];
    }
    
    _primitiveSpecificDataDuringPropertyChangeBlock = [[NSMutableDictionary alloc] initWithCapacity:0];
    [_primitiveSpecificDataDuringPropertyChangeBlock setDictionary:_primitiveSpecificData];
}

- (void)restorePropertiesToInitialState
{
    [_primitiveSpecificDataDuringPropertyChangeBlock setDictionary:_primitiveSpecificDataForInitialState];
}

- (void)changeProperty:(NSString *)propertyName to:(NSArray <NSNumber *> *)newPropertyValue
{
    _primitiveSpecificDataDuringPropertyChangeBlock[propertyName] = newPropertyValue;
}

- (void)endPropertyChangeBlockAndApplyChanges:(bool)animated
{
    if (animated) {
        _fractionOfAnimationElapsed = 0.0;
        _propertyChangeAnimationTimer = [NSTimer scheduledTimerWithTimeInterval:kMHDefaultPropertyChangeAnimationUpdateInterval
                                                                         target:self
                                                                       selector:@selector(propertyChangeAnimationTimerAction:)
                                                                       userInfo:nil
                                                                        repeats:YES];
    }
    else {
        _primitiveSpecificData = [NSDictionary dictionaryWithDictionary:_primitiveSpecificDataDuringPropertyChangeBlock];
        _primitiveSpecificDataDuringPropertyChangeBlock = nil;
        [self createGraphics];
    }
}

- (void)propertyChangeAnimationTimerAction:(id)userInfo
{
    _fractionOfAnimationElapsed += kMHDefaultPropertyChangeAnimationUpdateInterval/kMHDefaultPropertyChangeAnimationDuration;
    if (_fractionOfAnimationElapsed >= 1.0) {
        [_propertyChangeAnimationTimer invalidate];
        _propertyChangeAnimationTimer = nil;

        _primitiveSpecificData = [NSDictionary dictionaryWithDictionary:_primitiveSpecificDataDuringPropertyChangeBlock];
        _primitiveSpecificDataDuringPropertyChangeBlock = nil;
        [self createGraphics];
        return;
    }
    
    // interpolate between the _primitiveSpecificData and _primitiveSpecificDataDuringPropertyChangeBlock dictionaries
    NSMutableDictionary *interpolatedData = [[NSMutableDictionary alloc] initWithCapacity:0];
    for (NSString *key in _primitiveSpecificData) {
        
        NSArray <NSNumber *> *valuesArray1 = _primitiveSpecificData[key];
        NSArray <NSNumber *> *valuesArray2 = _primitiveSpecificDataDuringPropertyChangeBlock[key];
        
        // I am using a convenience C function weightedAverageOfTwoDoubleFloatArrays(...), defined at the top of this file
        NSArray <NSNumber *> *interpolatedValuesArray = weightedAverageOfTwoDoubleFloatArrays(_fractionOfAnimationElapsed, valuesArray1, valuesArray2);
        interpolatedData[key] = interpolatedValuesArray;
    }
    [self createGraphicsWithPrimitiveSpecificData:interpolatedData];
}






#pragma mark - Rendering into a graphics context

- (void)renderToPDFWithContextManager:(MHPDFRenderingContextManager *)contextManager
{
    CGContextRef pdfContext = contextManager.pdfContext;
    
    SKNode *spriteKitNode = self.spriteKitNode;
    SKShapeNode *shapeNode = (SKShapeNode *)[spriteKitNode childNodeWithName:kMHGraphicsPrimitiveShapeNodeName];    // FIXME: this makes an assumption that the node is a shape node. Safe?
    
    CGContextSetFillColorWithColor(pdfContext, shapeNode.fillColor.CGColor);
    CGContextSetStrokeColorWithColor(pdfContext, shapeNode.strokeColor.CGColor);
    CGContextSetLineWidth(pdfContext, shapeNode.lineWidth);
    
    CGContextAddPath(pdfContext, shapeNode.path);
    CGContextDrawPath(pdfContext, _drawingMode);
}


#pragma mark - Expression copying

- (instancetype)logicalCopy
{
    MHGraphicsPrimitive *myCopy = [[[self class] alloc] initWithType:_type
                                                         drawingMode:_drawingMode
                                                                path:_path
                                               primitiveSpecificData:[_primitiveSpecificData copy]];
    myCopy.codeRange = self.codeRange;
    return myCopy;
}



#pragma mark - dealloc

- (void)dealloc
{
    if (_path)
        CGPathRelease(_path);
}


@end
