//
//  MHMathFormulaParser.m
//  MadHat
//
//  Created by Dan Romik on 9/1/21.
//  Copyright © 2021 Dan Romik. All rights reserved.
//

#import "MHMathFormulaParser.h"
#import "MHParser+SpecialSymbols.h"
#import "MHHorizontalLayoutContainer.h"
#import "MHMathAtom.h"
#import "MHWhitespace.h"
#import "MHScriptedExpression.h"
#import "MHFraction.h"
#import "MHBracket.h"
#import "MHRadical.h"


typedef enum {
    MHMathFormulaParserBinaryOperatorAddition = 0,
    MHMathFormulaParserBinaryOperatorSubtraction = 1,
    MHMathFormulaParserBinaryOperatorMultiplication = 2,
    MHMathFormulaParserBinaryOperatorDivision = 3,
    MHMathFormulaParserBinaryOperatorUnknown = 4,
} MHMathFormulaParserBinaryOperatorType;

typedef enum {
    MHMathFormulaParserFunctionExp,
    MHMathFormulaParserFunctionLog,
    MHMathFormulaParserFunctionSine,
    MHMathFormulaParserFunctionCosine,
    MHMathFormulaParserFunctionTangent,
    MHMathFormulaParserFunctionArcsine,
    MHMathFormulaParserFunctionArccosine,
    MHMathFormulaParserFunctionArctangent,
    MHMathFormulaParserFunctionUnknown
} MHMathFormulaParserFunctionType;

typedef enum {
    MHMathFormulaParserTokenNumber,
    MHMathFormulaParserTokenVariableName,
    MHMathFormulaParserTokenBinaryOperator,
    MHMathFormulaParserTokenFunction,
    MHMathFormulaParserTokenLeftBracket,
    MHMathFormulaParserTokenRightBracket,
    MHMathFormulaParserTokenFraction,
    MHMathFormulaParserTokenPower,
    MHMathFormulaParserTokenSquareRoot,
    MHMathFormulaParserTokenExponentOfBracketedExpression,
    MHMathFormulaParserTokenAbsoluteValue,
    MHMathFormulaParserTokenNone
} MHMathFormulaParserTokenType;




// some useful macros to implement both adding an implicit multiplication operator at appropriate times, and adding a regular binary operator

#define InsertBinaryOperator(operatorTypeToInsert) {                                                            \
    previousTokenType = MHMathFormulaParserTokenBinaryOperator;                                                 \
    NSUInteger numberOfOperatorsInStack = operatorStack.count;                                                  \
    while (numberOfOperatorsInStack > 0) {                                                                      \
        MHMathFormulaParserToken *topTokenInStack = [operatorStack lastObject];                                 \
        if (topTokenInStack->type == MHMathFormulaParserTokenLeftBracket)                                       \
            break;                                                                                              \
        if (topTokenInStack->type != MHMathFormulaParserTokenBinaryOperator) {                                  \
            NSLog(@"error: expecting a binary operator");                                                       \
            return nil;                                                                                         \
        }                                                                                                       \
        MHMathFormulaParserBinaryOperatorType topOperatorInStack = topTokenInStack->operatorType;               \
        NSComparisonResult precedenceComparison = comparePrecedenceOfBinaryOperators(operatorTypeToInsert,      \
                                                                                     topOperatorInStack);       \
        if (precedenceComparison == NSOrderedAscending || precedenceComparison == NSOrderedSame) {              \
            [operatorStack removeLastObject];                                                                   \
            numberOfOperatorsInStack--;                                                                         \
            [outputListOfTokens addObject:topTokenInStack];                                                     \
        }                                                                                                       \
        else {                                                                                                  \
            break;                                                                                              \
        }                                                                                                       \
    }                                                                                                           \
    MHMathFormulaParserToken *token = [MHMathFormulaParserToken tokenWithBinaryOperator:operatorTypeToInsert];  \
    [operatorStack addObject:token];                                                                            \
}

#define InsertImplicitMultiplicationOperator() { InsertBinaryOperator(MHMathFormulaParserBinaryOperatorMultiplication); }

#define ConditionallyInsertImplicitMultiplicationOperator() {                                       \
    if (previousTokenType == MHMathFormulaParserTokenNumber                                         \
                || previousTokenType == MHMathFormulaParserTokenVariableName                        \
                || previousTokenType == MHMathFormulaParserTokenRightBracket                        \
                || previousTokenType == MHMathFormulaParserTokenFraction                            \
                || previousTokenType == MHMathFormulaParserTokenPower                               \
                || previousTokenType == MHMathFormulaParserTokenSquareRoot                          \
                || previousTokenType == MHMathFormulaParserTokenExponentOfBracketedExpression) {    \
        InsertImplicitMultiplicationOperator();                                                     \
    }                                                                                               \
}





@interface MHMathFormulaParserToken : NSObject
{
@public
    MHMathFormulaParserTokenType type;  // tells us what kind of token this is
    double numericalValue;          // tells us the numerical value if the token is of type MHMathFormulaParserTokenNumber
    NSString *variableName;         // tells us the variable name if the token is of type MHMathFormulaParserTokenVariableName
    
    // the next two instance variables are used for fractions, powers, and square roots:
    // * for a MHMathFormulaParserTokenFraction type token, the subformula1 and subformula2 fields will hold a postfix representation of the fraction's numerator and denominator, respectively
    // * for a MHMathFormulaParserTokenPower type token, the subformula1 and subformula2 fields will hold a postfix representation of the base and exponent, respectively
    // * for a MHMathFormulaParserTokenExponentOfBracketedExpression type token, the subformula2 field will hold a postfix representation of the exponent. The base for the power operation will be taken from the token preceding this token, so the subformula1 field is unused
    // * for a MHMathFormulaParserTokenSquareRoot type token, the subformula1 field will hold a postfix representation of the contents of the radical. The base for the power operation will be 1/2 since it's a square root, so the subformula2 field is unused
    NSArray <MHMathFormulaParserToken *> *subformula1;
    NSArray <MHMathFormulaParserToken *> *subformula2;
    
    MHMathFormulaParserBinaryOperatorType operatorType; // holds the operator type if the token is of type MHMathFormulaParserTokenBinaryOperator
    MHMathFormulaParserFunctionType functionType;   // holds the type of function if the token is of type MHMathFormulaParserTokenFunction
    
    // FIXME: this instance variable is used only in one very specific circumstance, which seems a bit wasteful. With a small effort it would be possible to incorporate this bit into one of the other instance variables (for example by adding another token type to the MHMathFormulaParserTokenType typedef). Consider whether this would be worth doing.
    BOOL bracketIsAbsoluteValue;    // for tokens of bracket type MHMathFormulaParserTokenExponentOfBracketedExpression, if this is YES then the bracket is an absolute value bracket, otherwise an ordinary bracket
}

