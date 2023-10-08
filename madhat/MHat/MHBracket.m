//
//  MHBracket.m
//  MadHat
//
//  Created by Dan Romik on 1/11/20.
//  Copyright © 2020 Dan Romik. All rights reserved.
//

#import "MHBracket.h"
#import "MHMathFontSystem+ExtensibleSymbols.h"
#import "MHGlyphNode.h"
#import "MHStyleIncludes.h"


NSString * const kMHBracketTypeLeftParenthesisKey = @"(";
NSString * const kMHBracketTypeRightParenthesisKey = @")";
NSString * const kMHBracketTypeLeftSquareBraceKey = @"[";
NSString * const kMHBracketTypeRightSquareBraceKey = @"]";
NSString * const kMHBracketTypeLeftCurlyBraceKey = @"{";
NSString * const kMHBracketTypeRightCurlyBraceKey = @"}";
NSString * const kMHBracketTypeFloorKey     = @"floor";
NSString * const kMHBracketTypeCeilingKey   = @"ceiling";
NSString * const kMHBracketTypeCeilingShortKey   = @"ceil";
NSString * const kMHBracketTypeVerticalBarKey   = @"|";
NSString * const kMHBracketTypeDoubleVerticalBarKey   = @"‖";
NSString * const kMHBracketTypeLeftAngleKey   = @"<";
NSString * const kMHBracketTypeRightAngleKey   = @">";
NSString * const kMHBracketTypeMatchOpposingBracketKey   = @"same";


NSString * const kMHBracketLeftCommandName    = @"left bracket";
NSString * const kMHBracketRightCommandName   = @"right bracket";
NSString * const kMHBracketMiddleCommandName   = @"middle bracket";
NSString * const kMHBracketCloseBracketCommandName   = @"close bracket";

NSString * const kMHBracketGlyphNodeName = @"BracketGlyphNode";


@interface MHBracket ()
{
    MHBracketOrientation _orientation;
    MHDimensions _dimensionsIgnoringWidth;
    NSUInteger _sizeVariant;                 // either a value between 0 and kMHBracketNumberOfGlyphVariants-1, or MHBracketDynamicallyDeterminedSize
}
@end


@implementation MHBracket



#pragma mark - Constructor methods

+ (instancetype)bracketWithType:(MHBracketType)type
                    orientation:(MHBracketOrientation)orientation
                        variant:(NSUInteger)variant
{
    return [[self alloc] initWithType:(MHBracketType)type
                          orientation:orientation
                              variant:variant];
}

- (instancetype)initWithType:(MHBracketType)type
                 orientation:(MHBracketOrientation)orientation
                     variant:(NSUInteger)variant
{
    if (self = [super init]) {
        _type = type;
        _orientation = orientation;
        _sizeVariant = variant;
        MHDimensions dimensions;
        dimensions.height = 0.0;
        dimensions.depth = 0.0;
        self.dimensions = dimensions;
    }
    return self;
}




#pragma mark - MHCommand protocol

