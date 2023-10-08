//
//  DRSmartBezierPath.m
//  MadHat
//
//  Created by Dan Romik on 8/2/20.
//  Copyright © 2020 Dan Romik. All rights reserved.
//

#import "DRSmartBezierPath.h"


static CGPoint BezierPathTangentVector(CGPoint point0, CGPoint point1, CGPoint point2, CGPoint point3, CGFloat time)
{
    CGFloat vectorX, vectorY, vectorNorm;
    CGFloat t = time;
    vectorX = 3*(1-t)*(1-t)*(point1.x-point0.x) + 6*t*(1-t)*(point2.x-point1.x) + 3*t*t*(point3.x-point2.x);
    vectorY = 3*(1-t)*(1-t)*(point1.y-point0.y) + 6*t*(1-t)*(point2.y-point1.y) + 3*t*t*(point3.y-point2.y);
    vectorNorm = sqrt(vectorX * vectorX + vectorY * vectorY);
    return CGPointMake(vectorX/vectorNorm, vectorY/vectorNorm);
}


static CGFloat ArcLengthForCubicBezierCurveWithPoints(CGPoint point0, CGPoint point1, CGPoint point2, CGPoint point3, CGFloat tolerance)
{
    // The distance between the initial and end point is (obviously) a lower bound for the arc length
    CGFloat lowerBound = sqrt((point3.x-point0.x)*(point3.x-point0.x) + (point3.y-point0.y)*(point3.y-point0.y));

    // The sum of the distances between the point pairs p0-p1, p1-p2, p2-p3 and p3-p4 is (less obviously) an upper bound for the arc length
    // This observation appeared in the paper "Adaptive subdivision and the length and energy of Bezier curves" by J. Gravesen, Computational Geometry 8 (1997), 13-31. (Mentioned in the abstract and on the first paragraph on page 14.)
    CGFloat upperBound = sqrt((point1.x-point0.x)*(point1.x-point0.x) + (point1.y-point0.y)*(point1.y-point0.y))
                        + sqrt((point2.x-point1.x)*(point2.x-point1.x) + (point2.y-point1.y)*(point2.y-point1.y))
                        + sqrt((point3.x-point2.x)*(point3.x-point2.x) + (point3.y-point2.y)*(point3.y-point2.y));
    
    // Based on this observation, Gravesen suggests an algorithm for approximating the arc length based on repeated (recursive) subdivision. This is the algorithm implemented below.
    
    if (upperBound < lowerBound + tolerance) {
        // The average of the upper and lower bounds will typically be a better approximation than each of the bounds, so return that as an answer
        return (upperBound + lowerBound)/2.0;
    }
    
    // Since we have not met our error tolerance, subdivide the Bezier curve into two sub-curves.
    // It is easy to work out formulas for the four element points of the two subdivided curves by solving a few linear equations
    CGPoint firstHalfPoint0, firstHalfPoint1, firstHalfPoint2, firstHalfPoint3;
    CGPoint secondHalfPoint0, secondHalfPoint1, secondHalfPoint2, secondHalfPoint3;
    
    // Formulas for the subcurve points corresponding to the first half of the passed curve
    firstHalfPoint0 = point0;
    firstHalfPoint1 = CGPointMake((point0.x + point1.x)/2.0, (point0.y + point1.y)/2.0);
    firstHalfPoint2 = CGPointMake((point0.x + 2.0*point1.x + point2.x)/4.0, (point0.y + 2.0*point1.y + point2.y)/4.0);
    firstHalfPoint3 = CGPointMake((point0.x + 3.0*point1.x + 3.0*point2.x + point3.x)/8.0,
                                  (point0.y + 3.0*point1.y + 3.0*point2.y + point3.y)/8.0);

    // Formulas for the subcurve points corresponding to the second half of the passed curve
    secondHalfPoint0 = firstHalfPoint3;
    secondHalfPoint1 = CGPointMake((point1.x + 2.0*point2.x + point3.x)/4.0, (point1.y + 2.0*point2.y + point3.y)/4.0);
    secondHalfPoint2 = CGPointMake((point2.x + point3.x)/2.0, (point2.y + point3.y)/2.0);
    secondHalfPoint3 = point3;
    
    // FIXME: add some checking on the tolerance here to make sure we don't go into an infinite recursion
    
    // Now evaluate the arc length of each of the subcurves, passing a tolerance value that's half of what we are trying to stay within
    CGFloat arcLengthFirstHalf = ArcLengthForCubicBezierCurveWithPoints(firstHalfPoint0, firstHalfPoint1, firstHalfPoint2, firstHalfPoint3, tolerance/2.0);
    CGFloat arcLengthSecondHalf = ArcLengthForCubicBezierCurveWithPoints(secondHalfPoint0, secondHalfPoint1, secondHalfPoint2, secondHalfPoint3, tolerance/2.0);
    
    // Return the sum of the two subcurve arc lengths
    return arcLengthFirstHalf + arcLengthSecondHalf;
}



