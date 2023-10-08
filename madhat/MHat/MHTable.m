//
//  MHTable.m
//  MadHat
//
//  Created by Dan Romik on 12/11/19.
//  Copyright © 2019 Dan Romik. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>
#import "MHTable.h"
#import "MHBracket.h"
#import "MHColorCommand.h"

static NSString * const kMHTableCommandNameTextTable = @"table";
static NSString * const kMHTableCommandNameMathTable = @"math table";
static NSString * const kMHTableCommandNameMatrix = @"matrix";

static NSString * const kMHTableFramedAttributeName = @"frame";
static NSString * const kMHTableFillAttributeName = @"fill";
static NSString * const kMHTableFillColorAttributeName = @"fill color";
static NSString * const kMHTableAlternatingRowFillAttributeName = @"alternating fill";
static NSString * const kMHTableAltFillColorAttributeName = @"alt fill color";
static NSString * const kMHTableHeaderFillColorAttributeName = @"header fill color";
static NSString * const kMHTableHeaderAltFillColorAttributeName = @"header alt fill color";

static NSString * const kMHTableLinesAttributeName = @"lines"; // FIXME: not implemented yet
static NSString * const kMHTableHorizontalLinesAttributeName = @"hlines";
static NSString * const kMHTableVerticalLinesAttributeName = @"vlines";
static NSString * const kMHTableLinesShowNoneAttributeValue = @"none";
static NSString * const kMHTableLinesShowAllAttributeValue = @"all";
static NSString * const kMHTableLinesShowEdgeLinesAttributeValue = @"edges";

static NSString * const kMHTableAlignmentsAttributeName = @"alignments";
static NSString * const kMHTableAlignmentLeftJustificationAttributeValue = @"left";
static NSString * const kMHTableAlignmentRightJustificationAttributeValue = @"right";
static NSString * const kMHTableAlignmentCenteredAttributeValue = @"center";

static unichar kMHTableAlignmentsSpecifierLeftJustificationChar = 'l';
static unichar kMHTableAlignmentsSpecifierRightJustificationChar = 'r';
static unichar kMHTableAlignmentsSpecifierCenteredChar = 'c';

static unichar kMHTableBooleanSpecifierStringYesSpecifierChar = 'y';
static unichar kMHTableBooleanSpecifierStringNoSpecifierChar = 'n';

static NSString * const kMHTableHeaderRowsAttributeName = @"header rows";
static NSString * const kMHTableHeaderColumnsAttributeName = @"header columns";
static NSString * const kMHTableHeaderNoneAttributeValue = @"none";
static NSString * const kMHTableHeaderLeadingAttributeValue = @"first";


static NSString * const kMHTableTableFillLowerNodeName = @"tablefilllower";
static NSString * const kMHTableTableFillHigherNodeName = @"tablefillhigher";
static NSString * const kMHTableTableLineNodeName = @"tableline";



typedef enum {
  MHTableCellHorizontalAlignmentTypeLeft,
    MHTableCellHorizontalAlignmentTypeCenter,
    MHTableCellHorizontalAlignmentTypeRight,
    MHTableCellHorizontalAlignmentCustom        // that means a detailed list of specifiers is given, one for each column
} MHTableCellHorizontalAlignmentType;

typedef enum {
    MHTableNoFill,
    MHTableUniformFill,
    MHTableAlternatingRowFill
} MHTableFillSpecificationType;

typedef enum {
    MHTableNoHeaders,
    MHTableLeadingHeader,
    MHTableCustomHeaders
} MHTableHeadersSpecificationType;



static NSArray *arrayOfBooleanSpecifiersFromSpecificationString(NSString *specificationString) {
    NSUInteger numberOfSpecifiers = specificationString.length;
    NSMutableArray *specifiersMutableArray = [[NSMutableArray alloc] initWithCapacity:numberOfSpecifiers];
    for (NSUInteger specifierIndex = 0; specifierIndex < numberOfSpecifiers; specifierIndex++) {
        unichar specifierChar = [specificationString characterAtIndex:specifierIndex];
        if (specifierChar == kMHTableBooleanSpecifierStringYesSpecifierChar) {
            [specifiersMutableArray addObject:[NSNumber numberWithBool:true]];
        }
        else if (specifierChar == kMHTableBooleanSpecifierStringNoSpecifierChar) {
            [specifiersMutableArray addObject:[NSNumber numberWithBool:false]];
        }
        else {
            // an illegal specifier - in this case we ignore the entire specifier string
            specifiersMutableArray = nil;
            break;
        }
    }
    return specifiersMutableArray ? [NSArray arrayWithArray:specifiersMutableArray] : nil;
}

static NSString *validatedStringOfAlignmentSpecifiersFromSpecificationString(NSString *specificationString) {
    NSUInteger stringLength = specificationString.length;
    for (NSUInteger index = 0; index < stringLength; index++) {
        unichar aChar = [specificationString characterAtIndex:index];
        if (aChar != kMHTableAlignmentsSpecifierLeftJustificationChar &&
            aChar != kMHTableAlignmentsSpecifierRightJustificationChar &&
            aChar != kMHTableAlignmentsSpecifierCenteredChar)
            return nil;
    }
    return specificationString;
}




@interface MHTable () {
    NSArray <NSArray <MHExpression *> *> *_cells;
    NSArray <NSNumber *> *_rowLengths;
    NSUInteger _numberOfRows;
    NSUInteger _numberOfColumns;
    
    NSArray <MHExpression *> *_flattenedCellArray;

    // FIXME: These booleans can be packed into a mask to save space
    bool _framed;
    bool _mathAxisCentering;
    
    MHTableFillSpecificationType _fillSpecification;
    
    // FIXME: More generally, it's not clear what would be an efficient data structure to store all the table parameters - the current one will potentially waste a lot of memory. Improve
    
    NSColor *_fillColor;
    NSColor *_altFillColor;
    NSColor *_headerFillColor;
    NSColor *_headerAltFillColor;

    MHTableCellHorizontalAlignmentType _horizontalAlignment;
    
