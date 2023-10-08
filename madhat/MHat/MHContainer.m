//
//  MHContainer.m
//  MadHat
//
//  Created by Dan Romik on 7/28/20.
//  Copyright © 2020 Dan Romik. All rights reserved.
//

#import "MHContainer.h"

#import "MHTextParagraph.h"

@implementation MHContainer


#pragma mark - Properties

- (void)setPresentationMode:(MHExpressionPresentationMode)presentationMode
{
    super.presentationMode = presentationMode;
    
    // The property is passed recursively to subexpressions
    NSArray <MHExpression *> *subexpressions = self.subexpressions;
    for (MHExpression *subexpression in subexpressions) {
        subexpression.presentationMode = presentationMode;
    }
}

- (void)setNestingLevel:(NSUInteger)nestingLevel
{
    super.nestingLevel = nestingLevel;

    // The property is passed recursively to subexpressions
    NSArray <MHExpression *> *subexpressions = self.subexpressions;
    for (MHExpression *subexpression in subexpressions) {
        subexpression.nestingLevel = nestingLevel;
    }
}



#pragma mark - Typesetting, sprite kit node and rendering


- (void)typesetWithContextManager:(MHTypesettingContextManager *)contextManager
{
    // FIXME: it would be good design to include this but including it messes up the behavior of graphics[...] expressions. Fix this
//    [super typesetWithContextManager:contextManager];
    
    NSArray <MHExpression *> *subexpressions = self.subexpressions;
    for (MHExpression *aSubexpression in subexpressions) {
        [aSubexpression typesetWithContextManager:contextManager];
    }

}

- (SKNode *)spriteKitNode
{
    if (!_spriteKitNode) {
        _spriteKitNode = super.spriteKitNode;

        NSArray <MHExpression *> *subexpressions = self.subexpressions;
        for (MHExpression *aSubexpression in subexpressions) {
            [self.spriteKitNode addChild:aSubexpression.spriteKitNode];
        }
    }
    return _spriteKitNode;
}

- (void)renderToPDFWithContextManager:(MHPDFRenderingContextManager *)contextManager
{
    NSArray <MHExpression *> *subexpressions = self.subexpressions;
    CGContextRef pdfContext = contextManager.pdfContext;
    for (MHExpression *subexpression in subexpressions) {
        CGPoint position = subexpression.position;
        CGContextTranslateCTM(pdfContext, position.x, position.y);
        [subexpression renderToPDFWithContextManager:contextManager];
        CGContextTranslateCTM(pdfContext, -position.x, -position.y);
    }
}


#pragma mark - Reformatting

- (void)reformatWithContextManager:(MHReformattingContextManager *)contextManager animationType:(MHReformattingAnimationType)animationType
{
    [super reformatWithContextManager:contextManager animationType:animationType];

    // Recursively call the same method on all subexpressions
    NSArray <MHExpression *> *subexpressions = self.subexpressions;
    for (MHExpression *subexpression in subexpressions) {
        [subexpression reformatWithContextManager:contextManager animationType:animationType];
    }
    
}




#pragma mark - Coding safety

- (NSArray <MHExpression *> *)subexpressions
{
    NSAssert1(false, @"Class %@ or one of its superclasses must implement the -subexpressions method", [self className]);
    return @[ ];
}



#pragma mark - Expression copying

- (instancetype)logicalCopy
{
    NSAssert1(false, @"Class %@ or one of its superclasses must implement the -logicalCopy method", [self className]);
    return nil;
}


#pragma mark - Code linkbacks

- (void)applyCodeRangeLinkbackToCode:(NSObject <MHSourceCodeString> *)code
{
    [super applyCodeRangeLinkbackToCode:code];
    // Now apply the code range linkbacks recursively to subexpressions
    NSArray <MHExpression *> *subexpressions = self.subexpressions;
    for (MHExpression *subexpression in subexpressions) {
        [subexpression applyCodeRangeLinkbackToCode:code];
    }
}





@end
