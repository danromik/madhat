//
//  NSScroller+KnobStyleExtension.m
//  MadHat
//
//  Created by Dan Romik on 8/8/21.
//  Copyright © 2021 Dan Romik. All rights reserved.
//

#import "NSScroller+KnobStyleExtension.h"

#import <AppKit/AppKit.h>


@implementation NSScroller (KnobStyleExtension)

+ (NSScrollerKnobStyle)knobStyleAdaptedToBackgroundColor:(NSColor *)color
{
    CIColor *myColorAsCIColor = [[CIColor alloc] initWithColor:color];
    CGFloat red = [myColorAsCIColor red];
    CGFloat green = [myColorAsCIColor green];
    CGFloat blue = [myColorAsCIColor blue];
    
    // the brightness is a weighted average of the red, green and blue components, see these references:
    // https://stackoverflow.com/questions/2509443/check-if-uicolor-is-dark-or-bright
    // https://www.w3.org/WAI/ER/WD-AERT/#color-contrast
    CGFloat brightness = 0.299 * red + 0.587 * green + 0.114 * blue;
    return (brightness < 0.5 ? NSScrollerKnobStyleLight : NSScrollerKnobStyleDark);
}

@end