    MHTableLinesSpecificationType _horizontalLinesSpecification;
    MHTableLinesSpecificationType _verticalLinesSpecification;
    NSArray <NSNumber *> *_horizontalLineBooleanSpecifiers;
    NSArray <NSNumber *> *_verticalLineBooleanSpecifiers;
    
    MHTableHeadersSpecificationType _headerRowsSpecification;
    MHTableHeadersSpecificationType _headerColumnsSpecification;
    NSArray <NSNumber *> *_headerRowsBooleanSpecifiers;
    NSArray <NSNumber *> *_headerColumnsBooleanSpecifiers;

    NSString *_columnAlignmentSpecifiers;
}

- (MHExpression *)cellAtRow:(NSUInteger)rowIndex column:(NSUInteger)columnIndex;

//@property bool framed;
@property bool mathAxisCentering;

@property MHTableFillSpecificationType fillSpecification;

@property NSColor *fillColor;
@property NSColor *altFillColor;
@property NSColor *headerFillColor;
@property NSColor *headerAltFillColor;

@property MHTableCellHorizontalAlignmentType horizontalAlignment;
@property NSString *columnAlignmentSpecifiers;

//@property MHTableLinesSpecificationType horizontalLinesSpecification;
//@property MHTableLinesSpecificationType verticalLinesSpecification;

//@property NSArray <NSNumber *> *horizontalLineBooleanSpecifiers;
//@property NSArray <NSNumber *> *verticalLineBooleanSpecifiers;

@property MHTableHeadersSpecificationType headerRowsSpecification;
@property MHTableHeadersSpecificationType headerColumnsSpecification;
@property NSArray <NSNumber *> *headerRowsBooleanSpecifiers;
@property NSArray <NSNumber *> *headerColumnsBooleanSpecifiers;

@end


@implementation MHTable


#pragma mark - MHCommand protocol


