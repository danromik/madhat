//
//  MHPackage.m
//  MadHat
//
//  Created by Dan Romik on 11/30/19.
//  Copyright © 2019 Dan Romik. All rights reserved.
//

#import "MHPackage.h"
#import "MHPackageManager.h"

#import "MHVerticalLayoutContainer.h"
#import "MHHorizontalLayoutContainer.h"
#import "MHTextParagraph.h"
#import "MHListCommand.h"
#import "MHTextAtom.h"
#import "MHWhitespace.h"
#import "MHRichTextAtom.h"
#import "MHParser.h"
#import "MHLink.h"

NSString * const kMHPackageFileExtension = @"mhatpkg";
NSString * const kMHPackageStandardPackageName = @"standard";

NSString * const kMHPackageNameKey = @"packagename";
NSString * const kMHPackageAuthorKey = @"packageauthor";
NSString * const kMHPackageVersionStringKey = @"packageversion";
NSString * const kMHPackageModulesKey = @"modules";
NSString * const kMHPackageCommandNameKey = @"commandname";
NSString * const kMHPackageCommandAliasKey = @"commandalias";
NSString * const kMHPackageCommandClassNameKey = @"commandclass";
NSString * const kMHPackageCommandHelpPageNameKey = @"helppage";
NSString * const kMHPackageCommandIsMathKeywordKey = @"mathkeyword";
NSString * const kMHPackageCommandIsConfigurationCommandKey = @"configurationcommand";
NSString * const kMHPackageCommandClassKey = @"commandclass";
NSString * const kMHPackageCommandParametersKey = @"commandparameters";
NSString * const kMHPackageCommandDisableKey = @"prototype";

NSString * const kMHPackageInfoCommandName = @"package info";
NSString * const kMHPackageAuthorNameCommandName = @"package author";
NSString * const kMHPackageListPackageModulesCommandName = @"package modules";
NSString * const kMHPackageListPackageClustersCommandName = @"package clusters";
NSString * const kMHPackageListPackageCommandsCommandName = @"package commands";

NSString * const kMHPackageListClusterCommandsCommandName = @"cluster commands";
NSString * const kMHPackageListModuleCommandsCommandName = @"module commands";   // FIXME: need to implement this
NSString * const kMHPackageListModuleClustersCommandName = @"module clusters";

static MHPackage *MHPackageLazilyLoadedStandardPackage = nil;


@interface MHPackage ()
{
    // The dictionary _modulesDict contains the main information of the package
    // Each keyed object in the dictionary is a module, represented by a dictionary in which each keyed object is
    // a command cluster, which is an array of commands.
    // Each command is represented by a dictionary where each keyed value is one of the Foundation framework primitive data types
    // (number, string, boolean etc)
    // This structure can be encapsulated in the following declaration:
    NSDictionary <NSString *,
                  NSDictionary <NSString *,
                                NSArray <NSDictionary *> *> *> *_modulesDict;

    NSDictionary <NSString *, NSDictionary *> *_allCommandsDict; // a single dictionary with a flattened, unordered hierarchy of all the commands in the package
    NSDictionary <NSString *, NSDictionary *> *_flattenedModulesDict; // a dictionary of modules, each stored as a flattened, unordered hierarchy of all the commands in the module (discarding the cluster structure)
}
@end


@implementation MHPackage




#pragma mark - Constructor methods

+ (instancetype)standardPackage
{
    if (!MHPackageLazilyLoadedStandardPackage) {
        MHPackageLazilyLoadedStandardPackage = [self packageWithName:kMHPackageStandardPackageName];
    }
    return MHPackageLazilyLoadedStandardPackage;
}

+ (instancetype)packageWithName:(NSString *)packageName
{
    NSString *filename = [[NSBundle mainBundle] pathForResource:packageName ofType:(NSString *)kMHPackageFileExtension];
    return [self packageWithContentsOfFile:filename];
}

+ (instancetype)packageWithContentsOfFile:(NSString *)filename
{
    return [[self alloc] initWithContentsOfFile:filename];
}

