//
//  MHAnnotatedHorizontalExtensibleSymbol.m
//  MadHat
//
//  Created by Dan Romik on 10/6/20.
//  Copyright © 2020 Dan Romik. All rights reserved.
//
//  Class description: this class implements an extensible horizontal symbol that stretches so as to become wider than a prescribed
//  content. The symbol is displayed with an argument expression above it and another below (these are referred to in the code as
//  the top annotation and bottom annotation). The symbol along with the annotation are aligned vertically according to one of three
//  positioning modes:
//
//  1. Top positioning: this aligns the bottom annotation with the line of math currently being typeset. This mode is used for
//     typesetting annotated overbrackets, overbraces and their variants.
//  2. Bottom positioning: this aligns the top annotation with the line of math currently being typeset. This mode is used for
//     typesetting annotated overbrackets, overbraces and their variants.
//  3. Middle positioning: this aligns the extensible symbol with the line of math currently being typeset. This mode is used for
//     typesetting extensible arrows, equal signs etc.
//
//  In the middle positioning mode, the top and bottom annotation are displayed in a smaller size than the text size of the containing
//  expression (that is, their nesting levels are increased, the top annotation being treated like a superscript and the bottom annotation
//  being treated as a subscript). In the top and bottom modes, the annotations are typeset in the same font size as the containing
//  expression.
//

#import "MHAnnotatedHorizontalExtensibleSymbol.h"
#import "MadHat.h"
#import "MHTypesettingContextManager.h"
#import "MHStyleIncludes.h"
#import "MHMathFontSystem.h"
#import "MHMathFontSystem+ExtensibleSymbols.h"
#import "MHGlyphNode.h"


static NSString * const kMHAnnotatedHorizontalExtensibleSymbolOverbraceCommandName = @"overbrace";
static NSString * const kMHAnnotatedHorizontalExtensibleSymbolUnderbraceCommandName = @"underbrace";
static NSString * const kMHAnnotatedHorizontalExtensibleSymbolOverbracketCommandName = @"overbracket";
static NSString * const kMHAnnotatedHorizontalExtensibleSymbolUnderbracketCommandName = @"underbracket";
static NSString * const kMHAnnotatedHorizontalExtensibleSymbolOverparenthesisCommandName = @"overparenthesis";
static NSString * const kMHAnnotatedHorizontalExtensibleSymbolUnderparenthesisCommandName = @"underparenthesis";
static NSString * const kMHAnnotatedHorizontalExtensibleSymbolOvertortoiseCommandName = @"overtortoise";
static NSString * const kMHAnnotatedHorizontalExtensibleSymbolUndertortoiseCommandName = @"undertortoise";

static NSString * const kMHAnnotatedHorizontalExtensibleSymbolAnnotatedEqualSignCommandName = @"annotated equal";
static NSString * const kMHAnnotatedHorizontalExtensibleSymbolAnnotatedRightArrowCommandName = @"annotated right arrow";
static NSString * const kMHAnnotatedHorizontalExtensibleSymbolAnnotatedDoubleRightArrowCommandName = @"annotated double right arrow";
static NSString * const kMHAnnotatedHorizontalExtensibleSymbolAnnotatedLeftArrowCommandName = @"annotated left arrow";
static NSString * const kMHAnnotatedHorizontalExtensibleSymbolAnnotatedDoubleLeftArrowCommandName = @"annotated double left arrow";
static NSString * const kMHAnnotatedHorizontalExtensibleSymbolAnnotatedLeftRightArrowCommandName = @"annotated left right arrow";
static NSString * const kMHAnnotatedHorizontalExtensibleSymbolAnnotatedDoubleLeftRightArrowCommandName = @"annotated double left right arrow";


static NSString * const kMHHorizontalExtensibleSymbolGlyphNodeName = @"HorizontalExtensibleSymbolGlyphNode";


// These are the nesting levels used for the top and bottom annotations of extensible symbols such as arrows and equal signs
// They are the same as those used for subscripts and superscripts, see the MHScriptedExpression class (and pages 140-141 in The TeXBook)
NSUInteger const kMHExtensibleSymbolTopAnnotationNestingLevels[kMHNumberOfNestingLevels] = {
    4, 5, 4, 5, 6, 7, 6, 7
};
NSUInteger const kMHExtensibleSymbolBottomAnnotationNestingLevels[kMHNumberOfNestingLevels] = {
    5, 5, 5, 5, 7, 7, 7, 7
};



// FIXME: add support for expressions with both bottom and top extensible brackets and annotations

// FIXME: more ambitiously, allow top and bottom brackets that enclose different parts of the contents in an interlacing fashion


