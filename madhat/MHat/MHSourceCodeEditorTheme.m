//
//  MHSourceCodeEditorTheme.m
//  MadHat
//
//  Created by Dan Romik on 12/6/21.
//  Copyright © 2021 Dan Romik. All rights reserved.
//

#import "MadHat.h"
#import "MHSourceCodeEditorTheme.h"
#import "MHSourceCodeTextStorage.h"
#import "MHParser+SpecialSymbols.h"




extern NSString * const kMHSourceCodeEditorThemesPlistBundledWithAppFilename;
extern NSString * const kMHSourceCodeEditorThemesPlistBundledWithAppFileExtension;

static NSString * const kEditorThemePlistKeyFont = @"font";
static NSString * const kEditorThemePlistKeyFontSize = @"font size";

NSString * const kEditorThemePlistKeyName = @"name";

static NSString * const kEditorThemePlistKeyBackground = @"background";
static NSString * const kEditorThemePlistKeyInsertionPoint = @"insertion point";
static NSString * const kEditorThemePlistKeyText = @"text";
static NSString * const kEditorThemePlistKeyMath = @"math";
static NSString * const kEditorThemePlistKeyMathBackground = @"math background";
static NSString * const kEditorThemePlistKeyCommand = @"command";
static NSString * const kEditorThemePlistKeyUnresolvedCommand = @"unresolved command";
static NSString * const kEditorThemePlistKeyMathKeyword = @"math keyword";
static NSString * const kEditorThemePlistKeyAssignment = @"assignment";
static NSString * const kEditorThemePlistKeyBlockMarker = @"block marker";
static NSString * const kEditorThemePlistKeyListDelimiter = @"list delimiter";
static NSString * const kEditorThemePlistKeyModeSwitch = @"mode switch";
static NSString * const kEditorThemePlistKeyComment = @"comment";
static NSString * const kEditorThemePlistKeyAttributes = @"attributes";
static NSString * const kEditorThemePlistKeyQuotedCode = @"quoted code";
static NSString * const kEditorThemePlistKeyQuotedCodeBackground = @"quoted code background";
static NSString * const kEditorThemePlistKeyCodeAnnotation = @"code annotation";
static NSString * const kEditorThemePlistKeyNotScanned = @"not scanned";
static NSString * const kEditorThemePlistKeySelection = @"selection";

static NSString * const kEditorThemePlistKeyDisableErrorHighlighting = @"noerrors";


static NSColor *NSColorFromRGBAValuesArray(NSArray *valuesArray) {
    return [NSColor colorWithRed:[valuesArray[0] doubleValue]
                           green:[valuesArray[1] doubleValue]
                            blue:[valuesArray[2] doubleValue]
                           alpha:[valuesArray[3] doubleValue]];
}

static NSArray <NSNumber *> *ArrayOfRGBAValuesFromNSColor(NSColor *color) {
    CIColor *myColorAsCIColor = [[CIColor alloc] initWithColor:color];
    CGFloat red = [myColorAsCIColor red];
    CGFloat green = [myColorAsCIColor green];
    CGFloat blue = [myColorAsCIColor blue];
    CGFloat alpha = [myColorAsCIColor alpha];
    return @[
        [NSNumber numberWithDouble:red],
        [NSNumber numberWithDouble:green],
        [NSNumber numberWithDouble:blue],
        [NSNumber numberWithDouble:alpha]
    ];
}

static MHSourceCodeEditorTheme *_MHSourceCodeDefaultThemeForQuotedCode;


