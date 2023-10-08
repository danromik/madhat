////
////  MHSourceCodeTextView+ColorSchemes.m
////  MadHat
////
////  Created by Dan Romik on 6/30/21.
////  Copyright © 2021 Dan Romik. All rights reserved.
////
//
//#import "MHSourceCodeTextView+ColorSchemes.h"
//#import "NSScroller+KnobStyleExtension.h"
//#import "AppDelegate.h"
//#import <AppKit/AppKit.h>
//
//NSString * const kMHSourceCodeSyntaxColorSchemesPlistFilename = @"syntax-colorschemes";
//NSString * const kMHSourceCodeSyntaxColorSchemesPlistFileExtension = @"plist";
//
//
//
//
//NSColor *NSColorFromRGBValuesArray(NSArray *valuesArray) {
//    return [NSColor colorWithRed:[valuesArray[0] doubleValue]
//                           green:[valuesArray[1] doubleValue]
//                            blue:[valuesArray[2] doubleValue]
//                           alpha:1.0];
//}
//
//
//
//@implementation MHSourceCodeTextView (ColorSchemes)
//
//
//static NSString * const kLightColorSchemeName = @"Light";
//static NSString * const kDarkColorSchemeName = @"Dark";
//
//static NSString * const kColorSchemeColorFieldBackground = @"background";
//static NSString * const kColorSchemeColorFieldInsertionPoint = @"insertion point";
//static NSString * const kColorSchemeColorFieldText = @"text";
//static NSString * const kColorSchemeColorFieldMath = @"math";
//static NSString * const kColorSchemeColorFieldMathBackground = @"math background";
//static NSString * const kColorSchemeColorFieldCommand = @"command";
//static NSString * const kColorSchemeColorFieldUnresolvedCommand = @"unresolved command";
//static NSString * const kColorSchemeColorFieldMathKeyword = @"math keyword";
//static NSString * const kColorSchemeColorFieldAssignment = @"assignment";
//static NSString * const kColorSchemeColorFieldBlockMarker = @"block marker";
//static NSString * const kColorSchemeColorFieldListDelimiter = @"list delimiter";
//static NSString * const kColorSchemeColorFieldModeSwitch = @"mode switch";
//static NSString * const kColorSchemeColorFieldComment = @"comment";
//static NSString * const kColorSchemeColorFieldAttributes = @"attributes";
//static NSString * const kColorSchemeColorFieldQuotedCode = @"quoted code";
//static NSString * const kColorSchemeColorFieldQuotedCodeBackground = @"quoted code background";
//static NSString * const kColorSchemeColorFieldCodeAnnotation = @"code annotation";
//static NSString * const kColorSchemeColorFieldNotScanned = @"not scanned";
//static NSString * const kColorSchemeColorFieldFallback = @"fallback";
//
//static MHSourceCodeColorScheme lightColorScheme;
//static bool lightColorSchemeLoaded;
//
//static MHSourceCodeColorScheme darkColorScheme;
//static bool darkColorSchemeLoaded;
//
//
//
//
//+ (MHSourceCodeColorScheme)lightColorScheme
//{
//    if (!lightColorSchemeLoaded) {
//
//        NSString *colorSchemesfilename = [[NSBundle mainBundle] pathForResource:kMHSourceCodeSyntaxColorSchemesPlistFilename
//                                                                         ofType:kMHSourceCodeSyntaxColorSchemesPlistFileExtension];
//        NSDictionary *colorSchemesDict = [NSDictionary dictionaryWithContentsOfFile:colorSchemesfilename];
//        NSDictionary *lightColorSchemeDict = colorSchemesDict[kLightColorSchemeName];
//
//        lightColorScheme.backgroundColor = NSColorFromRGBValuesArray(lightColorSchemeDict[kColorSchemeColorFieldBackground]);
//        lightColorScheme.insertionPointColor = NSColorFromRGBValuesArray(lightColorSchemeDict[kColorSchemeColorFieldInsertionPoint]);
//        lightColorScheme.textColor = NSColorFromRGBValuesArray(lightColorSchemeDict[kColorSchemeColorFieldText]);
//        lightColorScheme.mathModeColor = NSColorFromRGBValuesArray(lightColorSchemeDict[kColorSchemeColorFieldMath]);
//        lightColorScheme.mathModeBackgroundColor = NSColorFromRGBValuesArray(lightColorSchemeDict[kColorSchemeColorFieldMathBackground]);
//        lightColorScheme.commandColor = NSColorFromRGBValuesArray(lightColorSchemeDict[kColorSchemeColorFieldCommand]);
//        lightColorScheme.unresolvedCommandColor = NSColorFromRGBValuesArray(lightColorSchemeDict[kColorSchemeColorFieldUnresolvedCommand]);
//        lightColorScheme.mathKeywordColor = NSColorFromRGBValuesArray(lightColorSchemeDict[kColorSchemeColorFieldMathKeyword]);
//        lightColorScheme.assignmentColor = NSColorFromRGBValuesArray(lightColorSchemeDict[kColorSchemeColorFieldAssignment]);
//        lightColorScheme.blockMarkerColor = NSColorFromRGBValuesArray(lightColorSchemeDict[kColorSchemeColorFieldBlockMarker]);
//        lightColorScheme.listDelimiterColor = NSColorFromRGBValuesArray(lightColorSchemeDict[kColorSchemeColorFieldListDelimiter]);
//        lightColorScheme.modeSwitchControlCharColor = NSColorFromRGBValuesArray(lightColorSchemeDict[kColorSchemeColorFieldModeSwitch]);
//        lightColorScheme.commentColor = NSColorFromRGBValuesArray(lightColorSchemeDict[kColorSchemeColorFieldComment]);
//        lightColorScheme.attributesSymbolColor = NSColorFromRGBValuesArray(lightColorSchemeDict[kColorSchemeColorFieldAttributes]);
//        lightColorScheme.quotedCodeBlockColor = NSColorFromRGBValuesArray(lightColorSchemeDict[kColorSchemeColorFieldQuotedCode]);
//        lightColorScheme.quotedCodeBlockBackgroundColor = NSColorFromRGBValuesArray(lightColorSchemeDict[kColorSchemeColorFieldQuotedCodeBackground]);
//        lightColorScheme.codeAnnotationBlockColor = NSColorFromRGBValuesArray(lightColorSchemeDict[kColorSchemeColorFieldCodeAnnotation]);
//        lightColorScheme.notScannedColor = NSColorFromRGBValuesArray(lightColorSchemeDict[kColorSchemeColorFieldNotScanned]);
//        lightColorScheme.fallbackColor = NSColorFromRGBValuesArray(lightColorSchemeDict[kColorSchemeColorFieldFallback]);
//
//        lightColorSchemeLoaded = true;
//    }
//    return lightColorScheme;
//}
//
//+ (MHSourceCodeColorScheme)darkColorScheme
//{
//    if (!darkColorSchemeLoaded) {
//
//        NSString *colorSchemesfilename = [[NSBundle mainBundle] pathForResource:kMHSourceCodeSyntaxColorSchemesPlistFilename
//                                                                         ofType:kMHSourceCodeSyntaxColorSchemesPlistFileExtension];
//        NSDictionary *colorSchemesDict = [NSDictionary dictionaryWithContentsOfFile:colorSchemesfilename];
//        NSDictionary *darkColorSchemeDict = colorSchemesDict[kDarkColorSchemeName];
//
//        darkColorScheme.backgroundColor = NSColorFromRGBValuesArray(darkColorSchemeDict[kColorSchemeColorFieldBackground]);
//        darkColorScheme.insertionPointColor = NSColorFromRGBValuesArray(darkColorSchemeDict[kColorSchemeColorFieldInsertionPoint]);
//        darkColorScheme.textColor = NSColorFromRGBValuesArray(darkColorSchemeDict[kColorSchemeColorFieldText]);
//        darkColorScheme.mathModeColor = NSColorFromRGBValuesArray(darkColorSchemeDict[kColorSchemeColorFieldMath]);
//        darkColorScheme.mathModeBackgroundColor = NSColorFromRGBValuesArray(darkColorSchemeDict[kColorSchemeColorFieldMathBackground]);
//        darkColorScheme.commandColor = NSColorFromRGBValuesArray(darkColorSchemeDict[kColorSchemeColorFieldCommand]);
//        darkColorScheme.unresolvedCommandColor = NSColorFromRGBValuesArray(darkColorSchemeDict[kColorSchemeColorFieldUnresolvedCommand]);
//        darkColorScheme.mathKeywordColor = NSColorFromRGBValuesArray(darkColorSchemeDict[kColorSchemeColorFieldMathKeyword]);
//        darkColorScheme.assignmentColor = NSColorFromRGBValuesArray(darkColorSchemeDict[kColorSchemeColorFieldAssignment]);
//        darkColorScheme.blockMarkerColor = NSColorFromRGBValuesArray(darkColorSchemeDict[kColorSchemeColorFieldBlockMarker]);
//        darkColorScheme.listDelimiterColor = NSColorFromRGBValuesArray(darkColorSchemeDict[kColorSchemeColorFieldListDelimiter]);
//        darkColorScheme.modeSwitchControlCharColor = NSColorFromRGBValuesArray(darkColorSchemeDict[kColorSchemeColorFieldModeSwitch]);
//        darkColorScheme.commentColor = NSColorFromRGBValuesArray(darkColorSchemeDict[kColorSchemeColorFieldComment]);
//        darkColorScheme.attributesSymbolColor = NSColorFromRGBValuesArray(darkColorSchemeDict[kColorSchemeColorFieldAttributes]);
//        darkColorScheme.quotedCodeBlockColor = NSColorFromRGBValuesArray(darkColorSchemeDict[kColorSchemeColorFieldQuotedCode]);
//        darkColorScheme.quotedCodeBlockBackgroundColor = NSColorFromRGBValuesArray(darkColorSchemeDict[kColorSchemeColorFieldQuotedCodeBackground]);
//        darkColorScheme.codeAnnotationBlockColor = NSColorFromRGBValuesArray(darkColorSchemeDict[kColorSchemeColorFieldCodeAnnotation]);
//        darkColorScheme.notScannedColor = NSColorFromRGBValuesArray(darkColorSchemeDict[kColorSchemeColorFieldNotScanned]);
//        darkColorScheme.fallbackColor = NSColorFromRGBValuesArray(darkColorSchemeDict[kColorSchemeColorFieldFallback]);
//
//        darkColorSchemeLoaded = true;
//    }
//    return darkColorScheme;
//}
//
//
//
//
//- (void)updateColorSchemeAfterFontChange
//{
//    _colorScheme.modeSwitchControlCharAttributesDict = @{
//        NSForegroundColorAttributeName : (_colorScheme.modeSwitchControlCharColor ? _colorScheme.modeSwitchControlCharColor : [NSColor blackColor]),
//        NSFontAttributeName : _boldFont
//    };
//    _colorScheme.codeAnnotationBlockAttributesDict = @{
//        NSForegroundColorAttributeName : (_colorScheme.codeAnnotationBlockColor ? _colorScheme.codeAnnotationBlockColor : [NSColor grayColor]),
//        NSFontAttributeName : _italicFont
//    };
//
//    _colorScheme.allCharactersAttributesDict = @{ NSFontAttributeName : self.currentFont };
//}
//
//
//- (MHSourceCodeDefaultColorSchemeType)colorSchemeType
//{
//    return _colorSchemeType;
//}
//
//
//- (void)setColorSchemeType:(MHSourceCodeDefaultColorSchemeType)colorSchemeType
//{
//    _colorSchemeType = colorSchemeType;
//    
//    MHSourceCodeColorScheme preloadedColorScheme;
//    switch (_colorSchemeType) {
//        case MHSourceCodeDefaultColorSchemeLight:
//            preloadedColorScheme = [[self class] lightColorScheme];
//            break;
//        case MHSourceCodeDefaultColorSchemeDark:
//            preloadedColorScheme = [[self class] darkColorScheme];
//            break;
//    }
//    
//    _colorScheme.backgroundColor = preloadedColorScheme.backgroundColor;
//    _colorScheme.insertionPointColor = preloadedColorScheme.insertionPointColor;
//    _colorScheme.gutterBackgroundColor = _colorScheme.backgroundColor;
//
//    _colorScheme.textColor = preloadedColorScheme.textColor;
//    _colorScheme.mathModeColor = preloadedColorScheme.mathModeColor;
//    _colorScheme.mathModeBackgroundColor = preloadedColorScheme.mathModeBackgroundColor;
//    _colorScheme.commandColor = preloadedColorScheme.commandColor;
//    _colorScheme.unresolvedCommandColor = (_syntaxColoringHighlightsErrors ?
//                                           preloadedColorScheme.unresolvedCommandColor
//                                           : _colorScheme.commandColor);   // FIXME: improve
//    _colorScheme.mathKeywordColor = preloadedColorScheme.mathKeywordColor;
//    _colorScheme.assignmentColor = preloadedColorScheme.assignmentColor;
//    _colorScheme.blockMarkerColor = preloadedColorScheme.blockMarkerColor;
//    _colorScheme.listDelimiterColor = preloadedColorScheme.listDelimiterColor;
//    _colorScheme.modeSwitchControlCharColor = preloadedColorScheme.modeSwitchControlCharColor;
//    _colorScheme.commentColor = preloadedColorScheme.commentColor;
//    _colorScheme.quotedCodeBlockColor = preloadedColorScheme.quotedCodeBlockColor;
//    _colorScheme.quotedCodeBlockBackgroundColor = preloadedColorScheme.quotedCodeBlockBackgroundColor;
//    _colorScheme.codeAnnotationBlockColor = preloadedColorScheme.codeAnnotationBlockColor;
//    _colorScheme.attributesSymbolColor = preloadedColorScheme.attributesSymbolColor;
//    _colorScheme.notScannedColor = preloadedColorScheme.notScannedColor;
//    _colorScheme.fallbackColor = preloadedColorScheme.fallbackColor;
//    
//    self.backgroundColor = _colorScheme.backgroundColor;
//    self.enclosingScrollView.scrollerKnobStyle = [NSScroller knobStyleAdaptedToBackgroundColor:_colorScheme.backgroundColor];
//    self.insertionPointColor = _colorScheme.insertionPointColor;
//    _gutter.backgroundColor = _colorScheme.gutterBackgroundColor;
//    _gutter.markerColor = _colorScheme.textColor;
//
//    self.currentFont = [NSFont fontWithName:[AppDelegate defaultFontName]
//                                       size:[AppDelegate defaultFontSize]];
//    
//    _colorScheme.colorSchemeInitialized = YES;
//
//    [self createAttributesDictsForColorScheme];
//    [self applySyntaxColoringToRange:NSMakeRange(NSNotFound, 0)];
//}
//
//
//- (void)createAttributesDictsForColorScheme
//{
//    if (!(_colorScheme.colorSchemeInitialized))
//        return;
//    
//    _colorScheme.textAttributesDict = @{ NSForegroundColorAttributeName : _colorScheme.textColor };
//    _colorScheme.mathAttributesDict = @{ NSForegroundColorAttributeName : _colorScheme.mathModeColor };
//    _colorScheme.commandAttributesDict = @{
//        NSForegroundColorAttributeName : _colorScheme.commandColor,
////        NSUnderlineStyleAttributeName : @1,
//        NSFontAttributeName : _boldFont
//    };
//    
//    _colorScheme.unresolvedCommandAttributesDict = @{
//        NSForegroundColorAttributeName : _colorScheme.unresolvedCommandColor,
////        NSUnderlineStyleAttributeName : @1,
//        NSFontAttributeName : _boldFont
//    };
//    _colorScheme.mathKeywordAttributesDict = @{
//        NSForegroundColorAttributeName : _colorScheme.mathKeywordColor,
//        NSFontAttributeName : _boldFont
//    };
//    _colorScheme.assignmentAttributesDict = @{ NSForegroundColorAttributeName : _colorScheme.assignmentColor };
//    _colorScheme.blockMarkerAttributesDict = @{ NSForegroundColorAttributeName : _colorScheme.blockMarkerColor };
//    _colorScheme.listDelimiterAttributesDict = @{ NSForegroundColorAttributeName : _colorScheme.listDelimiterColor };
//
//    _colorScheme.modeSwitchControlCharAttributesDict = @{
//        NSForegroundColorAttributeName : _colorScheme.modeSwitchControlCharColor,
//        NSFontAttributeName : _boldFont
//    };
//    
//    _colorScheme.commentAttributesDict = @{ NSForegroundColorAttributeName : _colorScheme.commentColor };
//    _colorScheme.quotedCodeBlockAttributesDict = @{
//        NSForegroundColorAttributeName : _colorScheme.quotedCodeBlockColor,
////        NSFontAttributeName : _boldFont,
//    };
//    _colorScheme.codeAnnotationBlockAttributesDict = @{
//        NSForegroundColorAttributeName : _colorScheme.codeAnnotationBlockColor,
//        NSFontAttributeName : _italicFont,
//    };
//    _colorScheme.attributesSymbolAttributesDict = @{ NSForegroundColorAttributeName : _colorScheme.attributesSymbolColor };
//    _colorScheme.notScannedAttributesDict = @{ NSForegroundColorAttributeName : _colorScheme.notScannedColor };
//    _colorScheme.fallbackAttributesDict = @{ NSForegroundColorAttributeName : _colorScheme.fallbackColor };
//
//    _colorScheme.allCharactersAttributesDict = @{
//        NSFontAttributeName : self.currentFont
////        ,NSLigatureAttributeName : @0     // FIXME: tried this to disable ligatures, that doesn't work
//    };
//
//    _colorScheme.attributesDictsForSyntaxColoringClasses[kMHParserSyntaxColoringText] = _colorScheme.textAttributesDict;
//    _colorScheme.attributesDictsForSyntaxColoringClasses[kMHParserSyntaxColoringAssignment] = _colorScheme.assignmentAttributesDict;
//    _colorScheme.attributesDictsForSyntaxColoringClasses[kMHParserSyntaxColoringCommandName] = _colorScheme.commandAttributesDict;
//    _colorScheme.attributesDictsForSyntaxColoringClasses[kMHParserSyntaxColoringBlock] = _colorScheme.blockMarkerAttributesDict;
//    _colorScheme.attributesDictsForSyntaxColoringClasses[kMHParserSyntaxColoringListDelimiter] = _colorScheme.listDelimiterAttributesDict;
//    _colorScheme.attributesDictsForSyntaxColoringClasses[kMHParserSyntaxColoringModeSwitch] = _colorScheme.modeSwitchControlCharAttributesDict;
//    _colorScheme.attributesDictsForSyntaxColoringClasses[kMHParserSyntaxColoringComment] = _colorScheme.commentAttributesDict;
//    
//    _colorScheme.attributesDictsForSyntaxColoringClasses[kMHParserSyntaxColoringQuotedCodeBlock] = _colorScheme.quotedCodeBlockAttributesDict;
//    _colorScheme.attributesDictsForSyntaxColoringClasses[kMHParserSyntaxColoringCodeAnnotationBlock] = _colorScheme.codeAnnotationBlockAttributesDict;
//    _colorScheme.attributesDictsForSyntaxColoringClasses[kMHParserSyntaxColoringAttributesSymbol] = _colorScheme.attributesSymbolAttributesDict;
//    
//    _colorScheme.attributesDictsForSyntaxColoringClasses[kMHParserSyntaxColoringUnresolvedCommandName] = _colorScheme.unresolvedCommandAttributesDict;
//    _colorScheme.attributesDictsForSyntaxColoringClasses[kMHParserSyntaxColoringMathKeyword] = _colorScheme.mathKeywordAttributesDict;
//}
//
//
//
//
//@end
//
