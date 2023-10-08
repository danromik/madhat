//
//  MHMiscCommand.m
//  MadHat
//
//  Created by Dan Romik on 12/2/19.
//  Copyright © 2019 Dan Romik. All rights reserved.
//

#import "MHMiscCommand.h"
#import "MHHorizontalLayoutContainer.h"
#import "MHFraction.h"
#import "MHGlyphAtom.h"
#import "MHMathAtom.h"
#import "MHColorCommand.h"
#import "MHTable.h"
#import "MHGraphicsCanvas.h"
#import "MHGraphicsPrimitive.h"

static NSString * const kMHMiscCommandNameFillerText = @"fillertext";
static NSString * const kMHMiscCommandNameDebug = @"debug";
static NSString * const kMHMiscCommandNameAllNamedColors = @"named colors";



@implementation MHMiscCommand


+ (MHExpression *)commandNamed:(NSString *)name withParameters:(NSDictionary *)parameters argument:(MHHorizontalLayoutContainer *)argument
{
    static NSString *fillertext = @"Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.";
    NSUInteger fillertextLength = fillertext.length;

    if ([name isEqualToString:kMHMiscCommandNameDebug]) {
        return [MHHorizontalLayoutContainer containerWithPlainTextString:argument.description];
    }
    if ([name isEqualToString:kMHMiscCommandNameFillerText]) {
        NSUInteger numberOfWords = [argument.stringValue intValue];
        if (numberOfWords == 0)
            return [MHHorizontalLayoutContainer containerWithPlainTextString:fillertext];
        NSRange range;
        range.location = 0;
        range.length = fillertext.length;
        for (NSUInteger index = 0; index < numberOfWords; index++) {
            range = [fillertext rangeOfString:@" " options:0 range:range];
            if (range.location == NSNotFound)
                return [MHHorizontalLayoutContainer containerWithPlainTextString:fillertext];
            range.location++;
            range.length = fillertextLength - range.location;
        }
        
        return [MHHorizontalLayoutContainer containerWithPlainTextString:[fillertext substringToIndex:range.location-1]];
    }
        
    if ([name isEqualToString:kMHMiscCommandNameAllNamedColors]) {
        // Format an expression with a list of all named colors
        NSDictionary <NSString *, NSColor *> *namedColors = [MHColorCommand namedColors];

        NSUInteger numberOfColors = namedColors.count;
        NSMutableArray *tableRows = [[NSMutableArray alloc] initWithCapacity:numberOfColors];

        MHDimensions colorRectangleDimensions;
        colorRectangleDimensions.width = 100.0;
        colorRectangleDimensions.height = 16.0;
        colorRectangleDimensions.depth = 2.0;
        
        MHGraphicsRectangle viewRectangle;
        viewRectangle.minX = 0.0;
        viewRectangle.maxX = colorRectangleDimensions.width;
        viewRectangle.minY = 0.0;
        viewRectangle.maxY = colorRectangleDimensions.height;
        
        NSColor *grayColor = [NSColor grayColor];
        NSArray *namedColorKeys = [namedColors allKeys];
        for (NSUInteger colorPairIndex = 0; colorPairIndex < numberOfColors; colorPairIndex+=2) {
            NSMutableArray *row = [[NSMutableArray alloc] initWithCapacity:2];
            for (NSUInteger zeroOrOne = 0; zeroOrOne < 2; zeroOrOne++) {
                NSUInteger colorIndex = colorPairIndex + zeroOrOne;
                if (colorIndex < numberOfColors) {
                    NSString *namedColor = namedColorKeys[colorIndex];

                    NSColor *color = namedColors[namedColor];
                    MHExpression *fillColorCommand = [MHColorCommand colorCommandOfType:MHColorCommandGraphicsFillColor color:color];
                    MHExpression *strokeColorCommand = [MHColorCommand colorCommandOfType:MHColorCommandGraphicsStrokeColor color:grayColor];
                    MHHorizontalLayoutContainer *colorNameExpression = [MHHorizontalLayoutContainer containerWithPlainTextString:namedColor];
                    [row addObject:colorNameExpression];

                    MHHorizontalLayoutContainer *colorValueContainer = [MHHorizontalLayoutContainer expression];
                    MHGraphicsPrimitive *rectangle = [MHGraphicsPrimitive rectangleGraphicsWithRect:CGRectMake(0.0,
                                                                            -colorRectangleDimensions.depth,
                                                                            colorRectangleDimensions.width,
                                                                            colorRectangleDimensions.depth + colorRectangleDimensions.height)
                                                                                        drawingMode:kCGPathFillStroke];
                    [colorValueContainer addSubexpression:strokeColorCommand];
                    [colorValueContainer addSubexpression:fillColorCommand];
                    [colorValueContainer addSubexpression:rectangle];

                    MHGraphicsCanvas *canvas = [MHGraphicsCanvas graphicsCanvasWithDimensions:colorRectangleDimensions
                                                                                viewRectangle:viewRectangle
                                                                                     contents:colorValueContainer
                                                                                 cropContents:false
                                                                                    drawFrame:false];
                    
                    [row addObject:canvas];
                }
            }
            [tableRows addObject:row];
        }
        MHTable *table = [[MHTable alloc] initWithArrayOfExpressionArrays:tableRows];
        table.horizontalLinesSpecification = MHTableLinesShowAll;
        table.verticalLinesSpecification = MHTableLinesCustom;
        NSArray <NSNumber *> *tableVerticalLineBooleanSpecifiers = @[ @true, @false, @true, @false ];
        table.verticalLineBooleanSpecifiers = tableVerticalLineBooleanSpecifiers;
        table.framed = true;
        return table;

        
        
            
//                // *** 6/27/20 the code below resulted in a weird bug, I think I fixed it by adding an if conditional test in the spriteKitNode method of MHHorizontalLayoutContainer.m (search for "***" in that method) Update 7/30: I think I fixed the crashing bug with the new logicalCopy improvements
            
//                NSColor *color = namedColors[namedColor];
//
//                CGFloat red, green, blue, alpha;
//                [color getRed:&red green:&green blue:&blue alpha:&alpha];
//
//                MHHorizontalLayoutContainer *colorNameExpression = [MHHorizontalLayoutContainer containerWithPlainTextString:namedColor];
//                [container addSubexpression:colorNameExpression];
//                [container addListDelimiterWithType:MHListDelimiterTypePrimary];
//
//                MHExpression *colorCommand = [MHColorCommand colorCommandOfType:MHColorCommandTextForegroundColor
//                                                                          color:color];
//
//
//                [container addSubexpression:colorCommand];
//                [container addSubexpression:[MHHorizontalLayoutContainer containerWithPlainTextString:@"A quick brown fox jumps over the lazy dog"]];
//                [container addListDelimiterWithType:MHListDelimiterTypeSecondary];
//
//
//
//            }
//            // FIXME: this produces a warning and should be refactored/moved/improved. The command probably shouldn't be handled in this source file
//            return [[MHTable alloc] initWithArrayOfExpressionArrays:[container delimitedBlockTable]];
////            return container;
    }

    
    return nil;
}


+ (NSArray <NSString *> *)recognizedCommands
{
    return @[ kMHMiscCommandNameFillerText, kMHMiscCommandNameDebug, kMHMiscCommandNameAllNamedColors ];
}



@end