+ (instancetype)tokenWithNumber:(double)aNumber;
+ (instancetype)tokenWithVariableName:(NSString *)variableName;
+ (instancetype)tokenWithBinaryOperator:(MHMathFormulaParserBinaryOperatorType)operator;
+ (instancetype)tokenWithFunction:(MHMathFormulaParserFunctionType)functionType;
+ (instancetype)tokenWithLeftBracket;
+ (instancetype)tokenWithRightBracket;
+ (instancetype)fractionTokenWithNumerator:(NSArray <MHMathFormulaParserToken *> *)numerator
                               denominator:(NSArray <MHMathFormulaParserToken *> *)denominator;
+ (instancetype)powerTokenWithBase:(NSArray <MHMathFormulaParserToken *> *)base
                          exponent:(NSArray <MHMathFormulaParserToken *> *)exponent;
+ (instancetype)squareRootTokenWithContents:(NSArray <MHMathFormulaParserToken *> *)contents;
+ (instancetype)tokenWithExponentOfBracketedExpression:(NSArray <MHMathFormulaParserToken *> *)exponent;
+ (instancetype)absoluteValueToken;

@end


static NSString *kMHMathFormulaParserBinaryOperatorString = @"+−×/";




// declare some useful auxiliary C functions (for the actual definitions, see the bottom of this file)
static MHMathFormulaParserBinaryOperatorType binaryOperatorFromExpression(MHExpression *expression);
static NSComparisonResult comparePrecedenceOfBinaryOperators(MHMathFormulaParserBinaryOperatorType firstOperator,
                                                             MHMathFormulaParserBinaryOperatorType secondOperator);
static MHMathFormulaParserFunctionType functionTypeForSymbolName(NSString *symbolName);
static double numericallyEvaluateFunction(MHMathFormulaParserFunctionType functionType, double argument);




@interface MHMathFormulaParser ()
{
    MHHorizontalLayoutContainer *_formula;
    NSArray <MHMathFormulaParserToken *> *_formulaInPostfixRepresentation;
    id <MHMathFormulaParserDataProvider> _dataProvider;
    MHMathFormulaValidityType _validity;
}

@end

@implementation MHMathFormulaParser

#pragma mark - Constructor methods

+ (instancetype)formulaParserWithFormula:(MHHorizontalLayoutContainer *)formula
{
    return [[self alloc] initWithFormula:formula];
}

- (instancetype)initWithFormula:(MHHorizontalLayoutContainer *)formula
{
    if (self = [super init]) {
        self.formula = formula;
    }
    return self;
}


#pragma mark - Properties

- (MHHorizontalLayoutContainer *)formula
{
    return _formula;
}

- (void)setFormula:(MHHorizontalLayoutContainer *)formula
{
    _formula = formula;
    _formulaInPostfixRepresentation = [[self class] postfixRepresentationOfFormula:_formula];
    _validity = (_formulaInPostfixRepresentation ? MHMathFormulaValidityWellFormed : MHMathFormulaValidityIllFormed);
}

- (MHMathFormulaValidityType)validity
{
    return _validity;
}

- (id <MHMathFormulaParserDataProvider>)dataProvider
{
    return _dataProvider;
}

- (void)setDataProvider:(id<MHMathFormulaParserDataProvider>)dataProvider
{
    _dataProvider = dataProvider;
}





#pragma mark - The parser code: converting infix to postfix

//
// The code is an implementation of a modified version of Dijkstra's shunting-yard algorithm, with various adaptations to
// the particular encoding of mathematical expressions as MHExpression objects output by the MadHat language math mode parser,
// and the addition of a recursive structure in which tokens of certain types (fractions, powers) can hold subformulas that
// are evaluated recursively
//
// Some useful general references on the shuntng yard algorithm:
// https://en.wikipedia.org/wiki/Shunting-yard_algorithm
// http://www.cs.nthu.edu.tw/~wkhon/ds/ds10/tutorial/tutorial2.pdf
//

