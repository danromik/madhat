//
//  MHWhitespace.m
//  MadHat
//
//  Created by Dan Romik on 8/24/20.
//  Copyright © 2020 Dan Romik. All rights reserved.
//

#import "MHWhitespace.h"
#import "MHStyleIncludes.h"

#define kMHHorizontalSpaceEditingModeHeight               3.0

#define kMHHorizontalSpaceWideWidthFactor                 1.2
#define kMHHorizontalSpaceQuadWidthFactor                 2.0
#define kMHHorizontalSpaceQQuadWidthFactor                4.0
#define kMHHorizontalSpaceHalfSpaceWidthFactor            0.5     // If I ever change this value, it would make sense to rename the space type and constant

#define kMHVerticalSpaceSmall                            1.0
#define kMHVerticalSpaceMedium                           1.5
#define kMHVerticalSpaceLarge                            2.0
#define kMHVerticalSpaceHuge                             4.0

static NSString * const kMHHorizontalSpaceCommandName = @"space";
static NSString * const kMHNewlineCommandName = @"newline";
static NSString * const kMHVerticalSkipCommandName = @"vertical skip";

static NSString * const kMHVerticalSkipTypeSmall = @"small";
static NSString * const kMHVerticalSkipTypeMedium = @"medium";
static NSString * const kMHVerticalSkipTypeLarge = @"large";
static NSString * const kMHVerticalSkipTypeHuge = @"huge";


static NSString * const kMHWhitespaceUnderlineNode = @"MHWhitespaceUnderlineNode";
static NSString * const kMHWhitespaceStrikethroughNode = @"MHWhitespaceStrikethroughNode";
static NSString * const kMHWhitespaceHighlightNode = @"MHWhitespaceHighlightNode";




@interface MHWhitespace ()
{
    MHWhitespaceType _type;
}

@end

@implementation MHWhitespace



#pragma mark - Constructors


+ (instancetype)space
{
    return [self spaceWithType:MHHorizontalSpaceNormal];
}

+ (instancetype)newline
{
    return [self spaceWithType:MHVerticalSpaceNormal];
}

+ (instancetype)spaceWithType:(MHWhitespaceType)type
{
    return [[self alloc] initWithType:type];
}

+ (instancetype)customHorizontalSpaceWithWidth:(CGFloat)width
{
    return [[self alloc] initCustomHorizontalSpaceWithWidth:width];
}

+ (instancetype)customVerticalSpaceWithHeight:(CGFloat)height
{
    return [[self alloc] initCustomVerticalSpaceWithHeight:height];
}

- (instancetype)initWithType:(MHWhitespaceType)type
{
    if (self = [super init]) {
        _type = type;
    }
    return self;
}

- (instancetype)initCustomHorizontalSpaceWithWidth:(CGFloat)width
{
    if (self = [super init]) {
        _type = MHHorizontalSpaceCustom;
        MHDimensions dimensions;
        dimensions.width = width;
        dimensions.depth = 0.0;
        dimensions.height = 0.0;
        self.dimensions = dimensions;
    }
    return self;
}

- (instancetype)initCustomVerticalSpaceWithHeight:(CGFloat)height
{
    if (self = [super init]) {
        _type = MHVerticalSpaceCustom;
        MHDimensions dimensions;
        dimensions.height = height;
        dimensions.depth = 0.0;
        dimensions.width = 0.0;
        self.dimensions = dimensions;
    }
    return self;
}


#pragma mark - MHCommand protocol

+ (MHExpression *)commandNamed:(NSString *)name withParameters:(NSDictionary *)parameters argument:(MHHorizontalLayoutContainer *)argument
{
    bool isHorizontal;
    bool isVertical;
    if ((isHorizontal = [name isEqualToString:kMHHorizontalSpaceCommandName]) ||
        (isVertical = [name isEqualToString:kMHNewlineCommandName])) {
        NSString *argumentString = argument.stringValue;
        if (!argumentString || argumentString.length == 0)
            return (isHorizontal ? [self space] : [self newline]);
        CGFloat units = [argumentString floatValue];
        if (units < 0.0)
            units = 0.0;
        return (isHorizontal ? [self customHorizontalSpaceWithWidth:units] : [self customVerticalSpaceWithHeight:units]);
    }
    
    if ([name isEqualToString:kMHVerticalSkipCommandName]) {
        NSString *argumentString = [argument stringValue];
        if ([argumentString isEqualToString:kMHVerticalSkipTypeSmall]) {
            return [self spaceWithType:MHVerticalSpaceSmall];
        }
        if ([argumentString isEqualToString:kMHVerticalSkipTypeMedium]) {
            return [self spaceWithType:MHVerticalSpaceMedium];
        }
        if ([argumentString isEqualToString:kMHVerticalSkipTypeLarge]) {
            return [self spaceWithType:MHVerticalSpaceLarge];
        }
        if ([argumentString isEqualToString:kMHVerticalSkipTypeHuge]) {
            return [self spaceWithType:MHVerticalSpaceHuge];
        }
    }
    
    return nil;
}


