//
//  MHPackageManager.m
//  MadHat
//
//  Created by Dan Romik on 12/1/19.
//  Copyright © 2019 Dan Romik. All rights reserved.
//

#import "MHPackageManager.h"
#import "MHPlaceholderCommand.h"

NSString * const kMHCommandNameSeparator = @"-";

static MHPackageManager *_sharedPackageManager;

@interface MHPackageManager () {
    NSMutableDictionary *loadedPackages;
}

@end


@implementation MHPackageManager


#pragma mark - Constructor methods


+ (instancetype)sharedPackageManager
{
    if (!_sharedPackageManager) {
        _sharedPackageManager = [[[self class] alloc] init];
        [_sharedPackageManager loadStandardPackage];
    }
    return _sharedPackageManager;
}

- (instancetype)init
{
    if (self = [super init]) {
        loadedPackages = [[NSMutableDictionary alloc] initWithCapacity:0];
    }
    return self;
}




#pragma mark - Other methods

- (void)loadStandardPackage
{
    [self loadPackage:[MHPackage standardPackage]];
}

- (void)loadPackage:(MHPackage *)package
{
    // Get the package name and validate it. If it doesn't pass validation, don't load the package
    NSString *packageName = package.name;
    if (![[self class] validatePackageName:packageName]) {
        NSLog(@"Package name %@ didn't pass validation, ignoring it.", packageName);
        return;
    }

    [loadedPackages setObject:package forKey:packageName];
}

+ (bool)validatePackageName:(NSString *)name
{
    NSCharacterSet *alphanumeric = [NSCharacterSet alphanumericCharacterSet];
    return (name.length >= 1 && name.length <=10 && [@"" isEqualToString:[name stringByTrimmingCharactersInSet:alphanumeric]]);
}



// FIXME: this implementation looks inefficient, improve
- (nullable MHExpression *)expressionForMathKeyword:(NSString *)mathKeyword
{
    bool resolvedSuccessfully;
    MHExpression *expression = [self expressionForCommandString:mathKeyword
                                                    commandType:MHCommandMathKeyword
                                                commandArgument:nil
                             allowNotebookConfigurationCommands:NO
                                           resolvedSuccessfully:&resolvedSuccessfully];
    return (resolvedSuccessfully ? expression : nil);
}

// FIXME: this implementation looks inefficient, improve
- (MHExpression *)expressionForCommandString:(NSString *)commandString
                             commandArgument:(nullable MHHorizontalLayoutContainer *)argument
          allowNotebookConfigurationCommands:(BOOL)allowConfigCommands
                        resolvedSuccessfully:(nullable bool *)resolvedPtr
{
    return [self expressionForCommandString:commandString
                                commandType:MHCommandNormal
                            commandArgument:argument
         allowNotebookConfigurationCommands:allowConfigCommands
                       resolvedSuccessfully:resolvedPtr];
}

// FIXME: this implementation looks inefficient, improve
- (MHExpression *)expressionForCommandString:(NSString *)commandString
                                 commandType:(MHCommandType)type
                             commandArgument:(nullable MHHorizontalLayoutContainer *)argument
          allowNotebookConfigurationCommands:(BOOL)allowConfigCommands
                        resolvedSuccessfully:(nullable bool *)resolvedPtr
{
    NSArray <NSString *> *commandComponents = [commandString componentsSeparatedByString:kMHCommandNameSeparator];
    NSUInteger numberOfComponents = commandComponents.count;
    NSString *packageName;
    NSString *moduleName;
    NSString *commandName;
    
    MHHorizontalLayoutContainer *sanitizedArgument = argument ? argument : [MHHorizontalLayoutContainer expression]; // Don't want to pass a null value
    
    if (numberOfComponents >= 3) {
        packageName = commandComponents[0];
        moduleName = commandComponents[1];
        commandName = commandComponents[2];
        
        MHPackage *package = loadedPackages[packageName];
        
        MHExpression *expression = [package expressionForModule:moduleName
                                                        command:commandName
                                                    commandType:type
                                                       argument:sanitizedArgument
                             allowNotebookConfigurationCommands:allowConfigCommands];
        if (expression && resolvedPtr != nil) {
            *resolvedPtr = true;
            return expression;
        }
    }
    else if (numberOfComponents == 2) {
        moduleName = commandComponents[0];
        commandName = commandComponents[1];

        for (NSString *packageName in loadedPackages) {
            MHPackage *package = loadedPackages[packageName];
            
            MHExpression *expression = [package expressionForModule:moduleName
                                                            command:commandName
                                                        commandType:type
                                                           argument:sanitizedArgument
                                 allowNotebookConfigurationCommands:allowConfigCommands];
        if (expression && resolvedPtr != nil) {
                *resolvedPtr = true;
                return expression;
            }
        }
    }
    else if (numberOfComponents == 1) {
        commandName = commandString;

        for (NSString *packageName in loadedPackages) {
            MHPackage *package = loadedPackages[packageName];
            
            MHExpression *expression = [package expressionForModule:nil
                                                            command:commandName
                                                        commandType:type
                                                           argument:sanitizedArgument
                                 allowNotebookConfigurationCommands:allowConfigCommands];
        if (expression && resolvedPtr != nil) {
                *resolvedPtr = true;
                return expression;
            }
        }
    }

    // We didn't find the command, so return a default command expression and mark the passed boolean pointer as false
    if (resolvedPtr != nil) {
        *resolvedPtr = false;
    }
    return [MHPlaceholderCommand commandNamed:commandString withParameters:nil argument:sanitizedArgument];
}



#pragma mark - Autocomplete and help

- (nullable NSArray <NSString *> *)autocompleteSuggestionsForCommandPrefix:(NSString *)commandPrefix
                                              includeConfigurationCommands:(BOOL)includeConfigCommands
{
    NSMutableArray *mutableArray;
    
    for (NSString *packageName in loadedPackages) {
        MHPackage *package = loadedPackages[packageName];
        
        NSArray *packageSuggestions = [package autocompleteSuggestionsForCommandPrefix:commandPrefix
                                                          includeConfigurationCommands:includeConfigCommands];
        if (packageSuggestions) {
            if (!mutableArray)
                mutableArray = [[NSMutableArray alloc] initWithCapacity:0];
            [mutableArray addObjectsFromArray:packageSuggestions];
        }
    }
    [mutableArray sortUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    return mutableArray;
}

- (nullable NSString *)helpPageNameForCommandName:(NSString *)commandName
{
    for (NSString *packageName in loadedPackages) {
        MHPackage *package = loadedPackages[packageName];
        NSString *helpPageName = [package helpPageNameForCommandName:commandName];
        if (helpPageName)
            return helpPageName;
    }
    return nil;
}


@end