+ (MHExpression *)commandNamed:(NSString *)name withParameters:(nullable NSDictionary *)parameters argument:(MHHorizontalLayoutContainer *)argument
{
    bool isTextTable;
    bool isMathTable = false;
    bool isMatrix = false;
    if ((isTextTable = [name isEqualToString:kMHTableCommandNameTextTable])
        || (isMathTable = [name isEqualToString:kMHTableCommandNameMathTable])
        || (isMatrix = [name isEqualToString:kMHTableCommandNameMatrix])) {
        MHTable *table = [[self alloc] initWithArrayOfExpressionArrays:[argument delimitedBlockTable]];
        
        if (isMathTable || isMatrix) {
            table.mathAxisCentering = true;
            table.horizontalAlignment = MHTableCellHorizontalAlignmentTypeCenter;
        }
        
        NSDictionary <NSString *, MHExpression *> *attributes = argument.attributes;
        if (attributes) {
            MHExpression *horizontalLinesSpecificationExpression = attributes[kMHTableHorizontalLinesAttributeName];
            if (horizontalLinesSpecificationExpression) {
                NSString *horizontalLinesSpecificationString = [horizontalLinesSpecificationExpression stringValue];
                if ([horizontalLinesSpecificationString isEqualToString:kMHTableLinesShowNoneAttributeValue]) {
                    table.horizontalLinesSpecification = MHTableLinesShowNone;
                }
                else if ([horizontalLinesSpecificationString isEqualToString:kMHTableLinesShowAllAttributeValue]) {
                    table.horizontalLinesSpecification = MHTableLinesShowAll;
                }
                else if ([horizontalLinesSpecificationString isEqualToString:kMHTableLinesShowEdgeLinesAttributeValue]) {
                    table.horizontalLinesSpecification = MHTableLinesShowEdgeLines;
                }
                else {
                    NSArray *specifiersArray = arrayOfBooleanSpecifiersFromSpecificationString(horizontalLinesSpecificationString);
                    if (specifiersArray) {
                        table.horizontalLinesSpecification = MHTableLinesCustom;
                        table.horizontalLineBooleanSpecifiers = specifiersArray;
                    }
                }
            }
            
            MHExpression *verticalLinesSpecificationExpression = attributes[kMHTableVerticalLinesAttributeName];
            if (verticalLinesSpecificationExpression) {
                NSString *verticalLinesSpecificationString = [verticalLinesSpecificationExpression stringValue];
                if ([verticalLinesSpecificationString isEqualToString:kMHTableLinesShowNoneAttributeValue]) {
                    table.verticalLinesSpecification = MHTableLinesShowNone;
                }
                else if ([verticalLinesSpecificationString isEqualToString:kMHTableLinesShowAllAttributeValue]) {
                    table.verticalLinesSpecification = MHTableLinesShowAll;
                }
                else if ([verticalLinesSpecificationString isEqualToString:kMHTableLinesShowEdgeLinesAttributeValue]) {
                    table.verticalLinesSpecification = MHTableLinesShowEdgeLines;
                }
                else {
                    NSArray *specifiersArray = arrayOfBooleanSpecifiersFromSpecificationString(verticalLinesSpecificationString);
                    if (specifiersArray) {
                        table.verticalLinesSpecification = MHTableLinesCustom;
                        table.verticalLineBooleanSpecifiers = specifiersArray;
                    }
                }
            }
            
            MHExpression *framedAttributeExpression = attributes[kMHTableFramedAttributeName];
            if (framedAttributeExpression) {
                table.framed = [framedAttributeExpression boolValue];
            }
            
            MHExpression *columnAlignmentSpecificationExpression = attributes[kMHTableAlignmentsAttributeName];
            if (columnAlignmentSpecificationExpression) {
                NSString *columnAlignmentSpecificationString = [columnAlignmentSpecificationExpression stringValue];
                if ([columnAlignmentSpecificationString isEqualToString:kMHTableAlignmentLeftJustificationAttributeValue]) {
                    table.horizontalAlignment = MHTableCellHorizontalAlignmentTypeLeft;
                }
                else if ([columnAlignmentSpecificationString isEqualToString:kMHTableAlignmentRightJustificationAttributeValue]) {
                    table.horizontalAlignment = MHTableCellHorizontalAlignmentTypeRight;
                }
                else if ([columnAlignmentSpecificationString isEqualToString:kMHTableAlignmentCenteredAttributeValue]) {
                    table.horizontalAlignment = MHTableCellHorizontalAlignmentTypeCenter;
                }
                else {
                    NSString *specifiersString = validatedStringOfAlignmentSpecifiersFromSpecificationString(columnAlignmentSpecificationString);
                    if (specifiersString) {
                        table.horizontalAlignment = MHTableCellHorizontalAlignmentCustom;
                        table.columnAlignmentSpecifiers = specifiersString;
                    }
                }
            }
            
            MHExpression *fillColorExpression = attributes[kMHTableFillColorAttributeName];
            if (fillColorExpression) {
                table.fillColor = [fillColorExpression colorValue];
            }
            MHExpression *altFillColorExpression = attributes[kMHTableAltFillColorAttributeName];
            if (altFillColorExpression) {
                table.altFillColor = [altFillColorExpression colorValue];
            }
            MHExpression *headerFillColorExpression = attributes[kMHTableHeaderFillColorAttributeName];
            if (headerFillColorExpression) {
                table.headerFillColor = [headerFillColorExpression colorValue];
            }
            MHExpression *headerAltFillColorExpression = attributes[kMHTableHeaderAltFillColorAttributeName];
            if (headerAltFillColorExpression) {
                table.headerAltFillColor = [headerAltFillColorExpression colorValue];
            }

            MHExpression *uniformFillExpression = attributes[kMHTableFillAttributeName];
            if (uniformFillExpression) {
                bool uniformFill = [uniformFillExpression boolValue];
                table.fillSpecification = (uniformFill ? MHTableUniformFill : MHTableNoFill);
            }
            
            MHExpression *alternatingRowFillExpression = attributes[kMHTableAlternatingRowFillAttributeName];
            if (alternatingRowFillExpression) {
                bool alternatingRowFill = [alternatingRowFillExpression boolValue];
                table.fillSpecification = (alternatingRowFill ? MHTableAlternatingRowFill : MHTableNoFill);
            }
            
            MHExpression *headerRowsSpecificationExpression = attributes[kMHTableHeaderRowsAttributeName];
            if (headerRowsSpecificationExpression) {
                NSString *headerRowsSpecificationString = [headerRowsSpecificationExpression stringValue];
                if ([headerRowsSpecificationString isEqualToString:kMHTableHeaderNoneAttributeValue]) {
                    table.headerRowsSpecification = MHTableNoHeaders;
                }
                else if ([headerRowsSpecificationString isEqualToString:kMHTableHeaderLeadingAttributeValue]) {
                    table.headerRowsSpecification = MHTableLeadingHeader;
                }
                else {
                    NSArray *specifiersArray = arrayOfBooleanSpecifiersFromSpecificationString(headerRowsSpecificationString);
                    if (specifiersArray) {
                        table.headerRowsSpecification = MHTableCustomHeaders;
                        table.headerRowsBooleanSpecifiers = specifiersArray;
                    }
                }
            }

            MHExpression *headerColumnsSpecificationExpression = attributes[kMHTableHeaderColumnsAttributeName];
            if (headerColumnsSpecificationExpression) {
                NSString *headerColumnsSpecificationString = [headerColumnsSpecificationExpression stringValue];
                if ([headerColumnsSpecificationString isEqualToString:kMHTableHeaderNoneAttributeValue]) {
                    table.headerColumnsSpecification = MHTableNoHeaders;
                }
                else if ([headerColumnsSpecificationString isEqualToString:kMHTableHeaderLeadingAttributeValue]) {
                    table.headerColumnsSpecification = MHTableLeadingHeader;
                }
                else {
                    NSArray *specifiersArray = arrayOfBooleanSpecifiersFromSpecificationString(headerColumnsSpecificationString);
                    if (specifiersArray) {
                        table.headerColumnsSpecification = MHTableCustomHeaders;
                        table.headerColumnsBooleanSpecifiers = specifiersArray;
                    }
                }
            }

        }
        
        if (isMatrix) {
            MHBracket *leftParenthesis = [MHBracket bracketWithType:MHBracketTypeParenthesis
                                                                            orientation:MHBracketLeftOrientation
                                                                                variant:MHBracketDynamicallyDeterminedSize];
            
            MHBracket *rightParenthesis = [MHBracket bracketWithType:MHBracketTypeParenthesis
                                                                             orientation:MHBracketRightOrientation
                                                                                 variant:MHBracketDynamicallyDeterminedSize];
            
            MHHorizontalLayoutContainer *matrixContainer = [MHHorizontalLayoutContainer expression];
            [matrixContainer addSubexpression:leftParenthesis];
            [matrixContainer addSubexpression:table];
            [matrixContainer addSubexpression:rightParenthesis];
            return matrixContainer;
        }
        
        return table;
    }

    return nil;
}

+ (NSArray <NSString *> *)recognizedCommands
{
    return @[ kMHTableCommandNameTextTable, kMHTableCommandNameMathTable, kMHTableCommandNameMatrix ];
}



#pragma mark - Constructor method

- (instancetype)initWithArrayOfExpressionArrays:(NSArray <NSArray <MHExpression *> *> *)array
{
    if (self = [super init]) {
        _cells = array;              // save the array
        _numberOfRows = array.count; // record the number of rows
        
        NSMutableArray *flattenedCellMutableArray = [[NSMutableArray alloc] initWithCapacity:0];
        NSMutableArray *rowLengthsMutableArray = [[NSMutableArray alloc] initWithCapacity:_numberOfRows];
        
        // record the length of each row and the maximum row length, which is the number of columns
        _numberOfColumns = 0;
        for (NSArray <MHExpression *> *row in _cells) {
            NSUInteger rowLength = row.count;
            [rowLengthsMutableArray addObject:[NSNumber numberWithUnsignedInt:(unsigned int)rowLength]];
            if (rowLength > _numberOfColumns) {
                _numberOfColumns = rowLength;
            }
            [flattenedCellMutableArray addObjectsFromArray:row];
        }
         
        _flattenedCellArray = [NSArray arrayWithArray:flattenedCellMutableArray];
        _rowLengths = [NSArray arrayWithArray:rowLengthsMutableArray];
        
        _framed = false;
        _horizontalAlignment = MHTableCellHorizontalAlignmentTypeLeft;
        
        _headerRowsSpecification = MHTableNoHeaders;
    }
    return self;
}