@interface MHSourceCodeEditorTheme ()
{
    NSString *_name;
    BOOL _syntaxColoringHighlightsErrors;
    BOOL _editable;
    //
    NSFont *_font;
    NSFont *_boldFont;
    NSFont *_italicFont;
    //
    NSColor * _Nonnull _backgroundColor;
    NSColor * _Nonnull _insertionPointColor;
    //
    NSColor * _Nonnull _textColor;
    NSColor * _Nonnull _mathModeColor;
    NSColor * _Nullable _mathModeBackgroundColor;
    NSColor * _Nullable _quotedCodeBlockBackgroundColor;
    NSColor * _Nonnull _commandColor;
    NSColor * _Nonnull _unresolvedCommandColor;
    NSColor * _Nonnull _mathKeywordColor;
    NSColor * _Nonnull _assignmentColor;
    NSColor * _Nonnull _blockMarkerColor;
    NSColor * _Nonnull _listDelimiterColor;
    NSColor * _Nonnull _modeSwitchControlCharColor;
    NSColor * _Nonnull _commentColor;
    NSColor * _Nonnull _quotedCodeBlockColor;
    NSColor * _Nonnull _codeAnnotationBlockColor;
    NSColor * _Nonnull _attributesSymbolColor;
    NSColor * _Nonnull _notScannedColor;
    NSColor * _Nonnull _selectionColor;
    //
    NSDictionary * _Nonnull _textAttributesDict;
    NSDictionary * _Nonnull _mathAttributesDict;
    NSDictionary * _Nonnull _commandAttributesDict;
    NSDictionary * _Nonnull _unresolvedCommandAttributesDict;
    NSDictionary * _Nonnull _mathKeywordAttributesDict;
    NSDictionary * _Nonnull _assignmentAttributesDict;
    NSDictionary * _Nonnull _blockMarkerAttributesDict;
    NSDictionary * _Nonnull _listDelimiterAttributesDict;
    NSDictionary * _Nonnull _modeSwitchControlCharAttributesDict;
    NSDictionary * _Nonnull _commentAttributesDict;
    NSDictionary * _Nonnull _quotedCodeBlockAttributesDict;
    NSDictionary * _Nonnull _codeAnnotationBlockAttributesDict;
    NSDictionary * _Nonnull _attributesSymbolAttributesDict;
    NSDictionary * _Nonnull _notScannedAttributesDict;
    NSDictionary * _Nonnull _fallbackAttributesDict;
    NSDictionary * _Nonnull _allCharactersAttributesDict;
    //
    NSDictionary * _Nonnull _attributesDictsForSyntaxColoringClasses[kMHParserSyntaxColoringNumberOfColorClasses];
}

@end

@implementation MHSourceCodeEditorTheme


+ (instancetype)themeWithDictionaryRepresentation:(NSDictionary *)themeDict
{
    return [[self alloc] initWithDictionaryRepresentation:themeDict];
}