+ (MHExpression *)commandNamed:(NSString *)name withParameters:(NSDictionary *)parameters argument:(MHHorizontalLayoutContainer *)argument
{
    MHBracketOrientation orientation;
    MHBracketType type;
    if ([name isEqualToString:kMHBracketLeftCommandName]) {
        orientation = MHBracketLeftOrientation;
    }
    else if ([name isEqualToString:kMHBracketRightCommandName]) {
        orientation = MHBracketRightOrientation;
    }
    else if ([name isEqualToString:kMHBracketMiddleCommandName]) {
        orientation = MHBracketMiddleOrientation;
    }
    else if ([name isEqualToString:kMHBracketCloseBracketCommandName]) {
        return [self bracketWithType:MHBracketTypeMatchOpposingBracket
                         orientation:MHBracketRightOrientation
                             variant:MHBracketDynamicallyDeterminedSize];
    }
    else {
        return nil;
    }
    
    NSUInteger bracketVariant = MHBracketDynamicallyDeterminedSize;
    NSString *argumentString = argument.stringValue;
    
    NSUInteger argumentLength = argumentString.length;
    if (argumentLength > 0) {
        unichar lastChar = [argumentString characterAtIndex:argumentLength-1];
        if (lastChar >= '1' && lastChar - '1' <= kMHBracketNumberOfGlyphVariants) {
            bracketVariant = lastChar - '0';
            argumentString = [argumentString substringToIndex:argumentLength-1];
        }
    }
    
    if ([argumentString isEqualToString:kMHBracketTypeFloorKey])
        type = MHBracketTypeFloor;
    else if ([argumentString isEqualToString:kMHBracketTypeCeilingKey]
             || [argumentString isEqualToString:kMHBracketTypeCeilingShortKey])
        type = MHBracketTypeCeiling;
    else if ([argumentString isEqualToString:kMHBracketTypeVerticalBarKey])
        type = MHBracketTypeVerticalBar;
    else if ([argumentString isEqualToString:kMHBracketTypeDoubleVerticalBarKey])
        type = MHBracketTypeDoubleVerticalBar;
    else if ([argumentString isEqualToString:kMHBracketTypeMatchOpposingBracketKey])
        type = MHBracketTypeMatchOpposingBracket;
    else if (orientation == MHBracketLeftOrientation && [argumentString isEqualToString:kMHBracketTypeLeftAngleKey])
        type = MHBracketTypeAngleBrace;
    else if (orientation == MHBracketRightOrientation && [argumentString isEqualToString:kMHBracketTypeRightAngleKey])
        type = MHBracketTypeAngleBrace;
    else if (orientation == MHBracketLeftOrientation && [argumentString isEqualToString:kMHBracketTypeLeftParenthesisKey])
        type = MHBracketTypeParenthesis;
    else if (orientation == MHBracketRightOrientation && [argumentString isEqualToString:kMHBracketTypeRightParenthesisKey])
        type = MHBracketTypeParenthesis;
    else if (orientation == MHBracketLeftOrientation && [argumentString isEqualToString:kMHBracketTypeLeftSquareBraceKey])
        type = MHBracketTypeSquareBrace;
    else if (orientation == MHBracketRightOrientation && [argumentString isEqualToString:kMHBracketTypeRightSquareBraceKey])
        type = MHBracketTypeSquareBrace;
    else if (orientation == MHBracketLeftOrientation && [argumentString isEqualToString:kMHBracketTypeLeftCurlyBraceKey])
        type = MHBracketTypeCurlyBrace;
    else if (orientation == MHBracketRightOrientation && [argumentString isEqualToString:kMHBracketTypeRightCurlyBraceKey])
        type = MHBracketTypeCurlyBrace;
    else
        type = MHBracketTypeInvisible;     // the default bracket type is an empty one
    
    return [self bracketWithType:type orientation:orientation variant:bracketVariant];
}


+ (NSArray <NSString *> *)recognizedCommands
{
    return @[ kMHBracketLeftCommandName, kMHBracketRightCommandName, kMHBracketMiddleCommandName, kMHBracketCloseBracketCommandName ];
}



#pragma mark - Properties

- (NSString *)stringValue
{
    static NSString *stringValues[2][kMHBracketNumberOfVisibleBracketTypes+1] = {
        { @"(", @"[", @"⌊", @"⌈", @"|", @"‖", @"{", @"⟨", @"" },
        { @")", @"]", @"⌋", @"⌉", @"|", @"‖", @"}", @"⟩", @"" },
    };
    return stringValues[_orientation == MHBracketDynamicallyDeterminedOrientation ? MHBracketLeftOrientation : _orientation][_type];
}

- (NSString *)exportedLaTexOrientationString //RS - maybe just put this at the beginning of
//the implementation for exportedLaTeXBracketString. In fact there are 3 functions
//involved, should they all be combined in exportedLaTexValue?
{
    if (self.orientation == MHBracketLeftOrientation)
        return @"\\left";
    else if (self.orientation == MHBracketRightOrientation)
        return @"\\right";
    else return @"";
}