// a return value of nil means the formula is ill-formed
+ (nullable NSArray <MHMathFormulaParserToken *> *)postfixRepresentationOfFormula:(MHHorizontalLayoutContainer *)formula
{
    // Now convert the formula to postfix notation
    NSMutableArray <MHMathFormulaParserToken *> *outputListOfTokens = [[NSMutableArray alloc] initWithCapacity:0];
    NSMutableArray <MHMathFormulaParserToken *> *operatorStack = [[NSMutableArray alloc] initWithCapacity:0];
    
    // an auxiliary stack to help keep track of the types of brackets we're opening and closing. Any opening bracket gets pushed into the stack, and a closing bracket causes the opening bracket at the top of the stack to be popped out
    NSMutableArray <MHBracket *> *bracketStack = [[NSMutableArray alloc] initWithCapacity:0];
    
    NSArray <MHExpression *> *subexpressions = [formula flattenedListOfUnsplittableComponents];
    NSUInteger numberOfSubexpressions = subexpressions.count;
    NSUInteger subexpressionIndex;
    MHMathFormulaParserTokenType previousTokenType = MHMathFormulaParserTokenNone;
    for (subexpressionIndex = 0; subexpressionIndex < numberOfSubexpressions; subexpressionIndex++) {
        MHExpression *subexp = subexpressions[subexpressionIndex];
        bool isMathAtom = [subexp isKindOfClass:[MHMathAtom class]];
        bool isBracket = false;
        bool isBracketWithExponent = false;
        if (isMathAtom) {
            MHTypographyClass typographyClass = subexp.typographyClass;
            switch (typographyClass) {
                case MHTypographyClassNumber: {
                    // a number can only appear at the beginning of the formula, or following a binary operator or a left bracket. Otherwise we consider the formula ill-formed
                    if (previousTokenType == MHMathFormulaParserTokenNone
                        || previousTokenType == MHMathFormulaParserTokenBinaryOperator
                        || previousTokenType == MHMathFormulaParserTokenLeftBracket) {
                        previousTokenType = MHMathFormulaParserTokenNumber;
                        MHMathFormulaParserToken *token = [MHMathFormulaParserToken tokenWithNumber:[subexp floatValue]];
                        [outputListOfTokens addObject:token];
//                        NSLog(@"outputting number token %f", token->numericalValue);
                    }
                    else return nil;         // the formula is ill-formed
                }
                    break;
                case MHTypographyClassRomanMathVariable:
                case MHTypographyClassItalicMathVariable: {
                    // the atom represents either a variable or a function name, so determine which of these two cases applies
                    NSString *symbolName = [subexp stringValue];
                    MHMathFormulaParserFunctionType functionType = functionTypeForSymbolName(symbolName);
                    if (functionType == MHMathFormulaParserFunctionUnknown) {
                        // it's a variable
                        
                        ConditionallyInsertImplicitMultiplicationOperator();
                    
                        // a variable can only appear at the beginning of the formula, or following a binary operator or a left bracket. Otherwise we consider the formula ill-formed
                        if (previousTokenType == MHMathFormulaParserTokenNone
                            || previousTokenType == MHMathFormulaParserTokenBinaryOperator
                            || previousTokenType == MHMathFormulaParserTokenLeftBracket) {
                            previousTokenType = MHMathFormulaParserTokenVariableName;
                            MHMathFormulaParserToken *token = [MHMathFormulaParserToken tokenWithVariableName:symbolName];
                            [outputListOfTokens addObject:token];
//                            NSLog(@"outputting variable token %@", token->variableName);
                        }
                        else return nil;         // the formula is ill-formed
                    }
                    else {
                        // it's a function
                        
                        ConditionallyInsertImplicitMultiplicationOperator();
                        
                        // a function can only appear at the beginning of the formula, or following a binary operator or a left bracket. Otherwise we declare the formula ill-formed
                        if (previousTokenType == MHMathFormulaParserTokenNone
                            || previousTokenType == MHMathFormulaParserTokenBinaryOperator
                            || previousTokenType == MHMathFormulaParserTokenLeftBracket) {
                            previousTokenType = MHMathFormulaParserTokenFunction;
                            MHMathFormulaParserToken *token = [MHMathFormulaParserToken tokenWithFunction:functionType];
                            [operatorStack addObject:token];
//                            NSLog(@"pushing function token %@ into stack", symbolName);
                        }
                        else return nil;         // the formula is ill-formed
                    }
                }
                    break;
                case MHTypographyClassBinaryOperator: {
                    // find the internal encoding of the binary operator as a MHMathFormulaParserBinaryOperator data type
                    MHMathFormulaParserBinaryOperatorType binaryOperator = binaryOperatorFromExpression(subexp);
                    if (binaryOperator == MHMathFormulaParserBinaryOperatorUnknown)
                        return nil;     // a formula with an unknown binary operator is considered ill-formed
                    
                    // this code section implements support for unary + or - operators: if the operator currently being processed is one of those two types, and we are at the beginning of the formula or after a left bracket, we artificially insert a zero number token into the output before processing the operator, so that the binary operator inserted following this effectively behaves as the corresponding unary operator
                    if ((binaryOperator == MHMathFormulaParserBinaryOperatorAddition
                        || binaryOperator == MHMathFormulaParserBinaryOperatorSubtraction)
                        && (previousTokenType == MHMathFormulaParserTokenNone
                            || previousTokenType == MHMathFormulaParserTokenLeftBracket)) {
                        MHMathFormulaParserToken *zeroToken = [MHMathFormulaParserToken tokenWithNumber:0.0];
                        [outputListOfTokens addObject:zeroToken];
                        previousTokenType = MHMathFormulaParserTokenNumber;
                    }
                    
                    // a binary operator can only appear following a number or a variable name or a fraction or an exponent or a right bracket. Otherwise we declare the formula ill-formed
                    if (previousTokenType == MHMathFormulaParserTokenNumber
                        || previousTokenType == MHMathFormulaParserTokenVariableName
                        || previousTokenType == MHMathFormulaParserTokenFraction
                        || previousTokenType == MHMathFormulaParserTokenPower
                        || previousTokenType == MHMathFormulaParserTokenRightBracket) {
                        
                        InsertBinaryOperator(binaryOperator);
                    }
                    else return nil;         // the formula is ill-formed
                }
                    break;
                    
                default:
                    // any other type of math atom leads to the formula being declared ill-formed
                    NSLog(@"invalid symbol: cannot be processed by the math formula parser");
                    return nil;
                    break;
            }
        }
        else if ((isBracket = [subexp isKindOfClass:[MHBracket class]]) ||
                 (isBracketWithExponent =
                  [subexp isKindOfClass:[MHScriptedExpression class]]
                  && [((MHScriptedExpression *)subexp).body isKindOfClass:[MHBracket class]]
                  && (((MHBracket *)(((MHScriptedExpression *)subexp).body)).orientation == MHBracketRightOrientation
                      || ((MHBracket *)(((MHScriptedExpression *)subexp).body)).orientation == MHBracketDynamicallyDeterminedOrientation))) {
            MHBracketOrientation bracketOrientation = (isBracketWithExponent ? MHBracketRightOrientation
                                                : ((MHBracket *)subexp).orientation);
            MHBracketType bracketType = ((id <MHBracket>)subexp).type;

            MHBracketOrientation effectiveBracketOrientation;
            if (bracketOrientation == MHBracketLeftOrientation || bracketOrientation == MHBracketRightOrientation) {
                effectiveBracketOrientation = bracketOrientation;
            }
            else {
                if (bracketOrientation == MHBracketMiddleOrientation) {
                    // this should never happen. if we see a middle bracket, we declare the formula ill-formed.
                    return nil;
                }
                // if we got here, the bracket is of type MHBracketDynamicallyDeterminedOrientation
                if (bracketType != MHBracketTypeVerticalBar) {
                    // the only bracket with a dynamically determined orientation that we recognize is a vertical bar, which is interpreted as an absolute value left/right delimiter. If we see any other type, declare the formula ill-posed
                    return nil;
                }
                
                // if we got here, the bracket is an absolute value sign. We need to determine if we should treat it as a left absolute value bracket or a right absolute value bracket
                if (bracketStack.count == 0) {
                    // there are no brackets in the bracket stack, so we'll regard the absolute value as a left bracket
                    effectiveBracketOrientation = MHBracketLeftOrientation;
                    
                    if (isBracketWithExponent) {
                        // a left bracket cannot have an exponent -- declare the formula ill-formed in that case
                        return nil;
                    }
                }
                else if (previousTokenType == MHMathFormulaParserTokenBinaryOperator
                    || previousTokenType == MHMathFormulaParserTokenLeftBracket) {
                    // if the bracket follows a binary operator or a left bracket, it cannot be a right bracket, so we mark it as a left absolute value bracket
                    effectiveBracketOrientation = MHBracketLeftOrientation;
                    
                    if (isBracketWithExponent) {
                        // a left bracket cannot have an exponent -- declare the formula ill-formed in that case
                        return nil;
                    }
                }
                else {
                    // there are left brackets in the bracket stack, so examine the top one to see if it's an absolute value bracket and did not come with an explicitly specified left orientation. If that is the case, we regard the current bracket as the right bracket matching it. Otherwise, we'll consider the current bracket as a left absolute value bracket
                    MHBracket *leftBracket = [bracketStack lastObject];
                    effectiveBracketOrientation = ((leftBracket.type == MHBracketTypeVerticalBar
                                                   && leftBracket.orientation == MHBracketDynamicallyDeterminedOrientation)
                                                   ? MHBracketRightOrientation : MHBracketLeftOrientation);
                    
                    if (isBracketWithExponent && effectiveBracketOrientation == MHBracketLeftOrientation) {
                        // a left bracket cannot have an exponent -- declare the formula ill-formed in that case
                        return nil;
                    }
                }
            }
            
            switch (effectiveBracketOrientation) {
                case MHBracketLeftOrientation: {
                    
                    ConditionallyInsertImplicitMultiplicationOperator();

                    // a left bracket can only appear at the beginning of the formula, or following a binary operator, or following a left bracket, or (if it is not an absolute value bracket) following a function. Otherwise we declare the formula ill-formed
                    if (previousTokenType == MHMathFormulaParserTokenNone
                        || previousTokenType == MHMathFormulaParserTokenBinaryOperator
                        || previousTokenType == MHMathFormulaParserTokenLeftBracket
                        || (previousTokenType == MHMathFormulaParserTokenFunction && bracketType != MHBracketTypeVerticalBar)) {
                        // push the left bracket into the operator stack
                        previousTokenType = MHMathFormulaParserTokenLeftBracket;
                        [operatorStack addObject:[MHMathFormulaParserToken tokenWithLeftBracket]];
//                        NSLog(@"pushing left bracket token into stack");
                        
                        // push the bracket into the bracket stack
                        [bracketStack addObject:(MHBracket *)subexp];
                    }
                    else return nil;         // the formula is ill-formed
                }
                    break;
                case MHBracketRightOrientation: {
                    // a right bracket can only appear following a number or a variable name or a fraction or an exponent or a right bracket. Otherwise we declare the formula ill-formed
                    if (previousTokenType == MHMathFormulaParserTokenNumber
                        || previousTokenType == MHMathFormulaParserTokenVariableName
                        || previousTokenType == MHMathFormulaParserTokenFraction
                        || previousTokenType == MHMathFormulaParserTokenPower
                        || previousTokenType == MHMathFormulaParserTokenRightBracket) {
                        // a right bracket - start popping items from the operator stack and adding them to the postfix list until we encounter a left bracket, which we pop and discard
                        
                        if (bracketStack.count == 0) {
                            // the right bracket does not have a matching left bracket, so the formula is ill-formed
                            return nil;
                        }
                        MHBracket *leftBracket = [bracketStack lastObject];
                        [bracketStack removeLastObject];    // pop the matching left bracket out of the bracket stack
                        // check that the left bracket type matches that of the right bracket, otherwise the formula is ill-formed
                        if (leftBracket.type != bracketType) {
                            return nil;
                        }
                        
                        previousTokenType = MHMathFormulaParserTokenRightBracket;
                        NSUInteger numberOfOperatorsInStack = operatorStack.count;
                        while (numberOfOperatorsInStack > 0) {
                            MHMathFormulaParserToken *topTokenInStack = [operatorStack lastObject];
                            [operatorStack removeLastObject];
                            numberOfOperatorsInStack--;
                            if (topTokenInStack->type == MHMathFormulaParserTokenLeftBracket) {
                                break;  // once we encounter a left bracket, break out of the while loop
                            }
                            
                            if (numberOfOperatorsInStack == 0) {
                                // if we reached this far in the while loop with no more operators in the stack, that means the right bracket does not have a matching left bracket, so the formula is ill-formed
                                return nil;
                            }
                            
                            [outputListOfTokens addObject:topTokenInStack];
//                            NSLog(@"popping binary operator of type %d in parenthesized block and outputting it", topTokenInStack->operatorType);
                        }
                        
                        // if there's token of type MHMathFormulaParserTokenFunction on the top of the stack, pop it as well and add it to the output
                        if (numberOfOperatorsInStack > 0) {
                            MHMathFormulaParserToken *topToken = [operatorStack lastObject];
                            if (topToken->type == MHMathFormulaParserTokenFunction) {
                                [operatorStack removeLastObject];
                                [outputListOfTokens addObject:topToken];
//                                NSLog(@"popping a function of type %d from the stack and outputting it", topToken->functionType);
                            }
                        }
                        
                        // if the bracket has an exponent, create a token representing that exponent and output it to the postfix list
                        if (isBracketWithExponent) {
                            MHExpression *exponent = ((MHScriptedExpression *)subexp).superscript;
                            
                            // very clunky workaround to ensure that the exponent can be treated as MHHorizontalLayoutContainer instances, which is unfortunately necessary at this point for the formula parser design to work
                            // FIXME: IMPROVE so that this isn't necessary
                            MHHorizontalLayoutContainer *horizontalLayoutExponentWrapper;
                            if ([exponent isKindOfClass:[MHHorizontalLayoutContainer class]]) {
                                horizontalLayoutExponentWrapper = (MHHorizontalLayoutContainer *)exponent;
                            }
                            else {
                                horizontalLayoutExponentWrapper = [[MHHorizontalLayoutContainer alloc] init];
                                [horizontalLayoutExponentWrapper addSubexpression:[exponent logicalCopy]];
                            }
                            
                            NSArray <MHMathFormulaParserToken *> *exponentPostfixRep = [self postfixRepresentationOfFormula:horizontalLayoutExponentWrapper];
                            if (!exponentPostfixRep) {
                                // the formula for the exponent is ill-posed, so we consider the original formula ill-formed as well
                                return nil;
                            }
                            MHMathFormulaParserToken *exponentiationToken = [MHMathFormulaParserToken tokenWithExponentOfBracketedExpression:exponentPostfixRep];
                            
                            if (bracketType == MHBracketTypeVerticalBar)
                                exponentiationToken->bracketIsAbsoluteValue = YES;
                                
                            [outputListOfTokens addObject:exponentiationToken];
                        }
                        else {
                            // there is no exponent. In this case, for an absolute value bracket we output an absolute value token, and for normal brackets we don't need to output anything more
                            if (bracketType == MHBracketTypeVerticalBar) {
                                MHMathFormulaParserToken *absoluteValueToken = [MHMathFormulaParserToken absoluteValueToken];
                                [outputListOfTokens addObject:absoluteValueToken];
                            }
                        }
                        
                    }
                    else return nil;        // we cannot have a right bracket here. The formula is ill-formed.
                }
                    break;
                    
                case MHBracketDynamicallyDeterminedOrientation:
                    // this would be the case of an absolute value sign. Ignoring it for now.
                    if (bracketType != MHBracketTypeVerticalBar) {
                        // the only bracket with a dynamically determined orientation that we recognize is a vertical bar, which is interpreted as an absolute value left/right delimiter. If we see any other type, declare the formula ill-posed
                        return nil;
                    }
                    break;
                case MHBracketMiddleOrientation:
                    // this should never happen. if we see a middle bracket, we declare the formula ill-formed.
                    return nil;
                    break;
            }
        }
        else if ([subexp isKindOfClass:[MHFraction class]]) {
            // a fraction can only appear at the beginning of the formula, or following a binary operator or a left bracket. Otherwise we ignore it
            
            ConditionallyInsertImplicitMultiplicationOperator();

            if (previousTokenType == MHMathFormulaParserTokenNone
                || previousTokenType == MHMathFormulaParserTokenBinaryOperator
                || previousTokenType == MHMathFormulaParserTokenLeftBracket) {

                previousTokenType = MHMathFormulaParserTokenFraction;

                MHExpression *numerator = ((MHFraction *)subexp).numerator;
                MHExpression *denominator = ((MHFraction *)subexp).denominator;

                // very clunky workaround to ensure that the numerator and denominator can be treated as MHHorizontalLayoutContainer instances, which is unfortunately necessary at this point for the formula parser design to work
                // FIXME: IMPROVE so that this isn't necessary
                MHHorizontalLayoutContainer *horizontalLayoutNumeratorWrapper;
                MHHorizontalLayoutContainer *horizontalLayoutDenominatorWrapper;
                if ([numerator isKindOfClass:[MHHorizontalLayoutContainer class]]) {
                    horizontalLayoutNumeratorWrapper = (MHHorizontalLayoutContainer *)numerator;
                }
                else {
                    horizontalLayoutNumeratorWrapper = [[MHHorizontalLayoutContainer alloc] init];
                    [horizontalLayoutNumeratorWrapper addSubexpression:[numerator logicalCopy]];
                }
                if ([denominator isKindOfClass:[MHHorizontalLayoutContainer class]]) {
                    horizontalLayoutDenominatorWrapper = (MHHorizontalLayoutContainer *)denominator;
                }
                else {
                    horizontalLayoutDenominatorWrapper = [[MHHorizontalLayoutContainer alloc] init];
                    [horizontalLayoutDenominatorWrapper addSubexpression:[denominator logicalCopy]];
                }
                
                NSArray <MHMathFormulaParserToken *> *numeratorPostfixRep = [self postfixRepresentationOfFormula:horizontalLayoutNumeratorWrapper];
                
                if (!numeratorPostfixRep) {
                    // the numerator is an ill-formed formula, so we declare the larger formula containing it ill-formed as well
                    return nil;
                }
                
                NSArray <MHMathFormulaParserToken *> *denominatorPostfixRep = [self postfixRepresentationOfFormula:horizontalLayoutDenominatorWrapper];
                
                if (!denominatorPostfixRep) {
                    // the denominator is an ill-formed formula, so we declare the larger formula containing it ill-formed as well
                    return nil;
                }

                MHMathFormulaParserToken *token = [MHMathFormulaParserToken fractionTokenWithNumerator:numeratorPostfixRep
                                                                                   denominator:denominatorPostfixRep];
                
                [outputListOfTokens addObject:token];
//                NSLog(@"outputting fraction");
            }
        }
        else if ([subexp isKindOfClass:[MHScriptedExpression class]]) {
            // an exponent can only appear at the beginning of the formula, or following a binary operator or a left bracket. Otherwise we ignore it
            
            ConditionallyInsertImplicitMultiplicationOperator();
            
            if (previousTokenType == MHMathFormulaParserTokenNone
                || previousTokenType == MHMathFormulaParserTokenBinaryOperator
                || previousTokenType == MHMathFormulaParserTokenLeftBracket) {

                previousTokenType = MHMathFormulaParserTokenPower;
                
                MHExpression *base = ((MHScriptedExpression *)subexp).body;
                MHExpression *exponent = ((MHScriptedExpression *)subexp).superscript;

                // very clunky workaround to ensure that the base and exponent can be treated as MHHorizontalLayoutContainer instances, which is unfortunately necessary at this point for the formula parser design to work
                // FIXME: IMPROVE so that this isn't necessary
                MHHorizontalLayoutContainer *horizontalLayoutBaseWrapper;
                MHHorizontalLayoutContainer *horizontalLayoutExponentWrapper;
                if ([base isKindOfClass:[MHHorizontalLayoutContainer class]]) {
                    horizontalLayoutBaseWrapper = (MHHorizontalLayoutContainer *)base;
                }
                else {
                    horizontalLayoutBaseWrapper = [[MHHorizontalLayoutContainer alloc] init];
                    [horizontalLayoutBaseWrapper addSubexpression:[base logicalCopy]];
                }
                if ([exponent isKindOfClass:[MHHorizontalLayoutContainer class]]) {
                    horizontalLayoutExponentWrapper = (MHHorizontalLayoutContainer *)exponent;
                }
                else {
                    horizontalLayoutExponentWrapper = [[MHHorizontalLayoutContainer alloc] init];
                    [horizontalLayoutExponentWrapper addSubexpression:[exponent logicalCopy]];
                }

                NSArray <MHMathFormulaParserToken *> *basePostfixRep = [self postfixRepresentationOfFormula:horizontalLayoutBaseWrapper];
                
                if (!basePostfixRep) {
                    // the base is an ill-formed formula, so we declare the larger formula containing it ill-formed as well
                    return nil;
                }

                NSArray <MHMathFormulaParserToken *> *exponentPostfixRep = [self postfixRepresentationOfFormula:horizontalLayoutExponentWrapper];
                
                if (!exponentPostfixRep) {
                    // the exponent is an ill-formed formula, so we declare the larger formula containing it ill-formed as well
                    return nil;
                }

                MHMathFormulaParserToken *token = [MHMathFormulaParserToken powerTokenWithBase:basePostfixRep exponent:exponentPostfixRep];
                
                [outputListOfTokens addObject:token];
//                NSLog(@"outputting exponent");
            }
        }
        else if ([subexp isKindOfClass:[MHRadical class]]) {
            // a square root
            
            ConditionallyInsertImplicitMultiplicationOperator();
            
            // a square root can only appear at the beginning of the formula, or following a binary operator or a left bracket. Otherwise we ignore it
            if (previousTokenType == MHMathFormulaParserTokenNone
                || previousTokenType == MHMathFormulaParserTokenBinaryOperator
                || previousTokenType == MHMathFormulaParserTokenLeftBracket) {
                
                previousTokenType = MHMathFormulaParserTokenSquareRoot;
                
                MHExpression *contents = ((MHRadical *)subexp).contents;

                // very clunky workaround to ensure that the base and exponent can be treated as MHHorizontalLayoutContainer instances, which is unfortunately necessary at this point for the formula parser design to work
                // FIXME: IMPROVE so that this isn't necessary
                MHHorizontalLayoutContainer *horizontalLayoutContentsWrapper;
                if ([contents isKindOfClass:[MHHorizontalLayoutContainer class]]) {
                    horizontalLayoutContentsWrapper = (MHHorizontalLayoutContainer *)contents;
                }
                else {
                    horizontalLayoutContentsWrapper = [[MHHorizontalLayoutContainer alloc] init];
                    [horizontalLayoutContentsWrapper addSubexpression:[contents logicalCopy]];
                }

                NSArray <MHMathFormulaParserToken *> *contentsPostfixRep = [self postfixRepresentationOfFormula:horizontalLayoutContentsWrapper];
                
                if (!contentsPostfixRep) {
                    // the contents of the radical are an ill-formed formula, so we declare the larger formula containing them ill-formed as well
                    return nil;
                }

                MHMathFormulaParserToken *token = [MHMathFormulaParserToken squareRootTokenWithContents:contentsPostfixRep];
                
                [outputListOfTokens addObject:token];
//                NSLog(@"outputting square root");
            }
        }
        else if ([subexp isKindOfClass:[MHWhitespace class]]) {
            // white space is ignored
        }
        else {
            NSLog(@"invalid symbol");
            return nil;
        }
    }
    
    if (previousTokenType == MHMathFormulaParserTokenNone
        || previousTokenType == MHMathFormulaParserTokenBinaryOperator
        || previousTokenType == MHMathFormulaParserTokenFunction) {
        // the formula is empty or ended with a binary operator or a function token - declare it ill-formed
        return nil;
    }
    
    // Now add to the postfix representation any tokens remaining in the operator stack, but there shouldn't be any left bracket tokens, so if we see one we declare the formula ill-formed
    NSUInteger numberOfOperatorsRemainingInStack = operatorStack.count;
    
    for (NSInteger index = numberOfOperatorsRemainingInStack-1; index >= 0; index--) {
        MHMathFormulaParserToken *token = operatorStack[index];
        if (token->type == MHMathFormulaParserTokenLeftBracket) {
            return nil;     // an ill-formed formula
        }
        else {
            [outputListOfTokens addObject:token];
//            NSLog(@"outputting remaining token of type %d", token->type);
        }
    }
    
    // if we reached here, the formula is well-formed! Return the postfix representation
    return [NSArray arrayWithArray:outputListOfTokens];
}




