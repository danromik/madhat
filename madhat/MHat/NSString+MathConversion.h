//
//  NSString+MathConversion.h
//  MadHat
//
//  Created by Dan Romik on 1/9/20.
//  Copyright © 2020 Dan Romik. All rights reserved.
//

#import <AppKit/AppKit.h>


#import <Foundation/Foundation.h>
#import "MHMathFontSystem.h"

NS_ASSUME_NONNULL_BEGIN

@interface NSString (MathConversion)

+ (NSString *)stringByConvertingRomanCharactersInString:(NSString *)string toMathFontVariant:(MHMathFontVariant)mathFontVariant;

@end

NS_ASSUME_NONNULL_END
