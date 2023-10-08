//
//  MHRichTextAtom.m
//  MadHat
//
//  Created by Dan Romik on 7/13/20.
//  Copyright © 2020 Dan Romik. All rights reserved.
//

#import "MHRichTextAtom.h"
#import "MHTextNode.h"


@implementation MHRichTextAtom

+ (instancetype)richTextAtomWithAttributedString:(NSAttributedString *)attributedString
{
    return [[self alloc] initWithAttributedString:attributedString];
}

- (instancetype)initWithAttributedString:(NSAttributedString *)attributedString
{
    if (self = [super init]) {
        _attributedString = attributedString;
    }
    return self;
}

- (SKNode *)spriteKitNode
{
    if (!_spriteKitNode) {
        _spriteKitNode = [SKNode node];
    }
    return _spriteKitNode;
}

- (void)typesetWithContextManager:(MHTypesettingContextManager *)contextManager
{
    __block MHDimensions myDimensions;
    myDimensions.width = 0.0;
    myDimensions.height = 0.0;
    myDimensions.depth = 0.0;
    
    NSString *myString = _attributedString.string;
    
    SKNode *mySpriteKitNode = self.spriteKitNode;
    
    [mySpriteKitNode removeAllChildren];
    
    NSMutableArray *composedCharNodeArray = [[NSMutableArray alloc] initWithCapacity:0];
    NSMutableArray *composedCharBackgroundColorArray = [[NSMutableArray alloc] initWithCapacity:0];
    __block NSUInteger numberOfComposedChars = 0;

    [myString enumerateSubstringsInRange:NSMakeRange(0, myString.length)
                                 options:NSStringEnumerationByComposedCharacterSequences
                              usingBlock:^(NSString *composedCharSubstring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {

        NSDictionary *attributesDict = [self->_attributedString attributesAtIndex:substringRange.location effectiveRange:nil];

        NSColor *charForegroundColor = attributesDict[NSForegroundColorAttributeName];
        NSColor *charBackgroundColor = attributesDict[NSBackgroundColorAttributeName];
        NSFont *charFont = attributesDict[NSFontAttributeName];
        bool charUnderlining = ([attributesDict[NSUnderlineStyleAttributeName] integerValue] != NSUnderlineStyleNone);

        bool charStrikethrough = ([attributesDict[NSStrikethroughStyleAttributeName] integerValue] != NSUnderlineStyleNone);
        MHTextNode *composedCharNode = [MHTextNode textNodeWithString:composedCharSubstring];
        [composedCharNode configureWithFont:charFont
                                      color:charForegroundColor
                            backgroundColor:nil
                                underlining:charUnderlining
                              strikethrough:charStrikethrough];
        [mySpriteKitNode addChild:composedCharNode];
        composedCharNode.position = CGPointMake(myDimensions.width, 0.0);
        
        [composedCharNodeArray addObject:composedCharNode];
        [composedCharBackgroundColorArray addObject:(charBackgroundColor ? charBackgroundColor : [NSColor clearColor])];
        
        MHDimensions composedCharDimensions = composedCharNode.dimensions;
        myDimensions.width += composedCharDimensions.width;
        if (myDimensions.height < composedCharDimensions.height)
            myDimensions.height = composedCharDimensions.height;
        if (myDimensions.depth < composedCharDimensions.depth)
            myDimensions.depth = composedCharDimensions.depth;
        
        numberOfComposedChars++;
    }];
    
    // Add rectangles for the background colors of each composed character
    // FIXME: this code is a bit of a hack. Improve
    NSUInteger index;
    for (index = 0; index < numberOfComposedChars; index++) {
        MHTextNode *textNode = composedCharNodeArray[index];
        NSColor *backgroundColor = composedCharBackgroundColorArray[index];
        MHDimensions textNodeDimensions = textNode.dimensions;
        CGPoint textNodePosition = textNode.position;
        SKShapeNode *backgroundRectNode = [SKShapeNode shapeNodeWithRect:CGRectMake(1.0+textNodePosition.x, 1.0-myDimensions.depth, textNodeDimensions.width, myDimensions.depth+myDimensions.height)];
        backgroundRectNode.fillColor = backgroundColor;
        backgroundRectNode.strokeColor = backgroundColor;
        backgroundRectNode.zPosition = -2.0;
        [mySpriteKitNode addChild:backgroundRectNode];
    }
    
    self.dimensions = myDimensions;
}



#pragma mark - Copying expressions

- (instancetype)logicalCopy
{
    MHRichTextAtom *myCopy = [[self class] richTextAtomWithAttributedString:[_attributedString copy]];
    myCopy.codeRange = self.codeRange;
    return myCopy;
}


#pragma mark - Rendering in PDF contexts

- (void)renderToPDFWithContextManager:(MHPDFRenderingContextManager *)contextManager
{
    CGContextRef pdfContext = contextManager.pdfContext;
    CGContextSaveGState(pdfContext);
    NSArray <SKNode *> *children = self.spriteKitNode.children;

    // Render the background color rectangles
    // FIXME: this solution for drawing background colors is a bit of a hack - improve
    for (SKNode *child in children) {
        if ([child isKindOfClass:[SKShapeNode class]]) {
            SKShapeNode *backgroundChild = (SKShapeNode *)child;
            NSColor *backgroundColor = backgroundChild.fillColor;
            CGColorRef cgColor = [backgroundColor CGColor];
            CGContextAddPath(pdfContext, backgroundChild.path);
            CGContextSetFillColorWithColor(pdfContext, cgColor);
            CGContextSetStrokeColorWithColor(pdfContext, cgColor);
            CGContextDrawPath(pdfContext, kCGPathFillStroke);
        }
    }

    for (SKNode *child in children) {
        if ([child isKindOfClass:[MHTextNode class]]) {
            MHTextNode *textChild = (MHTextNode *)child;     // to let the compiler know we know this object is an instance of MHTextNode
            CGPoint childPosition = textChild.position;
            CGContextTranslateCTM(pdfContext, childPosition.x, childPosition.y);
            [textChild renderInPDFContext:pdfContext];
            CGContextTranslateCTM(pdfContext, -childPosition.x, -childPosition.y);
        }
    }
    CGContextRestoreGState(pdfContext);
    [super renderToPDFWithContextManager:contextManager];
}




@end
