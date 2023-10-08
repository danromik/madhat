//
//  MHGraphicsPlottingPrimitive.m
//  MadHat
//
//  Created by Dan Romik on 9/2/21.
//  Copyright © 2021 Dan Romik. All rights reserved.
//

#import "MHGraphicsPlottingPrimitive.h"


static NSString * const kMHGraphicsCommandPlotName = @"plot";
static NSString * const kMHGraphicsCommandParametricPlotName = @"parametric plot";
static NSString * const kMHGraphicsCommandPolarPlotName = @"polar plot";


static NSString * const kMHGraphicsPlottingRangeAttributeName = @"plot range";

typedef enum {
    MHGraphicsPlottingPrimitiveRegularPlot,
    MHGraphicsPlottingPrimitivePolarPlot,
    MHGraphicsPlottingPrimitiveParametricPlot
} MHGraphicsPlottingPrimitiveSubtype;


@interface MHGraphicsPlottingPrimitive ()
{
    MHGraphicsPlottingPrimitiveSubtype _subtype;
    NSString *_plotVariableName;
    MHHorizontalLayoutContainer *_mainFormula;
    MHHorizontalLayoutContainer *_secondFormula;
    MHMathFormulaParser *_mainFormulaParser;
    MHMathFormulaParser *_secondFormulaParser;
    MHMathFormulaValidityType _mainFormulaValidity;
    MHMathFormulaValidityType _secondFormulaValidity;
    NSDictionary *_parametersDict;
}

@property (readonly) MHPlottingRange plottingVariableRange;
- (MHPlottingRange)plottingVariableRangeForPrimitiveSpecificData:(NSDictionary *)primitiveSpecificData; // used during animations

@end


@implementation MHGraphicsPlottingPrimitive

+ (instancetype)plotGraphicsWithFormula:(MHHorizontalLayoutContainer *)formula
                       plotVariableName:(NSString *)variableName
                              plotRange:(MHPlottingRange)range
                             parameters:(NSDictionary <NSString *, NSNumber *> *)parameters
{
    return [[self alloc] initWithPlotSubtype:MHGraphicsPlottingPrimitiveRegularPlot
                                firstFormula:formula
                               secondFormula:nil
                            plotVariableName:variableName
                                   plotRange:range
                                  parameters:parameters];
}

+ (instancetype)parametricPlotGraphicsWithXFormula:(MHHorizontalLayoutContainer *)XFormula
                                          YFormula:(MHHorizontalLayoutContainer *)YFormula
                                  plotVariableName:(NSString *)variableName
                                     variableRange:(MHPlottingRange)range
                                        parameters:(NSDictionary <NSString *, NSNumber *> *)parameters
{
    return [[self alloc] initWithPlotSubtype:MHGraphicsPlottingPrimitiveParametricPlot
                                firstFormula:XFormula
                               secondFormula:YFormula
                            plotVariableName:variableName
                                   plotRange:range
                                  parameters:parameters];

}

+ (instancetype)polarPlotGraphicsWithFormula:(MHHorizontalLayoutContainer *)formula
                           angleVariableName:(NSString *)variableName
                               variableRange:(MHPlottingRange)range
                                  parameters:(NSDictionary <NSString *, NSNumber *> *)parameters
{
    return [[self alloc] initWithPlotSubtype:MHGraphicsPlottingPrimitivePolarPlot
                                firstFormula:formula
                               secondFormula:nil
                            plotVariableName:variableName
                                   plotRange:range
                                  parameters:parameters];
}