- (instancetype)initWithContentsOfFile:(NSString *)filename
{
    if (self = [super init]) {
        NSDictionary *propertyListDictionary = [NSDictionary dictionaryWithContentsOfFile:filename];
        if (!propertyListDictionary) {
            self = nil;
            return self;
        }
        _name = propertyListDictionary[kMHPackageNameKey];
        _author = propertyListDictionary[kMHPackageAuthorKey];
        _versionString = propertyListDictionary[kMHPackageVersionStringKey];
        _modulesDict = propertyListDictionary[kMHPackageModulesKey];
        
        // Create the flattened command dictionary and module command dictionaries for efficient lookup of commands
        NSMutableDictionary *allCommandsMutableDict = [[NSMutableDictionary alloc] initWithCapacity:0];
        NSMutableDictionary *flattenedModulesMutableDict = [[NSMutableDictionary alloc] initWithCapacity:0];
        
        for (NSString *module in _modulesDict) {
            NSDictionary *moduleDict = _modulesDict[module];
            NSMutableDictionary *commandsInModuleMutableDict = [[NSMutableDictionary alloc] initWithCapacity:0];
            for (NSString *cluster in moduleDict) {
                NSArray *clusterCommands = moduleDict[cluster];
                for (NSDictionary *commandDict in clusterCommands) {
                    NSString *commandName = commandDict[kMHPackageCommandNameKey];
                    NSString *commandClassName = commandDict[kMHPackageCommandClassNameKey];
                    Class commandClass = NSClassFromString(commandClassName);
                    
                    if (commandClass && ![commandClass conformsToProtocol:@protocol(MHCommand)]) {
                        NSLog(@"Warning: class %@ is specified as a command constructor for the '%@' command but does not conform to the MHCommand protocol", [commandClass className], commandName);
                    }
                    
                    NSNumber *commandIsDisabled = commandDict[kMHPackageCommandDisableKey];
                    if (commandIsDisabled && [commandIsDisabled boolValue]) {
                        continue;   // the command is disabled, do not process it
                    }
                    
                    // We process the command dictionary slightly by replacing the string command class name (if provided) with the actual class object,
                    // which is more efficient during runtime lookup of commands
                    NSMutableDictionary *processedCommandDict = [[NSMutableDictionary alloc] initWithCapacity:0];
                    [processedCommandDict addEntriesFromDictionary:commandDict];
                    
                    if (commandClassName != nil) {
                        [processedCommandDict removeObjectForKey:kMHPackageCommandClassNameKey];
                        if (commandClass) {
                            [processedCommandDict setObject:commandClass forKey:kMHPackageCommandClassKey];
                        }
                        else {
                            NSLog(@"Error: Missing command class %@ specified for command %@ in module %@", commandClassName,
                                  commandName, module);
                        }
                    }
                    
                    
                    // The processed dictionary is stored in a package-wide dictionary and the individual dictionary for the specific module
                    [allCommandsMutableDict setObject:[NSDictionary dictionaryWithDictionary:processedCommandDict] forKey:commandName];
                    [commandsInModuleMutableDict setObject:processedCommandDict forKey:commandName];
                    
                    // Now check if the command has an alias
                    NSString *commandAlias = commandDict[kMHPackageCommandAliasKey];
                    if (commandAlias) {
                        // There's an alias, so we'll record the processed dictionary in separate entries associated with the alias
                        [allCommandsMutableDict setObject:[NSDictionary dictionaryWithDictionary:processedCommandDict] forKey:commandAlias];
                        [commandsInModuleMutableDict setObject:processedCommandDict forKey:commandAlias];
                    }
                }
            }
            [flattenedModulesMutableDict setObject:[NSDictionary dictionaryWithDictionary:commandsInModuleMutableDict]
                                            forKey:module];
        }
        _allCommandsDict = [NSDictionary dictionaryWithDictionary:allCommandsMutableDict];
        _flattenedModulesDict = [NSDictionary dictionaryWithDictionary:flattenedModulesMutableDict];
    }
    return self;
}




#pragma mark - Various methods

- (NSArray <NSString *> *)modules
{
    NSMutableArray *modulesMutableArray = [[NSMutableArray alloc] initWithCapacity:0];
    for (NSString *module in _modulesDict) {
        [modulesMutableArray addObject:[NSString stringWithFormat:@"%@-%@", _name, module]];
    }
    return [NSArray arrayWithArray:modulesMutableArray];
}

- (NSArray <NSString *> *)clusters
{
    NSMutableArray *clustersMutableArray = [[NSMutableArray alloc] initWithCapacity:0];
    for (NSString *module in _modulesDict) {
        [clustersMutableArray addObjectsFromArray:[self clustersInModule:module]];
    }
    return [NSArray arrayWithArray:clustersMutableArray];
}

- (NSArray <NSString *> *)commands
{
    NSMutableArray *commandsMutableArray = [[NSMutableArray alloc] initWithCapacity:0];
    for (NSString *module in _modulesDict) {
        [commandsMutableArray addObjectsFromArray:[self commandsInModule:module]];
    }
    return [NSArray arrayWithArray:commandsMutableArray];
}

