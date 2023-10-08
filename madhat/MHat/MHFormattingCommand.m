//
//  MHFormattingCommand.m
//  MadHat
//
//  Created by Dan Romik on 10/31/19.
//  Copyright © 2019 Dan Romik. All rights reserved.
//


#import "MHFormattingCommand.h"
#import "MHHorizontalLayoutContainer.h"
#import "MHStyleIncludes.h"

// Basic typing style commands
static NSString * const kMHFormattingCommandCommandNameFontSize      = @"font size";
static NSString * const kMHFormattingCommandCommandNameFontName      = @"font";
static NSString * const kMHFormattingCommandCommandNameEditFontName  = @"edit font";
static NSString * const kMHFormattingCommandCommandNameMathFontName  = @"math font";
static NSString * const kMHFormattingCommandCommandNameFontClusterName = @"font cluster";
static NSString * const kMHFormattingCommandCommandNameBold          = @"bold on";
static NSString * const kMHFormattingCommandCommandNameUnbold        = @"bold off";
static NSString * const kMHFormattingCommandCommandNameItalic        = @"italic on";
static NSString * const kMHFormattingCommandCommandNameUnitalic      = @"italic off";
static NSString * const kMHFormattingCommandCommandNameHighlight     = @"highlight on";
static NSString * const kMHFormattingCommandCommandNameUnhighlight   = @"highlight off";
static NSString * const kMHFormattingCommandCommandNameUnderline     = @"underline on";
static NSString * const kMHFormattingCommandCommandNameNoUnderline   = @"underline off";
static NSString * const kMHFormattingCommandCommandNameStrikethrough = @"strikethrough on";
static NSString * const kMHFormattingCommandCommandNameNoStrikethrough = @"strikethrough off";


// Paragraph styling commands
static NSString * const kMHFormattingCommandCommandNameSuppressParagraphIndent = @"suppress paragraph indent";
static NSString * const kMHFormattingCommandCommandNameForceNewParagraph = @"new paragraph";


static NSDictionary <NSString *, NSArray *> *MHFontClusters = nil;

@interface MHFormattingCommand ()
{
    MHFormattingCommandType _type;
    CGFloat _floatArgument;
    NSString *_stringArgument;
}

@end



@implementation MHFormattingCommand



#pragma mark - MHCommand protocol

+ (instancetype)commandNamed:(NSString *)name withParameters:(NSDictionary *)parameters argument:(MHHorizontalLayoutContainer *)argument
{
    if ([name isEqualToString:kMHFormattingCommandCommandNameFontSize]) {
        return [self fontSizeCommand:[argument floatValue]];
    }
    else if ([name isEqualToString:kMHFormattingCommandCommandNameFontName]) {
        return [self fontFormattingCommandWithType:MHFormattingCommandFont fontName:[argument stringValue]];
    }
    else if ([name isEqualToString:kMHFormattingCommandCommandNameEditFontName]) {
        return [self fontFormattingCommandWithType:MHFormattingCommandEditFont fontName:[argument stringValue]];
    }
    else if ([name isEqualToString:kMHFormattingCommandCommandNameMathFontName]) {
        return [self fontFormattingCommandWithType:MHFormattingCommandMathFont fontName:[argument stringValue]];
    }
    else if ([name isEqualToString:kMHFormattingCommandCommandNameBold]) {
        return [self formattingCommandWithNoArgumentOfType:MHFormattingCommandBold];
    }
    else if ([name isEqualToString:kMHFormattingCommandCommandNameUnbold]) {
        return [self formattingCommandWithNoArgumentOfType:MHFormattingCommandUnbold];
    }
    else if ([name isEqualToString:kMHFormattingCommandCommandNameItalic]) {
        return [self formattingCommandWithNoArgumentOfType:MHFormattingCommandItalic];
    }
    else if ([name isEqualToString:kMHFormattingCommandCommandNameUnitalic]) {
        return [self formattingCommandWithNoArgumentOfType:MHFormattingCommandUnitalic];
    }
    else if ([name isEqualToString:kMHFormattingCommandCommandNameHighlight]) {
        return [self formattingCommandWithNoArgumentOfType:MHFormattingCommandHighlight];
    }
    else if ([name isEqualToString:kMHFormattingCommandCommandNameUnhighlight]) {
        return [self formattingCommandWithNoArgumentOfType:MHFormattingCommandUnhighlight];
    }
    else if ([name isEqualToString:kMHFormattingCommandCommandNameUnderline]) {
        return [self formattingCommandWithNoArgumentOfType:MHFormattingCommandUnderline];
    }
    else if ([name isEqualToString:kMHFormattingCommandCommandNameNoUnderline]) {
        return [self formattingCommandWithNoArgumentOfType:MHFormattingCommandNoUnderline];
    }
    else if ([name isEqualToString:kMHFormattingCommandCommandNameStrikethrough]) {
        return [self formattingCommandWithNoArgumentOfType:MHFormattingCommandStrikethrough];
    }
    else if ([name isEqualToString:kMHFormattingCommandCommandNameNoStrikethrough]) {
        return [self formattingCommandWithNoArgumentOfType:MHFormattingCommandNoStrikethrough];
    }
    else if ([name isEqualToString:kMHFormattingCommandCommandNameFontClusterName]) {
        return [self fontFormattingCommandWithType:MHFormattingCommandFontCluster fontName:[argument stringValue]];
    }
    else if ([name isEqualToString:kMHFormattingCommandCommandNameSuppressParagraphIndent]) {
        return [self suppressParagraphIndentCommand];
    }
    else if ([name isEqualToString:kMHFormattingCommandCommandNameForceNewParagraph]) {
        return [self forceNewParagraphCommand];
    }


    return nil; // [super commandNamed:name withParameters:parameters argument:argument];
}