- (NSString *)exportedLaTexBracketString //RS
{
    if (self.type == MHBracketTypeParenthesis)
    {
        if (self.orientation == MHBracketLeftOrientation) return @"(";
        else if (self.orientation == MHBracketRightOrientation) return @")";
        else return @"(???)";
    }
    if (self.type == MHBracketTypeSquareBrace)
    {
        if (self.orientation == MHBracketLeftOrientation) return @"[";
        else if (self.orientation == MHBracketRightOrientation) return @"]";
        else return @"(???)";
    }
    if (self.type == MHBracketTypeCurlyBrace)
    {
        if (self.orientation == MHBracketLeftOrientation) return @"\\{";
        else if (self.orientation == MHBracketRightOrientation) return @"\\}";
        else return @"(???)";
    }
    if (self.type == MHBracketTypeFloor)
    {
        if (self.orientation == MHBracketLeftOrientation)
            return @"\\lfloor ";
        else if (self.orientation == MHBracketRightOrientation)
            return @"\\rfloor ";
        else return @"(???)";
    }
    
    else if (self.type == MHBracketTypeCeiling)
    {
        if (self.orientation == MHBracketLeftOrientation)
            return @"\\lceil ";
        else if (self.orientation == MHBracketRightOrientation)
            return @"\\rceil ";
        else return @"(???)";
    }
    else if (self.type == MHBracketTypeVerticalBar) return @"|";
    else if (self.type == MHBracketTypeDoubleVerticalBar) return @"\\|";
    else if (self.type == MHBracketTypeAngleBrace && self.orientation == MHBracketLeftOrientation) return @"\\langle";
    else if (self.type == MHBracketTypeAngleBrace && self.orientation == MHBracketRightOrientation) return @"\\rangle";
    else return @"(???)";
}

- (NSString *)exportedLaTeXValue //RS - bracket of type "same" is not implemented, "middle" is not implemented
//nor are the custom sizes, which in LaTeX would correspond to \small, \Big, \Large, etc.
//for subsets of the sizing set {1,2,...,8}
//\binom command in latex include parentheses, results in double parenthesis (see comment in MHFraction). Maybe \binom is the only problem?
{
    return [NSString stringWithFormat: @"%@%@",
            self.exportedLaTexOrientationString, self.exportedLaTexBracketString];
}


// FIXME: decide if this is useful for anything, if not, remove it
- (bool)heightIsAdjustable
{
    return true;
}

- (MHBracketOrientation)orientation
{
    return _orientation;
}
- (void)setOrientation:(MHBracketOrientation)orientation
{
    _orientation = orientation;
}

- (MHDimensions)dimensionsIgnoringWidth
{
    return _dimensionsIgnoringWidth;
}

- (void)setDimensionsIgnoringWidth:(MHDimensions)dimensions
{
    _dimensionsIgnoringWidth = dimensions;
    if (_spriteKitNode) {
        // FIXME: this approach isn't very good object-oriented programming
        SKNode *spriteKitNodeParent = _spriteKitNode.parent;
        [_spriteKitNode removeFromParent];
        _spriteKitNode = nil;   // invalidate the current sprite kit node
        [spriteKitNodeParent addChild:self.spriteKitNode];  // replace it with a fresh one calculated using the updated dimensions
    }
}

- (NSUInteger)sizeVariant
{
    return _sizeVariant;
}

- (void)setSizeVariant:(NSUInteger)sizeVariant
{
    _sizeVariant = sizeVariant;
}



- (MHTypographyClass)typographyClass
{
    switch (_orientation) {
        case MHBracketLeftOrientation:
            return MHTypographyClassLeftBracket;
        case MHBracketRightOrientation:
            return MHTypographyClassRightBracket;
        default:
            return MHTypographyClassUnknown;
    }
}



#pragma mark - spriteKitNode and typeset methods

- (SKNode *)spriteKitNode
{
    if (!_spriteKitNode) {
        _spriteKitNode = [SKSpriteNode spriteNodeWithColor:[NSColor clearColor] size:NSZeroSize];
        _spriteKitNode.ownerExpression = self;
    }
    return _spriteKitNode;
}



