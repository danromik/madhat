//
//  MHLinearContainer.h
//  MadHat
//
//  Created by Dan Romik on 7/30/20.
//  Copyright © 2020 Dan Romik. All rights reserved.
//

#import "MHContainer.h"

NS_ASSUME_NONNULL_BEGIN



#pragma mark - Interface for MHListDelimiter private class



@interface MHLinearContainer : MHContainer
{
    @protected NSMutableArray <MHExpression *> *_subexpressions;
}


@property (readonly) bool locallyScoped;   // defaults to YES. This means that changes to the typesetting context inside the container do not influence subsequent typesetting outside. Subclasses can override to change this behavior



@property (readonly) NSUInteger numberOfSubexpressions;
- (void)addSubexpression:(MHExpression *)expression;
- (MHExpression *)expressionAtIndex:(NSUInteger)index;
- (MHExpression *)lastExpression;
- (void)replaceExpressionAtIndex:(NSUInteger)index withExpression:(MHExpression *)newExpression;
- (void)removeExpressionAtIndex:(NSUInteger)index;
- (void)insertExpression:(MHExpression *)expression atIndex:(NSUInteger)index;



@property (readonly) NSUInteger numberOfDelimitedBlocks;
-(void)addListDelimiterWithType:(MHListDelimiterType)type;
- (MHLinearContainer *)expressionFromDelimitedBlockAtIndex:(NSUInteger)index;
- (NSArray <NSArray <MHExpression *> *> *)delimitedBlockTable;   // returns array of array of delimited blocks


// Some convenience methods to parse delimited block arrays into common data types
- (CGPoint)pointValue;  // parses the container as two coordinates separated by a primary delimiter, or CGPointZero if there are fewer than two delimited blocks
- (NSArray <NSValue *> *)arrayOfPointValues;  // parses the container as a sequence of points (as described above) separated by secondary delimiters. Each row that doesn't contain at least two delimited blocks (one for each coordinate) gets ignored


@end



@class MHParagraph;

// FIXME: is this the most logical file in which to declare this protocol?
@protocol MHIncrementalTypesetting
- (MHParagraph *)expressionAtIndex:(NSUInteger)index;
- (void)retypesetParagraphsInRange:(NSRange)range withContextManager:(MHTypesettingContextManager *)contextManager;
@end


NS_ASSUME_NONNULL_END
