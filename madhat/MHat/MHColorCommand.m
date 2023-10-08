//
//  MHColorCommand.m
//  MadHat
//
//  Created by Dan Romik on 10/23/19.
//  Copyright © 2019 Dan Romik. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>
#import "MHColorCommand.h"
#import "MHHorizontalLayoutContainer.h"
#import "MHStyleIncludes.h"
#import "MHTable.h"


NSString * const kMHColorTextForegroundColorCommandName = @"color";
NSString * const kMHColorTextHighlightColorCommandName = @"highlight color";
NSString * const kMHColorParagraphBackgroundColorCommandName = @"box background color";
NSString * const kMHColorParagraphFrameColorCommandName = @"box frame color";
NSString * const kMHColorPageBackgroundColorCommandName = @"page background color";
NSString * const kMHColorStrokeColorCommandName = @"stroke color";
NSString * const kMHColorFillColorCommandName = @"fill color";

NSString * const kMHColorCommandNamedColorsPlistFilename = @"colors";
NSString * const kMHColorCommandNamedColorsPlistFileExtension = @"plist";

static NSDictionary <NSString *, NSColor *> *MHColorCommandNamedColors = nil;



@interface MHColorCommand ()
{
    MHColorCommandType _type;
    NSColor *_color;
}

@end


@implementation MHColorCommand



#pragma mark - Constructors

+ (instancetype)colorCommandOfType:(MHColorCommandType)type color:(NSColor *)color
{
    return [[self alloc] initWithColorCommandType:type color:color];
}

- (instancetype)initWithColorCommandType:(MHColorCommandType)type color:(NSColor *)color
{
    if (self = [super init]) {
        _type = type;
        _color = color;
    }
    return self;
}

#pragma mark - MHCommand protocol

+ (instancetype)commandNamed:(NSString *)name withParameters:(NSDictionary *)parameters argument:(MHHorizontalLayoutContainer *)argument
{
    MHColorCommandType commandType;
    if ([name isEqualToString:kMHColorTextForegroundColorCommandName]) {
        commandType = MHColorCommandTextForegroundColor;
    }
    else if ([name isEqualToString:kMHColorTextHighlightColorCommandName]) {
        commandType = MHColorCommandTextHighlightColor;
    }
    else if ([name isEqualToString:kMHColorParagraphBackgroundColorCommandName]) {
        commandType = MHColorCommandParagraphBackgroundColor;
    }
    else if ([name isEqualToString:kMHColorParagraphFrameColorCommandName]) {
        commandType = MHColorCommandParagraphFrameColor;
    }
    else if ([name isEqualToString:kMHColorPageBackgroundColorCommandName]) {
        commandType = MHColorCommandPageBackgroundColor;
    }
    else if ([name isEqualToString:kMHColorStrokeColorCommandName]) {
        commandType = MHColorCommandGraphicsStrokeColor;
    }
    else if ([name isEqualToString:kMHColorFillColorCommandName]) {
        commandType = MHColorCommandGraphicsFillColor;
    }
    else
        return nil;
    
    NSColor *argumentColor = [argument colorValue];
    
    if (argumentColor)
        return [self colorCommandOfType:commandType color:argumentColor];
    
    return nil;
}

+ (NSArray <NSString *> *)recognizedCommands
{
    return @[
        kMHColorTextForegroundColorCommandName,
        kMHColorTextHighlightColorCommandName,
        kMHColorParagraphBackgroundColorCommandName,
        kMHColorParagraphFrameColorCommandName,
        kMHColorPageBackgroundColorCommandName,
        kMHColorStrokeColorCommandName,
        kMHColorFillColorCommandName
    ];
}



#pragma mark - typeset method