- (instancetype)initWithDictionaryRepresentation:(NSDictionary *)themeDict
{
    if (self = [super init]) {
        _name = [themeDict[kEditorThemePlistKeyName] copy];
        if (!_name) {
            _name = @"(unknown)";
        }
        _editable = YES;
        _syntaxColoringHighlightsErrors = YES;
        
        NSNumber *noErrorHighlightingNumber = themeDict[kEditorThemePlistKeyDisableErrorHighlighting];
        if (noErrorHighlightingNumber && [noErrorHighlightingNumber boolValue]) {
            _syntaxColoringHighlightsErrors = NO;
        }
        
        static CGFloat minFontSize = 4.0;
        static CGFloat maxFontSize = 200.0;

        NSString *fontName = themeDict[kEditorThemePlistKeyFont];
        CGFloat fontSize = [(NSNumber *)(themeDict[kEditorThemePlistKeyFontSize]) doubleValue];
        _font = [NSFont fontWithName:fontName size:fontSize];
        if (fontSize < minFontSize)
            fontSize = minFontSize;
        else if (fontSize > maxFontSize)
            fontSize = maxFontSize;
        _font = [NSFont fontWithName:fontName size:fontSize];
        if (!_font) {
            _font = [NSFont systemFontOfSize:fontSize];
        }
        _boldFont = [[NSFontManager sharedFontManager] convertFont:_font toHaveTrait:NSFontBoldTrait];
        _italicFont = [[NSFontManager sharedFontManager] convertFont:_font toHaveTrait:NSFontItalicTrait];

        _backgroundColor = NSColorFromRGBAValuesArray(themeDict[kEditorThemePlistKeyBackground]);
        _insertionPointColor = NSColorFromRGBAValuesArray(themeDict[kEditorThemePlistKeyInsertionPoint]);
        _textColor = NSColorFromRGBAValuesArray(themeDict[kEditorThemePlistKeyText]);
        _mathModeColor = NSColorFromRGBAValuesArray(themeDict[kEditorThemePlistKeyMath]);
        _mathModeBackgroundColor = NSColorFromRGBAValuesArray(themeDict[kEditorThemePlistKeyMathBackground]);
        _commandColor = NSColorFromRGBAValuesArray(themeDict[kEditorThemePlistKeyCommand]);

        _unresolvedCommandColor = (_syntaxColoringHighlightsErrors ?
                                   NSColorFromRGBAValuesArray(themeDict[kEditorThemePlistKeyUnresolvedCommand]) : _commandColor);

//        _unresolvedCommandColor = NSColorFromRGBAValuesArray(themeDict[kEditorThemePlistKeyUnresolvedCommand]);

        _mathKeywordColor = NSColorFromRGBAValuesArray(themeDict[kEditorThemePlistKeyMathKeyword]);
        _assignmentColor = NSColorFromRGBAValuesArray(themeDict[kEditorThemePlistKeyAssignment]);
        _blockMarkerColor = NSColorFromRGBAValuesArray(themeDict[kEditorThemePlistKeyBlockMarker]);
        _listDelimiterColor = NSColorFromRGBAValuesArray(themeDict[kEditorThemePlistKeyListDelimiter]);
        _modeSwitchControlCharColor = NSColorFromRGBAValuesArray(themeDict[kEditorThemePlistKeyModeSwitch]);
        _commentColor = NSColorFromRGBAValuesArray(themeDict[kEditorThemePlistKeyComment]);
        _attributesSymbolColor = NSColorFromRGBAValuesArray(themeDict[kEditorThemePlistKeyAttributes]);
        _quotedCodeBlockColor = NSColorFromRGBAValuesArray(themeDict[kEditorThemePlistKeyQuotedCode]);
        _quotedCodeBlockBackgroundColor = NSColorFromRGBAValuesArray(themeDict[kEditorThemePlistKeyQuotedCodeBackground]);
        _codeAnnotationBlockColor = NSColorFromRGBAValuesArray(themeDict[kEditorThemePlistKeyCodeAnnotation]);
        _notScannedColor = NSColorFromRGBAValuesArray(themeDict[kEditorThemePlistKeyNotScanned]);
        _selectionColor = NSColorFromRGBAValuesArray(themeDict[kEditorThemePlistKeySelection]);
    }
    return self;
}

- (NSDictionary *)dictionaryRepresentation
{
    NSDictionary *dict = @{
        kEditorThemePlistKeyName : _name,
        kEditorThemePlistKeyFont : _font.familyName,
        kEditorThemePlistKeyFontSize : [NSNumber numberWithDouble:_font.pointSize],
        kEditorThemePlistKeyBackground : ArrayOfRGBAValuesFromNSColor(_backgroundColor),
        kEditorThemePlistKeyInsertionPoint : ArrayOfRGBAValuesFromNSColor(_insertionPointColor),
        kEditorThemePlistKeyText : ArrayOfRGBAValuesFromNSColor(_textColor),
        kEditorThemePlistKeyMath : ArrayOfRGBAValuesFromNSColor(_mathModeColor),
        kEditorThemePlistKeyMathBackground : ArrayOfRGBAValuesFromNSColor(_mathModeBackgroundColor),
        kEditorThemePlistKeyCommand : ArrayOfRGBAValuesFromNSColor(_commandColor),
        kEditorThemePlistKeyUnresolvedCommand : ArrayOfRGBAValuesFromNSColor(_unresolvedCommandColor),
        kEditorThemePlistKeyMathKeyword : ArrayOfRGBAValuesFromNSColor(_mathKeywordColor),
        kEditorThemePlistKeyAssignment : ArrayOfRGBAValuesFromNSColor(_assignmentColor),
        kEditorThemePlistKeyBlockMarker : ArrayOfRGBAValuesFromNSColor(_blockMarkerColor),
        kEditorThemePlistKeyListDelimiter : ArrayOfRGBAValuesFromNSColor(_listDelimiterColor),
        kEditorThemePlistKeyModeSwitch : ArrayOfRGBAValuesFromNSColor(_modeSwitchControlCharColor),
        kEditorThemePlistKeyComment : ArrayOfRGBAValuesFromNSColor(_commentColor),
        kEditorThemePlistKeyAttributes : ArrayOfRGBAValuesFromNSColor(_attributesSymbolColor),
        kEditorThemePlistKeyQuotedCode : ArrayOfRGBAValuesFromNSColor(_quotedCodeBlockColor),
        kEditorThemePlistKeyQuotedCodeBackground : ArrayOfRGBAValuesFromNSColor(_quotedCodeBlockBackgroundColor),
        kEditorThemePlistKeyCodeAnnotation : ArrayOfRGBAValuesFromNSColor(_codeAnnotationBlockColor),
        kEditorThemePlistKeyNotScanned : ArrayOfRGBAValuesFromNSColor(_notScannedColor),
        kEditorThemePlistKeySelection : ArrayOfRGBAValuesFromNSColor(_selectionColor)
    };
    return dict;
}