+ (NSArray <NSString *> *)recognizedCommands
{
    return @[
        kMHFormattingCommandCommandNameFontSize,
        kMHFormattingCommandCommandNameFontName,
        kMHFormattingCommandCommandNameEditFontName,
        kMHFormattingCommandCommandNameMathFontName,
        kMHFormattingCommandCommandNameBold,
        kMHFormattingCommandCommandNameUnbold,
        kMHFormattingCommandCommandNameItalic,
        kMHFormattingCommandCommandNameUnitalic,
        kMHFormattingCommandCommandNameHighlight,
        kMHFormattingCommandCommandNameUnhighlight,
        kMHFormattingCommandCommandNameUnderline,
        kMHFormattingCommandCommandNameNoUnderline,
        kMHFormattingCommandCommandNameStrikethrough,
        kMHFormattingCommandCommandNameNoStrikethrough,
        kMHFormattingCommandCommandNameSuppressParagraphIndent,
        kMHFormattingCommandCommandNameForceNewParagraph
    ];
}


#pragma mark - Constructors

+ (instancetype)formattingCommandWithNoArgumentOfType:(MHFormattingCommandType)type
{
    return [[self alloc] initWithType:type];
}

- (instancetype)initWithType:(MHFormattingCommandType)type floatArgument:(CGFloat)floatArgument stringArgument:(nullable NSString *)stringArgument
{
    if (self = [super init]) {
        _type = type;
        _floatArgument = floatArgument;
        _stringArgument = stringArgument;
    }
    return self;
}

- (instancetype)initWithType:(MHFormattingCommandType)type
{
    if (self = [super init]) {
        _type = type;
    }
    return self;
}


+ (instancetype)fontFormattingCommandWithType:(MHFormattingCommandType)type fontName:(NSString *)fontName
{
    return [[self alloc] initFontFormattingCommandWithType:type fontName:fontName];
}

- (instancetype)initFontFormattingCommandWithType:(MHFormattingCommandType)type fontName:(NSString *)fontName
{
    if (self = [super init]) {
        _type = type;
        _stringArgument = fontName;
    }
    return self;
}

+ (instancetype)fontSizeCommand:(CGFloat)fontSize
{
    return [[self alloc] initFontSizeCommand:fontSize];
}

- (instancetype)initFontSizeCommand:(CGFloat)fontSize
{
    if (self = [super init]) {
        _type = MHFormattingCommandFontSize;
        _floatArgument = fontSize;
    }
    return self;
}

+ (instancetype)suppressParagraphIndentCommand
{
    return [[self alloc] initWithSuppressParagraphIndentCommand];
}

- (instancetype)initWithSuppressParagraphIndentCommand
{
    if (self = [super init]) {
        _type = MHFormattingCommandSuppressParagraphIndent;
    }
    return self;
}

+ (instancetype)forceNewParagraphCommand
{
    return [[self alloc] initWithForceNewParagraphCommand];
}

- (instancetype)initWithForceNewParagraphCommand
{
    if (self = [super init]) {
        _type = MHFormattingCommandForceNewParagraph;
    }
    return self;
}




#pragma mark - typeset method