#pragma mark - Defining the subexpressions

- (NSArray <MHExpression *> *)subexpressions
{
    return _flattenedCellArray;
}



#pragma mark - Accessing cells


- (MHExpression *)cellAtRow:(NSUInteger)rowIndex column:(NSUInteger)columnIndex
{
    if (rowIndex >= _numberOfRows || columnIndex >= _numberOfColumns) {
        NSLog(@"this isn't supposed to happen");
        return [MHExpression expression];   // FIXME: maybe crash with an error message?
    }
    NSArray <MHExpression *> *row = [_cells objectAtIndex:rowIndex];
    NSUInteger rowLength = row.count;
    if (columnIndex >= rowLength)
        return [MHExpression expression];   // return an empty expression for a cell column index that's outside the current row but still in the table dimensions
    return [row objectAtIndex:columnIndex];
}


#pragma mark - typeset method

- (void)typesetWithContextManager:(MHTypesettingContextManager *)contextManager
{
    [super typesetWithContextManager:contextManager];
    
    MHDimensions myDimensions;
    myDimensions.width = 0.0;
    myDimensions.height = 0.0;
    myDimensions.depth = 0.0;
    
    CGFloat leftCellPadding = 6.0;      // FIXME: add option to change these parameters, make them proportional to the font size
    CGFloat rightCellPadding = 6.0;
    CGFloat topCellPadding = 3.0;
    CGFloat bottomCellPadding = 3.0;
    
    NSMutableArray <NSNumber *> *rowHeights = [[NSMutableArray alloc] initWithCapacity:_numberOfRows];
    NSMutableArray <NSNumber *> *rowDepths = [[NSMutableArray alloc] initWithCapacity:_numberOfColumns];
    NSMutableArray <NSNumber *> *columnWidths = [[NSMutableArray alloc] initWithCapacity:_numberOfColumns];

    NSMutableArray <NSNumber *> *rowCumulativeTotalHeights = [[NSMutableArray alloc] initWithCapacity:_numberOfColumns];
    NSMutableArray <NSNumber *> *columnCumulativeWidths = [[NSMutableArray alloc] initWithCapacity:_numberOfColumns];

    // Start by making a pass over all the table cells, typesetting them and recording the depths and heights of each row, and cumulative vertical height (not counting cell top and bottom padding) as we descend down the rows
    NSUInteger rowIndex, columnIndex;
    CGFloat cumulativeTotalHeight = 0.0;
    for (rowIndex = 0; rowIndex < _numberOfRows; rowIndex++) {
        CGFloat currentRowHeight = 0.0;
        CGFloat currentRowDepth = 0.0;
        for (columnIndex = 0; columnIndex < _numberOfColumns; columnIndex++) {
            MHExpression *cell = [self cellAtRow:rowIndex column:columnIndex];
//            [cell typesetWithContextManager:contextManager];
            MHDimensions cellDimensions = cell.dimensions;
            if (cellDimensions.height > currentRowHeight)
                currentRowHeight = cellDimensions.height;
            if (cellDimensions.depth > currentRowDepth)
                currentRowDepth = cellDimensions.depth;
        }
        [rowDepths addObject:[NSNumber numberWithFloat:currentRowDepth]];   // FIXME: this information isn't actually used - remove
        [rowHeights addObject:[NSNumber numberWithFloat:currentRowHeight]]; // FIXME: this information is used but only because I coded up the storing of the cumulative row heights in an inefficient way. Probably can be eliminated too
        [rowCumulativeTotalHeights addObject:[NSNumber numberWithFloat:cumulativeTotalHeight]];
        cumulativeTotalHeight += currentRowDepth + currentRowHeight;
    }
    
    // We can now calculate the overall table height and depth
    CGFloat tableHeight = cumulativeTotalHeight + _numberOfRows * (bottomCellPadding+topCellPadding);
    if (_mathAxisCentering) {
        CGFloat mathAxisHeight = [contextManager mathAxisHeightForNestingLevel:self.nestingLevel];
        myDimensions.depth = tableHeight/2.0 - mathAxisHeight;
        myDimensions.height = tableHeight/2.0 + mathAxisHeight;
    }
    else {
        myDimensions.depth = 0.0;
        myDimensions.height = tableHeight;
    }

    // Now make an analogous second pass over the cells but with the outer loop over the columns and the inner loop over the rows, to calculate the width of each column and cumulative horizontal width (not counting cell padding) moving over the columns from left to right
    CGFloat cumulativeWidth = 0.0;
    for (columnIndex = 0; columnIndex < _numberOfColumns; columnIndex++) {
        CGFloat currentColumnWidth = 0.0;
        for (rowIndex = 0; rowIndex < _numberOfRows; rowIndex++) {
            MHExpression *cell = [self cellAtRow:rowIndex column:columnIndex];
            MHDimensions cellDimensions = cell.dimensions;
            if (cellDimensions.width > currentColumnWidth)
                currentColumnWidth = cellDimensions.width;
        }
        [columnWidths addObject:[NSNumber numberWithFloat:currentColumnWidth]];
        [columnCumulativeWidths addObject:[NSNumber numberWithFloat:cumulativeWidth]];
        cumulativeWidth += currentColumnWidth;
    }
    
    // Use this information to calculate the total table width
    myDimensions.width = cumulativeWidth + _numberOfColumns * (leftCellPadding + rightCellPadding);
    
    // Removing any SpriteKit nodes related to table decorations (cell border lines, cell fills) from previous typesetting rounds
    [_spriteKitNode removeChildrenInArray:[_spriteKitNode objectForKeyedSubscript:kMHTableTableLineNodeName]];
    [_spriteKitNode removeChildrenInArray:[_spriteKitNode objectForKeyedSubscript:kMHTableTableFillLowerNodeName]];
    [_spriteKitNode removeChildrenInArray:[_spriteKitNode objectForKeyedSubscript:kMHTableTableFillHigherNodeName]];

    NSUInteger numberOfHorizontalLineSpecifiers = _horizontalLineBooleanSpecifiers.count;
    NSUInteger numberOfVerticalLineSpecifiers = _verticalLineBooleanSpecifiers.count;
    NSUInteger numberOfAlignmentSpecifiers = _columnAlignmentSpecifiers.length;
    NSUInteger numberOfHeaderRowSpecifiers = _headerRowsBooleanSpecifiers.count;
    NSUInteger numberOfHeaderColumnSpecifiers = _headerColumnsBooleanSpecifiers.count;

    // finally set the cell positions
    CGFloat nextCumulativeTotalHeight = 0.0;
    for (rowIndex = 0; rowIndex < _numberOfRows; rowIndex++) {
        
        cumulativeTotalHeight = (rowIndex == 0 ? [[rowCumulativeTotalHeights objectAtIndex:rowIndex] floatValue] :
                                 nextCumulativeTotalHeight);
        if (rowIndex+1 < _numberOfRows)
            nextCumulativeTotalHeight = [[rowCumulativeTotalHeights objectAtIndex:rowIndex+1] floatValue];
        
        CGFloat yOffset = cumulativeTotalHeight + rowIndex*(bottomCellPadding+topCellPadding) + [rowHeights[rowIndex] floatValue] + topCellPadding;
        
        for (columnIndex = 0; columnIndex < _numberOfColumns; columnIndex++) {
            CGFloat hAlignmentOffset;
            MHExpression *cell = [self cellAtRow:rowIndex column:columnIndex];
            cumulativeWidth = [[columnCumulativeWidths objectAtIndex:columnIndex] floatValue];
            
            MHTableCellHorizontalAlignmentType thisColumnAlignment;
            if (_horizontalAlignment != MHTableCellHorizontalAlignmentCustom)
                thisColumnAlignment = _horizontalAlignment;
            else {
                if (columnIndex < numberOfAlignmentSpecifiers) {
                    unichar alignmentSpecifier = [_columnAlignmentSpecifiers characterAtIndex:columnIndex];
                    if (alignmentSpecifier == kMHTableAlignmentsSpecifierLeftJustificationChar)
                        thisColumnAlignment = MHTableCellHorizontalAlignmentTypeLeft;
                    else if (alignmentSpecifier == kMHTableAlignmentsSpecifierRightJustificationChar)
                        thisColumnAlignment = MHTableCellHorizontalAlignmentTypeRight;
                    else
                        thisColumnAlignment = MHTableCellHorizontalAlignmentTypeCenter;
                }
                else {
                    thisColumnAlignment = MHTableCellHorizontalAlignmentTypeLeft;
                }
            }

            switch (thisColumnAlignment) {
                case MHTableCellHorizontalAlignmentCustom:
                    NSLog(@"FIXME: this should never happen");
                case MHTableCellHorizontalAlignmentTypeLeft:
                    hAlignmentOffset = 0.0;
                    break;
                case MHTableCellHorizontalAlignmentTypeCenter: {
                    CGFloat columnWidth = [[columnWidths objectAtIndex:columnIndex] floatValue];
                    MHDimensions cellDimensions = cell.dimensions;
                    hAlignmentOffset = (columnWidth - cellDimensions.width)/2.0;
                }
                    break;
                case MHTableCellHorizontalAlignmentTypeRight: {
                    CGFloat columnWidth = [[columnWidths objectAtIndex:columnIndex] floatValue];
                    MHDimensions cellDimensions = cell.dimensions;
                    hAlignmentOffset = columnWidth - cellDimensions.width;
                }
                    break;
            }

            CGFloat xOffset = cumulativeWidth + columnIndex*(leftCellPadding+rightCellPadding) + leftCellPadding;
            cell.position = NSMakePoint(xOffset + hAlignmentOffset, tableHeight - yOffset - myDimensions.depth);
            
            
            bool showVerticalLine = (rowIndex == 0 &&
                                     (_verticalLinesSpecification == MHTableLinesShowAll ||
                                      (columnIndex == 0 && (_framed || _verticalLinesSpecification == MHTableLinesShowEdgeLines)) ||
                                      (_verticalLinesSpecification == MHTableLinesCustom && columnIndex < numberOfVerticalLineSpecifiers
                                       && [_verticalLineBooleanSpecifiers[columnIndex] boolValue])));
            if (showVerticalLine) {
                CGMutablePathRef linePath = CGPathCreateMutable();
                CGFloat linePathXCoord = xOffset - leftCellPadding;
                CGPathMoveToPoint(linePath, nil, linePathXCoord, -myDimensions.depth);
                CGPathAddLineToPoint(linePath, nil, linePathXCoord, myDimensions.height);
                SKShapeNode *lineNode = [SKShapeNode shapeNodeWithPath:linePath];
                CGPathRelease(linePath);
                lineNode.strokeColor = [NSColor blackColor];
                lineNode.name = kMHTableTableLineNodeName;
                [_spriteKitNode addChild:lineNode];
            }
            
            bool columnShouldBeFilledWithHeaderColor = (rowIndex == 0) &&
            (_fillSpecification != MHTableAlternatingRowFill) &&
            ((columnIndex == 0 && _headerColumnsSpecification == MHTableLeadingHeader)
                || (_headerColumnsSpecification == MHTableCustomHeaders && columnIndex < numberOfHeaderColumnSpecifiers &&
                [_headerColumnsBooleanSpecifiers[columnIndex] boolValue]));
            if (columnShouldBeFilledWithHeaderColor) {
                CGFloat lowerXCoord = xOffset - leftCellPadding;
                CGFloat columnWidth = [[columnWidths objectAtIndex:columnIndex] floatValue];    // FIXME: this value might have already been retrieved in the switch statement above - refactor
                SKShapeNode *columnFillNode = [SKShapeNode shapeNodeWithRect:CGRectMake(lowerXCoord, -myDimensions.depth,
                                                                                        columnWidth + leftCellPadding + rightCellPadding,
                                                                                        myDimensions.depth + myDimensions.height)];
                NSColor *columnFillColor = (_headerFillColor ? _headerFillColor : [NSColor lightGrayColor]);
                columnFillNode.fillColor = columnFillColor;
                columnFillNode.strokeColor = columnFillColor;
                columnFillNode.name = kMHTableTableFillHigherNodeName;
                columnFillNode.zPosition = -193.0;
                [_spriteKitNode addChild:columnFillNode];
            }
            
            bool cellShouldBeFilledWithHeaderAlternatingColor =
            (_fillSpecification == MHTableAlternatingRowFill) &&
            ((columnIndex == 0 && _headerColumnsSpecification == MHTableLeadingHeader)
                || (_headerColumnsSpecification == MHTableCustomHeaders && columnIndex < numberOfHeaderColumnSpecifiers &&
                [_headerColumnsBooleanSpecifiers[columnIndex] boolValue]));

            if (cellShouldBeFilledWithHeaderAlternatingColor) {
                CGFloat lowerXCoord = xOffset - leftCellPadding;
                CGFloat columnWidth = [[columnWidths objectAtIndex:columnIndex] floatValue];    // FIXME: this value might have already been retrieved in the switch statement above - refactor
                
                CGFloat lowerYCoord =
                (rowIndex+1 < _numberOfRows ?
                 myDimensions.height - nextCumulativeTotalHeight -(rowIndex+1)*(bottomCellPadding+topCellPadding) :
                 -myDimensions.depth);
                CGFloat upperYCoord = myDimensions.height - cumulativeTotalHeight -rowIndex*(bottomCellPadding+topCellPadding);
                
                SKShapeNode *columnFillNode = [SKShapeNode shapeNodeWithRect:CGRectMake(lowerXCoord, lowerYCoord,
                                                                                        columnWidth + leftCellPadding + rightCellPadding,
                                                                                        upperYCoord - lowerYCoord)];
                NSColor *columnFillColor = rowIndex % 2 == 0 ?
                    (_headerFillColor ? _headerFillColor : [NSColor lightGrayColor])
                    : (_headerAltFillColor ? _headerAltFillColor : [NSColor grayColor]);
                columnFillNode.fillColor = columnFillColor;
                columnFillNode.strokeColor = columnFillColor;
                columnFillNode.name = kMHTableTableFillHigherNodeName;
                columnFillNode.zPosition = -193.0;
                [_spriteKitNode addChild:columnFillNode];
            }
            
        }
        
        bool showHorizontalLine = ((_horizontalLinesSpecification == MHTableLinesShowAll) ||
                                   (rowIndex == 0 && (_framed || _horizontalLinesSpecification == MHTableLinesShowEdgeLines)) ||
                                   (_horizontalLinesSpecification == MHTableLinesCustom &&
                                    rowIndex < numberOfHorizontalLineSpecifiers &&
                                    [_horizontalLineBooleanSpecifiers[rowIndex] boolValue]));
        if (showHorizontalLine) {
            CGMutablePathRef linePath = CGPathCreateMutable();
            CGFloat linePathYCoord = myDimensions.height - cumulativeTotalHeight -rowIndex*(bottomCellPadding+topCellPadding);
            CGPathMoveToPoint(linePath, nil, 0.0, linePathYCoord);
            CGPathAddLineToPoint(linePath, nil, myDimensions.width, linePathYCoord);
            SKShapeNode *lineNode = [SKShapeNode shapeNodeWithPath:linePath];
            CGPathRelease(linePath);
            lineNode.strokeColor = [NSColor blackColor];
            lineNode.name = kMHTableTableLineNodeName;
            [_spriteKitNode addChild:lineNode];
        }

        bool rowShouldBeFilledWithHeaderColor = (rowIndex == 0 && _headerRowsSpecification == MHTableLeadingHeader)
                                                 || (_headerRowsSpecification == MHTableCustomHeaders &&
                                                     rowIndex < numberOfHeaderRowSpecifiers &&
                                                     [_headerRowsBooleanSpecifiers[rowIndex] boolValue]);
        bool rowSHouldBeFilledWithAlternatingColor = (_fillSpecification == MHTableAlternatingRowFill);
        if (rowShouldBeFilledWithHeaderColor || rowSHouldBeFilledWithAlternatingColor) {
            CGFloat lowerYCoord =
            (rowIndex+1 < _numberOfRows ?
             myDimensions.height - nextCumulativeTotalHeight -(rowIndex+1)*(bottomCellPadding+topCellPadding) :
             -myDimensions.depth);
            CGFloat upperYCoord = myDimensions.height - cumulativeTotalHeight -rowIndex*(bottomCellPadding+topCellPadding);
            SKShapeNode *rowFillNode = [SKShapeNode shapeNodeWithRect:CGRectMake(0.0, lowerYCoord+0.25, myDimensions.width,
                                                                                 upperYCoord-lowerYCoord-0.5
                                                                                 )];
            NSColor *rowFillColor;
            
            if (rowShouldBeFilledWithHeaderColor) {
                if (_fillSpecification == MHTableAlternatingRowFill && rowIndex % 2 == 1)
                    rowFillColor = (_headerAltFillColor ? _headerAltFillColor : [NSColor grayColor]);
                else
                    rowFillColor = (_headerFillColor ? _headerFillColor : [NSColor lightGrayColor]);
            }
            else {
                rowFillColor = (rowIndex % 2 == 0 ? (_fillColor ? _fillColor : [NSColor lightGrayColor])
                : (_altFillColor ? _altFillColor : [NSColor whiteColor]));
            }
            
            rowFillNode.fillColor = rowFillColor;
            rowFillNode.strokeColor = rowFillColor;
            rowFillNode.name = kMHTableTableFillLowerNodeName;
            rowFillNode.zPosition = -195.0;
            [_spriteKitNode addChild:rowFillNode];
        }
    }
    
    bool showHorizontalLine = (_framed || (_horizontalLinesSpecification == MHTableLinesShowAll) ||
                               (_horizontalLinesSpecification == MHTableLinesShowEdgeLines) ||
                               (_horizontalLinesSpecification == MHTableLinesCustom &&
                                rowIndex < numberOfHorizontalLineSpecifiers &&
                                [_horizontalLineBooleanSpecifiers[rowIndex] boolValue]));
    if (showHorizontalLine) {
        CGMutablePathRef linePath = CGPathCreateMutable();
        CGPathMoveToPoint(linePath, nil, 0.0, -myDimensions.depth);
        CGPathAddLineToPoint(linePath, nil, myDimensions.width, -myDimensions.depth);
        SKShapeNode *lineNode = [SKShapeNode shapeNodeWithPath:linePath];
        CGPathRelease(linePath);
        lineNode.strokeColor = [NSColor blackColor];
        lineNode.name = kMHTableTableLineNodeName;
        [_spriteKitNode addChild:lineNode];
    }
    
    bool showVerticalLine = (_framed || _verticalLinesSpecification == MHTableLinesShowAll ||
                             (_verticalLinesSpecification == MHTableLinesShowEdgeLines) ||
                             (_verticalLinesSpecification == MHTableLinesCustom && columnIndex < numberOfVerticalLineSpecifiers
                              && [_verticalLineBooleanSpecifiers[columnIndex] boolValue]));
    if (showVerticalLine) {
        CGMutablePathRef linePath = CGPathCreateMutable();
        CGPathMoveToPoint(linePath, nil, myDimensions.width, -myDimensions.depth);
        CGPathAddLineToPoint(linePath, nil, myDimensions.width, myDimensions.height);
        SKShapeNode *lineNode = [SKShapeNode shapeNodeWithPath:linePath];
        CGPathRelease(linePath);
        lineNode.strokeColor = [NSColor blackColor];
        lineNode.name = kMHTableTableLineNodeName;
        [_spriteKitNode addChild:lineNode];
    }
    
    if (_fillSpecification == MHTableUniformFill) {
        SKShapeNode *fillNode = [SKShapeNode shapeNodeWithRect:CGRectMake(0.0, -myDimensions.depth, myDimensions.width, myDimensions.depth+myDimensions.height)];
        fillNode.fillColor = _fillColor ? _fillColor : [NSColor lightGrayColor];
        fillNode.name = kMHTableTableFillLowerNodeName;
        fillNode.zPosition = -200.0;
        [_spriteKitNode addChild:fillNode];
    }

    self.dimensions = myDimensions;
}



