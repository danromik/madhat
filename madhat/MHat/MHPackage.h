//
//  MHPackage.h
//  MadHat
//
//  Created by Dan Romik on 11/30/19.
//  Copyright © 2019 Dan Romik. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MadHat.h"
#import "MHCommand.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString * const kMHPackageNameKey;
extern NSString * const kMHPackageAuthorKey;
extern NSString * const kMHPackageVersionStringKey;
extern NSString * const kMHPackageModulesKey;
extern NSString * const kMHPackageCommandNameKey;
extern NSString * const kMHPackageCommandAliasKey;
extern NSString * const kMHPackageCommandClassNameKey;
extern NSString * const kMHPackageCommandParametersKey;




@interface MHPackage : NSObject

// Properties

@property (readonly) NSString *name;
@property (readonly) NSString *author;
@property (readonly) NSString *versionString;



// Constructor methods

+ (instancetype)standardPackage;                                // the standard package
+ (instancetype)packageWithName:(NSString *)packageName;        // looks for a resource file for the package in the main application bundle
+ (instancetype)packageWithContentsOfFile:(NSString *)filename; // to load a package from a file that's not necessarily in the main app bundle



// Methods providing information about the package and its modules, clusters, and commands

- (NSArray <NSString *> *)modules;
- (NSArray <NSString *> *)clusters;
- (NSArray <NSString *> *)commands;
- (NSArray <NSString *> *)clustersInModule:(NSString *)module;
- (NSArray <NSString *> *)commandsInModule:(NSString *)module;
- (NSArray <NSString *> *)commandsInModule:(NSString *)module cluster:(NSString *)cluster;

- (NSUInteger)numberOfModules;
- (NSUInteger)numberOfClusters;
- (NSUInteger)numberOfCommands;
- (NSUInteger)numberOfClustersInModule:(NSString *)module;
- (NSUInteger)numberOfCommandsInModule:(NSString *)module;
- (NSUInteger)numberOfCommandsInModule:(NSString *)module cluster:(NSString *)cluster;

- (NSString *)infoString;   // Gives a general description of the package


// Here, if the module is specified the package looks for a command in that module. If it is nil, it searches in all the modules
// If the command is not found, the method returns nil
- (MHExpression *)expressionForModule:(nullable NSString *)module
                              command:(NSString *)command
                          commandType:(MHCommandType)type
                             argument:(MHHorizontalLayoutContainer *)argument
   allowNotebookConfigurationCommands:(BOOL)allowConfigCommands;

// Commands for which no command class is specified will be routed to this instance method instead of to a class method:
- (MHExpression *)expressionForCommandWithUnspecifiedClassName:(NSString *)commandName
                                             commandParameters:(nullable NSDictionary *)commandParameters
                                                   commandType:(MHCommandType)type
                                                      argument:(MHHorizontalLayoutContainer *)argument;


- (nullable NSArray <NSString *> *)autocompleteSuggestionsForCommandPrefix:(NSString *)commandPrefix
                                              includeConfigurationCommands:(BOOL)includeConfigCommands;
- (nullable NSString *)helpPageNameForCommandName:(NSString *)commandName;

@end

NS_ASSUME_NONNULL_END