- (void)typesetWithContextManager:(MHTypesettingContextManager *)contextManager
{
    switch (_type) {
        case MHFormattingCommandFontSize:
            [contextManager setBaseFontSize:_floatArgument];
            break;
        case MHFormattingCommandFont:
            [contextManager setTextFontName:_stringArgument forPresentationMode:MHExpressionPresentationModePublishing];
            break;
        case MHFormattingCommandEditFont:
            [contextManager setTextFontName:_stringArgument forPresentationMode:MHExpressionPresentationModeEditing];
            break;
        case MHFormattingCommandMathFont:
            [contextManager setMathFontName:_stringArgument];
            break;
        case MHFormattingCommandBold:
            [contextManager setTextBold:true];
            break;
        case MHFormattingCommandUnbold:
            [contextManager setTextBold:false];
            break;
        case MHFormattingCommandItalic:
            [contextManager setTextItalic:true];
            break;
        case MHFormattingCommandUnitalic:
            [contextManager setTextItalic:false];
            break;
        case MHFormattingCommandHighlight:
            [contextManager setTextHighlighting:true];
            break;
        case MHFormattingCommandUnhighlight:
            [contextManager setTextHighlighting:false];
            break;
        case MHFormattingCommandUnderline:
            [contextManager setTextUnderlining:true];
            break;
        case MHFormattingCommandNoUnderline:
            [contextManager setTextUnderlining:false];
            break;
        case MHFormattingCommandStrikethrough:
            [contextManager setTextStrikethrough:true];
            break;
        case MHFormattingCommandNoStrikethrough:
            [contextManager setTextStrikethrough:false];
            break;
        case MHFormattingCommandSuppressParagraphIndent:
            contextManager.paragraphHasIndentSuppressed = YES;
            break;
        case MHFormattingCommandForceNewParagraph:
            contextManager.paragraphForcedAsNewParagraph = YES;
            break;
        case MHFormattingCommandFontCluster: {
            if (!MHFontClusters) {
                
                // FIXME: this information shouldn't be hard-coded into the source code but should be loaded dynamically
                
                // lazily populate the dictionary of font clusters - this will only happen once
                NSString *latinModernFontClusterName = @"latin modern";
                NSArray *latinModernFontClusterFontFamilyNames = @[
                    @"Latin Modern Roman", @"Latin Modern Math"
                ];
                
                NSString *termesFontClusterName = @"termes";
                NSArray *termesFontClusterFontFamilyNames = @[
                    @"TeX Gyre Termes", @"TeX Gyre Termes Math"
                ];

                NSString *bonumFontClusterName = @"bonum";
                NSArray *bonumFontClusterFontFamilyNames = @[
                    @"TeX Gyre Bonum", @"TeX Gyre Bonum Math"
                ];

                NSString *scholaFontClusterName = @"schola";
                NSArray *scholaFontClusterFontFamilyNames = @[
                    @"TeX Gyre Schola", @"TeX Gyre Schola Math"
                ];

                NSString *pagellaFontClusterName = @"pagella";
                NSArray *pagellaFontClusterFontFamilyNames = @[
                    @"TeX Gyre Pagella", @"TeX Gyre Pagella Math"
                ];
                
                MHFontClusters = @{
                    latinModernFontClusterName : latinModernFontClusterFontFamilyNames,
                    termesFontClusterName : termesFontClusterFontFamilyNames,
                    bonumFontClusterName : bonumFontClusterFontFamilyNames,
                    scholaFontClusterName : scholaFontClusterFontFamilyNames,
                    pagellaFontClusterName : pagellaFontClusterFontFamilyNames,
                };
            }
            NSArray *fontClusterArray = MHFontClusters[_stringArgument];
            if (fontClusterArray) {
                NSString *textFont = fontClusterArray[0];
                NSString *mathFont = fontClusterArray[1];
                [contextManager setTextFontName:textFont forPresentationMode:MHExpressionPresentationModePublishing];
                [contextManager setTextFontName:textFont forPresentationMode:MHExpressionPresentationModeEditing];
                [contextManager setMathFontName:mathFont];
            }
        }
            break;
    }
}







#pragma mark - Expression copying

- (instancetype)logicalCopy
{
    return [[[self class] alloc] initWithType:_type floatArgument:_floatArgument stringArgument:_stringArgument];
}



- (NSString *)exportedLaTeXValue
{
    switch (_type) {
        case MHFormattingCommandSuppressParagraphIndent:
            return @"\\noindent{}";
            break;
        case MHFormattingCommandForceNewParagraph:
            return @"\n";
            break;
            
        case MHFormattingCommandFontSize:
        case MHFormattingCommandFont:
        case MHFormattingCommandEditFont:
        case MHFormattingCommandMathFont:
        case MHFormattingCommandFontCluster:
        case MHFormattingCommandBold:
        case MHFormattingCommandUnbold:
        case MHFormattingCommandItalic:
        case MHFormattingCommandUnitalic:
        case MHFormattingCommandHighlight:
        case MHFormattingCommandUnhighlight:
        case MHFormattingCommandUnderline:
        case MHFormattingCommandNoUnderline:
        case MHFormattingCommandStrikethrough:
        case MHFormattingCommandNoStrikethrough:
            // FIXME: what to do here?
            break;
    }
    return super.exportedLaTeXValue;
}


@end