- (void)typesetWithContextManager:(MHTypesettingContextManager *)contextManager
{
    NSUInteger nestingLevel = self.nestingLevel;
    
    NSColor *color = contextManager.textForegroundColor;

    CGFloat emWidth = [contextManager fontSizeForNestingLevel:nestingLevel];
    CGFloat mathAxisHeight = [contextManager mathAxisHeightForNestingLevel:nestingLevel];

    CGFloat bracketHeightAboveMathAxis = -1+(_dimensionsIgnoringWidth.height - mathAxisHeight > _dimensionsIgnoringWidth.depth + mathAxisHeight ?
                                          _dimensionsIgnoringWidth.height - mathAxisHeight : _dimensionsIgnoringWidth.depth + mathAxisHeight);  // FIXME: what is the purpose of the -1 ?

    [_spriteKitNode removeAllChildren]; // FIXME: maybe mark the relevant children specifically and remove only them? That's how I'm doing it in the MHRadical class, think about whether that's better

    MHDimensions myDimensions;

    // Take care of the simplest case first
    if (_type == MHBracketTypeInvisible) {
        myDimensions.width = 0.0;
        myDimensions.height = bracketHeightAboveMathAxis - mathAxisHeight;
        myDimensions.depth = bracketHeightAboveMathAxis + mathAxisHeight;
        self.dimensions = myDimensions;
        return;
    }
    

    NSFont *mathFont = [contextManager mathFontForNestingLevel:nestingLevel traits:MHMathFontTraitRoman];
    MHBracketOrientation effectiveOrientation = (_orientation == MHBracketDynamicallyDeterminedOrientation ||
                                                                _orientation == MHBracketMiddleOrientation ?
                                                                MHBracketRightOrientation : _orientation);
    
    bool underlining = contextManager.textUnderlining;
    
    MHMathFontSystem *mathFontSystem = contextManager.mathFontSystem;
    MHDimensions glyphDimensions;
    
    NSString *glyphName;
    if (_sizeVariant == MHBracketDynamicallyDeterminedSize) {
        glyphName = [mathFontSystem glyphNameForBracketOfType:_type
                                                  orientation:effectiveOrientation
                              forEnclosingHeightAboveMathAxis:bracketHeightAboveMathAxis
                                                withPointSize:emWidth
                                                getDimensions:&glyphDimensions];
    }
    else {
        glyphName = [mathFontSystem glyphNameForBracketOfType:_type
                                                  orientation:effectiveOrientation
                                                 variantLevel:_sizeVariant
                                                withPointSize:emWidth
                                                getDimensions:&glyphDimensions];
    }

    if (glyphName) {
        MHGlyphNode *bracketNode = [MHGlyphNode glyphNodeWithGlyphName:glyphName];
        [bracketNode configureWithFont:mathFont
                                 color:color
                       backgroundColor:nil
                           underlining:underlining
                         strikethrough:false];
        bracketNode.name = kMHBracketGlyphNodeName;

        [_spriteKitNode addChild:bracketNode];
        self.dimensions = glyphDimensions;
        return;
    }
    
    // Since glyphName is nil, that means the content is too high to be enclosed by one of the standard glyph variants,
    // so we must create an extensible bracket by using tileable extension pieces. The precise algorithm will depend
    // on the type of bracket
    
    NSString *lowerHookGlyphName;
    NSString *upperHookGlyphName;
    NSString *extensionPieceGlyphName;
    NSString *middlePieceGlyphName;
    
    MHDimensions lowerHookDimensions;
    MHDimensions upperHookDimensions;
    MHDimensions extensionPieceDimensions;
    MHDimensions middlePieceDimensions;
    
    [mathFontSystem getExtensibleBracketPartsOfType:_type
                                        orientation:effectiveOrientation
                                      withPointSize:emWidth
                              getLowerHookGlyphName:&lowerHookGlyphName
                             getLowerHookDimensions:&lowerHookDimensions
                              getUpperHookGlyphName:&upperHookGlyphName
                             getUpperHookDimensions:&upperHookDimensions
                         getExtensionPieceGlyphName:&extensionPieceGlyphName
                        getExtensionPieceDimensions:&extensionPieceDimensions
                            getMiddlePieceGlyphName:&middlePieceGlyphName
                           getMiddlePieceDimensions:&middlePieceDimensions];
    
    unsigned int numberOfExtensionPieces;
    MHGlyphNode *lowerHookNode;
    MHGlyphNode *upperHookNode;
    MHGlyphNode *extensionPieceNode;
    MHGlyphNode *middlePieceNode;
    NSUInteger index;
    CGFloat verticalOffsetFromMathAxis;
    switch (_type) {
        case MHBracketTypeParenthesis:
        case MHBracketTypeSquareBrace:
            numberOfExtensionPieces =
            ceilf((2*bracketHeightAboveMathAxis - lowerHookDimensions.height - upperHookDimensions.height) / extensionPieceDimensions.height);
            
            lowerHookNode = [MHGlyphNode glyphNodeWithGlyphName:lowerHookGlyphName];
            [lowerHookNode configureWithFont:mathFont
                                       color:color
                             backgroundColor:nil
                                 underlining:underlining
                               strikethrough:false];
            lowerHookNode.name = kMHBracketGlyphNodeName;
            
            lowerHookNode.position = CGPointMake(0.0, mathAxisHeight
                                                 - 0.5*numberOfExtensionPieces*extensionPieceDimensions.height
                                                 - lowerHookDimensions.height);

            [_spriteKitNode addChild:lowerHookNode];
            
            upperHookNode = [MHGlyphNode glyphNodeWithGlyphName:upperHookGlyphName];
            [upperHookNode configureWithFont:mathFont
                                       color:color
                             backgroundColor:nil
                                 underlining:underlining
                               strikethrough:false];
            upperHookNode.name = kMHBracketGlyphNodeName;
            
            upperHookNode.position = CGPointMake(0.0, mathAxisHeight + 0.5*numberOfExtensionPieces*extensionPieceDimensions.height);

            [_spriteKitNode addChild:upperHookNode];
            
            for (index = 0; index < numberOfExtensionPieces; index++) {
                extensionPieceNode = [MHGlyphNode glyphNodeWithGlyphName:extensionPieceGlyphName];
                [extensionPieceNode configureWithFont:mathFont
                                                color:color
                                      backgroundColor:nil
                                          underlining:underlining
                                        strikethrough:false];
                extensionPieceNode.name = kMHBracketGlyphNodeName;
                
                extensionPieceNode.position = CGPointMake(0.0, mathAxisHeight +
                                                          extensionPieceDimensions.height * (index - 0.5*numberOfExtensionPieces));

                [_spriteKitNode addChild:extensionPieceNode];
            }
            
            myDimensions.width = lowerHookDimensions.width;
            myDimensions.height = mathAxisHeight + 0.5*numberOfExtensionPieces*extensionPieceDimensions.height + upperHookDimensions.height;
            myDimensions.depth = -mathAxisHeight + 0.5*numberOfExtensionPieces*extensionPieceDimensions.height + lowerHookDimensions.height;
            
            self.dimensions = myDimensions;

            break;
                        
        case MHBracketTypeFloor:
            numberOfExtensionPieces =
            ceilf((2*bracketHeightAboveMathAxis - lowerHookDimensions.height) / extensionPieceDimensions.height);
            
            lowerHookNode = [MHGlyphNode glyphNodeWithGlyphName:lowerHookGlyphName];
            [lowerHookNode configureWithFont:mathFont
                                       color:color
                             backgroundColor:nil
                                 underlining:underlining
                               strikethrough:false];
            lowerHookNode.name = kMHBracketGlyphNodeName;

            verticalOffsetFromMathAxis = 0.5*(numberOfExtensionPieces*extensionPieceDimensions.height +lowerHookDimensions.height);
            lowerHookNode.position = CGPointMake(0.0, mathAxisHeight - verticalOffsetFromMathAxis);

            [_spriteKitNode addChild:lowerHookNode];
            
            for (index = 0; index < numberOfExtensionPieces; index++) {
                extensionPieceNode = [MHGlyphNode glyphNodeWithGlyphName:extensionPieceGlyphName];
                [extensionPieceNode configureWithFont:mathFont
                                                color:color
                                      backgroundColor:nil
                                          underlining:underlining
                                        strikethrough:false];
                extensionPieceNode.name = kMHBracketGlyphNodeName;

                extensionPieceNode.position = CGPointMake(0.0,mathAxisHeight - verticalOffsetFromMathAxis + lowerHookDimensions.height
                                                          + index * extensionPieceDimensions.height);

                [_spriteKitNode addChild:extensionPieceNode];
            }
            
            myDimensions.width = lowerHookDimensions.width;
            myDimensions.height = mathAxisHeight + verticalOffsetFromMathAxis;
            myDimensions.depth = -mathAxisHeight + verticalOffsetFromMathAxis;
            
            self.dimensions = myDimensions;
            
            break;

        case MHBracketTypeCeiling:
            numberOfExtensionPieces =
            ceilf((2*bracketHeightAboveMathAxis - upperHookDimensions.height) / extensionPieceDimensions.height);
            
            upperHookNode = [MHGlyphNode glyphNodeWithGlyphName:upperHookGlyphName];
            [upperHookNode configureWithFont:mathFont
                                       color:color
                             backgroundColor:nil
                                 underlining:underlining
                               strikethrough:false];
            upperHookNode.name = kMHBracketGlyphNodeName;

            verticalOffsetFromMathAxis = 0.5*(numberOfExtensionPieces*extensionPieceDimensions.height + upperHookDimensions.height);
            upperHookNode.position = CGPointMake(0.0, mathAxisHeight + verticalOffsetFromMathAxis - upperHookDimensions.height);

            [_spriteKitNode addChild:upperHookNode];
            
            for (index = 0; index < numberOfExtensionPieces; index++) {
                extensionPieceNode = [MHGlyphNode glyphNodeWithGlyphName:extensionPieceGlyphName];
                [extensionPieceNode configureWithFont:mathFont
                                                color:color
                                      backgroundColor:nil
                                          underlining:underlining
                                        strikethrough:false];
                extensionPieceNode.name = kMHBracketGlyphNodeName;

                extensionPieceNode.position = CGPointMake(0.0,mathAxisHeight - verticalOffsetFromMathAxis
                                                          + index * extensionPieceDimensions.height);

                [_spriteKitNode addChild:extensionPieceNode];
            }
            
            myDimensions.width = upperHookDimensions.width;
            myDimensions.height = mathAxisHeight + verticalOffsetFromMathAxis;
            myDimensions.depth = -mathAxisHeight + verticalOffsetFromMathAxis;
            
            self.dimensions = myDimensions;
            
            break;
            
        case MHBracketTypeVerticalBar:
        case MHBracketTypeDoubleVerticalBar: {
            
            // FIXME: the calculations are wrong here, since they are not taking into account that this extension piece has both a height and a depth
            
            
            CGFloat totalExtensionPieceHeight = extensionPieceDimensions.depth + extensionPieceDimensions.height;
            numberOfExtensionPieces = ceilf(2*bracketHeightAboveMathAxis / totalExtensionPieceHeight);

            verticalOffsetFromMathAxis = 0.5 * numberOfExtensionPieces * totalExtensionPieceHeight;
            
            for (index = 0; index < numberOfExtensionPieces; index++) {
                extensionPieceNode = [MHGlyphNode glyphNodeWithGlyphName:extensionPieceGlyphName];
                [extensionPieceNode configureWithFont:mathFont
                                                color:color
                                      backgroundColor:nil
                                          underlining:underlining
                                        strikethrough:false];
                extensionPieceNode.name = kMHBracketGlyphNodeName;

                extensionPieceNode.position = CGPointMake(0.0,mathAxisHeight - verticalOffsetFromMathAxis + index * totalExtensionPieceHeight + extensionPieceDimensions.depth);
                [_spriteKitNode addChild:extensionPieceNode];
            }
            
            myDimensions.width = extensionPieceDimensions.width;
            myDimensions.height = mathAxisHeight + verticalOffsetFromMathAxis;
            myDimensions.depth = -mathAxisHeight + verticalOffsetFromMathAxis;
            
            self.dimensions = myDimensions;
        }
            break;

        case MHBracketTypeCurlyBrace:
            numberOfExtensionPieces = 2 *
            ceilf((bracketHeightAboveMathAxis - 0.5*lowerHookDimensions.height - 0.5*upperHookDimensions.height - 0.5*middlePieceDimensions.height) / extensionPieceDimensions.height);
            
            lowerHookNode = [MHGlyphNode glyphNodeWithGlyphName:lowerHookGlyphName];
            [lowerHookNode configureWithFont:mathFont
                                       color:color
                             backgroundColor:nil
                                 underlining:underlining
                               strikethrough:false];
            lowerHookNode.name = kMHBracketGlyphNodeName;

            lowerHookNode.position = CGPointMake(0.0, mathAxisHeight
                                                 - 0.5*numberOfExtensionPieces*extensionPieceDimensions.height
                                                 - lowerHookDimensions.height - 0.5*middlePieceDimensions.height);
            [_spriteKitNode addChild:lowerHookNode];
            
            upperHookNode = [MHGlyphNode glyphNodeWithGlyphName:upperHookGlyphName];
            [upperHookNode configureWithFont:mathFont
                                       color:color
                             backgroundColor:nil
                                 underlining:underlining
                               strikethrough:false];
            upperHookNode.name = kMHBracketGlyphNodeName;

            upperHookNode.position = CGPointMake(0.0, mathAxisHeight + 0.5*numberOfExtensionPieces*extensionPieceDimensions.height
                                                 + 0.5*middlePieceDimensions.height);
            [_spriteKitNode addChild:upperHookNode];
            
            middlePieceNode  = [MHGlyphNode glyphNodeWithGlyphName:middlePieceGlyphName];
            [middlePieceNode configureWithFont:mathFont
                                         color:color
                               backgroundColor:nil
                                   underlining:underlining
                                 strikethrough:false];
            middlePieceNode.name = kMHBracketGlyphNodeName;
            
            middlePieceNode.position = CGPointMake(0.0, mathAxisHeight - 0.5*middlePieceDimensions.height);
            [_spriteKitNode addChild:middlePieceNode];
            
            for (index = 0; 2*index < numberOfExtensionPieces; index++) {
                extensionPieceNode = [MHGlyphNode glyphNodeWithGlyphName:extensionPieceGlyphName];
                [extensionPieceNode configureWithFont:mathFont
                                                color:color
                                      backgroundColor:nil
                                          underlining:underlining
                                        strikethrough:false];
                extensionPieceNode.name = kMHBracketGlyphNodeName;

                extensionPieceNode.position = CGPointMake(0.0, mathAxisHeight + 0.5*middlePieceDimensions.height
                                                          + extensionPieceDimensions.height * index);
                [_spriteKitNode addChild:extensionPieceNode];

                extensionPieceNode = [MHGlyphNode glyphNodeWithGlyphName:extensionPieceGlyphName];
                [extensionPieceNode configureWithFont:mathFont
                                                color:color
                                      backgroundColor:nil
                                          underlining:underlining
                                        strikethrough:false];
                extensionPieceNode.name = kMHBracketGlyphNodeName;

                extensionPieceNode.position = CGPointMake(0.0, mathAxisHeight - 0.5*middlePieceDimensions.height
                                                          - extensionPieceDimensions.height * (index+1));
                [_spriteKitNode addChild:extensionPieceNode];
            }
            
            myDimensions.width = middlePieceDimensions.width;
            myDimensions.height = mathAxisHeight + 0.5*(numberOfExtensionPieces*extensionPieceDimensions.height+middlePieceDimensions.height) + upperHookDimensions.height;
            myDimensions.depth = -mathAxisHeight + 0.5*(numberOfExtensionPieces*extensionPieceDimensions.height+middlePieceDimensions.height) + lowerHookDimensions.height;
            
            self.dimensions = myDimensions;

            break;
            
            
        default:
            break;
    }
}



#pragma mark - Rendering in graphics contexts

- (void)renderToPDFWithContextManager:(MHPDFRenderingContextManager *)contextManager
{
    CGContextRef pdfContext = contextManager.pdfContext;
    NSArray <SKNode *> *children = self.spriteKitNode.children;
    for (SKNode *child in children) {
        if ([child.name isEqualToString:kMHBracketGlyphNodeName]) {
            MHGlyphNode *glyphChild = (MHGlyphNode *)child;     // to let the compiler know we know this object is an instance of MHGlyphNode
            CGPoint childPosition = glyphChild.position;
            CGContextTranslateCTM(pdfContext, childPosition.x, childPosition.y);
            [glyphChild renderInPDFContext:pdfContext];
            CGContextTranslateCTM(pdfContext, -childPosition.x, -childPosition.y);
        }
    }
}


#pragma mark - Expression copying

- (instancetype)logicalCopy
{
    MHBracket *myCopy = [[self class] bracketWithType:_type orientation:_orientation variant:_sizeVariant];
    myCopy.codeRange = self.codeRange;
    return myCopy;
}



@end