- (NSArray <NSString *> *)clustersInModule:(NSString *)module
{
//    NSMutableArray *clustersMutableArray = [[NSMutableArray alloc] initWithCapacity:0];
    NSDictionary *moduleDict = _modulesDict[module];
    NSArray *clustersInModule = [moduleDict allKeys];
    
    return clustersInModule;
    
//    for (NSString *cluster in clustersInModule) {
//        [clustersMutableArray addObject:[NSString stringWithFormat:@"%@-%@-%@", _name, module, cluster]];
//    }
//    return [NSArray arrayWithArray:clustersMutableArray];
}

- (NSArray <NSString *> *)commandsInModule:(NSString *)module
{
    NSMutableArray *commandsMutableArray = [[NSMutableArray alloc] initWithCapacity:0];
    NSDictionary *moduleDict = _modulesDict[module];
    for (NSString *cluster in moduleDict) {
        [commandsMutableArray addObjectsFromArray:[self commandsInModule:module cluster:cluster]];
    }
    return [NSArray arrayWithArray:commandsMutableArray];
}

- (NSArray <NSString *> *)commandsInModule:(NSString *)module cluster:(NSString *)cluster
{
    NSMutableArray *commandsMutableArray = [[NSMutableArray alloc] initWithCapacity:0];
    NSDictionary *moduleDict = _modulesDict[module];
    NSArray *clusterArray = moduleDict[cluster];
    for (NSDictionary *commandDict in clusterArray) {
        NSString *commandName = commandDict[kMHPackageCommandNameKey];
        NSString *commandAlias = commandDict[kMHPackageCommandAliasKey];
        [commandsMutableArray addObject:[NSString stringWithFormat:@"%@%@%@",
                                         // _name, module, cluster,
                                         commandName,
                                         (commandAlias ? @"/" : @""),
                                         (commandAlias ? commandAlias : @"")
                                         ]];

//        [commandsMutableArray addObject:[NSString stringWithFormat:@"%@-%@-%@-%@%@%@%@",
//                                         _name, module, cluster, commandName,
//                                         (commandAlias ? @" [alias: " : @""),
//                                         (commandAlias ? commandAlias : @""),
//                                         (commandAlias ? @"]" : @"")
//                                         ]];
    }
    return [NSArray arrayWithArray:commandsMutableArray];
}

- (NSUInteger)numberOfModules
{
    return [self.modules count];
}
- (NSUInteger)numberOfClusters
{
    return [self.clusters count];
}

- (NSUInteger)numberOfCommands
{
    return [self.commands count];
}

- (NSUInteger)numberOfClustersInModule:(NSString *)module
{
    return [self clustersInModule:module].count;
}

- (NSUInteger)numberOfCommandsInModule:(NSString *)module
{
    return [self commandsInModule:module].count;
}

- (NSUInteger)numberOfCommandsInModule:(NSString *)module cluster:(NSString *)cluster
{
    return [self commandsInModule:module cluster:cluster].count;
}

- (NSString *)infoString
{
    return [NSString stringWithFormat:NSLocalizedString(@"Package %@, version %@ (%lu modules, %lu clusters, %lu commands)", @""),
            _name, _versionString, self.numberOfModules, self.numberOfClusters, self.numberOfCommands];
}



- (MHExpression *)expressionForModule:(nullable NSString *)module
                              command:(NSString *)command
                          commandType:(MHCommandType)type
                             argument:(MHHorizontalLayoutContainer *)argument
   allowNotebookConfigurationCommands:(BOOL)allowConfigCommands
{
    NSDictionary *commandDict;
    if (module) {
        NSDictionary *moduleDict = _flattenedModulesDict[module];
        commandDict = moduleDict[command];
    }
    else {
        commandDict = _allCommandsDict[command];
    }

    if (commandDict) {
        Class commandClass = commandDict[kMHPackageCommandClassKey];
        NSString *commandName = commandDict[kMHPackageCommandNameKey];   // this is the true command name (as opposed to an alias)
        NSDictionary *commandParameters = commandDict[kMHPackageCommandParametersKey];
        
        BOOL commandIsMathKeyword = NO;
//        if (type == MHCommandMathKeyword) {
            NSNumber *mathKeywordDictionaryValue = commandDict[kMHPackageCommandIsMathKeywordKey];
            if (mathKeywordDictionaryValue)
                commandIsMathKeyword = [mathKeywordDictionaryValue boolValue];
//        }
        
        if (!commandClass)
            return [self expressionForCommandWithUnspecifiedClassName:commandName
                                                    commandParameters:commandParameters
                                                          commandType:(MHCommandType)type
                                                             argument:argument];
        
        if (type == MHCommandNormal && !commandIsMathKeyword) {
            BOOL commandIsConfigurationCommand = NO;
            NSNumber *configurationCommandDictionaryValue = commandDict[kMHPackageCommandIsConfigurationCommandKey];
            if (configurationCommandDictionaryValue)
                commandIsConfigurationCommand = [configurationCommandDictionaryValue boolValue];
            if ((!commandIsConfigurationCommand) || allowConfigCommands)
                return [commandClass commandNamed:commandName withParameters:commandParameters argument:argument];
        }
        else if (type == MHCommandMathKeyword && commandIsMathKeyword) {
            return [commandClass commandNamed:commandName withParameters:commandParameters argument:argument];
        }
    }
    return nil;
}