static CGFloat RecursivelyFindPointAtArcLengthParameter(
                            CGPoint point0, CGPoint point1, CGPoint point2, CGPoint point3,
                            CGFloat arcLengthAtBeginning,
                            CGFloat timeAtBeginning, CGFloat timeAtEnd,
                            CGFloat targetLength,
                            CGPoint *targetPointPtr,
                            CGFloat *timeAtTargetPointPtr,
                            bool *searchingForTargetPtr,
                            CGFloat tolerance)
{
    // The distance between the initial and end point is (obviously) a lower bound for the arc length
    CGFloat lowerBound = sqrt((point3.x-point0.x)*(point3.x-point0.x) + (point3.y-point0.y)*(point3.y-point0.y));

    // The sum of the distances between the point pairs p0-p1, p1-p2, p2-p3 and p3-p4 is (less obviously) an upper bound for the arc length
    // This observation appeared in the paper "Adaptive subdivision and the length and energy of Bezier curves" by J. Gravesen, Computational Geometry 8 (1997), 13-31. (Mentioned in the abstract and on the first paragraph on page 14.)
    CGFloat upperBound = sqrt((point1.x-point0.x)*(point1.x-point0.x) + (point1.y-point0.y)*(point1.y-point0.y))
                        + sqrt((point2.x-point1.x)*(point2.x-point1.x) + (point2.y-point1.y)*(point2.y-point1.y))
                        + sqrt((point3.x-point2.x)*(point3.x-point2.x) + (point3.y-point2.y)*(point3.y-point2.y));
    
    // Now we can use this observation, as in Gravesen's algorithm used in the ArcLengthForCubicBezierCurveWithPoints function above, to recursively and incrementally compute arc lengths of smallers and smaller subcurves in a way that homes in on a specific target value for the arc length and return the associated point, recording the value of the curve time parameter at that location
    
    CGFloat timeAtMidway = (timeAtBeginning+timeAtEnd)/2.0;
    
    if (upperBound < lowerBound + tolerance) {
        // The average of the upper and lower bounds will typically be a better approximation than each of the bounds, so return that as an answer
        CGFloat arcLengthApproximateValue = (upperBound + lowerBound)/2.0;
        
        // Record the target point if this is the first time during the calculation when the cumulative arc length exceeds the target value
        // FIXME: is there a way to do this without the awkward "searchingForTargetPtr" boolean reference?
        // FIXME: more generally, there seems to be some room for optimization in which the function wouldn't require as many arguments, so fewer variables would have to be copied in each function call. In theory I think I could eliminate targetPointPtr, timeAtTargetPointPtr, searchingForTargetPtr and targetLength (since the value of those variables doesn't change throughout the calculation) by routing the call through another function before the recursion begins and then storing the values of those variables in static variables that are accessible from within the current function scope. This would be less readable and understandable, but a bit more efficient. Not sure if the small efficiency gain is really worth it though.
        if ((*searchingForTargetPtr) && arcLengthAtBeginning+arcLengthApproximateValue > targetLength) {
            *targetPointPtr = CGPointMake((point0.x + 3.0*point1.x + 3.0*point2.x + point3.x)/8.0,
                                          (point0.y + 3.0*point1.y + 3.0*point2.y + point3.y)/8.0);
            *timeAtTargetPointPtr = timeAtMidway;
            *searchingForTargetPtr = false;
        }
        return arcLengthApproximateValue;
    }
    
    // Since we have not met our error tolerance, subdivide the Bezier curve into two sub-curves.
    // It is easy to work out formulas for the four element points of the two subdivided curves by solving a few linear equations
    CGPoint firstHalfPoint0, firstHalfPoint1, firstHalfPoint2, firstHalfPoint3;
    CGPoint secondHalfPoint0, secondHalfPoint1, secondHalfPoint2, secondHalfPoint3;
    
    // Formulas for the subcurve points corresponding to the first half of the passed curve
    firstHalfPoint0 = point0;
    firstHalfPoint1 = CGPointMake((point0.x + point1.x)/2.0, (point0.y + point1.y)/2.0);
    firstHalfPoint2 = CGPointMake((point0.x + 2.0*point1.x + point2.x)/4.0, (point0.y + 2.0*point1.y + point2.y)/4.0);
    firstHalfPoint3 = CGPointMake((point0.x + 3.0*point1.x + 3.0*point2.x + point3.x)/8.0,
                                  (point0.y + 3.0*point1.y + 3.0*point2.y + point3.y)/8.0);

    // Formulas for the subcurve points corresponding to the second half of the passed curve
    secondHalfPoint0 = firstHalfPoint3;
    secondHalfPoint1 = CGPointMake((point1.x + 2.0*point2.x + point3.x)/4.0, (point1.y + 2.0*point2.y + point3.y)/4.0);
    secondHalfPoint2 = CGPointMake((point2.x + point3.x)/2.0, (point2.y + point3.y)/2.0);
    secondHalfPoint3 = point3;
    
    // FIXME: add some checking on the tolerance here to make sure we don't go into an infinite recursion
    
    CGFloat halfTolerance = tolerance/2.0;
    
    // Now evaluate the arc length of each of the subcurves, passing a tolerance value that's half of what we are trying to stay within, and, in a small enhancement to Gravesen's algorithm, keep track of the target arc length value, the time parameters at the beginning and end of each subcurve being handled, the cumulative arc length of the curve up to the beginning of the current subcurve, and pointers to the target point variable and time at target point variables where the results of the computation will be stored
    CGFloat arcLengthFirstHalf = RecursivelyFindPointAtArcLengthParameter(
                                          firstHalfPoint0, firstHalfPoint1, firstHalfPoint2, firstHalfPoint3,
                                          arcLengthAtBeginning,
                                          timeAtBeginning, timeAtMidway,
                                          targetLength,
                                          targetPointPtr,
                                          timeAtTargetPointPtr,
                                          searchingForTargetPtr,
                                          halfTolerance);

    // Note: it's important for the calculation for the second half to take place after the calculation for the first helf
    CGFloat arcLengthSecondHalf = RecursivelyFindPointAtArcLengthParameter(
                                           secondHalfPoint0, secondHalfPoint1, secondHalfPoint2, secondHalfPoint3,
                                           arcLengthAtBeginning + arcLengthFirstHalf,
                                           timeAtMidway, timeAtEnd,
                                           targetLength,
                                           targetPointPtr,
                                           timeAtTargetPointPtr,
                                           searchingForTargetPtr,
                                           halfTolerance);
    
    // Return the sum of the two subcurve arc lengths
    return arcLengthFirstHalf + arcLengthSecondHalf;
}