@interface MHAnnotatedHorizontalExtensibleSymbol ()
{
    MHExpression *_topAnnotation;

    MHExpression *_bottomAnnotation;
    MHHorizontalExtensibleSymbolType _symbolType;
    MHHorizontalExtensibleSymbolPositioning _positioning;
}

@end

@implementation MHAnnotatedHorizontalExtensibleSymbol


#pragma mark - Constructors


+ (instancetype)horizontalExtensibleSymbolWithSymbolType:(MHHorizontalExtensibleSymbolType)symbolType
                                           topAnnotation:(MHExpression *)topAnnotation
                                        bottomAnnotation:(MHExpression *)bottomAnnotation
                                             positioning:(MHHorizontalExtensibleSymbolPositioning)positioning;
{
    return [[[self class] alloc] initWithSymbolType:symbolType
                                      topAnnotation:topAnnotation
                                   bottomAnnotation:bottomAnnotation
                                        positioning:positioning];
}

- (instancetype)initWithSymbolType:(MHHorizontalExtensibleSymbolType)symbolType
                     topAnnotation:(MHExpression *)topAnnotation
                  bottomAnnotation:(MHExpression *)bottomAnnotation
                       positioning:(MHHorizontalExtensibleSymbolPositioning)positioning
{
    if (self = [super init]) {
        _topAnnotation = topAnnotation;
        _symbolType = symbolType;
        _bottomAnnotation = bottomAnnotation;
        _positioning = positioning;
    }
    return self;
}

#pragma mark - MHCommand protocol

