//
//  MHPackageManager.h
//  MadHat
//
//  Created by Dan Romik on 12/1/19.
//  Copyright © 2019 Dan Romik. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MadHat.h"
#import "MHPackage.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString * const kMHCommandNameSeparator;


@interface MHPackageManager : NSObject

+ (instancetype)sharedPackageManager;   // a singleton instance that anyone can use. Comes preloaded with the standard package

- (void)loadStandardPackage;       // This loads the standard commands. Currently it has to be called manually, at some future version it will run automatically on initialization

- (void)loadPackage:(MHPackage *)package;

- (MHExpression *)expressionForCommandString:(NSString *)commandString
                             commandArgument:(nullable MHHorizontalLayoutContainer *)argument
          allowNotebookConfigurationCommands:(BOOL)allowConfigCommands
                        resolvedSuccessfully:(nullable bool *)resolvedPtr;

- (nullable MHExpression *)expressionForMathKeyword:(NSString *)mathKeyword;    // returns nil if mathKeyword is not a valid math keyword

- (nullable NSArray <NSString *> *)autocompleteSuggestionsForCommandPrefix:(NSString *)commandPrefix
                                              includeConfigurationCommands:(BOOL)includeConfigCommands;
- (nullable NSString *)helpPageNameForCommandName:(NSString *)commandName;


@end

NS_ASSUME_NONNULL_END
