//
//  MHColorCommand.h
//  MadHat
//
//  Created by Dan Romik on 10/23/19.
//  Copyright © 2019 Dan Romik. All rights reserved.
//

#import "MHCommand.h"


typedef enum {
    MHColorCommandTextForegroundColor,
    MHColorCommandTextHighlightColor,
    MHColorCommandParagraphBackgroundColor,
    MHColorCommandParagraphFrameColor,
    MHColorCommandPageBackgroundColor,
    MHColorCommandGraphicsStrokeColor,
    MHColorCommandGraphicsFillColor
} MHColorCommandType;


NS_ASSUME_NONNULL_BEGIN

@interface MHColorCommand : MHCommand <MHCommand>

+ (NSDictionary <NSString *, NSColor *> *)namedColors;


// FIXME: have some declared initializers to create the different types of color commands instead of using the MHCommand factory method

+ (instancetype)colorCommandOfType:(MHColorCommandType)type color:(NSColor *)color;

@end



@interface MHExpression (ColorParsingExtension)

- (nullable NSColor *)colorValue;   // returns nil if the expression could not be parsed as a color

@end


NS_ASSUME_NONNULL_END