#pragma mark - Properties



// FIXME: it would be better if I could refactor this to inherit this functionality from MHHorizontalLayoutContainer
- (void)setPresentationMode:(MHExpressionPresentationMode)presentationMode
{
    super.presentationMode = presentationMode;
    
    // The property is passed recursively to table cells
    NSUInteger rowIndex, columnIndex;
    for (rowIndex = 0; rowIndex < _numberOfRows; rowIndex++) {
        for (columnIndex = 0; columnIndex < _numberOfColumns; columnIndex++) {
            MHExpression *cell = [self cellAtRow:rowIndex column:columnIndex];
            cell.presentationMode = presentationMode;
        }
    }
}

// FIXME: it would be better if I could refactor this to inherit this functionality from MHHorizontalLayoutContainer
- (void)setNestingLevel:(NSUInteger)nestingLevel
{
    super.nestingLevel = nestingLevel;

    // The property is passed recursively to table cells
    NSUInteger rowIndex, columnIndex;
    for (rowIndex = 0; rowIndex < _numberOfRows; rowIndex++) {
        for (columnIndex = 0; columnIndex < _numberOfColumns; columnIndex++) {
            MHExpression *cell = [self cellAtRow:rowIndex column:columnIndex];
            cell.nestingLevel = nestingLevel;
        }
    }

}


