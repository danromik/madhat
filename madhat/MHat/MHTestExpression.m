//
//  MHTestExpression.m
//  MadHat
//
//  Created by Dan Romik on 8/16/21.
//  Copyright © 2021 Dan Romik. All rights reserved.
//

#import "MHTestExpression.h"

NSString * const kMHTestExpressionCommandName = @"test expression";

@implementation MHTestExpression

+ (instancetype)testExpressionWithDimensions:(MHDimensions)dimensions
{
    MHTestExpression *newExpression = [self expression];
    newExpression.dimensions = dimensions;
    return newExpression;
}

+ (MHExpression *)commandNamed:(NSString *)name withParameters:(nullable NSDictionary *)parameters argument:(MHHorizontalLayoutContainer *)argument;
{
    if ([name isEqualToString:kMHTestExpressionCommandName]) {
        MHDimensions dimensions;
        dimensions.width = 0.0;
        dimensions.height = 0.0;
        dimensions.depth = 0.0;
        NSUInteger numberOfArguments = [argument numberOfDelimitedBlocks];
        if (numberOfArguments >= 1) {
            MHExpression *widthExpression = [argument expressionFromDelimitedBlockAtIndex:0];
            dimensions.width = [widthExpression floatValue];
            if (dimensions.width < 0.0)
                dimensions.width = 0.0;
        }
        if (numberOfArguments >= 2) {
            MHExpression *heightExpression = [argument expressionFromDelimitedBlockAtIndex:1];
            dimensions.height = [heightExpression floatValue];
            if (dimensions.height < 0.0)
                dimensions.height = 0.0;
        }
        if (numberOfArguments >= 3) {
            MHExpression *depthExpression = [argument expressionFromDelimitedBlockAtIndex:2];
            dimensions.depth = [depthExpression floatValue];
            if (dimensions.depth < 0.0)
                dimensions.depth = 0.0;
        }
        return [self testExpressionWithDimensions:dimensions];
    }
    return nil;
}

+ (NSArray <NSString *> *)recognizedCommands
{
    return @[ kMHTestExpressionCommandName ];
}

- (void)typesetWithContextManager:(MHTypesettingContextManager *)contextManager
{
    SKNode *mySpriteKitNode = self.spriteKitNode;
    [mySpriteKitNode removeAllChildren];
    
    MHDimensions myDimensions = self.dimensions;
    SKSpriteNode *rectNode = [SKSpriteNode spriteNodeWithColor:[NSColor grayColor] size:NSMakeSize(myDimensions.width, myDimensions.depth + myDimensions.height)];
    rectNode.anchorPoint = CGPointMake(0.0, myDimensions.depth/(myDimensions.depth+myDimensions.height));
    [mySpriteKitNode addChild:rectNode];
}



- (instancetype)logicalCopy
{
    MHTestExpression *myCopy = [[self class] testExpressionWithDimensions:self.dimensions];
    myCopy.codeRange = self.codeRange;
    return myCopy;
}

@end
