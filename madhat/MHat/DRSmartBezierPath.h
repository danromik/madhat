//
//  DRSmartBezierPath.h
//  MadHat
//
//  Created by Dan Romik on 8/2/20.
//  Copyright © 2020 Dan Romik. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NSBezierPath+QuartzUtilities.h"

NS_ASSUME_NONNULL_BEGIN

@interface DRSmartBezierPath : NSBezierPath     // FIXME: do I really need a subclass, or maybe make it a category on NSBezierPath?


- (CGFloat)totalArcLength;

// if a vlaue other than nil is passed to tangentVectorPtr, the tangent vector will be stored in the variable pointed to
- (CGPoint)pointAtArcLengthParameter:(CGFloat)length tangentVectorPointer:(nullable CGPoint *)tangentVectorPtr;

@end

NS_ASSUME_NONNULL_END