+ (NSArray <NSString *> *)recognizedCommands
{
    return @[ kMHHorizontalSpaceCommandName ];
}




#pragma mark - Properties

- (MHWhitespaceType)type
{
    return _type;
}

- (MHSpaceOrientationType)orientation
{
    return ((_type == MHHorizontalSpaceNormal) ||
            (_type == MHHorizontalSpaceWide) ||
            (_type == MHHorizontalSpaceQuad) ||
            (_type == MHHorizontalSpaceDoubleQuad) ||
            (_type == MHHorizontalSpaceHalf) ||
            (_type == MHHorizontalSpaceLogical) ||
            (_type == MHHorizontalSpaceCustom)) ? MHWhitespaceOrientationHorizontal : MHWhitespaceOrientationVertical;
}

- (MHTypographyClass)typographyClass
{
    return (_type == MHHorizontalSpaceLogical ? MHTypographyClassNone : MHTypographyClassWhiteSpace);
}


- (MHDimensions)dimensionsWithContextManager:(MHTypesettingContextManager *)contextManager
{
    bool isHorizontalSpace = (_type == MHHorizontalSpaceNormal) ||
    (_type == MHHorizontalSpaceWide) ||
    (_type == MHHorizontalSpaceQuad) ||
    (_type == MHHorizontalSpaceDoubleQuad) ||
    (_type == MHHorizontalSpaceHalf) ||
    (_type == MHHorizontalSpaceLogical) ||
    (_type == MHHorizontalSpaceCustom);
    
    MHDimensions dimensions;
    dimensions.depth = 0.0;

    if (isHorizontalSpace) {
        // Horizontal space
        dimensions.height = 0.0;
        MHExpressionPresentationMode myPresentationMode = self.presentationMode;
        NSFont *font = [contextManager textFontForPresentationMode:myPresentationMode nestingLevel:self.nestingLevel];
        CGFloat interWordSpace = [@" " sizeWithAttributes:@{ NSFontAttributeName : font }].width;

        switch (_type) {
            case MHHorizontalSpaceHalf:
                dimensions.width = interWordSpace * kMHHorizontalSpaceHalfSpaceWidthFactor;
                break;
            case MHHorizontalSpaceNormal:
                dimensions.width = interWordSpace;
                break;
            case MHHorizontalSpaceWide:
                dimensions.width = interWordSpace * kMHHorizontalSpaceWideWidthFactor;
                break;
            case MHHorizontalSpaceQuad:
                dimensions.width = interWordSpace * kMHHorizontalSpaceQuadWidthFactor;
                break;
            case MHHorizontalSpaceDoubleQuad:
                dimensions.width = interWordSpace * kMHHorizontalSpaceQQuadWidthFactor;
                break;
            case MHHorizontalSpaceLogical:
                dimensions.width = 0.0;
                break;
            case MHHorizontalSpaceCustom:
                dimensions.width = self.dimensions.width;
                break;
            default:
                // we should never end up here
                break;
        }
        return dimensions;
    }
    else {
        // Vertical space
        dimensions.width = 0.0;
        MHExpressionPresentationMode myPresentationMode = self.presentationMode;
        CGFloat interlineDistance = [contextManager absoluteLineSpacingForPresentationMode:myPresentationMode];
        CGFloat lineHeight = [contextManager absoluteLineHeightForPresentationMode:myPresentationMode];

        switch (_type) {
            case MHVerticalSpaceNormal:
                dimensions.height = interlineDistance;
                break;
            case MHVerticalSpaceParagraphSpacing:
                dimensions.height = interlineDistance;
                break;
            case MHVerticalSpaceSmall:
                dimensions.height = kMHVerticalSpaceSmall * lineHeight;
                break;
            case MHVerticalSpaceMedium:
                dimensions.height = kMHVerticalSpaceMedium * lineHeight;
                break;
            case MHVerticalSpaceLarge:
                dimensions.height = kMHVerticalSpaceLarge * lineHeight;
                break;
            case MHVerticalSpaceHuge:
                dimensions.height = kMHVerticalSpaceHuge * lineHeight;
                break;
            case MHVerticalSpaceCustom:
                dimensions.height = self.dimensions.height;
                break;
            default:
                // we should never end up here
                break;
        }
        return dimensions;
    }
}