- (void)typesetWithContextManager:(MHTypesettingContextManager *)contextManager
{
//    self.presentationMode = MHExpressionPresentationModePublishing;     // FIXME: temporarily disabling editing mode to work on MHGraphicsCommand
    
    [super typesetWithContextManager:contextManager];
    switch (_type) {
        case MHColorCommandTextForegroundColor:
            contextManager.textForegroundColor = _color;
            break;
        case MHColorCommandTextHighlightColor:
            contextManager.textHighlightColor = _color;
            break;
        case MHColorCommandParagraphBackgroundColor:
            contextManager.paragraphBackgroundColor = _color;
            break;
        case MHColorCommandParagraphFrameColor:
            contextManager.paragraphFrameColor = _color;
            break;
        case MHColorCommandPageBackgroundColor:
            contextManager.pageBackgroundColor = _color;
            break;
        case MHColorCommandGraphicsStrokeColor:
            contextManager.strokeColor = _color;
            break;
        case MHColorCommandGraphicsFillColor:
            contextManager.fillColor = _color;
            break;
    }
}




#pragma mark - Expression copying

- (instancetype)logicalCopy
{
    return [[self class] colorCommandOfType:_type color:_color];
}


#pragma mark - Other methods


+ (NSDictionary <NSString *, NSColor *> *)namedColors
{
    if (!MHColorCommandNamedColors) {
        NSString *filename = [[NSBundle mainBundle] pathForResource:kMHColorCommandNamedColorsPlistFilename
                                                             ofType:kMHColorCommandNamedColorsPlistFileExtension];
        NSDictionary *colors = [NSDictionary dictionaryWithContentsOfFile:filename];
        NSMutableDictionary *parsedColors = [[NSMutableDictionary alloc] initWithCapacity:0];
        for (NSString *colorName in colors) {
            NSArray *components = colors[colorName];
            CGFloat red = [(NSNumber *)(components[0]) floatValue];
            CGFloat green = [(NSNumber *)(components[1]) floatValue];
            CGFloat blue = [(NSNumber *)(components[2]) floatValue];
            parsedColors[colorName] = [NSColor colorWithRed:red green:green blue:blue alpha:1.0];
        }
        MHColorCommandNamedColors = [NSDictionary dictionaryWithDictionary:parsedColors];
    }
    return MHColorCommandNamedColors;
}


@end



@implementation MHExpression (ColorParsingExtension)

- (nullable NSColor *)colorValue
{
    NSUInteger numberOfDelimitedBlocks;
    if (![self isKindOfClass:[MHLinearContainer class]] ||
        (numberOfDelimitedBlocks=[(MHLinearContainer *)self numberOfDelimitedBlocks]) == 1) {
        // Interpret the argument as a named color
        NSString *colorName = [self stringValue];
        NSDictionary <NSString *, NSColor *> *namedColors = [MHColorCommand namedColors];
        return namedColors[colorName];
    }
    else if (numberOfDelimitedBlocks == 3 || numberOfDelimitedBlocks == 4) {
        // Interpret the argument as a triple of RGB values or a quadruple of RGBA values
        CGFloat red = [[(MHLinearContainer *)self expressionFromDelimitedBlockAtIndex:0] floatValue];
        CGFloat green = [[(MHLinearContainer *)self expressionFromDelimitedBlockAtIndex:1] floatValue];
        CGFloat blue = [[(MHLinearContainer *)self expressionFromDelimitedBlockAtIndex:2] floatValue];
        CGFloat alpha;
        
        if (numberOfDelimitedBlocks == 4) {
            alpha = [[(MHLinearContainer *)self expressionFromDelimitedBlockAtIndex:3] floatValue];
            if (alpha < 0.0)
                alpha = 0.0;
            else if (alpha > 1.0)
                alpha = 1.0;
        }
        else
            alpha = 1.0;
        
        if (red < 0.0)
            red = 0.0;
        else if (red > 1.0)
            red = 1.0;

        if (green < 0.0)
            green = 0.0;
        else if (green > 1.0)
            green = 1.0;

        if (blue < 0.0)
            blue = 0.0;
        else if (blue > 1.0)
            blue = 1.0;
        
        NSColor *color = [NSColor colorWithRed:red green:green blue:blue alpha:alpha];
        return color;
    }
    
    return nil;
}

@end