- (MHExpression *)expressionForCommandWithUnspecifiedClassName:(NSString *)commandName
                                             commandParameters:(nullable NSDictionary *)commandParameters
                                                   commandType:(MHCommandType)type
                                                      argument:(MHHorizontalLayoutContainer *)argument
{
    // Any command for which the command class name is not specified in the .mhatpkg file is routed here for handling
    
    if (type == MHCommandMathKeyword)
        return nil;                     // currently no math keywords with an unspecified class are handled here
    
    if ([commandName isEqualToString:kMHPackageInfoCommandName]) {
        return [MHHorizontalLayoutContainer containerWithPlainTextString:self.infoString];
    }
    if ([commandName isEqualToString:kMHPackageAuthorNameCommandName]) {
        return [MHHorizontalLayoutContainer containerWithPlainTextString:self.author];
    }
    if ([commandName isEqualToString:kMHPackageListPackageModulesCommandName]) {
        return [MHHorizontalLayoutContainer formattedContainerWithArrayOfPlainTextStrings:self.modules];
    }
    if ([commandName isEqualToString:kMHPackageListPackageClustersCommandName]) {
        return [MHHorizontalLayoutContainer formattedContainerWithArrayOfPlainTextStrings:self.clusters];
    }
    if ([commandName isEqualToString:kMHPackageListPackageCommandsCommandName]) {
        NSArray *paragraphsArray = [self paragraphsArrayForFormattedListOfCommandsInPackage];
        MHTextParagraph *dummyParagraph = [MHTextParagraph expression];
        dummyParagraph.attachedContent = paragraphsArray;
        return dummyParagraph;
    }
    if ([commandName isEqualToString:kMHPackageListModuleCommandsCommandName]) {
        NSString *moduleName = argument.stringValue;
        NSArray *paragraphsArray = [self paragraphsArrayForFormattedListOfCommandsInModule:moduleName];
        MHTextParagraph *dummyParagraph = [MHTextParagraph expression];
        dummyParagraph.attachedContent = paragraphsArray;
        return dummyParagraph;
    }
    if ([commandName isEqualToString:kMHPackageListModuleClustersCommandName]) {
        // FIXME: old implementation - improve to use list commands like the "modulecommands" command implementation above
        
        NSString *moduleName = argument.stringValue;
        return [MHHorizontalLayoutContainer formattedContainerWithArrayOfPlainTextStrings:[self clustersInModule:moduleName]];
    }
    if ([commandName isEqualToString:kMHPackageListClusterCommandsCommandName]) {
        NSString *clusterString = argument.stringValue;
        NSArray *clusterStringComponents = [clusterString componentsSeparatedByString:kMHCommandNameSeparator];
        NSUInteger numberOfComponents = clusterStringComponents.count;
        
        if (numberOfComponents == 2) {
            NSString *moduleName = clusterStringComponents[0];
            NSString *clusterName = clusterStringComponents[1];
            
            NSArray *paragraphsArray = [self paragraphsArrayForFormattedListOfCommandsInModule:moduleName cluster:clusterName];
            MHTextParagraph *dummyParagraph = [MHTextParagraph expression];
            dummyParagraph.attachedContent = paragraphsArray;
            return dummyParagraph;
            
        }
        // FIXME: maybe add an option to just specify the cluster name, and add code to look for a module that has a cluster with that name?
        
        return nil;
    }
    return nil;
}