- (NSString *)stringValue
{
    bool isHorizontalSpace = (_type == MHHorizontalSpaceNormal) ||
        (_type == MHHorizontalSpaceWide) ||
        (_type == MHHorizontalSpaceQuad) ||
        (_type == MHHorizontalSpaceDoubleQuad) ||
        (_type == MHHorizontalSpaceHalf) ||
        (_type == MHHorizontalSpaceLogical) ||
        (_type == MHHorizontalSpaceCustom);

    return (_type == MHHorizontalSpaceLogical ? @"" : (isHorizontalSpace ? @" " : @"\n"));
}

- (NSString *)exportedLaTeXValue //RS - This probably needs to be updated for different types of white space.
{
    return self.stringValue;
}



#pragma mark - Other methods

- (void)makeLarger
{
    switch (_type) {
        //
        // horizontal spaces:
        //
        case MHHorizontalSpaceLogical:
            _type = MHHorizontalSpaceHalf;
            break;
        case MHHorizontalSpaceHalf:
            _type = MHHorizontalSpaceNormal;
            break;
        case MHHorizontalSpaceNormal:
            _type = MHHorizontalSpaceWide;
            break;
        case MHHorizontalSpaceWide:
            _type = MHHorizontalSpaceQuad;
            break;
        case MHHorizontalSpaceQuad:
            _type = MHHorizontalSpaceDoubleQuad;
            break;
        case MHHorizontalSpaceDoubleQuad:
        case MHHorizontalSpaceCustom:
            // do nothing
            break;
        //
        // vertical spaces:
        //
        case MHVerticalSpaceNormal:
            _type = MHVerticalSpaceParagraphSpacing;
            break;
        case MHVerticalSpaceParagraphSpacing:
            _type = MHVerticalSpaceLarge;
            break;
        case MHVerticalSpaceSmall:
            _type = MHVerticalSpaceMedium;
            break;
        case MHVerticalSpaceMedium:
            _type = MHVerticalSpaceLarge;
            break;
        case MHVerticalSpaceLarge:
            _type = MHVerticalSpaceHuge;
            break;
        case MHVerticalSpaceHuge:
        case MHVerticalSpaceCustom:
            // do nothing
            break;
    }
}

- (void)typesetWithContextManager:(MHTypesettingContextManager *)contextManager
{
    MHDimensions myDimensions;
    myDimensions.width = 0.0;
    myDimensions.depth = 0.0;
    myDimensions.height = 0.0;
    bool isCustomSpace = (_type == MHHorizontalSpaceCustom || _type == MHVerticalSpaceCustom);
    if (isCustomSpace) {
        myDimensions = self.dimensions;
    }
    [super typesetWithContextManager:contextManager];
    if (isCustomSpace) {
        // calling the super method will reset the dimensions to 0, so set them back to the correct custom value
        // FIXME: this approach of storing the custom width/height in the dimensions property and then adding special logic to make sure this doesn't cause problems seems problematic. Might be safer to add an instance variable to avoid this
        self.dimensions = myDimensions;
    }
    
    bool isHorizontalSpace = (_type == MHHorizontalSpaceNormal) ||
    (_type == MHHorizontalSpaceWide) ||
    (_type == MHHorizontalSpaceQuad) ||
    (_type == MHHorizontalSpaceDoubleQuad) ||
    (_type == MHHorizontalSpaceHalf) ||
    (_type == MHHorizontalSpaceLogical) ||
    (_type == MHHorizontalSpaceCustom);

    if (isHorizontalSpace) {
        // Horizontal space
        MHExpressionPresentationMode myPresentationMode = self.presentationMode;

        // FIXME: this setup makes some redundant method calls, retrieving the font and presentation mode twice - improve?
        NSFont *font = [contextManager textFontForPresentationMode:myPresentationMode nestingLevel:self.nestingLevel];
        if (!isCustomSpace) {
            myDimensions = [self dimensionsWithContextManager:contextManager];
        }

        myDimensions.height = (myPresentationMode == MHExpressionPresentationModePublishing ? 0.0 : kMHHorizontalSpaceEditingModeHeight);

        [[_spriteKitNode childNodeWithName:kMHWhitespaceUnderlineNode] removeFromParent];
        [[_spriteKitNode childNodeWithName:kMHWhitespaceStrikethroughNode] removeFromParent];
        [[_spriteKitNode childNodeWithName:kMHWhitespaceHighlightNode] removeFromParent];

        bool textHighlightingOn = contextManager.textHighlighting;
        if (textHighlightingOn) {
            NSColor *backgroundColor = contextManager.textHighlightColor;

            CGFloat ascender = font.ascender;
            CGFloat descender = font.descender;
            SKSpriteNode *backgroundNode = [SKSpriteNode spriteNodeWithColor:backgroundColor size:CGSizeMake(myDimensions.width+2, ascender-descender)];
            backgroundNode.anchorPoint = CGPointZero;
            backgroundNode.position = CGPointMake(-1,descender);
            backgroundNode.zPosition = -100.0;
            backgroundNode.name = kMHWhitespaceHighlightNode;

            [_spriteKitNode addChild:backgroundNode];
        }
        
        bool textUnderliningOn = contextManager.textUnderlining;
        if (textUnderliningOn) {
            NSColor *foregroundColor = contextManager.textForegroundColor;
            
            SKSpriteNode *underlineNode = [SKSpriteNode spriteNodeWithColor:foregroundColor size:CGSizeMake(myDimensions.width+2, 0.5)];
            underlineNode.anchorPoint = CGPointZero;
            underlineNode.position = CGPointMake(-1.0,-2.0);
            underlineNode.zPosition = -50.0;

            underlineNode.name = kMHWhitespaceUnderlineNode;

            [_spriteKitNode addChild:underlineNode];
        }
        
        bool textStrikethroughOn = contextManager.textStrikethrough;
        if (textStrikethroughOn) {
            NSColor *foregroundColor = contextManager.textForegroundColor;
            
            SKSpriteNode *strikethroughNode = [SKSpriteNode spriteNodeWithColor:foregroundColor size:CGSizeMake(myDimensions.width+2, 1.0)];
            strikethroughNode.anchorPoint = CGPointZero;
            strikethroughNode.position = CGPointMake(-1.0,3.5);
            strikethroughNode.zPosition = -50.0;

            strikethroughNode.name = kMHWhitespaceStrikethroughNode;

            [_spriteKitNode addChild:strikethroughNode];
        }
        
        self.dimensions = myDimensions;
    }
    else {
        // Vertical space - do nothing at the moment, the layout classes will have logic to process vertical spaces
    }
}