+ (instancetype)commandNamed:(NSString *)name withParameters:(nullable NSDictionary *)parameters argument:(MHHorizontalLayoutContainer *)argument
{
    // FIXME: ugly code, needs rewriting to make more readable and efficient
    
    bool isOverbracket = false;
    bool isOverbrace = false;
    bool isUnderbracket = false;
    bool isUnderbrace = false;
    bool isOverparenthesis = false;
    bool isUnderparenthesis = false;
    bool isOvertortoise = false;
    bool isUndertortoise = false;
    bool isAnnotatedEqualSign = false;
    bool isAnnotatedRightArrow = false;
    bool isAnnotatedDoubleRightArrow = false;
    bool isAnnotatedLeftArrow = false;
    bool isAnnotatedDoubleLeftArrow = false;
    bool isAnnotatedLeftRightArrow = false;
    bool isAnnotatedDoubleLeftRightArrow = false;
    if ((isOverbracket = [name isEqualToString:kMHAnnotatedHorizontalExtensibleSymbolOverbracketCommandName])
        || (isOverbrace = [name isEqualToString:kMHAnnotatedHorizontalExtensibleSymbolOverbraceCommandName])
        || (isOverparenthesis = [name isEqualToString:kMHAnnotatedHorizontalExtensibleSymbolOverparenthesisCommandName])
        || (isOvertortoise = [name isEqualToString:kMHAnnotatedHorizontalExtensibleSymbolOvertortoiseCommandName])
        || (isUnderbracket = [name isEqualToString:kMHAnnotatedHorizontalExtensibleSymbolUnderbracketCommandName])
        || (isUnderbrace = [name isEqualToString:kMHAnnotatedHorizontalExtensibleSymbolUnderbraceCommandName])
        || (isUnderparenthesis = [name isEqualToString:kMHAnnotatedHorizontalExtensibleSymbolUnderparenthesisCommandName])
        || (isUndertortoise = [name isEqualToString:kMHAnnotatedHorizontalExtensibleSymbolUndertortoiseCommandName])
        || (isAnnotatedEqualSign = [name isEqualToString:kMHAnnotatedHorizontalExtensibleSymbolAnnotatedEqualSignCommandName])
        || (isAnnotatedRightArrow = [name isEqualToString:kMHAnnotatedHorizontalExtensibleSymbolAnnotatedRightArrowCommandName])
        || (isAnnotatedDoubleRightArrow = [name isEqualToString:kMHAnnotatedHorizontalExtensibleSymbolAnnotatedDoubleRightArrowCommandName])
        || (isAnnotatedLeftArrow = [name isEqualToString:kMHAnnotatedHorizontalExtensibleSymbolAnnotatedLeftArrowCommandName])
        || (isAnnotatedDoubleLeftArrow = [name isEqualToString:kMHAnnotatedHorizontalExtensibleSymbolAnnotatedDoubleLeftArrowCommandName])
        || (isAnnotatedLeftRightArrow = [name isEqualToString:kMHAnnotatedHorizontalExtensibleSymbolAnnotatedLeftRightArrowCommandName])
        || (isAnnotatedDoubleLeftRightArrow = [name isEqualToString:kMHAnnotatedHorizontalExtensibleSymbolAnnotatedDoubleLeftRightArrowCommandName])) {

        MHExpression *firstArgument = [argument expressionFromDelimitedBlockAtIndex:0];
        MHExpression *secondArgument = [argument expressionFromDelimitedBlockAtIndex:1];
        MHHorizontalExtensibleSymbolType extensibleSymbolType;
        if (isOverbracket || isOverbrace || isOverparenthesis || isOvertortoise) {
            extensibleSymbolType = (isOverbrace ? MHHorizontalExtensibleSymbolOverbrace :
                           (isOverbracket ? MHHorizontalExtensibleSymbolOverbracket :
                            (isOverparenthesis ? MHHorizontalExtensibleSymbolOverparenthesis : MHHorizontalExtensibleSymbolOvertortoise)));
            
            return [self horizontalExtensibleSymbolWithSymbolType:extensibleSymbolType
                                                    topAnnotation:secondArgument
                                                 bottomAnnotation:firstArgument
                                                      positioning:MHHorizontalExtensibleSymbolPositioningTop];

        }
        else if (isUnderbracket || isUnderbrace || isUnderparenthesis || isUndertortoise) {
            extensibleSymbolType = (isUnderbrace ? MHHorizontalExtensibleSymbolUnderbrace :
                           (isUnderbracket ? MHHorizontalExtensibleSymbolUnderbracket :
                            (isUnderparenthesis ? MHHorizontalExtensibleSymbolUnderparenthesis : MHHorizontalExtensibleSymbolUndertortoise)));

            return [self horizontalExtensibleSymbolWithSymbolType:extensibleSymbolType
                                                    topAnnotation:firstArgument
                                                 bottomAnnotation:secondArgument
                                                      positioning:MHHorizontalExtensibleSymbolPositioningBottom];
        }
        else if (isAnnotatedEqualSign || isAnnotatedRightArrow || isAnnotatedDoubleRightArrow || isAnnotatedLeftArrow || isAnnotatedDoubleLeftArrow || isAnnotatedLeftRightArrow || isAnnotatedDoubleLeftRightArrow) {
            extensibleSymbolType = (isAnnotatedEqualSign ? MHHorizontalExtensibleSymbolEqualSign :
                           (isAnnotatedRightArrow ? MHHorizontalExtensibleSymbolRightArrow :
                            (isAnnotatedDoubleRightArrow ? MHHorizontalExtensibleSymbolDoubleRightArrow :
                             (isAnnotatedLeftArrow ? MHHorizontalExtensibleSymbolLeftArrow :
                              (isAnnotatedDoubleLeftArrow ? MHHorizontalExtensibleSymbolDoubleLeftArrow :
                               (isAnnotatedLeftRightArrow ? MHHorizontalExtensibleSymbolLeftRightArrow :
                                MHHorizontalExtensibleSymbolDoubleLeftRightArrow))))));
            
            return [self horizontalExtensibleSymbolWithSymbolType:extensibleSymbolType
                                                    topAnnotation:firstArgument
                                                 bottomAnnotation:secondArgument
                                                      positioning:MHHorizontalExtensibleSymbolPositioningMiddle];
        }
        
    }
    
    return nil;
}

+ (NSArray <NSString *> *)recognizedCommands
{
    return @[
        kMHAnnotatedHorizontalExtensibleSymbolOverbraceCommandName,
        kMHAnnotatedHorizontalExtensibleSymbolUnderbraceCommandName,
        kMHAnnotatedHorizontalExtensibleSymbolOverbracketCommandName,
        kMHAnnotatedHorizontalExtensibleSymbolUnderbracketCommandName,
        kMHAnnotatedHorizontalExtensibleSymbolOverparenthesisCommandName,
        kMHAnnotatedHorizontalExtensibleSymbolUnderparenthesisCommandName,
        kMHAnnotatedHorizontalExtensibleSymbolOvertortoiseCommandName,
        kMHAnnotatedHorizontalExtensibleSymbolUndertortoiseCommandName,
        kMHAnnotatedHorizontalExtensibleSymbolAnnotatedRightArrowCommandName
    ];
}


#pragma mark - Properties

- (NSArray <MHExpression *> *)subexpressions
{
    return @[ _topAnnotation, _bottomAnnotation ];
}

- (MHTypographyClass)typographyClass
{
    bool isArrow = (_positioning == MHHorizontalExtensibleSymbolPositioningMiddle);
    return (isArrow ? MHTypographyClassBinaryRelation : MHTypographyClassCompoundExpression);
}