- (NSArray *)paragraphsArrayForFormattedListOfCommandsInPackage
{
    NSMutableArray *paragraphsArray = [[NSMutableArray alloc] initWithCapacity:0];
    
    
    
    MHTextParagraph *packageHeaderParagraph = [MHTextParagraph expression];
    [packageHeaderParagraph addSubexpression:[MHListCommand listCommandWithType:MHListCommandListIndent]];
    [packageHeaderParagraph addSubexpression:[MHListCommand listCommandWithType:MHListCommandUnnumberedItem]];

    NSDictionary *packageNameAttributes = @{
        NSFontAttributeName : [NSFont fontWithName:MHSourceCodeTextViewDefaultFontName
                                              size:MHSourceCodeTextViewDefaultFontSize],
        NSForegroundColorAttributeName : [NSColor blackColor],
//            NSBackgroundColorAttributeName : [NSColor colorWithRed:253.0/256.0 green:246.0/256.0 blue:227.0/256.0 alpha:1.0]
    };
    NSAttributedString *packageAttributedString = [[NSAttributedString alloc] initWithString:[self name] attributes:packageNameAttributes];

    [packageHeaderParagraph addSubexpression:[MHTextAtom textAtomWithString:@"Package"]];
    [packageHeaderParagraph addSubexpression:[MHWhitespace space]];
    [packageHeaderParagraph addSubexpression:[MHRichTextAtom richTextAtomWithAttributedString:packageAttributedString]];
    NSUInteger numModules = [self numberOfModules];
    NSUInteger numClusters = [self numberOfClusters];
    NSUInteger numCommands = [self numberOfCommands];
    NSString *detailString = [NSString stringWithFormat:@" (%lu module%@, %lu cluster%@, %lu command%@):",
                              numModules, (numModules == 1 ? @"" : @"s"),
                              numClusters, (numClusters == 1 ? @"" : @"s"),
                              numCommands, (numCommands == 1 ? @"" : @"s")];
    [packageHeaderParagraph addSubexpression:[MHTextAtom textAtomWithString:detailString]];

    [paragraphsArray addObject:packageHeaderParagraph];
    
    MHTextParagraph *packageBeginIndentParagraph = [MHTextParagraph expression];
    [packageBeginIndentParagraph addSubexpression:[MHListCommand listCommandWithType:MHListCommandListIndent]];
    [paragraphsArray addObject:packageBeginIndentParagraph];
    
    NSArray *modules = self.modules;
    for (NSString *module in modules) {
        NSArray *moduleComponents = [module componentsSeparatedByString:kMHCommandNameSeparator];
        if (moduleComponents.count == 2) {
            NSString *moduleName = moduleComponents[1];
            NSArray *moduleParagraphsArray = [self paragraphsArrayForFormattedListOfCommandsInModule:moduleName];
            [paragraphsArray addObjectsFromArray:moduleParagraphsArray];
        }
    }
    
    MHTextParagraph *packageEndIndentParagraph = [MHTextParagraph expression];
    [packageEndIndentParagraph addSubexpression:[MHListCommand listCommandWithType:MHListCommandListUnindent]];
    [packageEndIndentParagraph addSubexpression:[MHListCommand listCommandWithType:MHListCommandListUnindent]];
    [paragraphsArray addObject:packageEndIndentParagraph];
    
    return paragraphsArray;
}


- (NSArray *)paragraphsArrayForFormattedListOfCommandsInModule:(NSString *)moduleName
{
    NSArray <NSString *> *clustersInModule = [self clustersInModule:moduleName];
    
    NSMutableArray *vContainer = [[NSMutableArray alloc] initWithCapacity:0];

    MHTextParagraph *moduleHeaderParagraph = [MHTextParagraph expression];
    [moduleHeaderParagraph addSubexpression:[MHListCommand listCommandWithType:MHListCommandUnnumberedItem]];
    
    NSDictionary *moduleClusterNameAttributes = @{
        NSFontAttributeName : [NSFont fontWithName:MHSourceCodeTextViewDefaultFontName
                                              size:MHSourceCodeTextViewDefaultFontSize],
        NSForegroundColorAttributeName : [NSColor blackColor],
//            NSBackgroundColorAttributeName : [NSColor colorWithRed:253.0/256.0 green:246.0/256.0 blue:227.0/256.0 alpha:1.0]
    };
    NSAttributedString *moduleAttributedString = [[NSAttributedString alloc] initWithString:moduleName
                                                                                 attributes:moduleClusterNameAttributes];

    [moduleHeaderParagraph addSubexpression:[MHTextAtom textAtomWithString:@"Module"]];
    [moduleHeaderParagraph addSubexpression:[MHWhitespace space]];
    [moduleHeaderParagraph addSubexpression:[MHRichTextAtom
                                             richTextAtomWithAttributedString:moduleAttributedString]];
    NSUInteger numClusters = [self numberOfClustersInModule:moduleName];
    NSUInteger numCommands = [self numberOfCommandsInModule:moduleName];
    NSString *detailString = [NSString stringWithFormat:@" (%lu cluster%@, %lu command%@):",
                              numClusters, (numClusters == 1 ? @"" : @"s"),
                              numCommands, (numCommands == 1 ? @"" : @"s")];
    [moduleHeaderParagraph addSubexpression:[MHTextAtom textAtomWithString:detailString]];

    [vContainer addObject:moduleHeaderParagraph];

    MHTextParagraph *clustersBeginIndentParagraph = [MHTextParagraph expression];
    [clustersBeginIndentParagraph addSubexpression:[MHListCommand listCommandWithType:MHListCommandListIndent]];
    [vContainer addObject:clustersBeginIndentParagraph];

    for (NSString *cluster in clustersInModule) {
        NSArray *clusterParagraphs = [self paragraphsArrayForFormattedListOfCommandsInModule:moduleName cluster:cluster];
        [vContainer addObjectsFromArray:clusterParagraphs];
    }

    MHTextParagraph *clustersEndIndentParagraph = [MHTextParagraph expression];
    [clustersEndIndentParagraph addSubexpression:[MHListCommand listCommandWithType:MHListCommandListUnindent]];
    [vContainer addObject:clustersEndIndentParagraph];

    MHParagraph *moduleClosingParagraph = [MHTextParagraph expression];
    [vContainer addObject:moduleClosingParagraph];
    
    return vContainer;
}


