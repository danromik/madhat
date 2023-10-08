//
//  MHProfiler.m
//  MadHat
//
//  Created by Dan Romik on 7/29/20.
//  Copyright © 2020 Dan Romik. All rights reserved.
//

#import <objc/runtime.h>

#import "MHProfiler.h"
#import "MHExpression.h"
#import "MHCommand.h"

static MHProfiler *MHProfilerSingletonObject;



@implementation MHProfiler

+ (instancetype)defaultProfiler
{
    if (!MHProfilerSingletonObject) {
        MHProfilerSingletonObject = [[MHProfiler alloc] init];
    }
    return MHProfilerSingletonObject;
}

- (void)parseExpressionSubclassesTree
{
    // Code adapted from https://www.cocoawithlove.com/2010/01/getting-subclasses-of-objective-c-class.html
    
    Class parentClass = [MHExpression class];

    int numClasses = objc_getClassList(NULL, 0);
    Class *classes = NULL;
    
    classes = (__unsafe_unretained Class *)malloc(sizeof(Class) * numClasses);
    numClasses = objc_getClassList(classes, numClasses);

    NSMutableArray *expressionClasses = [NSMutableArray array];
    NSUInteger depth;
    NSUInteger rootIndex = 0;
    for (NSInteger i = 0; i < numClasses; i++) {
        Class superClass = classes[i];
        depth = 0;
        while(superClass && superClass != parentClass) {
            superClass = class_getSuperclass(superClass);
            depth++;
        }
        if (superClass != nil) {
//            NSLog(@"found class %@, depth=%ld", classes[i], depth);
            if ([[classes[i] className] isEqualToString:@"MHExpression"]) {
                rootIndex = expressionClasses.count;
            }
            [expressionClasses addObject:@{ @"class" : classes[i], @"depth" : [NSNumber numberWithUnsignedLong:depth] }];
        }
    }
    free(classes);
    
//    NSString *parsedTreeString = [self stringOutlineOfSubclassesOfClassAtIndex:rootIndex usingClassDictsArray:expressionClasses];
//    NSLog(@"parsed string = %@", parsedTreeString);
    
    
    NSMutableString *string = [[NSMutableString alloc] initWithCapacity:0];
    NSUInteger totalNumberOfCommands = 0;

    [string appendString:@"\nList of MHExpression subclasses that handle user commands:\n\
----------------------------------------------------------\n"];
    for (NSDictionary *classDict in expressionClasses) {
        Class expressionClass = classDict[@"class"];
        Class expressionClassSuperclass = [expressionClass superclass];
        
        // Related stack overflow discussion:
        // https://stackoverflow.com/questions/17147203/objective-c-detect-if-class-overrides-inherited-method/19276997#19276997
        if ([expressionClass conformsToProtocol:@protocol(MHCommand)]) {
            if (![expressionClassSuperclass conformsToProtocol:@protocol(MHCommand)]
                    || [expressionClass methodForSelector:@selector(recognizedCommands)] !=
                    [expressionClassSuperclass methodForSelector:@selector(recognizedCommands)]) {
                NSArray *commands = [expressionClass recognizedCommands];
                NSUInteger numberOfCommands = commands.count;
                totalNumberOfCommands += numberOfCommands;
                [string appendFormat:@"%@ (%lu %@): ", expressionClass, numberOfCommands,
                 (numberOfCommands == 1 ? @"command" : @"commands")];
                bool addComma = false;
                for (NSString *commandName in commands) {
                    [string appendFormat:@"%@%@", (addComma ? @", " : @""), commandName];
                    addComma = true;
                }
                [string appendString:@"\n"];
            }
            else {
                NSLog(@"Class %@ does not implement the recognizedCommands method", expressionClass);
            }
        }
    }
    [string appendFormat:@"\nTotal: %lu commands\n", totalNumberOfCommands];
    NSLog(@"%@", string);
}

- (NSString *)stringOutlineOfSubclassesOfClassAtIndex:(NSUInteger)index usingClassDictsArray:(NSArray *)array
{
    NSUInteger numberOfClasses = array.count;

    NSDictionary *currentClassDict = array[index];
    Class currentClass = currentClassDict[@"class"];
    NSUInteger currentClassDepth = [(NSNumber *)currentClassDict[@"depth"] unsignedLongValue];
    
    NSMutableString *stringToPrint = [[NSMutableString alloc] initWithCapacity:0];
    [stringToPrint appendFormat:@"⌘listitem.%@\n\n", [currentClass className]];
    
    NSUInteger loopIndex;
    for (loopIndex = 0; loopIndex < numberOfClasses; loopIndex++) {
        NSDictionary *loopClassDict = array[loopIndex];
        Class loopClass = loopClassDict[@"class"];
        NSUInteger loopClassDepth = [(NSNumber *)loopClassDict[@"depth"] unsignedIntegerValue];
        if (loopClassDepth == currentClassDepth + 1 && [loopClass isSubclassOfClass:currentClass]) {
            NSString *outlineForSubclass = [self stringOutlineOfSubclassesOfClassAtIndex:loopIndex usingClassDictsArray:array];
            [stringToPrint appendFormat:@"⌘listindent.%@⌘listunindent.", outlineForSubclass];
        }
    }
    
    return stringToPrint;
}

@end