- (SKNode *)spriteKitNode
{
    if (!_spriteKitNode) {
        switch (self.presentationMode) {
            case MHExpressionPresentationModePublishing:
                return super.spriteKitNode;
            case MHExpressionPresentationModeEditing:
                _spriteKitNode = [SKSpriteNode spriteNodeWithColor:[NSColor colorWithWhite:0.7 alpha:1.0]
                                                              size:CGSizeMake(self.dimensions.width, kMHHorizontalSpaceEditingModeHeight)];
                ((SKSpriteNode *)_spriteKitNode).anchorPoint = CGPointZero;
                _spriteKitNode.ownerExpression = self;
                return _spriteKitNode;
        }
    }
    return _spriteKitNode;
}



#pragma mark - Rendering to a PDF context

- (void)renderToPDFWithContextManager:(MHPDFRenderingContextManager *)contextManager
{
    [super renderToPDFWithContextManager:contextManager];

    CGContextRef pdfContext = contextManager.pdfContext;
    CGContextSaveGState(pdfContext);

    SKSpriteNode *highlightNode = (SKSpriteNode *)[self.spriteKitNode childNodeWithName:kMHWhitespaceHighlightNode];
    if (highlightNode) {
        CGContextSetFillColorWithColor(pdfContext, [highlightNode.color CGColor]);
        CGContextAddRect(pdfContext, highlightNode.frame);
        CGContextDrawPath(pdfContext, kCGPathFill);
    }

    SKSpriteNode *underlineNode = (SKSpriteNode *)[self.spriteKitNode childNodeWithName:kMHWhitespaceUnderlineNode];
    if (underlineNode) {
        CGContextSetFillColorWithColor(pdfContext, [underlineNode.color CGColor]);
        CGContextAddRect(pdfContext, underlineNode.frame);
        CGContextDrawPath(pdfContext, kCGPathFill);
    }

    SKSpriteNode *strikethroughNode = (SKSpriteNode *)[self.spriteKitNode childNodeWithName:kMHWhitespaceStrikethroughNode];
    if (strikethroughNode) {
        CGContextSetFillColorWithColor(pdfContext, [strikethroughNode.color CGColor]);
        CGContextAddRect(pdfContext, strikethroughNode.frame);
        CGContextDrawPath(pdfContext, kCGPathFill);
    }

    CGContextRestoreGState(pdfContext);
}



#pragma mark - Copying

- (instancetype)logicalCopy
{
    MHWhitespace *myCopy;
    if (_type == MHHorizontalSpaceCustom) {
        myCopy = [[self class] customHorizontalSpaceWithWidth:self.dimensions.width];
    }
    else if (_type == MHVerticalSpaceCustom) {
        myCopy = [[self class] customVerticalSpaceWithHeight:self.dimensions.height];
    }
    else {
        myCopy = [[self class] spaceWithType:_type];
    }
    myCopy.codeRange = self.codeRange;
    return myCopy;
}



@end
