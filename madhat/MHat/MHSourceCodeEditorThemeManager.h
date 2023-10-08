//
//  MHSourceCodeEditorThemeManager.h
//  MadHat
//
//  Created by Dan Romik on 12/6/21.
//  Copyright © 2021 Dan Romik. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const _Nonnull kMHSourceCodeEditorThemeManagerThemesChangedNotification;
extern NSString * const _Nonnull kMHSourceCodeEditorThemeManagerThemeWasRenamedNotification;
extern NSString * const _Nonnull kMHSourceCodeEditorEditorThemeChangeAffectedThemeName;
extern NSString * const _Nonnull kMHSourceCodeEditorEditorThemeRenamingNewNameKey;


NS_ASSUME_NONNULL_BEGIN

@class MHSourceCodeEditorTheme;
@interface MHSourceCodeEditorThemeManager : NSObject

@property (copy) NSString *userDefaultThemeName;
@property (readonly) MHSourceCodeEditorTheme *userDefaultTheme;

@property (readonly) NSUInteger numberOfPresetThemes;

+ (instancetype)defaultManager;     // a singleton object that manages the editor themes

- (NSArray <MHSourceCodeEditorTheme *> *)themes;
- (nullable MHSourceCodeEditorTheme *)themeWithName:(NSString *)name;   // returns nil if theme not found

- (MHSourceCodeEditorTheme *)defaultTheme;  // a theme to use as a default, for example when initializing an MHSourceCodeTextView
- (MHSourceCodeEditorTheme *)defaultThemeForQuotedCode;

- (nullable MHSourceCodeEditorTheme *)duplicateEditorThemeAndReturnNewThemeName:(NSString *)nameOfThemeToDuplicate; // returns nil if the operation was not successful

- (BOOL)applyAndSaveTheme:(MHSourceCodeEditorTheme *)workingCopyOfThemeToSave;  // returns YES if successful

- (BOOL)renameThemeWithName:(NSString *)oldName toName:(NSString *)newName; // returns YES if successful
- (BOOL)deleteThemeWithName:(NSString *)name;

- (BOOL)reorderThemesByMovingThemeWithIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex;


@end

NS_ASSUME_NONNULL_END