- (void)setNestingLevel:(NSUInteger)nestingLevel
{
    super.nestingLevel = nestingLevel;
    if (_positioning == MHHorizontalExtensibleSymbolPositioningMiddle) {
        // For extensible arrows and equal signs, we use the same algorithm for nesting levels as ordinary subscripts and superscripts
        _topAnnotation.nestingLevel = kMHExtensibleSymbolTopAnnotationNestingLevels[nestingLevel];
        _bottomAnnotation.nestingLevel = kMHExtensibleSymbolBottomAnnotationNestingLevels[nestingLevel];
    }
}



#pragma mark - Typesetting

- (void)typesetWithContextManager:(MHTypesettingContextManager *)contextManager
{
    [super typesetWithContextManager:contextManager];
    
    MHDimensions myDimensions;
    MHDimensions topAnnotationDimensions = _topAnnotation.dimensions;

    MHDimensions bottomAnnotationDimensions = _bottomAnnotation.dimensions;
    

    [_spriteKitNode removeChildrenInArray:[_spriteKitNode objectForKeyedSubscript:kMHHorizontalExtensibleSymbolGlyphNodeName]];
    
    NSColor *color = contextManager.textForegroundColor;
    NSUInteger nestingLevel = self.nestingLevel;
    CGFloat emWidth = [contextManager fontSizeForNestingLevel:nestingLevel];
    NSFont *mathFont = [contextManager mathFontForNestingLevel:nestingLevel traits:MHMathFontTraitRoman];
    MHMathFontSystem *mathFontSystem = contextManager.mathFontSystem;
    MHDimensions glyphDimensions;
    CGFloat widthToEnclose = (_positioning == MHHorizontalExtensibleSymbolPositioningMiddle ?
                                              fmaxf(topAnnotationDimensions.width, bottomAnnotationDimensions.width) :
                              (_positioning == MHHorizontalExtensibleSymbolPositioningTop) ? bottomAnnotationDimensions.width : topAnnotationDimensions.width);
    NSString *glyphName = [mathFontSystem glyphNameForHorizontalExtensibleSymbolOfType:_symbolType
                                                            forEnclosingWidth:widthToEnclose
                                                                withPointSize:emWidth
                                                                getDimensions:&glyphDimensions];
    if (glyphName) {
        // We found a glyph of an extensible symbol that's at least as wide as the specified width
        
        MHGlyphNode *extensibleSymbolNode = [MHGlyphNode glyphNodeWithGlyphName:glyphName];
        [extensibleSymbolNode configureWithFont:mathFont
                                          color:color
                                backgroundColor:nil
                                    underlining:false
                                  strikethrough:false];
        extensibleSymbolNode.name = kMHHorizontalExtensibleSymbolGlyphNodeName;
        
        myDimensions.width = fmaxf(glyphDimensions.width, fmaxf(topAnnotationDimensions.width, bottomAnnotationDimensions.width));
        
        switch (_positioning) {
            case MHHorizontalExtensibleSymbolPositioningTop:
                _bottomAnnotation.position = CGPointMake((myDimensions.width - bottomAnnotationDimensions.width)/2.0, 0.0);

                extensibleSymbolNode.position = CGPointMake((myDimensions.width - glyphDimensions.width)/2.0, bottomAnnotationDimensions.height + glyphDimensions.depth + 3.0); // FIXME: ad hoc offset, improve

                _topAnnotation.position = CGPointMake((myDimensions.width - topAnnotationDimensions.width)/2.0,
                                                  bottomAnnotationDimensions.height + 3.0 + glyphDimensions.height + glyphDimensions.depth
                                                  + topAnnotationDimensions.depth + 3.0);
                myDimensions.height = topAnnotationDimensions.height + 3.0 + glyphDimensions.height + glyphDimensions.depth
                                            + bottomAnnotationDimensions.depth + bottomAnnotationDimensions.height + 3.0;
                myDimensions.depth = topAnnotationDimensions.depth;
                break;
            case MHHorizontalExtensibleSymbolPositioningBottom:
                _topAnnotation.position = CGPointMake((myDimensions.width - topAnnotationDimensions.width)/2.0, 0.0);

                extensibleSymbolNode.position = CGPointMake((myDimensions.width - glyphDimensions.width)/2.0, -topAnnotationDimensions.depth
                                                   - glyphDimensions.height - 3.0); // FIXME: ad hoc offset, improve

                _bottomAnnotation.position = CGPointMake((myDimensions.width - bottomAnnotationDimensions.width)/2.0,
                                                  -topAnnotationDimensions.depth - 3.0 - glyphDimensions.height - glyphDimensions.depth
                                                  - bottomAnnotationDimensions.height - 3.0);
                myDimensions.depth = topAnnotationDimensions.depth + 3.0 + glyphDimensions.height + glyphDimensions.depth
                                            + bottomAnnotationDimensions.depth + bottomAnnotationDimensions.height + 3.0;
                myDimensions.height = topAnnotationDimensions.height;
                break;
            case MHHorizontalExtensibleSymbolPositioningMiddle: {
                CGFloat arrowOffset = 1.0;  // FIXME: not sure why this is needed // [contextManager mathAxisHeightForNestingLevel:nestingLevel];
                
                extensibleSymbolNode.position = CGPointMake((myDimensions.width - glyphDimensions.width)/2.0, arrowOffset);

                _topAnnotation.position = CGPointMake((myDimensions.width - topAnnotationDimensions.width)/2.0,
                                                       arrowOffset + glyphDimensions.height + 3.0 + topAnnotationDimensions.depth);

                _bottomAnnotation.position = CGPointMake((myDimensions.width - bottomAnnotationDimensions.width)/2.0,
                                                   arrowOffset - glyphDimensions.depth - 3.0 - bottomAnnotationDimensions.height);
                
                myDimensions.height = arrowOffset + glyphDimensions.height + 3.0 + topAnnotationDimensions.depth + topAnnotationDimensions.height;
                myDimensions.depth = glyphDimensions.depth + 3.0 + bottomAnnotationDimensions.height + bottomAnnotationDimensions.depth;
            }
                break;
        }
        
        [_spriteKitNode addChild:extensibleSymbolNode];
        
        self.dimensions = myDimensions;
        
        return;
    }
    
    // Since glyphName is nil, that means the content is too wide to be enclosed by one of the standard glyph variants
    // so we must create an extensible symbol by using tileable extension pieces. The precise algorithm will depend
    // on the type of symbol

    NSString *leftHookGlyphName;
    NSString *rightHookGlyphName;
    NSString *extensionPieceGlyphName;
    NSString *middlePieceGlyphName;
    
    MHDimensions leftHookDimensions;
    MHDimensions rightHookDimensions;
    MHDimensions extensionPieceDimensions;
    MHDimensions middlePieceDimensions;
    
    [mathFontSystem getExtensibleHorizontalExtensibleSymbolPartsOfType:_symbolType
                                                         withPointSize:emWidth
                                                  getLeftHookGlyphName:&leftHookGlyphName
                                                 getLeftHookDimensions:&leftHookDimensions
                                                 getRightHookGlyphName:&rightHookGlyphName
                                                getRightHookDimensions:&rightHookDimensions
                                            getExtensionPieceGlyphName:&extensionPieceGlyphName
                                           getExtensionPieceDimensions:&extensionPieceDimensions
                                               getMiddlePieceGlyphName:&middlePieceGlyphName
                                              getMiddlePieceDimensions:&middlePieceDimensions];
    
    unsigned int numberOfExtensionPieces;

    MHGlyphNode *leftHookNode;
    MHGlyphNode *rightHookNode;
    MHGlyphNode *extensionPieceNode;
    MHGlyphNode *middlePieceNode;
    NSUInteger index;
    
    SKNode *extensibleSymbolContainerNode;
    
    MHDimensions extensibleSymbolDimensions;
    
    CGFloat padding = 6.0;     // FIXME: ad hoc value, improve
    CGFloat widthToEncloseWithPadding = widthToEnclose + padding;

    switch (_symbolType) {
        case MHHorizontalExtensibleSymbolOverbracket:
        case MHHorizontalExtensibleSymbolUnderbracket:
        case MHHorizontalExtensibleSymbolOverparenthesis:
        case MHHorizontalExtensibleSymbolUnderparenthesis:
        case MHHorizontalExtensibleSymbolOvertortoise:
        case MHHorizontalExtensibleSymbolUndertortoise:

        case MHHorizontalExtensibleSymbolEqualSign:
        case MHHorizontalExtensibleSymbolRightArrow:
        case MHHorizontalExtensibleSymbolDoubleRightArrow:
        case MHHorizontalExtensibleSymbolLeftArrow:
        case MHHorizontalExtensibleSymbolDoubleLeftArrow:
        case MHHorizontalExtensibleSymbolLeftRightArrow:
        case MHHorizontalExtensibleSymbolDoubleLeftRightArrow:

            extensibleSymbolContainerNode = [SKNode node];
            extensibleSymbolContainerNode.name = kMHHorizontalExtensibleSymbolGlyphNodeName;
            
            if (widthToEncloseWithPadding < leftHookDimensions.width + rightHookDimensions.width)
                numberOfExtensionPieces = 1;
            else {
                numberOfExtensionPieces = ceilf((widthToEncloseWithPadding - leftHookDimensions.width - rightHookDimensions.width) / extensionPieceDimensions.width);
            }
            
            leftHookNode = [MHGlyphNode glyphNodeWithGlyphName:leftHookGlyphName];
            [leftHookNode configureWithFont:mathFont
                                      color:color
                            backgroundColor:nil
                                underlining:false
                              strikethrough:false];
            
            leftHookNode.position = CGPointMake(0.0, 0.0);

            [extensibleSymbolContainerNode addChild:leftHookNode];
            
            rightHookNode = [MHGlyphNode glyphNodeWithGlyphName:rightHookGlyphName];
            [rightHookNode configureWithFont:mathFont
                                       color:color
                             backgroundColor:nil
                                 underlining:false
                               strikethrough:false];
            
            rightHookNode.position = CGPointMake(leftHookDimensions.width + numberOfExtensionPieces*extensionPieceDimensions.width, 0.0);

            [extensibleSymbolContainerNode addChild:rightHookNode];
            
            for (index = 0; index < numberOfExtensionPieces; index++) {
                extensionPieceNode = [MHGlyphNode glyphNodeWithGlyphName:extensionPieceGlyphName];
                [extensionPieceNode configureWithFont:mathFont
                                                color:color
                                      backgroundColor:nil
                                          underlining:false
                                        strikethrough:false];
                extensionPieceNode.name = kMHHorizontalExtensibleSymbolGlyphNodeName;

                extensionPieceNode.position = CGPointMake(leftHookDimensions.width + index * extensionPieceDimensions.width, 0.0);

                [extensibleSymbolContainerNode addChild:extensionPieceNode];
            }
            
            [_spriteKitNode addChild:extensibleSymbolContainerNode];
            
            extensibleSymbolDimensions.width = leftHookDimensions.width + rightHookDimensions.width + numberOfExtensionPieces * extensionPieceDimensions.width;
            extensibleSymbolDimensions.depth = fmaxf(leftHookDimensions.depth, rightHookDimensions.depth);
            extensibleSymbolDimensions.height = fmaxf(leftHookDimensions.height, rightHookDimensions.height);
            myDimensions.width = fmaxf(extensibleSymbolDimensions.width, bottomAnnotationDimensions.width);
            
            // note: code continues after the switch { ... } block with positioning the different subexpressions and setting the dimensions
            
            break;
            
        case MHHorizontalExtensibleSymbolOverbrace:
        case MHHorizontalExtensibleSymbolUnderbrace:
            
            extensibleSymbolContainerNode = [SKNode node];
            extensibleSymbolContainerNode.name = kMHHorizontalExtensibleSymbolGlyphNodeName;
            
            numberOfExtensionPieces =
            ceilf((widthToEncloseWithPadding - leftHookDimensions.width - rightHookDimensions.width - middlePieceDimensions.width) / extensionPieceDimensions.width / 2.0);
            
            leftHookNode = [MHGlyphNode glyphNodeWithGlyphName:leftHookGlyphName];
            [leftHookNode configureWithFont:mathFont
                                      color:color
                            backgroundColor:nil
                                underlining:false
                              strikethrough:false];
            
            leftHookNode.position = CGPointMake(0.0, 0.0);

            [extensibleSymbolContainerNode addChild:leftHookNode];
            
            rightHookNode = [MHGlyphNode glyphNodeWithGlyphName:rightHookGlyphName];
            [rightHookNode configureWithFont:mathFont
                                       color:color
                             backgroundColor:nil
                                 underlining:false
                               strikethrough:false];
            
            rightHookNode.position = CGPointMake(leftHookDimensions.width + middlePieceDimensions.width
                                                 + 2.0*numberOfExtensionPieces*extensionPieceDimensions.width, 0.0);

            [extensibleSymbolContainerNode addChild:rightHookNode];
            
            
            middlePieceNode = [MHGlyphNode glyphNodeWithGlyphName:middlePieceGlyphName];
            [middlePieceNode configureWithFont:mathFont
                                         color:color
                               backgroundColor:nil
                                   underlining:false
                                 strikethrough:false];
            
            middlePieceNode.position = CGPointMake(leftHookDimensions.width
                                                   + numberOfExtensionPieces * extensionPieceDimensions.width, 0.0);

            [extensibleSymbolContainerNode addChild:middlePieceNode];
            
            CGFloat secondMiddlePieceOffsetFromFirst = numberOfExtensionPieces*extensionPieceDimensions.width + middlePieceDimensions.width;
            
            for (index = 0; index < numberOfExtensionPieces; index++) {
                
                // Add the first extension piece
                extensionPieceNode = [MHGlyphNode glyphNodeWithGlyphName:extensionPieceGlyphName];
                [extensionPieceNode configureWithFont:mathFont
                                                color:color
                                      backgroundColor:nil
                                          underlining:false
                                        strikethrough:false];
                extensionPieceNode.name = kMHHorizontalExtensibleSymbolGlyphNodeName;

                extensionPieceNode.position = CGPointMake(leftHookDimensions.width + index * extensionPieceDimensions.width, 0.0);

                [extensibleSymbolContainerNode addChild:extensionPieceNode];

                // Add the second extension piece
                extensionPieceNode = [MHGlyphNode glyphNodeWithGlyphName:extensionPieceGlyphName];
                [extensionPieceNode configureWithFont:mathFont
                                                color:color
                                      backgroundColor:nil
                                          underlining:false
                                        strikethrough:false];
                extensionPieceNode.name = kMHHorizontalExtensibleSymbolGlyphNodeName;

                extensionPieceNode.position = CGPointMake(secondMiddlePieceOffsetFromFirst +
                                                          leftHookDimensions.width + index * extensionPieceDimensions.width, 0.0);

                [extensibleSymbolContainerNode addChild:extensionPieceNode];
            }
            
            [_spriteKitNode addChild:extensibleSymbolContainerNode];
            
            extensibleSymbolDimensions.width = leftHookDimensions.width + rightHookDimensions.width + 2.0*numberOfExtensionPieces * extensionPieceDimensions.width + middlePieceDimensions.width;
            extensibleSymbolDimensions.depth = fmaxf(fmaxf(leftHookDimensions.depth, rightHookDimensions.depth), middlePieceDimensions.depth);
            extensibleSymbolDimensions.height = fmaxf(fmaxf(leftHookDimensions.height, rightHookDimensions.height), middlePieceDimensions.height);

            myDimensions.width = fmaxf(extensibleSymbolDimensions.width, bottomAnnotationDimensions.width);
            
            // note: code continues after the switch { ... } block with positioning the different subexpressions and setting the dimensions
            
            break;


        case MHHorizontalExtensibleSymbolNone:
            // Nothing to do, return
            NSLog(@"FIXME: invalid code point");
            return;
            break;
    }
    
    CGPoint topAnnotationPosition;
    CGPoint extensibleSymbolContainerPosition;
    CGPoint bottomAnnotationPosition;
    
    switch (_positioning) {
        case MHHorizontalExtensibleSymbolPositioningTop:
            // Set the top annotation position
            topAnnotationPosition = CGPointMake((myDimensions.width - topAnnotationDimensions.width)/2.0,
                                             bottomAnnotationDimensions.height + 3.0 + extensibleSymbolDimensions.height + extensibleSymbolDimensions.depth
                                             + topAnnotationDimensions.depth + 3.0);
            
            // Set the extensible symbol position
            extensibleSymbolContainerPosition = CGPointMake((myDimensions.width - extensibleSymbolDimensions.width)/2.0,
                                                   bottomAnnotationDimensions.height + extensibleSymbolDimensions.depth + 3.0); // FIXME: ad hoc offset, improve

            // Set the bottom annotation position
            bottomAnnotationPosition = CGPointMake((myDimensions.width - bottomAnnotationDimensions.width)/2.0, 0.0);

            // Set the total dimensions
            myDimensions.height = bottomAnnotationDimensions.height + 3.0 + extensibleSymbolDimensions.depth + extensibleSymbolDimensions.height + 3.0 + topAnnotationDimensions.depth + topAnnotationDimensions.height;
            myDimensions.depth = bottomAnnotationDimensions.depth;
            break;
            
        case MHHorizontalExtensibleSymbolPositioningBottom:
            // Set the top annotation position
            topAnnotationPosition = CGPointMake((myDimensions.width - topAnnotationDimensions.width)/2.0, 0.0);

            // Set the extensible symbol position
            extensibleSymbolContainerPosition = CGPointMake((myDimensions.width - extensibleSymbolDimensions.width)/2.0,
                                                   -topAnnotationDimensions.depth - extensibleSymbolDimensions.height - 3.0); // FIXME: ad hoc offset, improve

            // Set the bottom annotation position
            bottomAnnotationPosition = CGPointMake((myDimensions.width - bottomAnnotationDimensions.width)/2.0,
                                             -topAnnotationDimensions.depth - 3.0 - extensibleSymbolDimensions.height - extensibleSymbolDimensions.depth
                                             - bottomAnnotationDimensions.height - 3.0);

            // Set the total dimensions
            myDimensions.depth = topAnnotationDimensions.depth + 3.0 + extensibleSymbolDimensions.depth + extensibleSymbolDimensions.height + 3.0 + bottomAnnotationDimensions.depth + bottomAnnotationDimensions.height;
            myDimensions.height = topAnnotationDimensions.height;
            break;
            
        case MHHorizontalExtensibleSymbolPositioningMiddle: {
            CGFloat arrowOffset = 1.0; // FIXME: not sure why this is needed // [contextManager mathAxisHeightForNestingLevel:nestingLevel];
            
            // Set the top annotation position
            topAnnotationPosition = CGPointMake((myDimensions.width - topAnnotationDimensions.width)/2.0,
                                                 arrowOffset + extensibleSymbolDimensions.height + 3.0 + topAnnotationDimensions.depth);

            // Set the extensible symbol position
            extensibleSymbolContainerPosition = CGPointMake((myDimensions.width - extensibleSymbolDimensions.width)/2.0, arrowOffset);

            // Set the bottom annotation position
            bottomAnnotationPosition = CGPointMake((myDimensions.width - bottomAnnotationDimensions.width)/2.0,
                                             arrowOffset-extensibleSymbolDimensions.depth - 3.0 - bottomAnnotationDimensions.height);

            // Set the overall dimensions
            myDimensions.height = arrowOffset + extensibleSymbolDimensions.height + 3.0 + topAnnotationDimensions.depth + topAnnotationDimensions.height;
            myDimensions.depth = extensibleSymbolDimensions.depth + 3.0 + bottomAnnotationDimensions.height + bottomAnnotationDimensions.depth;
        }
            break;
    }
    
    _topAnnotation.position = topAnnotationPosition;
    _bottomAnnotation.position = bottomAnnotationPosition;
    extensibleSymbolContainerNode.position = extensibleSymbolContainerPosition;
    
    self.dimensions = myDimensions;
    
}



