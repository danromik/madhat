//
//  MHMathFormulaParser.h
//  MadHat
//
//  Created by Dan Romik on 9/1/21.
//  Copyright © 2021 Dan Romik. All rights reserved.
//
//  This class parses mathematical formulas in infix notation, given as MHExpression objects and evaluates them numerically,
//  with variable names being evaluated using a delegate data provider object
//  A key assumption is that the MHExpression object was formed by parsing MadHat language code in math mode. This is important
//  since the MadHat math mode parser encodes semantic data regarding the nature of the expressions it reads; for example "+"
//  is marked as a binary operator, brackets and superscripts are handled correctly, etc. The text mode parser does not make any
//  attempt to do such things, so a simple text formula parsed in text mode will not be processed correctly by MHMathFormulaParser
//


#import <Foundation/Foundation.h>
#import "MHExpression.h"

typedef enum {
    MHMathFormulaValidityWellFormed,
    MHMathFormulaValidityIllFormed
} MHMathFormulaValidityType;


NS_ASSUME_NONNULL_BEGIN

@protocol MHMathFormulaParserDataProvider;
@interface MHMathFormulaParser : NSObject

@property (nullable, weak) id <MHMathFormulaParserDataProvider> dataProvider;
@property (readonly) MHHorizontalLayoutContainer *formula;     // FIXME: the class for the formula variable is currently given as MHHorizontalLayoutContainer, because the parser uses the flattenedListOfUnsplittableComponents method of that class. However, logically we should take an MHLinearContainer object or an MHExpression object for the formula. IMPROVE

@property (readonly) MHMathFormulaValidityType validity;  // this can be used to test if the formula is well-formed. Only well-formed formulas can be evaluated using the evaluateFormulaWithAuxiliaryData: method



+ (instancetype)formulaParserWithFormula:(MHHorizontalLayoutContainer *)formula;

- (double)evaluateFormulaWithAuxiliaryData:(nullable void *)data;   // the data gets passed to the delegate, see the MHMathFormulaParserDataProvider protocol definition

@end


@protocol MHMathFormulaParserDataProvider <NSObject>

- (double)valueForVariableName:(NSString *)variableName auxiliaryData:(nullable void *)data;

@end

NS_ASSUME_NONNULL_END
