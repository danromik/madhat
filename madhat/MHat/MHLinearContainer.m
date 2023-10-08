//
//  MHLinearContainer.m
//  MadHat
//
//  Created by Dan Romik on 7/30/20.
//  Copyright © 2020 Dan Romik. All rights reserved.
//

#import "MHLinearContainer.h"



@interface MHListDelimiter : MHExpression
// see implementation at the end of this source file

@property (readonly) MHListDelimiterType type;

+ (instancetype)delimiter;     // Convenience constructor
+ (instancetype)delimiterWithType:(MHListDelimiterType)type;     // Convenience constructor

@end






@interface MHLinearContainer ()

- (NSMutableArray *)subexpressions;

@end


@implementation MHLinearContainer



#pragma mark - Properties

- (NSMutableArray *)subexpressions
{
    if (!_subexpressions)
        _subexpressions = [NSMutableArray arrayWithCapacity:0];
    return _subexpressions;
}

- (bool)locallyScoped
{
    return true;
}

- (NSString *)stringValue
{
    NSMutableString *aString = [NSMutableString stringWithCapacity:64];
    for (MHExpression *subexpression in _subexpressions) {
        [aString appendFormat:@"%@",subexpression.stringValue];
    }
    return [NSString stringWithString:aString];
}

- (NSString *)exportedLaTeXValue
{
    NSMutableString *aString = [NSMutableString stringWithCapacity:0];
    for (MHExpression *subexpression in _subexpressions) {
        [aString appendString:subexpression.exportedLaTeXValue];
    }
    return [NSString stringWithString:aString];
}

- (short int)leftItalicCorrection
{
    NSArray <MHExpression *> *subexpressions = self.subexpressions;
    if (subexpressions.count == 0)
        return 0;
    return [subexpressions[0] leftItalicCorrection];
}

- (short int)rightItalicCorrection
{
    NSArray <MHExpression *> *subexpressions = self.subexpressions;
    if (subexpressions.count == 0)
        return 0;
    return [[subexpressions lastObject] rightItalicCorrection];
}

- (short int)topDecorationPositioningOffset
{
    NSUInteger numberOfSubexpressions = _subexpressions.count;
    short int offset = 10000;
    for (NSUInteger index = 0; index < numberOfSubexpressions; index++) {
        MHExpression *subexpression = [self expressionAtIndex:index];
        short int subexpPositioningOffset = [subexpression topDecorationPositioningOffset];
        if (subexpPositioningOffset < offset)
            offset = subexpPositioningOffset;
    }
    return offset;
}



#pragma mark - Subexpression actions and accessors

- (NSUInteger)numberOfSubexpressions
{
    return _subexpressions.count;
}

- (MHExpression *)expressionAtIndex:(NSUInteger)index
{
    return (index < _subexpressions.count ? [_subexpressions objectAtIndex:index] : nil);
}

- (MHExpression *)lastExpression
{
    return [_subexpressions lastObject];
}

- (void)addSubexpression:(MHExpression *)expression
{
    expression.parent = self;
    expression.nestingLevel = self.nestingLevel;
    expression.presentationMode = self.presentationMode;
    // FIXME: maybe add an "if (_spriteKitNode) ..." clause here similar to the replaceExpressionAtIndex:withExpression: method?
    [self.subexpressions addObject:expression];
}

- (void)replaceExpressionAtIndex:(NSUInteger)index withExpression:(MHExpression *)newExpression
{
    MHExpression *oldExpression = (MHExpression *)[_subexpressions objectAtIndex:index];
    oldExpression.parent = nil;
    newExpression.parent = self;
    newExpression.nestingLevel = self.nestingLevel;
    newExpression.presentationMode = self.presentationMode;
    [self.subexpressions replaceObjectAtIndex:index withObject:newExpression];
    
    if (_spriteKitNode) {
        [oldExpression.spriteKitNode removeFromParent];
        [_spriteKitNode addChild:newExpression.spriteKitNode];
    }
}

- (void)removeExpressionAtIndex:(NSUInteger)index
{
    MHExpression *expression = (MHExpression *)[_subexpressions objectAtIndex:index];
    expression.parent = nil;
    [self.subexpressions removeObjectAtIndex:index];
    if (_spriteKitNode) {
        [expression.spriteKitNode removeFromParent];
    }
}

- (void)insertExpression:(MHExpression *)expression atIndex:(NSUInteger)index
{
    expression.parent = self;
    expression.nestingLevel = self.nestingLevel;
    expression.presentationMode = self.presentationMode;
    [self.subexpressions insertObject:expression atIndex:index];
    if (_spriteKitNode) {
        [_spriteKitNode addChild:expression.spriteKitNode];
    }
}




#pragma mark - Working with delimited blocks

- (void)addListDelimiterWithType:(MHListDelimiterType)type
{
    [self addSubexpression:[MHListDelimiter delimiterWithType:type]];
}

- (NSUInteger)numberOfDelimitedBlocks
{
    NSUInteger counter = 1;
    for (MHExpression *subexpression in _subexpressions) {
        if ([subexpression isKindOfClass:[MHListDelimiter class]]) {
            counter++;
        }
    }
    return counter;
}

