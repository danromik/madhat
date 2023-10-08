//
//  NSScroller+KnobStyleExtension.h
//  MadHat
//
//  Created by Dan Romik on 8/8/21.
//  Copyright © 2021 Dan Romik. All rights reserved.
//

#import <AppKit/AppKit.h>


#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSScroller (KnobStyleExtension)

+ (NSScrollerKnobStyle)knobStyleAdaptedToBackgroundColor:(NSColor *)color;

@end

NS_ASSUME_NONNULL_END
