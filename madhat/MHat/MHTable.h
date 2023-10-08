//
//  MHTable.h
//  MadHat
//
//  Created by Dan Romik on 12/11/19.
//  Copyright © 2019 Dan Romik. All rights reserved.
//

#import "MHContainer.h"
#import "MHCommand.h"

NS_ASSUME_NONNULL_BEGIN


typedef enum {
    MHTableLinesShowNone = 0,
    MHTableLinesShowAll,
    MHTableLinesShowEdgeLines,
    MHTableLinesCustom          // this means a detailed list of specifiers is given, one for each line
} MHTableLinesSpecificationType;



@interface MHTable : MHContainer <MHCommand>   // FIXME: it might make more sense to make this a subclass of MHContainer (see also the note in the -applyCodeRangeLinkbackToCode method in the implementation file)

@property bool framed;

@property MHTableLinesSpecificationType horizontalLinesSpecification;
@property MHTableLinesSpecificationType verticalLinesSpecification;
@property NSArray <NSNumber *> *horizontalLineBooleanSpecifiers;
@property NSArray <NSNumber *> *verticalLineBooleanSpecifiers;


- (instancetype)initWithArrayOfExpressionArrays:(NSArray <NSArray <MHExpression *> *> *)array;

@end

NS_ASSUME_NONNULL_END