#pragma mark - Expression copying

- (instancetype)logicalCopy
{
    MHAnnotatedHorizontalExtensibleSymbol *myCopy = [[[self class] alloc] initWithSymbolType:_symbolType
                                                                               topAnnotation:[_topAnnotation logicalCopy]
                                                                            bottomAnnotation:[_bottomAnnotation logicalCopy]
                                                                                 positioning:_positioning];

    myCopy.codeRange = self.codeRange;
    return myCopy;
}


#pragma mark - Rendering in PDF context

- (void)renderToPDFWithContextManager:(MHPDFRenderingContextManager *)contextManager
{
    [super renderToPDFWithContextManager:contextManager];
    CGContextRef pdfContext = contextManager.pdfContext;

    // FIXME: ad hoc code to get things working temporarily, needs refactoring
    
    CGContextSaveGState(pdfContext);
    
    SKNode *extensibleSymbolNode = [_spriteKitNode childNodeWithName:kMHHorizontalExtensibleSymbolGlyphNodeName];
    
    if ([extensibleSymbolNode isMemberOfClass:[MHGlyphNode class]]) {
        MHGlyphNode *singleGlyphNode = (MHGlyphNode *)extensibleSymbolNode;
        
        CGPoint glyphNodePosition = singleGlyphNode.position;
        CGContextTranslateCTM(pdfContext, glyphNodePosition.x, glyphNodePosition.y);
        
        [singleGlyphNode renderInPDFContext:pdfContext];
    }
    else if ([extensibleSymbolNode isMemberOfClass:[SKNode class]]) {
        CGPoint nodePosition = extensibleSymbolNode.position;
        CGContextTranslateCTM(pdfContext, nodePosition.x, nodePosition.y);
        NSArray *children = [extensibleSymbolNode children];
        for (SKNode *child in children) {
            if ([child isMemberOfClass:[MHGlyphNode class]]) {
                MHGlyphNode *childGlyphNode = (MHGlyphNode *)child;
                
                CGPoint glyphNodePosition = childGlyphNode.position;
                CGContextTranslateCTM(pdfContext, glyphNodePosition.x, glyphNodePosition.y);
                [childGlyphNode renderInPDFContext:pdfContext];
                CGContextTranslateCTM(pdfContext, -glyphNodePosition.x, -glyphNodePosition.y);
            }
        }
    }
    
    CGContextRestoreGState(pdfContext);
    
}

@end