- (void)createAttributesDictsWithFont:(NSFont *)font italicFont:(NSFont *)italicFont boldFont:(NSFont *)boldFont
{
    _textAttributesDict = @{ NSForegroundColorAttributeName : _textColor };
    _mathAttributesDict = @{ NSForegroundColorAttributeName : _mathModeColor };
    
    _commandAttributesDict = @{
        NSForegroundColorAttributeName : _commandColor,
        NSFontAttributeName : boldFont
    };
    
    _unresolvedCommandAttributesDict = @{
        NSForegroundColorAttributeName : _unresolvedCommandColor,
        NSFontAttributeName : boldFont
    };
    _mathKeywordAttributesDict = @{
        NSForegroundColorAttributeName : _mathKeywordColor,
        NSFontAttributeName : boldFont
    };
    _assignmentAttributesDict = @{ NSForegroundColorAttributeName : _assignmentColor };
    _blockMarkerAttributesDict = @{ NSForegroundColorAttributeName : _blockMarkerColor };
    _listDelimiterAttributesDict = @{ NSForegroundColorAttributeName : _listDelimiterColor };

    _modeSwitchControlCharAttributesDict = @{
        NSForegroundColorAttributeName : _modeSwitchControlCharColor,
        NSFontAttributeName : boldFont
    };
    
    _commentAttributesDict = @{ NSForegroundColorAttributeName : _commentColor };
    _quotedCodeBlockAttributesDict = @{
        NSForegroundColorAttributeName : _quotedCodeBlockColor,
    };
    _codeAnnotationBlockAttributesDict = @{
        NSForegroundColorAttributeName : _codeAnnotationBlockColor,
        NSFontAttributeName : italicFont,
    };
    _attributesSymbolAttributesDict = @{ NSForegroundColorAttributeName : _attributesSymbolColor };
    _notScannedAttributesDict = @{ NSForegroundColorAttributeName : _notScannedColor };

    _fallbackAttributesDict = @{ NSForegroundColorAttributeName : [NSColor greenColor] };   // this should never be used, but will reveal itself if we ever run into an unrecognized syntax coloring class

    _allCharactersAttributesDict = @{ NSFontAttributeName : font };

    _attributesDictsForSyntaxColoringClasses[kMHParserSyntaxColoringText] = _textAttributesDict;
    _attributesDictsForSyntaxColoringClasses[kMHParserSyntaxColoringAssignment] = _assignmentAttributesDict;
    _attributesDictsForSyntaxColoringClasses[kMHParserSyntaxColoringCommandName] = _commandAttributesDict;
    _attributesDictsForSyntaxColoringClasses[kMHParserSyntaxColoringBlock] = _blockMarkerAttributesDict;
    _attributesDictsForSyntaxColoringClasses[kMHParserSyntaxColoringListDelimiter] = _listDelimiterAttributesDict;
    _attributesDictsForSyntaxColoringClasses[kMHParserSyntaxColoringModeSwitch] = _modeSwitchControlCharAttributesDict;
    _attributesDictsForSyntaxColoringClasses[kMHParserSyntaxColoringComment] = _commentAttributesDict;
    
    _attributesDictsForSyntaxColoringClasses[kMHParserSyntaxColoringQuotedCodeBlock] = _quotedCodeBlockAttributesDict;
    _attributesDictsForSyntaxColoringClasses[kMHParserSyntaxColoringCodeAnnotationBlock] = _codeAnnotationBlockAttributesDict;
    _attributesDictsForSyntaxColoringClasses[kMHParserSyntaxColoringAttributesSymbol] = _attributesSymbolAttributesDict;
    
    _attributesDictsForSyntaxColoringClasses[kMHParserSyntaxColoringUnresolvedCommandName] = _unresolvedCommandAttributesDict;
    _attributesDictsForSyntaxColoringClasses[kMHParserSyntaxColoringMathKeyword] = _mathKeywordAttributesDict;
}