#pragma mark - Evaluating a formula in the postfix representation

- (double)evaluateFormulaWithAuxiliaryData:(void *)data
{
    return [self evaluatePostfixFormula:_formulaInPostfixRepresentation withAuxiliaryData:data];
}

- (double)evaluatePostfixFormula:(NSArray <MHMathFormulaParserToken *> *)postfixFormula withAuxiliaryData:(void *)data
{
    NSMutableArray <MHMathFormulaParserToken *> *postfixTokenList = [postfixFormula mutableCopy];
    NSUInteger numberOfTokens = postfixTokenList.count;
    NSUInteger tokenIndex;
    for (tokenIndex = 0; tokenIndex < numberOfTokens; tokenIndex++) {
        
        MHMathFormulaParserToken *token = postfixTokenList[tokenIndex];

        switch (token->type) {
            case MHMathFormulaParserTokenNumber:
                // no need to do anything to number tokens
                break;
            case MHMathFormulaParserTokenVariableName: {
                // a variable - need to evaluate it numerically and then replace the variable token with a number token
                double numericalValue = [self.dataProvider valueForVariableName:token->variableName auxiliaryData:data];
                MHMathFormulaParserToken *numberToken = [MHMathFormulaParserToken tokenWithNumber:numericalValue];
                [postfixTokenList removeObjectAtIndex:tokenIndex];
                [postfixTokenList insertObject:numberToken atIndex:tokenIndex];
            }
                break;
            case MHMathFormulaParserTokenBinaryOperator: {
                // the operator acts on the previous two values, which we can assume have been evaluated numerically already
                MHMathFormulaParserToken *firstArgument = (tokenIndex >= 2 ? postfixTokenList[tokenIndex-2] : nil);     // rudimentary means of protecting against a crash even in the face of invalid input
                MHMathFormulaParserToken *secondArgument = (tokenIndex >= 1 ? postfixTokenList[tokenIndex-1] : nil);    // rudimentary means of protecting against a crash even in the face of invalid input
                if (!firstArgument) {
                    // a default value of 0 to be used in case a token was missing
                    firstArgument = [MHMathFormulaParserToken tokenWithNumber:0.0];
                }
                if (!secondArgument) {
                    // a default value of 0 to be used in case a token was missing
                    secondArgument = [MHMathFormulaParserToken tokenWithNumber:0.0];
                }
                double firstArgumentNumericalValue = (firstArgument ? firstArgument->numericalValue : 0.0);
                double secondArgumentNumericalValue = (secondArgument ? secondArgument->numericalValue : 0.0);

                double valueOfOperation;
                switch (token->operatorType) {
                    case MHMathFormulaParserBinaryOperatorAddition:
                        valueOfOperation = firstArgumentNumericalValue + secondArgumentNumericalValue;
                        break;
                    case MHMathFormulaParserBinaryOperatorSubtraction:
                        valueOfOperation = firstArgumentNumericalValue - secondArgumentNumericalValue;
                        break;
                    case MHMathFormulaParserBinaryOperatorMultiplication:
                        valueOfOperation = firstArgumentNumericalValue * secondArgumentNumericalValue;
                        break;
                    case MHMathFormulaParserBinaryOperatorDivision:
                        valueOfOperation = (secondArgumentNumericalValue != 0.0
                                            ? firstArgumentNumericalValue / secondArgumentNumericalValue : 0.0);    // FIXME: we don't want to deal with a division by zero at this point, maybe add this later
                        break;
                    default:
                        // this should never happen, but have a value assigned for graceful error handling
                        valueOfOperation = 0.0;
                        break;
                }
                
                // create a new number token to hold the value of the operation
                MHMathFormulaParserToken *newToken = [MHMathFormulaParserToken tokenWithNumber:valueOfOperation];

                // now replace the operator token and the preceding two tokens being acted on with the new token
                [postfixTokenList removeObjectAtIndex:tokenIndex];
                [postfixTokenList insertObject:newToken atIndex:tokenIndex];

                if (tokenIndex >= 1) {
                    [postfixTokenList removeObjectAtIndex:tokenIndex-1];
                    tokenIndex--;
                    numberOfTokens--;
                    if (tokenIndex >= 1) {
                        [postfixTokenList removeObjectAtIndex:tokenIndex-1];
                        tokenIndex--;
                        numberOfTokens--;
                    }
                }
            }
                break;
            case MHMathFormulaParserTokenFunction: {
                // the function acts on the previous value, which we can assume has been evaluated numerically already
                MHMathFormulaParserToken *argument = (tokenIndex >= 1 ? postfixTokenList[tokenIndex-1] : nil);     // rudimentary means of protecting against a crash even in the face of invalid input
                double argumentNumericalValue = argument ? argument->numericalValue : 0.0;
                double valueOfOperation = numericallyEvaluateFunction(token->functionType, argumentNumericalValue);
                
                // create a new token to hold the result of the evaluation
                MHMathFormulaParserToken *newToken = [MHMathFormulaParserToken tokenWithNumber:valueOfOperation];

                // now replace the operator token and the preceding token being acted on with the new token
                [postfixTokenList removeObjectAtIndex:tokenIndex];
                [postfixTokenList insertObject:newToken atIndex:tokenIndex];

                if (tokenIndex >= 1) {
                    [postfixTokenList removeObjectAtIndex:tokenIndex-1];
                    tokenIndex--;
                    numberOfTokens--;
                }
            }
                break;
            case MHMathFormulaParserTokenFraction: {
                // a fraction - need to evaluate it numerically and then replace the fraction token with a number token
                double numeratorValue = [self evaluatePostfixFormula:token->subformula1 withAuxiliaryData:data];
                double denominatorValue = [self evaluatePostfixFormula:token->subformula2 withAuxiliaryData:data];
                double fractionNumericalValue = (denominatorValue == 0.0 ? 0.0 : numeratorValue / denominatorValue);    // FIXME: we don't want to deal with a division by zero at this point, maybe add this later
                MHMathFormulaParserToken *numberToken = [MHMathFormulaParserToken tokenWithNumber:fractionNumericalValue];
                [postfixTokenList removeObjectAtIndex:tokenIndex];
                [postfixTokenList insertObject:numberToken atIndex:tokenIndex];
            }
                break;
            case MHMathFormulaParserTokenPower: {
                // a power - need to evaluate it numerically and then replace the power token with a number token
                double baseValue = [self evaluatePostfixFormula:token->subformula1 withAuxiliaryData:data];
                double exponentValue = [self evaluatePostfixFormula:token->subformula2 withAuxiliaryData:data];
                double powerNumericalValue = pow(baseValue, exponentValue);
                double actualPowerValue = isnan(powerNumericalValue) ? 0.0 : powerNumericalValue;   // FIXME: consider the value as 0 for an invalid value, maybe add error reporting for this case later
                MHMathFormulaParserToken *numberToken = [MHMathFormulaParserToken
                                                         tokenWithNumber:actualPowerValue];
                [postfixTokenList removeObjectAtIndex:tokenIndex];
                [postfixTokenList insertObject:numberToken atIndex:tokenIndex];
            }
                break;
            case MHMathFormulaParserTokenSquareRoot: {
                // a square root - need to evaluate it numerically and then replace the power token with a number token
                double radicalContentsNumericalValue = [self evaluatePostfixFormula:token->subformula1 withAuxiliaryData:data];
                double radicalNumericalValue = (radicalContentsNumericalValue < 0.0 ? 0.0 : sqrt(radicalContentsNumericalValue));   // FIXME: we don't want to deal with what to do about square roots of negative numbers at this point, maybe add better error reporting later
                MHMathFormulaParserToken *numberToken = [MHMathFormulaParserToken tokenWithNumber:radicalNumericalValue];
                [postfixTokenList removeObjectAtIndex:tokenIndex];
                [postfixTokenList insertObject:numberToken atIndex:tokenIndex];
            }
                break;
            case MHMathFormulaParserTokenExponentOfBracketedExpression: {
                // the exponentiation acts on the previous value, which we can assume has been evaluated numerically already
                MHMathFormulaParserToken *base = (tokenIndex >= 1 ? postfixTokenList[tokenIndex-1] : nil);     // rudimentary means of protecting against a crash even in the face of invalid input
                double baseValue = base ? base->numericalValue : 0.0;
                
                if (token->bracketIsAbsoluteValue)
                    baseValue = (baseValue >= 0.0 ? baseValue : -baseValue);
                
                double exponentValue = [self evaluatePostfixFormula:token->subformula2 withAuxiliaryData:data];
                double valueOfOperation = pow(baseValue, exponentValue);
                double actualValueOfOperation = isnan(valueOfOperation) ? 0.0 : valueOfOperation;   // FIXME: consider the value as 0 for an invalid value, maybe add error reporting for this case later
                
                // create a new token to hold the result of the evaluation
                MHMathFormulaParserToken *newToken = [MHMathFormulaParserToken tokenWithNumber:actualValueOfOperation];

                // now replace the operator token and the preceding token being acted on with the new token
                [postfixTokenList removeObjectAtIndex:tokenIndex];
                [postfixTokenList insertObject:newToken atIndex:tokenIndex];

                if (tokenIndex >= 1) {
                    [postfixTokenList removeObjectAtIndex:tokenIndex-1];
                    tokenIndex--;
                    numberOfTokens--;
                }
            }
                break;
            case MHMathFormulaParserTokenAbsoluteValue: {
                // the absolute value acts on the previous value, which we can assume has been evaluated numerically already
                MHMathFormulaParserToken *previousToken = (tokenIndex >= 1 ? postfixTokenList[tokenIndex-1] : nil);     // rudimentary means of protecting against a crash even in the face of invalid input
                double previousValue = previousToken ? previousToken->numericalValue : 0.0;
                double absoluteValueOfPreviousValue = (previousValue >= 0.0 ? previousValue : -previousValue);
                
                // create a new token to hold the result of the evaluation
                MHMathFormulaParserToken *newToken = [MHMathFormulaParserToken tokenWithNumber:absoluteValueOfPreviousValue];

                // now replace the operator token and the preceding token being acted on with the new token
                [postfixTokenList removeObjectAtIndex:tokenIndex];
                [postfixTokenList insertObject:newToken atIndex:tokenIndex];

                if (tokenIndex >= 1) {
                    [postfixTokenList removeObjectAtIndex:tokenIndex-1];
                    tokenIndex--;
                    numberOfTokens--;
                }
            }
                break;
            default:
//            case MHMathFormulaParserTokenLeftBracket:
//            case MHMathFormulaParserTokenRightBracket:
//            case MHMathFormulaParserTokenNone:
                // these cases never show up since such tokens are never output as part of the postfix token list
                break;
        }
    }
    
    // if all went well, we are left with exactly one token, which has been evaluated numerically and contains the answer
    if (numberOfTokens == 1) {
        MHMathFormulaParserToken *finalToken = postfixTokenList[0];
        if (finalToken->type == MHMathFormulaParserTokenNumber)
            return finalToken->numericalValue;

        NSLog(@"error: invalid code point");    // we should never end up here
        return 0.0;
    }
    
    if (numberOfTokens == 0)
        return 0.0;
    
//    NSLog(@"error: evaluation was not successful");
    return 0.0;
}


