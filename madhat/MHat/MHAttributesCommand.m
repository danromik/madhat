//
//  MadHattributesCommand.m
//  MadHat
//
//  Created by Dan Romik on 9/9/20.
//  Copyright © 2020 Dan Romik. All rights reserved.
//

#import "MHAttributesCommand.h"
#import "MHParser+SpecialSymbols.h"

NSString * const kMHAttributesCommandName = @"attributes";

NSString * const kMHAttributesFalseValuedBooleanPrefix = @"no ";

@implementation MHAttributesCommand



- (NSDictionary < NSString *, MHExpression *> *)attributesDictionary
{
    MHLinearContainer *container = self.argument;

    NSUInteger numberOfBlocks = container.numberOfDelimitedBlocks;
    NSMutableDictionary *mutableDict = [[NSMutableDictionary alloc] initWithCapacity:numberOfBlocks];

    for (NSUInteger blockIndex = 0; blockIndex < numberOfBlocks; blockIndex++) {
        MHLinearContainer *block = [container expressionFromDelimitedBlockAtIndex:blockIndex];

        NSUInteger numberOfSubexpressions = block.numberOfSubexpressions;
        bool foundAssignmentOperator = false;
        for (NSUInteger subexpressionIndex = 0; subexpressionIndex < numberOfSubexpressions; subexpressionIndex++) {
            MHExpression *subexpression = [block expressionAtIndex:subexpressionIndex];
            NSString *subexpString = subexpression.stringValue;
            if ([subexpString isEqualToString:kMHParserCharAssignmentString]) {
                MHLinearContainer *keyExpressionContainer = [[container class] expression];
                for (NSUInteger ind = 0; ind < subexpressionIndex; ind++) {
                    MHExpression *keySubexpression = [[block expressionAtIndex:ind] logicalCopy];
                    [keyExpressionContainer addSubexpression:keySubexpression];
                }
                NSString *keyString = keyExpressionContainer.stringValue;
                MHExpression *expressionToAssignAsValue;
                NSUInteger numberOfSubexpressionsInValue = numberOfSubexpressions -subexpressionIndex-1;
                if (numberOfSubexpressionsInValue == 1) {
                    expressionToAssignAsValue = [[block expressionAtIndex:subexpressionIndex+1] logicalCopy];
                }
                else {
                    MHLinearContainer *valueExpressionContainer = [[container class] expression];
                    for (NSUInteger ind = subexpressionIndex+1; ind < numberOfSubexpressions; ind++) {
                        MHExpression *valueSubexpression = [[block expressionAtIndex:ind] logicalCopy];
                        [valueExpressionContainer addSubexpression:valueSubexpression];
                    }
                    expressionToAssignAsValue = valueExpressionContainer;
                }
                [mutableDict setObject:expressionToAssignAsValue forKey:keyString];
                foundAssignmentOperator = true;
                break;
            }
        }
        if (!foundAssignmentOperator) {
            // An entry with no assignment operator will be interpreted as a boolean attribute. If it starts with the keyword "no " it is read as a false-valued boolean (associated with the name following the "no ", otherwise as a true-valued boolean
            NSString *blockString = block.stringValue;
            NSRange prefixRange = [blockString rangeOfString:kMHAttributesFalseValuedBooleanPrefix];
            if (prefixRange.location == 0) {
                NSString *booleanAttributeName = [blockString substringFromIndex:prefixRange.location + prefixRange.length];
                MHExpression *falseValuedBooleanExpression = [MHExpression booleanExpressionWithValue:false];
                [mutableDict setObject:falseValuedBooleanExpression forKey:booleanAttributeName];
            }
            else {
                MHExpression *trueValuedBooleanExpression = [MHExpression booleanExpressionWithValue:true];
                [mutableDict setObject:trueValuedBooleanExpression forKey:blockString];
            }
        }
    }

    return [NSDictionary dictionaryWithDictionary:mutableDict];
}


// As of the current implementation (MadHat version 1.0.1), attributes blocks are not designed to have context that needs to be typeset or exported to PDF. So we override the typesetWithContextManager: and renderToPDFWithContextManager: methods to disable typesetting/rendering. (Not doing this would create problems with content being positioned incorrectly in exported page footers and headers when they contain attributes blocks.)
- (void)typesetWithContextManager:(MHTypesettingContextManager *)contextManager { /* disabled */ }
- (void)renderToPDFWithContextManager:(MHPDFRenderingContextManager *)contextManager { /* disabled */ }


+ (NSArray <NSString *> *)recognizedCommands
{
    return @[ kMHAttributesCommandName ];
}



@end