- (void)recreateAttributesDictsForFont:(NSFont *)font italicFont:(NSFont *)italicFont boldFont:(NSFont *)boldFont
{
    _modeSwitchControlCharAttributesDict = @{
        NSForegroundColorAttributeName : (_modeSwitchControlCharColor ? _modeSwitchControlCharColor : [NSColor blackColor]),
        NSFontAttributeName : boldFont
    };
    _codeAnnotationBlockAttributesDict = @{
        NSForegroundColorAttributeName : (_codeAnnotationBlockColor ? _codeAnnotationBlockColor : [NSColor grayColor]),
        NSFontAttributeName : italicFont
    };

    _allCharactersAttributesDict = @{ NSFontAttributeName : font };
}



- (void)applySyntaxColoringToTextStorage:(MHSourceCodeTextStorage *)sourceCodeTextStorage range:(NSRange)range
{
    NSUInteger minIndex, maxIndexPlusOne;
    if (range.location != NSNotFound) {
        minIndex = range.location;
        maxIndexPlusOne = range.location + range.length;
    }
    else {
        minIndex = 0;
        maxIndexPlusOne = sourceCodeTextStorage.length;
    }
    
    NSUInteger charIndex;
    
    char *bytes = (char *)(sourceCodeTextStorage.codeSemanticsData.bytes);

    NSRange charRange = NSMakeRange(0, 1);
    [sourceCodeTextStorage beginEditing];
    for (charIndex = minIndex; charIndex < maxIndexPlusOne; charIndex++) {
        charRange.location = charIndex;
        char currentByte = bytes[charIndex];
        
        bool charScanned = ((currentByte & kMHParserSyntaxColoringCharacterScanned) != 0);
        bool charMathMode = ((currentByte & kMHParserSyntaxColoringMathMode) != 0);
        char currentByteForegroundColorCode = currentByte & (kMHParserSyntaxColoringBitMask
                            -kMHParserSyntaxColoringCharacterScanned-kMHParserSyntaxColoringMathMode);
        bool charModeShift = (currentByteForegroundColorCode == kMHParserSyntaxColoringModeSwitch);
        bool charQuotedCode = (currentByteForegroundColorCode == kMHParserSyntaxColoringQuotedCodeBlock);
        bool charCommand = (currentByteForegroundColorCode == kMHParserSyntaxColoringCommandName);
        bool charUnresolvedCommand = (currentByteForegroundColorCode == kMHParserSyntaxColoringUnresolvedCommandName);
        bool charMathKeyword = (currentByteForegroundColorCode == kMHParserSyntaxColoringMathKeyword);

        NSDictionary *attributes =
            (currentByteForegroundColorCode < kMHParserSyntaxColoringNumberOfColorClasses ?
             _attributesDictsForSyntaxColoringClasses[currentByteForegroundColorCode] : _fallbackAttributesDict);

        [sourceCodeTextStorage setAttributes:attributes range:charRange];

        NSColor *backgroundColor;
        if (charMathMode)
            backgroundColor = _mathModeBackgroundColor;
        else if (charQuotedCode)
            backgroundColor = _quotedCodeBlockBackgroundColor;
        else
            backgroundColor = _backgroundColor;

        [sourceCodeTextStorage addAttribute:NSBackgroundColorAttributeName value:backgroundColor range:charRange];

        if (!charScanned && _syntaxColoringHighlightsErrors) {
            [sourceCodeTextStorage addAttribute:NSForegroundColorAttributeName value:_notScannedColor range:charRange];
        }
        
        if (!charModeShift && !charCommand && !charUnresolvedCommand && !charMathKeyword
            && (currentByteForegroundColorCode != kMHParserSyntaxColoringCodeAnnotationBlock)) {
            // the first few excluded categories are displayed in the bold font
            // code annotation block characters are displayed in italic
            [sourceCodeTextStorage addAttributes:_allCharactersAttributesDict range:charRange];
        }
    }
    [sourceCodeTextStorage endEditing];
}