- (NSArray *)paragraphsArrayForFormattedListOfCommandsInModule:(NSString *)moduleName cluster:(NSString *)cluster
{
    NSDictionary *moduleClusterNameAttributes = @{
        NSFontAttributeName : [NSFont fontWithName:MHSourceCodeTextViewDefaultFontName
                                              size:MHSourceCodeTextViewDefaultFontSize],
        NSForegroundColorAttributeName : [NSColor blackColor],
//            NSBackgroundColorAttributeName : [NSColor colorWithRed:253.0/256.0 green:246.0/256.0 blue:227.0/256.0 alpha:1.0]
    };
    
    NSMutableArray *paragraphsArray = [[NSMutableArray alloc] initWithCapacity:0];
    
    MHTextParagraph *clusterHeaderParagraph = [MHTextParagraph expression];
    [clusterHeaderParagraph addSubexpression:[MHListCommand listCommandWithType:MHListCommandUnnumberedItem]];
    
    NSString *clusterString = [NSString stringWithFormat:@"%@-%@", moduleName, cluster];
    NSAttributedString *clusterAttributedString = [[NSAttributedString alloc] initWithString:clusterString
                                                                                 attributes:moduleClusterNameAttributes];

    [clusterHeaderParagraph addSubexpression:[MHTextAtom textAtomWithString:@"Cluster"]];
    [clusterHeaderParagraph addSubexpression:[MHWhitespace space]];
    [clusterHeaderParagraph addSubexpression:[MHRichTextAtom
                                              richTextAtomWithAttributedString:clusterAttributedString]];
    NSUInteger numCommands = [self numberOfCommandsInModule:moduleName cluster:cluster];
    NSString *numCommandsString = [NSString stringWithFormat:@" (%lu command%@):", numCommands,
                                   (numCommands == 1 ? @"" : @"s")];
    [clusterHeaderParagraph addSubexpression:[MHTextAtom textAtomWithString:numCommandsString]];

    [paragraphsArray addObject:clusterHeaderParagraph];

    MHTextParagraph *clusterBeginIndentParagraph = [MHTextParagraph expression];
    [clusterBeginIndentParagraph addSubexpression:[MHListCommand listCommandWithType:MHListCommandListIndent]];
    [paragraphsArray addObject:clusterBeginIndentParagraph];

    NSArray <NSString *> *commandNames = [self commandsInModule:moduleName cluster:cluster];
    
    NSFont *commandNameFontBeforeBolding = [NSFont fontWithName:MHSourceCodeTextViewDefaultFontName
                                                           size:MHSourceCodeTextViewDefaultFontSize];
    NSFont *commandNameFont = [[NSFontManager sharedFontManager] convertFont:commandNameFontBeforeBolding
                                                                 toHaveTrait:NSBoldFontMask];

    NSFont *commandSymbolFont = [NSFont fontWithName:@"Lucida Grande" size:MHSourceCodeTextViewDefaultFontSize];
    NSColor *textModeBackgroundColor = [NSColor colorWithRed:0.988 green:0.96 blue:0.886 alpha:1.0];
    NSColor *mathModeBackgroundColor = [NSColor colorWithRed:0.85 green:0.9 blue:0.85 alpha:1.0];
    NSColor *commandColor = [NSColor colorWithRed:0.25 green:0.0 blue:0.75 alpha:1.0];
    NSColor *mathKeywordColor = [NSColor colorWithRed:0.5 green:0.1 blue:0.26 alpha:1.0];

    NSDictionary *commandNameInTextModeAttributes = @{
        NSFontAttributeName : commandNameFont,
        NSForegroundColorAttributeName : commandColor,
        NSBackgroundColorAttributeName : textModeBackgroundColor
    };
    NSDictionary *commandSymbolInTextModeAttributes = @{
        NSFontAttributeName : commandSymbolFont,
        NSForegroundColorAttributeName : commandColor,
        NSBackgroundColorAttributeName : textModeBackgroundColor
    };
    NSDictionary *commandNameInMathModeAttributes = @{
        NSFontAttributeName : commandNameFont,
        NSForegroundColorAttributeName : commandColor,
        NSBackgroundColorAttributeName : mathModeBackgroundColor
    };
    NSDictionary *commandSymbolInMathModeAttributes = @{
        NSFontAttributeName : commandSymbolFont,
        NSForegroundColorAttributeName : commandColor,
        NSBackgroundColorAttributeName : mathModeBackgroundColor
    };
    NSDictionary *mathKeywordAttributes = @{
        NSFontAttributeName : commandNameFont,
        NSForegroundColorAttributeName : mathKeywordColor,
        NSBackgroundColorAttributeName : mathModeBackgroundColor
    };

    NSString *singleCommandCharString = [NSString stringWithFormat:@"%C", kMHParserCharStartCommand];
    NSString *doubleCommandCharString = [NSString stringWithFormat:@"%C%C", kMHParserCharStartCommand, kMHParserCharStartCommand];

    for (NSString *command in commandNames) {
        
        NSArray *commandComponents = [command componentsSeparatedByString:@"/"];
        NSUInteger numComponents = commandComponents.count;
        
        MHTextParagraph *commandParagraph = [MHTextParagraph expression];
        [commandParagraph addSubexpression:[MHListCommand listCommandWithType:MHListCommandUnnumberedItem]];
        
        bool commandIsMathKeyword = false;
        NSDictionary *commandDict = _allCommandsDict[command];
        NSNumber *mathKeywordDictionaryValue = commandDict[kMHPackageCommandIsMathKeywordKey];
        if (mathKeywordDictionaryValue)
            commandIsMathKeyword = [mathKeywordDictionaryValue boolValue];
        
        bool commandUsedInMathMode = [moduleName isEqualToString:@"math"];   // FIXME: a temporary hack - this should be determined through explicitly provided parameters in the command dictionary

        NSDictionary *commandNameAttributesToUse = (commandIsMathKeyword ? mathKeywordAttributes :
                                                    (commandUsedInMathMode ? commandNameInMathModeAttributes : commandNameInTextModeAttributes));
        NSDictionary *commandSymbolAttributesToUse;
        if (!commandIsMathKeyword)
            commandSymbolAttributesToUse = (commandUsedInMathMode ? commandSymbolInMathModeAttributes : commandSymbolInTextModeAttributes);

        if (numComponents >= 1) {
            NSString *commandName = commandComponents[0];
            
            // Some not-terribly-well-written code to handle "double command symbol" commands (aka notebook configuration commands)
            bool commandNameBeginsWithCommandSymbol = ([commandName characterAtIndex:0] == kMHParserCharStartCommand);
            
            NSAttributedString *commandSymbolAttributedString;
            MHRichTextAtom *commandSymbolAtom;
            
            if (!commandIsMathKeyword) {
                commandSymbolAttributedString = [[NSAttributedString alloc]
                                                 initWithString:(commandNameBeginsWithCommandSymbol ?
                                                                 doubleCommandCharString : singleCommandCharString)
                                                 attributes:commandSymbolAttributesToUse];
                commandSymbolAtom = [MHRichTextAtom richTextAtomWithAttributedString:commandSymbolAttributedString];
            }

            NSAttributedString *commandAttributedString = [[NSAttributedString alloc]
                                                           initWithString:(commandNameBeginsWithCommandSymbol ?
                                                                           [commandName substringFromIndex:1] : commandName)
                                                           attributes:commandNameAttributesToUse];
            MHRichTextAtom *commandAtom = [MHRichTextAtom richTextAtomWithAttributedString:commandAttributedString];
            
            NSString *helpPageName = commandDict[kMHPackageCommandHelpPageNameKey];
            
            if (helpPageName.length > 0) {
                MHHorizontalLayoutContainer *container = [[MHHorizontalLayoutContainer alloc] init];
                if (!commandIsMathKeyword) {
                    [container addSubexpression:commandSymbolAtom];
                }
                [container addSubexpression:commandAtom];
//                MHLink *commandExpressionWithHelpLink = [MHLink helpPageLinkWithHelpPageName:helpPageName contents:container];
                MHLink *commandExpressionWithHelpLink = [MHLink intralinkWithPageName:helpPageName contents:container];
                [commandParagraph addSubexpression:commandExpressionWithHelpLink];
            }
            else {
                if (!commandIsMathKeyword) {
                    [commandParagraph addSubexpression:commandSymbolAtom];
                }
                [commandParagraph addSubexpression:commandAtom];
            }

//            if (commandIsMathKeyword) {
//                MHLink *commandExpressionWithHelpLink = [MHLink commandHelpLinkWithCommandName:commandName contents:commandAtom];
//                [commandParagraph addSubexpression:commandExpressionWithHelpLink];
//            }
//            else {
//                MHLink *commandExpressionWithHelpLink = [MHLink commandHelpLinkWithCommandName:commandName];
//                [commandParagraph addSubexpression:commandExpressionWithHelpLink];
//            }

//            if (!commandIsMathKeyword) {
//                [commandParagraph addSubexpression:commandSymbolAtom];
//            }
//            [commandParagraph addSubexpression:commandAtom];
            
            if (numComponents >= 2) {
                MHWhitespace *newline = [MHWhitespace newline];
                [commandParagraph addSubexpression:newline];
//                [commandParagraph addSubexpression:[MHTextAtom textAtomWithString:@"alias:"]];
                 
                if (!commandIsMathKeyword) {
                    commandSymbolAtom = [MHRichTextAtom richTextAtomWithAttributedString:commandSymbolAttributedString];
                }

                commandAttributedString = [[NSAttributedString alloc] initWithString:commandComponents[1]
                                                                          attributes:commandNameAttributesToUse];
                commandAtom = [MHRichTextAtom richTextAtomWithAttributedString:commandAttributedString];
                
                if (commandIsMathKeyword) {
                    [commandParagraph addSubexpression:commandAtom];
                }
                else {
                    MHLink *commandExpressionWithHelpLink = [MHLink commandHelpLinkWithCommandName:commandComponents[1]];
                    [commandParagraph addSubexpression:commandExpressionWithHelpLink];
                }

//                if (!commandIsMathKeyword) {
//                    [commandParagraph addSubexpression:commandSymbolAtom];
//                }
//                [commandParagraph addSubexpression:commandAtom];
            }
        }
        [paragraphsArray addObject:commandParagraph];
    }
    
    MHTextParagraph *clusterEndIndentParagraph = [MHTextParagraph expression];
    [clusterEndIndentParagraph addSubexpression:[MHListCommand listCommandWithType:MHListCommandListUnindent]];
    [paragraphsArray addObject:clusterEndIndentParagraph];

    MHTextParagraph *clusterClosingParagraph = [MHTextParagraph expression];
    [paragraphsArray addObject:clusterClosingParagraph];

    return paragraphsArray;
}