static CGFloat FindPointAtArcLengthParameter(
                            CGPoint point0, CGPoint point1, CGPoint point2, CGPoint point3,
                            CGFloat arcLengthAtBeginning,
                            CGFloat targetLength,
                            CGPoint *targetPointPtr,
                            CGFloat *timeAtTargetPointPtr,
                            CGFloat tolerance)
{
    bool searching = true;
    return RecursivelyFindPointAtArcLengthParameter(point0, point1, point2, point3,
                                                    arcLengthAtBeginning,
                                                    0.0, 1.0, targetLength, targetPointPtr, timeAtTargetPointPtr,
                                                    &searching, tolerance);
}







@implementation DRSmartBezierPath



- (CGFloat)totalArcLength
{
    NSUInteger numberOfElements = self.elementCount;
    NSUInteger index;
    NSPoint currentPoint = CGPointZero;
    NSPoint elementPoints[3];
    CGFloat accumulatedLength = 0.0;
    for (index = 0; index < numberOfElements; index++) {
        NSBezierPathElement element = [self elementAtIndex:index associatedPoints:elementPoints];
        CGFloat elementArcLength = 0.0;
        switch (element) {
            case NSBezierPathElementMoveTo:
                elementArcLength = 0.0;
                currentPoint = elementPoints[0];
                break;
            case NSBezierPathElementLineTo:
            case NSBezierPathElementClosePath:  // FIXME: assuming here that closepath returns the starting point of the path. Check that this is corerct
            {
                CGFloat deltaX = elementPoints[0].x-currentPoint.x;
                CGFloat deltaY = elementPoints[0].y-currentPoint.y;
                elementArcLength = sqrt(deltaX * deltaX + deltaY * deltaY);
                currentPoint = elementPoints[0];
            }
                break;
            case NSBezierPathElementCurveTo:
                elementArcLength = ArcLengthForCubicBezierCurveWithPoints(currentPoint, elementPoints[0], elementPoints[1], elementPoints[2], 0.001);
                currentPoint = elementPoints[2];
                break;
        }
        accumulatedLength += elementArcLength;
    }
    return accumulatedLength;
}