// FIXME: it would be better if I could refactor this to inherit this functionality from MHHorizontalLayoutContainer
- (SKNode *)spriteKitNode
{
    if (!_spriteKitNode) {
        MHDimensions dimensions = self.dimensions;
        switch (self.presentationMode) {
            case MHExpressionPresentationModeEditing:
                _spriteKitNode = [SKSpriteNode spriteNodeWithColor:[NSColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.0] size:CGSizeMake(dimensions.width, dimensions.height+dimensions.depth)];
                break;
            case MHExpressionPresentationModePublishing:
                _spriteKitNode = [SKSpriteNode spriteNodeWithColor:[NSColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.0] size:CGSizeMake(dimensions.width, dimensions.height+dimensions.depth)];
                break;
        }
        _spriteKitNode.ownerExpression = self;
        ((SKSpriteNode *)_spriteKitNode).anchorPoint = CGPointMake(0.0, dimensions.depth/(dimensions.height+dimensions.depth));
        
        NSUInteger rowIndex, columnIndex;
        for (rowIndex = 0; rowIndex < _numberOfRows; rowIndex++) {
            for (columnIndex = 0; columnIndex < _numberOfColumns; columnIndex++) {
                MHExpression *cell = [self cellAtRow:rowIndex column:columnIndex];
                SKNode *cellNode = cell.spriteKitNode;
                if (cellNode) {
                    [_spriteKitNode addChild:cellNode];
                }
            }
        }
    }
    return _spriteKitNode;
}