- (instancetype)initWithPlotSubtype:(MHGraphicsPlottingPrimitiveSubtype)subtype
                       firstFormula:(MHHorizontalLayoutContainer *)firstFormula
                      secondFormula:(nullable MHHorizontalLayoutContainer *)secondFormula
               plotVariableName:(NSString *)variableName
                      plotRange:(MHPlottingRange)range
                     parameters:(NSDictionary <NSString *, NSNumber *> *)parameters
{
    if (self = [super init]) {
        _type = MHGraphicsPrimitivePlotSubprimitive;
        _subtype = subtype;
        _drawingMode = kCGPathStroke;
        _path = CGPathCreateMutable();
        
        _mainFormula = firstFormula;
        _secondFormula = secondFormula;
        
        _plotVariableName = variableName;
        
        NSMutableDictionary *parametersDictWithWrappedValues = [[NSMutableDictionary alloc] initWithCapacity:0];
        for (NSString *parameterName in parameters) {
            NSNumber *parameterValue = parameters[parameterName];
            [parametersDictWithWrappedValues setObject:@[ parameterValue ] forKey:parameterName];
        }
        
        // the plotting range is stored in the _primitiveSpecificData dictionary so it can be animated
        parametersDictWithWrappedValues[kMHGraphicsPlottingRangeAttributeName] = @[
            [NSNumber numberWithDouble:range.minValue], [NSNumber numberWithDouble:range.maxValue]
        ];
        
        _primitiveSpecificData = [NSDictionary dictionaryWithDictionary:parametersDictWithWrappedValues];
        _primitiveSpecificDataForInitialState = _primitiveSpecificData;
        
        _mainFormulaParser = [MHMathFormulaParser formulaParserWithFormula:_mainFormula];
        _mainFormulaParser.dataProvider = self;
        _mainFormulaValidity = _mainFormulaParser.validity;

        if (_subtype == MHGraphicsPlottingPrimitiveParametricPlot) {
            _secondFormulaParser = [MHMathFormulaParser formulaParserWithFormula:_secondFormula];
            _secondFormulaParser.dataProvider = self;
            _secondFormulaValidity = _secondFormulaParser.validity;
        }
    }
    return self;
}


#pragma mark - Graphics drawing

- (void)createGraphicsWithPrimitiveSpecificData:(NSDictionary *)primitiveSpecificData
{
    static const NSUInteger numberOfPlotPoints = 800;   // FIXME: make this customizable
    
    _parametersDict = primitiveSpecificData;    // this is used in the -valueForVariableName:auxiliaryData: method call to look up parameter values

    if (_path)
        CGPathRelease(_path);
    _path = CGPathCreateMutable();
    
    if (_mainFormulaValidity == MHMathFormulaValidityIllFormed
        || ((_subtype == MHGraphicsPlottingPrimitiveParametricPlot) && (_secondFormulaValidity == MHMathFormulaValidityIllFormed))) {
        // at least one of the formulas we need for the plot is ill-formed
        
        // draw an annoying "X" graphic to give a visual cue to the reader that there's something wrong with the plot
        static const CGFloat alpha = 0.4;
        CGPathMoveToPoint(_path, nil, (1-alpha)*_viewRectangle.minX+alpha*_viewRectangle.maxX,
                          (1-alpha)*_viewRectangle.minY+alpha*_viewRectangle.maxY);
        CGPathAddLineToPoint(_path, nil, alpha*_viewRectangle.minX+(1-alpha)*_viewRectangle.maxX,
                             alpha*_viewRectangle.minY+(1-alpha)*_viewRectangle.maxY);

        CGPathMoveToPoint(_path, nil, (1-alpha)*_viewRectangle.minX+alpha*_viewRectangle.maxX,
                          alpha*_viewRectangle.minY+(1-alpha)*_viewRectangle.maxY);
        CGPathAddLineToPoint(_path, nil, alpha*_viewRectangle.minX+(1-alpha)*_viewRectangle.maxX,
                             (1-alpha)*_viewRectangle.minY+alpha*_viewRectangle.maxY);

        // set some default parameters for drawing the error image
        _strokeColor = [NSColor redColor];
        _lineThickness = 2.0;
    }
    else {
        // the relevant formulas are well-formed, so draw the actual plot
    
        MHPlottingRange myRange = [self plottingVariableRangeForPrimitiveSpecificData:primitiveSpecificData];
        double plotParameterIncrement = (myRange.maxValue - myRange.minValue) / (numberOfPlotPoints-1);
        
        for (NSUInteger plotPointIndex = 0; plotPointIndex < numberOfPlotPoints; plotPointIndex++) {
            double plotParameterValue = myRange.minValue + plotPointIndex * plotParameterIncrement;
            double firstFormulaValue = [_mainFormulaParser evaluateFormulaWithAuxiliaryData:&plotParameterValue];
            double secondFormulaValue = [_secondFormulaParser evaluateFormulaWithAuxiliaryData:&plotParameterValue];
            
            double plotXValue, plotYValue;
            switch (_subtype) {
                case MHGraphicsPlottingPrimitiveRegularPlot:
                    plotXValue = plotParameterValue;
                    plotYValue = firstFormulaValue;
                    break;
                case MHGraphicsPlottingPrimitivePolarPlot:
                    plotXValue = firstFormulaValue * cos(plotParameterValue);
                    plotYValue = firstFormulaValue * sin(plotParameterValue);
                    break;
                case MHGraphicsPlottingPrimitiveParametricPlot:
                    plotXValue = firstFormulaValue;
                    plotYValue = secondFormulaValue;
                    break;
            }
            
            if (plotPointIndex == 0)
                CGPathMoveToPoint(_path, nil, plotXValue, plotYValue);
            else
                CGPathAddLineToPoint(_path, nil, plotXValue, plotYValue);
        }
    }
    
    _parametersDict = nil;
    
    [super createGraphicsWithPrimitiveSpecificData:primitiveSpecificData];
}



