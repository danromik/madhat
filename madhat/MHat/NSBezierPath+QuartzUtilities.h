//
//  NSBezierPath+QuartzUtilities.m
//
//  Created by Dan Romik on 12/7/19.
//  Copyright © 2019 Dan Romik. All rights reserved.
//

#import <AppKit/AppKit.h>


#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSBezierPath (BezierPathQuartzUtilities)

- (CGPathRef)quartzPath;
+ (instancetype)bezierPathWithCGPath:(CGPathRef)cgPath;

@end

NS_ASSUME_NONNULL_END