@end









@implementation MHMathFormulaParserToken : NSObject

+ (instancetype)tokenWithNumber:(double)aNumber
{
    MHMathFormulaParserToken *token = [[self alloc] init];
    token->type = MHMathFormulaParserTokenNumber;
    token->numericalValue = aNumber;
    return token;
}

+ (instancetype)tokenWithVariableName:(NSString *)variableName
{
    MHMathFormulaParserToken *token = [[self alloc] init];
    token->type = MHMathFormulaParserTokenVariableName;
    token->variableName = variableName;
    return token;
}

+ (instancetype)tokenWithBinaryOperator:(MHMathFormulaParserBinaryOperatorType)operator
{
    MHMathFormulaParserToken *token = [[self alloc] init];
    token->type = MHMathFormulaParserTokenBinaryOperator;
    token->operatorType = operator;
    return token;
}

+ (instancetype)tokenWithLeftBracket
{
    MHMathFormulaParserToken *token = [[self alloc] init];
    token->type = MHMathFormulaParserTokenLeftBracket;
    return token;
}

+ (instancetype)tokenWithRightBracket
{
    MHMathFormulaParserToken *token = [[self alloc] init];
    token->type = MHMathFormulaParserTokenRightBracket;
    return token;
}

+ (instancetype)fractionTokenWithNumerator:(NSArray <MHMathFormulaParserToken *> *)numerator
                               denominator:(NSArray <MHMathFormulaParserToken *> *)denominator
{
    MHMathFormulaParserToken *token = [[self alloc] init];
    token->type = MHMathFormulaParserTokenFraction;
    token->subformula1 = numerator;
    token->subformula2 = denominator;
    return token;
}