#pragma mark - MHCommand protocol

+ (NSArray <NSString *> *)recognizedCommands
{
    return @[ kMHGraphicsCommandPlotName, kMHGraphicsCommandParametricPlotName, kMHGraphicsCommandPolarPlotName ];
}

+ (MHExpression *)commandNamed:(NSString *)name
                withParameters:(nullable NSDictionary *)parameters
                      argument:(MHHorizontalLayoutContainer *)argument
{
    bool isRegularPlot = false;
    bool isPolarPlot = false;
    bool isParametricPlot = false;
    if ((isRegularPlot = [name isEqualToString:kMHGraphicsCommandPlotName])
        || (isPolarPlot = [name isEqualToString:kMHGraphicsCommandPolarPlotName])
        || (isParametricPlot = [name isEqualToString:kMHGraphicsCommandParametricPlotName])) {

        MHPlottingRange defaultPlotRange;
        MHPlottingRange plotRange;
        defaultPlotRange.minValue = 0.0;
        defaultPlotRange.maxValue = ((isRegularPlot || isParametricPlot) ? 1.0 : 2.0*M_PI);
        plotRange.minValue = defaultPlotRange.minValue;
        plotRange.maxValue = defaultPlotRange.maxValue;
        NSString *varName = (isRegularPlot ? @"x" : (isPolarPlot ? @"θ" : @"t"));       // the default symbol for a plotting variable - x for a normal plot, θ for a polar plot, t for a parametric plot
        MHHorizontalLayoutContainer *firstFormula;
        MHHorizontalLayoutContainer *secondFormula;
        
        NSUInteger numberOfBlocks = [argument numberOfDelimitedBlocks];

        if (numberOfBlocks <= 1 && isParametricPlot) {
            return nil;         // a parametric plot requires at least two arguments for the formulas for the x and y coordinates
        }
        else {
            if (isRegularPlot || isPolarPlot) {
                // the argument syntax for a regular plot and a polar plot is the same

                if (numberOfBlocks <= 1) {
                    firstFormula = argument;
                }
                else {
                    firstFormula = (MHHorizontalLayoutContainer *)[argument expressionFromDelimitedBlockAtIndex:0]; // FIXME: casting is bad - improve to remove assumptions
                    MHExpression *plotVariableSpecificationExpression = [argument expressionFromDelimitedBlockAtIndex:1];
                    NSString *plotVariableSpecificationString = [plotVariableSpecificationExpression stringValue];
                    NSArray <NSString *> *plotVariableSpecificationComponents = [plotVariableSpecificationString
                                                                                 componentsSeparatedByString:@"<"];
                    NSUInteger numberOfComponents = plotVariableSpecificationComponents.count;
                    if (numberOfComponents == 1) {
                        // if there is only one component, we use that as the variable name, and use the default values for the variable plotting range
                        varName = [plotVariableSpecificationString
                                   stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                    }
                    else if (numberOfComponents >= 3) {
                        // if there are three components, similar to "3 < z < 7", we use the middle component as the variable name, and the first and third component for the range min and max values. (Any components after the third are ignored.)

                        varName = [plotVariableSpecificationComponents[1]
                                   stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                        plotRange.minValue = [plotVariableSpecificationComponents[0] floatValue];
                        plotRange.maxValue = [plotVariableSpecificationComponents[2] floatValue];
                        
                        // if the max value is not greater than the min, that's an error, so revert to the default values
                        if (plotRange.minValue >= plotRange.maxValue) {
                            plotRange.minValue = defaultPlotRange.minValue;
                            plotRange.maxValue = defaultPlotRange.maxValue;
                        }
                    }
                    else {
                        // there are two components, so there's no canonical way to interpret what the user is asking. We'll use the first component for the variable name, and try to use the second component for the max value of the range, keeping the min at its default value, if the given max value is positive, otherwise revert to the default values
                        varName = [plotVariableSpecificationComponents[0]
                                   stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                        plotRange.maxValue = [plotVariableSpecificationComponents[1] floatValue];
                        if (plotRange.minValue >= plotRange.maxValue) {
                            plotRange.minValue = defaultPlotRange.minValue;
                            plotRange.maxValue = defaultPlotRange.maxValue;
                        }
                    }
                }
            }
            else {
                // a parametric plot - parse the arguments
                if (numberOfBlocks == 2) {
                    // FIXME: casting is bad - improve to remove assumptions
                    firstFormula = (MHHorizontalLayoutContainer *)[argument expressionFromDelimitedBlockAtIndex:0];
                    secondFormula = (MHHorizontalLayoutContainer *)[argument expressionFromDelimitedBlockAtIndex:1];
                    
                    // since a third argument is missing, we proceed with the default values for the variable name and range
                }
                else {  // if we got here, there are at least three argument blocks
                    
                    // FIXME: casting is bad - improve to remove assumptions
                    firstFormula = (MHHorizontalLayoutContainer *)[argument expressionFromDelimitedBlockAtIndex:0];
                    secondFormula = (MHHorizontalLayoutContainer *)[argument expressionFromDelimitedBlockAtIndex:1];
                    
                    MHExpression *plotVariableSpecificationExpression = [argument expressionFromDelimitedBlockAtIndex:2];
                    NSString *plotVariableSpecificationString = [plotVariableSpecificationExpression stringValue];
                    NSArray <NSString *> *plotVariableSpecificationComponents = [plotVariableSpecificationString
                                                                                 componentsSeparatedByString:@"<"];
                    NSUInteger numberOfComponents = plotVariableSpecificationComponents.count;
                    if (numberOfComponents == 1) {
                        // if there is only one component, we use that as the variable name, and use the default values for the variable plotting range
                        varName = [plotVariableSpecificationString
                                   stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                    }
                    else if (numberOfComponents >= 3) {
                        // if there are three components, similar to "3 < z < 7", we use the middle component as the variable name, and the first and third component for the range min and max values. (Any components after the third are ignored.)

                        varName = [plotVariableSpecificationComponents[1]
                                   stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                        plotRange.minValue = [plotVariableSpecificationComponents[0] floatValue];
                        plotRange.maxValue = [plotVariableSpecificationComponents[2] floatValue];
                        
                        // if the max value is not greater than the min, that's an error, so revert to the default values
                        if (plotRange.minValue >= plotRange.maxValue) {
                            plotRange.minValue = defaultPlotRange.minValue;
                            plotRange.maxValue = defaultPlotRange.maxValue;
                        }
                    }
                    else {
                        // there are two components, so there's no canonical way to interpret what the user is asking. We'll use the first component for the variable name, and try to use the second component for the max value of the range, keeping the min at its default value, if the given max value is positive, otherwise revert to the default values
                        varName = [plotVariableSpecificationComponents[0]
                                   stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                        plotRange.maxValue = [plotVariableSpecificationComponents[1] floatValue];
                        if (plotRange.minValue >= plotRange.maxValue) {
                            plotRange.minValue = defaultPlotRange.minValue;
                            plotRange.maxValue = defaultPlotRange.maxValue;
                        }
                    }
                }
            }
        }
        
        // if there are any parameters that were passed along as attributes, process them
        NSDictionary <NSString *, NSNumber *> *parametersDict;
        NSDictionary <NSString *, MHExpression *> *attributes = argument.attributes;
        if (attributes) {
            // create a parameter dictionary
            NSMutableDictionary *mutableDict = [[NSMutableDictionary alloc] initWithCapacity:0];
            for (NSString *attributeName in attributes) {
                MHExpression *attributeValueExpression = attributes[attributeName];
                double attributeNumericalValue = [attributeValueExpression floatValue];
                [mutableDict setObject:[NSNumber numberWithDouble:attributeNumericalValue] forKey:attributeName];
                parametersDict = [NSDictionary dictionaryWithDictionary:mutableDict];
            }
        }
        
        if (isRegularPlot)
            return [self plotGraphicsWithFormula:firstFormula plotVariableName:varName plotRange:plotRange parameters:parametersDict];
        
        if (isPolarPlot)
            return [self polarPlotGraphicsWithFormula:firstFormula
                                    angleVariableName:varName
                                        variableRange:plotRange
                                           parameters:parametersDict];
        
        if (isParametricPlot)   // the only remaining case
            return [self parametricPlotGraphicsWithXFormula:firstFormula
                                                   YFormula:secondFormula
                                           plotVariableName:varName
                                              variableRange:plotRange
                                                 parameters:parameters];

        
        // this should never run, but if we end up here for some weird reason, do something
        return nil;
    }

    return nil;
}

#pragma mark - Properties

- (MHPlottingRange)plottingVariableRange
{
    return [self plottingVariableRangeForPrimitiveSpecificData:_primitiveSpecificData];
}

- (MHPlottingRange)plottingVariableRangeForPrimitiveSpecificData:(NSDictionary *)primitiveSpecificData
{
    MHPlottingRange range;
    NSArray <NSNumber *> *plottingRangeValues = primitiveSpecificData[kMHGraphicsPlottingRangeAttributeName];
    NSUInteger numberOfValues = plottingRangeValues.count;
    if (numberOfValues >= 1) {
        NSNumber *minValueNumber = plottingRangeValues[0];
        range.minValue = [minValueNumber doubleValue];
    }
    else {
        range.minValue = 0.0;
    }
    
    if (numberOfValues >= 2) {
        NSNumber *maxValueNumber = plottingRangeValues[1];
        range.maxValue = [maxValueNumber doubleValue];
    }
    else {
        range.maxValue = 1.0;
    }
    return range;
}


#pragma mark - MHMathFormulaParserDataProvider protocol

- (double)valueForVariableName:(NSString *)variableName auxiliaryData:(nullable void *)data
{
    if ([variableName isEqualToString:_plotVariableName])
        return *((double *)data);
    
    if ([variableName isEqualToString:@"π"])
        return M_PI;
    
    if ([variableName isEqualToString:@"e"])
        return M_E;
    
    // check if the variable name is in our parameters dictionary
    NSArray <NSNumber *> *parameterContainer = _parametersDict[variableName];
    if (parameterContainer) {
        NSNumber *parameterNumber = parameterContainer[0];
        return [parameterNumber doubleValue];
    }

    return 0.0; // FIXME: maybe add handling for what to do with unknown variable names later on
}


#pragma mark - Expression copying

- (instancetype)logicalCopy
{
    NSMutableDictionary *parametersDictWithUnwrappedValues = [[NSMutableDictionary alloc] initWithCapacity:0];
    for (NSString *parameterName in _primitiveSpecificData) {
        NSArray <NSNumber *> *wrappedParameterValue = _primitiveSpecificData[parameterName];
        [parametersDictWithUnwrappedValues setObject:wrappedParameterValue[0] forKey:parameterName];
    }
    
    MHGraphicsPlottingPrimitive *myCopy = [[[self class] alloc]
                                           initWithPlotSubtype:_subtype
                                           firstFormula:[_mainFormula logicalCopy]
                                           secondFormula:[_secondFormula logicalCopy]
                                           plotVariableName:[_plotVariableName copy]
                                           plotRange:self.plottingVariableRange
                                           parameters:[NSDictionary dictionaryWithDictionary:parametersDictWithUnwrappedValues]];

    myCopy.codeRange = self.codeRange;
    return myCopy;
}


@end