#pragma mark - Autocomplete suggestions and help page names

// FIXME: at the moment autocomplete only works for commands, not for math keywords - improve
- (nullable NSArray <NSString *> *)autocompleteSuggestionsForCommandPrefix:(NSString *)commandPrefix
                                              includeConfigurationCommands:(BOOL)includeConfigCommands
{
    NSMutableArray *mutableArray;
    for (NSString *commandName in _allCommandsDict) {
        NSDictionary *commandDict = _allCommandsDict[commandName];
        if ([commandName hasPrefix:commandPrefix]) {
            // is it a regular command (as opposed to a math keyword)?
            BOOL commandIsMathKeyword = NO;
            NSNumber *mathKeywordDictionaryValue = commandDict[kMHPackageCommandIsMathKeywordKey];
            if (mathKeywordDictionaryValue)
                commandIsMathKeyword = [mathKeywordDictionaryValue boolValue];

            if (!commandIsMathKeyword) {    // only add the command to the autocomplete suggestions if it's not a math keyword
                
                BOOL commandIsConfigurationCommand = NO;
                NSNumber *configurationCommandDictionaryValue = commandDict[kMHPackageCommandIsConfigurationCommandKey];
                if (configurationCommandDictionaryValue)
                    commandIsConfigurationCommand = [configurationCommandDictionaryValue boolValue];

                if ((!commandIsConfigurationCommand) || includeConfigCommands) {
                    // only add the command to the autocomplete suggestions if it's not a configuration command, or if it's a configuration commands and we were asked to include those
                    if (!mutableArray) {
                        mutableArray = [[NSMutableArray alloc] initWithCapacity:0];
                    }
                    [mutableArray addObject:commandName];
                }
            }
        }
    }
    return mutableArray;
}

- (NSString *)helpPageNameForCommandName:(NSString *)commandName
{
    NSDictionary *commandDict = _allCommandsDict[commandName];
    if (commandDict) {
        NSString *helpPageName = commandDict[kMHPackageCommandHelpPageNameKey];
        return helpPageName;
    }
    return nil;
}




#pragma mark - description

- (NSString *)description
{
    // FIXME: improve
    return [NSString stringWithFormat:@"<%@ package info string=%@", [self className], [self infoString]];
}

@end
