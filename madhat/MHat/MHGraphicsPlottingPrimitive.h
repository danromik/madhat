//
//  MHGraphicsPlottingPrimitive.h
//  MadHat
//
//  Created by Dan Romik on 9/2/21.
//  Copyright © 2021 Dan Romik. All rights reserved.
//

#import "MHGraphicsPrimitive.h"
#import "MHCommand.h"
#import "MHMathFormulaParser.h"




typedef struct {
    double minValue;
    double maxValue;
} MHPlottingRange;


NS_ASSUME_NONNULL_BEGIN

@interface MHGraphicsPlottingPrimitive : MHGraphicsPrimitive <MHCommand, MHMathFormulaParserDataProvider>

+ (instancetype)plotGraphicsWithFormula:(MHHorizontalLayoutContainer *)formula
                       plotVariableName:(NSString *)variableName
                              plotRange:(MHPlottingRange)range
                             parameters:(NSDictionary <NSString *, NSNumber *> *)parameters;

+ (instancetype)parametricPlotGraphicsWithXFormula:(MHHorizontalLayoutContainer *)XFormula
                                          YFormula:(MHHorizontalLayoutContainer *)YFormula
                                  plotVariableName:(NSString *)variableName
                                     variableRange:(MHPlottingRange)range
                                        parameters:(NSDictionary <NSString *, NSNumber *> *)parameters;

+ (instancetype)polarPlotGraphicsWithFormula:(MHHorizontalLayoutContainer *)formula
                           angleVariableName:(NSString *)variableName
                               variableRange:(MHPlottingRange)range
                                  parameters:(NSDictionary <NSString *, NSNumber *> *)parameters;



@end

NS_ASSUME_NONNULL_END