#pragma mark - Expression copying



- (instancetype)logicalCopy
{
    // FIXME: implement this after working on improving the class
//    NSAssert(false, @"Need to implement logicalCopy method of class MHTable");
    
    
    NSArray <NSArray <MHExpression *> *> *cellCopies;
    NSMutableArray <NSArray <MHExpression *> *> *cellCopiesMutable = [[NSMutableArray alloc] initWithCapacity:_numberOfRows];
    for (NSUInteger rowIndex = 0; rowIndex < _numberOfRows; rowIndex++) {
        NSUInteger rowLength = [_rowLengths[rowIndex] unsignedIntValue];
        NSArray <MHExpression *> *row = _cells[rowIndex];
        NSArray <MHExpression *> *rowCopy;
        NSMutableArray <MHExpression *> *rowCopyMutable = [[NSMutableArray alloc] initWithCapacity:rowLength];
        for (NSUInteger columnIndex = 0; columnIndex < rowLength; columnIndex++) {
            MHExpression *cell = row[columnIndex];
            MHExpression *cellCopy = [cell logicalCopy];
            [rowCopyMutable addObject:cellCopy];
        }
        rowCopy = [NSArray arrayWithArray:rowCopyMutable];
        [cellCopiesMutable addObject:rowCopy];
    }
    cellCopies = [NSArray arrayWithArray:cellCopiesMutable];
    
    MHTable *myCopy = [[[self class] alloc] initWithArrayOfExpressionArrays:cellCopies];
    
    myCopy.framed = _framed;    // FIXME: etc. Add similar commands for other instance variables
    myCopy.mathAxisCentering = _mathAxisCentering;
    myCopy.fillSpecification = _fillSpecification;
    if (_fillColor)
        myCopy.fillColor = _fillColor;
    if (_altFillColor)
        myCopy.altFillColor = _altFillColor;
    if (_headerFillColor)
        myCopy.headerFillColor = _headerFillColor;
    if (_headerAltFillColor)
        myCopy.headerAltFillColor = _headerAltFillColor;
    myCopy.horizontalAlignment = _horizontalAlignment;
    myCopy.horizontalLinesSpecification = _horizontalLinesSpecification;
    myCopy.verticalLinesSpecification = _verticalLinesSpecification;
    if (_horizontalLineBooleanSpecifiers)
        myCopy.horizontalLineBooleanSpecifiers = [_horizontalLineBooleanSpecifiers copy];
    if (_verticalLineBooleanSpecifiers)
        myCopy.verticalLineBooleanSpecifiers = [_verticalLineBooleanSpecifiers copy];
    myCopy.headerRowsSpecification = _headerRowsSpecification;
    myCopy.headerColumnsSpecification = _headerColumnsSpecification;
    if (_headerRowsBooleanSpecifiers)
        myCopy.headerRowsBooleanSpecifiers = [_headerRowsBooleanSpecifiers copy];
    if (_headerColumnsBooleanSpecifiers)
        myCopy.headerColumnsBooleanSpecifiers = [_headerColumnsBooleanSpecifiers copy];
    
    myCopy.columnAlignmentSpecifiers = [_columnAlignmentSpecifiers copy];
    
    myCopy.codeRange = self.codeRange;

    return myCopy;
}