+ (instancetype)powerTokenWithBase:(NSArray <MHMathFormulaParserToken *> *)base
                          exponent:(NSArray <MHMathFormulaParserToken *> *)exponent
{
    MHMathFormulaParserToken *token = [[self alloc] init];
    token->type = MHMathFormulaParserTokenPower;
    token->subformula1 = base;
    token->subformula2 = exponent;
    return token;
}

+ (instancetype)squareRootTokenWithContents:(NSArray <MHMathFormulaParserToken *> *)contents
{
    MHMathFormulaParserToken *token = [[self alloc] init];
    token->type = MHMathFormulaParserTokenSquareRoot;
    token->subformula1 = contents;
    return token;
}

+ (instancetype)tokenWithExponentOfBracketedExpression:(NSArray <MHMathFormulaParserToken *> *)exponent
{
    MHMathFormulaParserToken *token = [[self alloc] init];
    token->type = MHMathFormulaParserTokenExponentOfBracketedExpression;
    token->subformula2 = exponent;
    return token;
}


+ (instancetype)tokenWithFunction:(MHMathFormulaParserFunctionType)functionType
{
    MHMathFormulaParserToken *token = [[self alloc] init];
    token->type = MHMathFormulaParserTokenFunction;
    token->functionType = functionType;
    return token;
}