+ (NSArray <NSString *> *)localizedThemeEditableForegroundColorDescriptions
{
    static NSArray <NSString *> *_localizedEditableThemeForegroundColorDescriptions;
    if (!_localizedEditableThemeForegroundColorDescriptions) {
        _localizedEditableThemeForegroundColorDescriptions = @[
            NSLocalizedString(@"Text foreground", @""),
            NSLocalizedString(@"Math foreground", @""),
            NSLocalizedString(@"Math keyword", @""),
            NSLocalizedString(@"Command", @""),
            NSLocalizedString(@"Unresolved command", @""),
            NSLocalizedString(@"Mode shift symbols M̂ T̂", @""),
            NSLocalizedString(@"Assignment symbol ←", @""),
            NSLocalizedString(@"Block markers ⟪ ⟫", @""),
            NSLocalizedString(@"List delimiters ；＃", @""),
            NSLocalizedString(@"Attributes symbol ＠", @""),
            NSLocalizedString(@"Comment", @""),
            NSLocalizedString(@"Ignored", @""),
        ];
    }
    return _localizedEditableThemeForegroundColorDescriptions;
}

- (NSUInteger)indexForMathModeForegroundColor
{
    return 1;
}
- (NSUInteger)indexForMathKeywordColor
{
    return 2;
}

- (NSUInteger)indexForCommandColor
{
    return 3;
}
- (NSUInteger)indexForUnresolvedCommandColor
{
    return 4;
}

- (NSColor *)colorForEditableForegroundColorWithIndex:(NSUInteger)index
{
    switch (index) {
        case 0:
            return _textColor;
        case 1:
            return _mathModeColor;
        case 2:
            return _mathKeywordColor;
        case 3:
            return _commandColor;
        case 4:
            return _unresolvedCommandColor;
        case 5:
            return _modeSwitchControlCharColor;
        case 6:
            return _assignmentColor;
        case 7:
            return _blockMarkerColor;
        case 8:
            return _listDelimiterColor;
        case 9:
            return _attributesSymbolColor;
        case 10:
            return _commandColor;
        case 11:
            return _notScannedColor;
    }
    return [NSColor blackColor];
}

- (void)setColorForEditableAttributeWithIndex:(NSUInteger)index toColor:(NSColor *)color
{
    switch (index) {
        case 0:
            _textColor = color;
            break;
        case 1:
            _mathModeColor = color;
            break;
        case 2:
            _mathKeywordColor = color;
            break;
        case 3:
            _commandColor = color;
            break;
        case 4:
            _unresolvedCommandColor = color;
            break;
        case 5:
            _modeSwitchControlCharColor = color;
            break;
        case 6:
            _assignmentColor = color;
            break;
        case 7:
            _blockMarkerColor = color;
            break;
        case 8:
            _listDelimiterColor = color;
            break;
        case 9:
            _attributesSymbolColor = color;
            break;
        case 10:
            _commandColor = color;
            break;
        case 11:
            _notScannedColor = color;
            break;
    }
}

- (instancetype)copyWithZone:(nullable NSZone *)zone
{
    NSDictionary *myDictionaryRepresentation = [self dictionaryRepresentation];
    MHSourceCodeEditorTheme *myCopy = [[self class] themeWithDictionaryRepresentation:myDictionaryRepresentation];
    myCopy.editable = self.editable;
    return myCopy;
}

- (MHSourceCodeEditorTheme *)copyWithErrorHighlightingDisabled
{
    NSMutableDictionary *myDictionaryRepresentation = [[self dictionaryRepresentation] mutableCopy];
    myDictionaryRepresentation[kEditorThemePlistKeyDisableErrorHighlighting] = [NSNumber numberWithBool:YES];
    MHSourceCodeEditorTheme *myCopy = [[self class] themeWithDictionaryRepresentation:myDictionaryRepresentation];
    myCopy.editable = self.editable;
    return myCopy;
}

@end