- (CGPoint)pointAtArcLengthParameter:(CGFloat)length tangentVectorPointer:(nullable CGPoint *)tangentVectorPtr
{
    NSUInteger numberOfElements = self.elementCount;
    NSUInteger index;
    NSPoint currentPoint = CGPointZero;
    NSPoint elementPoints[3];
    CGFloat accumulatedLength = 0.0;
    for (index = 0; index < numberOfElements; index++) {
        NSBezierPathElement element = [self elementAtIndex:index associatedPoints:elementPoints];
        CGFloat elementArcLength = 0.0;
        switch (element) {
            case NSBezierPathElementMoveTo:
                elementArcLength = 0.0;
                currentPoint = elementPoints[0];
                break;
            case NSBezierPathElementLineTo:
            case NSBezierPathElementClosePath:  // FIXME: assuming here that closepath returns the starting point of the path. Check that this is correct
            {
                CGFloat deltaX = elementPoints[0].x-currentPoint.x;
                CGFloat deltaY = elementPoints[0].y-currentPoint.y;
                elementArcLength = sqrt(deltaX * deltaX + deltaY * deltaY);
                if (accumulatedLength + elementArcLength > length) {
                    CGFloat lineFraction = (length - accumulatedLength)/elementArcLength;
                    if (tangentVectorPtr != nil) {
                        CGFloat vectorNorm = sqrt(deltaX * deltaX + deltaY * deltaY);
                        *tangentVectorPtr = CGPointMake(deltaX/vectorNorm, deltaY/vectorNorm);
                    }
                    return CGPointMake(currentPoint.x + lineFraction * deltaX, currentPoint.y + lineFraction * deltaY);
                }
                currentPoint = elementPoints[0];
            }
                break;
            case NSBezierPathElementCurveTo: {
                CGPoint pointAtLength;
                CGFloat timeParameterAtLength;
                elementArcLength = FindPointAtArcLengthParameter(
                            currentPoint, elementPoints[0], elementPoints[1], elementPoints[2], // bezier curve control points
                            accumulatedLength,  // arc length at beginning
                            length,             // target length to look for
                            &pointAtLength,     // pointer to store target point, if found
                            &timeParameterAtLength,  // pointer to store time parameter at target point, if found
                            0.001               // error tolerance value
                            );
                if (accumulatedLength + elementArcLength > length) {
                    if (tangentVectorPtr != nil) {
                        *tangentVectorPtr = BezierPathTangentVector(
                                                currentPoint, elementPoints[0], elementPoints[1], elementPoints[2],
                                                timeParameterAtLength);
                    }
                    return pointAtLength;
                }
                currentPoint = elementPoints[2];
            }
                break;
        }
        accumulatedLength += elementArcLength;
    }
    return currentPoint;
}

@end