+ (instancetype)absoluteValueToken
{
    MHMathFormulaParserToken *token = [[self alloc] init];
    token->type = MHMathFormulaParserTokenAbsoluteValue;
    return token;
}

@end








// some useful auxiliary C functions

static MHMathFormulaParserBinaryOperatorType binaryOperatorFromExpression(MHExpression *expression) {
    NSString *expressionString = [expression stringValue];
    if (expressionString.length != 1)
        return MHMathFormulaParserBinaryOperatorUnknown;
    unichar expressionChar = [expressionString characterAtIndex:0];
    if (expressionChar == kMHParserCharPlusSign)
        return MHMathFormulaParserBinaryOperatorAddition;
    if (expressionChar == kMHParserCharMinusSign)
        return MHMathFormulaParserBinaryOperatorSubtraction;
    if (expressionChar == kMHParserCharMinusSign)
        return MHMathFormulaParserBinaryOperatorSubtraction;
    if (expressionChar == kMHParserCharMultiplicationSymbol
        || expressionChar == kMHParserCharCenterDot || expressionChar == kMHParserCharCenterDot
        || expressionChar == kMHParserCharAsterisk || expressionChar == kMHParserCharAsteriskOperator)
        return MHMathFormulaParserBinaryOperatorMultiplication;
    if (expressionChar == '/')
        return MHMathFormulaParserBinaryOperatorDivision;

    return MHMathFormulaParserBinaryOperatorUnknown;
}