#pragma mark - Code linkbacks

- (void)applyCodeRangeLinkbackToCode:(NSObject <MHSourceCodeString> *)code
{
    // FIXME: a bit of a hack, not good OO practice - it would be better to set things up so that we inherit the implementation from the MHContainer class
    
    [super applyCodeRangeLinkbackToCode:code];
    // Apply the code range linkbacks recursively to all the table cells
    for (NSArray <MHExpression *> *tableRow in _cells) {
        for (MHExpression *cell in tableRow) {
            [cell applyCodeRangeLinkbackToCode:code];
        }
    }
}


#pragma mark - Rendering in PDF context

- (void)renderToPDFWithContextManager:(MHPDFRenderingContextManager *)contextManager
{
    CGContextRef pdfContext = contextManager.pdfContext;
    
    NSArray <SKShapeNode *> *fillNodes = (NSArray <SKShapeNode *> *)[_spriteKitNode objectForKeyedSubscript:kMHTableTableFillLowerNodeName];
    for (SKShapeNode *fillNode in fillNodes) {
        CGContextSaveGState(pdfContext);
        CGContextSetStrokeColorWithColor(pdfContext, [fillNode.strokeColor CGColor]);
        CGContextSetLineWidth(pdfContext, fillNode.lineWidth);
        CGContextSetLineCap(pdfContext, fillNode.lineCap);
        CGContextSetFillColorWithColor(pdfContext, [fillNode.fillColor CGColor]);
        CGContextAddPath(pdfContext, fillNode.path);
        CGContextDrawPath(pdfContext, kCGPathFillStroke);
        CGContextRestoreGState(pdfContext);
    }

    fillNodes = (NSArray <SKShapeNode *> *)[_spriteKitNode objectForKeyedSubscript:kMHTableTableFillHigherNodeName];
    for (SKShapeNode *fillNode in fillNodes) {
        CGContextSaveGState(pdfContext);
        CGContextSetStrokeColorWithColor(pdfContext, [fillNode.strokeColor CGColor]);
        CGContextSetLineWidth(pdfContext, fillNode.lineWidth);
        CGContextSetLineCap(pdfContext, fillNode.lineCap);
        CGContextSetFillColorWithColor(pdfContext, [fillNode.fillColor CGColor]);
        CGContextAddPath(pdfContext, fillNode.path);
        CGContextDrawPath(pdfContext, kCGPathFillStroke);
        CGContextRestoreGState(pdfContext);
    }

    NSArray <SKShapeNode *> *lineNodes = (NSArray <SKShapeNode *> *)[_spriteKitNode objectForKeyedSubscript:kMHTableTableLineNodeName];
    for (SKShapeNode *lineNode in lineNodes) {
        CGContextSaveGState(pdfContext);
        CGContextSetStrokeColorWithColor(pdfContext, [lineNode.strokeColor CGColor]);
        CGContextSetLineWidth(pdfContext, lineNode.lineWidth);
        CGContextSetLineCap(pdfContext, lineNode.lineCap);
        CGContextAddPath(pdfContext, lineNode.path);
        CGContextDrawPath(pdfContext, kCGPathStroke);
        CGContextRestoreGState(pdfContext);
    }

    [super renderToPDFWithContextManager:contextManager];
}





@end