- (MHLinearContainer *)expressionFromDelimitedBlockAtIndex:(NSUInteger)index
{
    NSUInteger blockIndex = 0;
//    NSUInteger subexpressionIndex = 0;
    MHLinearContainer *newContainer = nil;
    if (index == 0)
        newContainer = [[self class] expression];
    for (MHExpression *subexpression in _subexpressions) {
        if ([subexpression isKindOfClass:[MHListDelimiter class]]) {
            blockIndex++;
            if (blockIndex == index)
                newContainer = [[self class] expression];
            else if (newContainer)
                return newContainer;
        }
        else if (newContainer) {
            MHExpression *subexpressionCopy = [subexpression logicalCopy];
            [newContainer addSubexpression:subexpressionCopy];
        }
    }
    if (newContainer)
        return newContainer;
    return [MHLinearContainer expression];   // return an empty expression if we didn't find the block
}

- (NSArray <NSArray <MHExpression *> *> *)delimitedBlockTable
{
    NSMutableArray *rows = [[NSMutableArray alloc] initWithCapacity:0];
    NSMutableArray *currentRow = [[NSMutableArray alloc] initWithCapacity:0];
    MHLinearContainer *currentBlockContainer = [[self class] expression];
    for (MHExpression *subexpression in _subexpressions) {
        if ([subexpression isKindOfClass:[MHListDelimiter class]]) {
            // add the current block to the current row and start a new current block
            [currentRow addObject:currentBlockContainer];
            currentBlockContainer = [[self class] expression];
            if (((MHListDelimiter *)subexpression).type == MHListDelimiterTypeSecondary) {
                // for a secondary delimiter, close the current row and start a new one
                [rows addObject:[NSArray arrayWithArray:currentRow]];
                currentRow = [[NSMutableArray alloc] initWithCapacity:0];
            }
        }
        else {
            MHExpression *subexpressionCopy = [subexpression logicalCopy];
            [currentBlockContainer addSubexpression:subexpressionCopy];
        }
    }
    // add the current block on exit from the loop to the current row
    [currentRow addObject:currentBlockContainer];
    
    // add the current row on exit from the loop to the array of rows
    [rows addObject:currentRow];
    
    // return the tabulated array of rows
    return [NSArray arrayWithArray:rows];
}



#pragma mark - Parsing into common data types

- (CGPoint)pointValue
{
    if (self.numberOfDelimitedBlocks < 2)
        return CGPointZero;
    MHExpression *xCoordinateExpression = [self expressionFromDelimitedBlockAtIndex:0];
    MHExpression *yCoordinateExpression = [self expressionFromDelimitedBlockAtIndex:1];
    return CGPointMake(xCoordinateExpression.floatValue, yCoordinateExpression.floatValue);
}

- (NSArray <NSValue *> *)arrayOfPointValues
{
    NSArray <NSArray <MHExpression *> *> *blocks = [self delimitedBlockTable];
    NSMutableArray *pointsMutableArray = [[NSMutableArray alloc] initWithCapacity:blocks.count];
    for (NSArray <MHExpression *> *blockRow in blocks) {
        if (blockRow.count >= 2) {
            MHExpression *xCoordinateExpression = blockRow[0];
            MHExpression *yCoordinateExpression = blockRow[1];
            CGPoint point = CGPointMake(xCoordinateExpression.floatValue, yCoordinateExpression.floatValue);
            NSValue *pointValue = [NSValue valueWithPoint:point];
            [pointsMutableArray addObject:pointValue];
        }
    }
    return [NSArray arrayWithArray:pointsMutableArray];
}



#pragma mark - Expression copying

- (instancetype)logicalCopy
{
    MHLinearContainer *myCopy = [[self class] expression];
    myCopy.codeRange = self.codeRange;
    for (MHExpression *subexpression in _subexpressions) {
        MHExpression *subexpressionCopy = [subexpression logicalCopy];
        [myCopy addSubexpression:subexpressionCopy];
    }
    return myCopy;
}




@end




#pragma mark - MHListDelimiter class (a private class only used by MHHorizontalLayoutContainer)

@implementation MHListDelimiter

+ (instancetype)delimiter
{
    return [self delimiterWithType:MHListDelimiterTypePrimary];
}

+ (instancetype)delimiterWithType:(MHListDelimiterType)type
{
    return [[self alloc] initWithDelimiterWithType:type];
}

- (instancetype)initWithDelimiterWithType:(MHListDelimiterType)type
{
    if (self = [super init]) {
        _type = type;
    }
    return self;
}

- (instancetype)logicalCopy
{
    MHListDelimiter *myCopy = [[self class] delimiterWithType:_type];
    myCopy.codeRange = self.codeRange;
    return myCopy;
}




#pragma mark - description

- (NSString *)description
{
    return [NSString stringWithFormat:@"<delimiter: %@>", _type == MHListDelimiterTypePrimary ? @"primary" : @"secondary"];
}



@end