static NSComparisonResult comparePrecedenceOfBinaryOperators(MHMathFormulaParserBinaryOperatorType firstOperator,
                                                      MHMathFormulaParserBinaryOperatorType secondOperator)
{
    bool firstOpIsAdditionOrSubtraction = (firstOperator == MHMathFormulaParserBinaryOperatorAddition
                                           || firstOperator == MHMathFormulaParserBinaryOperatorSubtraction);
    bool secondOpIsAdditionOrSubtraction = (secondOperator == MHMathFormulaParserBinaryOperatorAddition
                                           || secondOperator == MHMathFormulaParserBinaryOperatorSubtraction);
    if (firstOpIsAdditionOrSubtraction) {
        return (secondOpIsAdditionOrSubtraction ? NSOrderedSame : NSOrderedAscending);
    }
    return (secondOpIsAdditionOrSubtraction ? NSOrderedDescending : NSOrderedSame);
}

static MHMathFormulaParserFunctionType functionTypeForSymbolName(NSString *symbolName)
{
    static NSDictionary *recognizedFunctions = nil;
    
    if (!recognizedFunctions) {
        // instantiate the dictionary in a lazy way - this should run just once
        recognizedFunctions = @{
            @"exp" : [NSNumber numberWithInteger:MHMathFormulaParserFunctionExp],
            @"log" : [NSNumber numberWithInteger:MHMathFormulaParserFunctionLog],
            @"ln" : [NSNumber numberWithInteger:MHMathFormulaParserFunctionLog],
            @"sin" : [NSNumber numberWithInteger:MHMathFormulaParserFunctionSine],
            @"cos" : [NSNumber numberWithInteger:MHMathFormulaParserFunctionCosine],
            @"tan" : [NSNumber numberWithInteger:MHMathFormulaParserFunctionTangent],
            @"arcsin" : [NSNumber numberWithInteger:MHMathFormulaParserFunctionArcsine],
            @"arccos" : [NSNumber numberWithInteger:MHMathFormulaParserFunctionArccosine],
            @"arctan" : [NSNumber numberWithInteger:MHMathFormulaParserFunctionArctangent],
        };
    }
    
    NSNumber *encodedFunctionType = recognizedFunctions[symbolName];
    if (encodedFunctionType) {
        return (MHMathFormulaParserFunctionType)[encodedFunctionType integerValue];
    }

    return MHMathFormulaParserFunctionUnknown;
}

static double numericallyEvaluateFunction(MHMathFormulaParserFunctionType functionType, double argument)
{
    double evaluationResult;
    switch (functionType) {
        case MHMathFormulaParserFunctionExp:
            evaluationResult = exp(argument);
            break;
        case MHMathFormulaParserFunctionLog:
            evaluationResult = log(argument);
            break;
        case MHMathFormulaParserFunctionSine:
            evaluationResult = sin(argument);
            break;
        case MHMathFormulaParserFunctionCosine:
            evaluationResult = cos(argument);
            break;
        case MHMathFormulaParserFunctionTangent:
            evaluationResult = tan(argument);
            break;
        case MHMathFormulaParserFunctionArcsine:
            evaluationResult = asin(argument);
            break;
        case MHMathFormulaParserFunctionArccosine:
            evaluationResult = acos(argument);
            break;
        case MHMathFormulaParserFunctionArctangent:
            evaluationResult = atan(argument);
            break;
        default:
            evaluationResult = 0.0;
            break;
    }
    return isnan(evaluationResult) ? 0.0 : evaluationResult;   // FIXME: an invalid result is returned as 0.0, which means that errors are ignored - consider finding a way to indicate that the function cannot be evaluated at this point
}

