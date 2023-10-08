//
//  MHSourceCodeEditorThemeManager.m
//  MadHat
//
//  Created by Dan Romik on 12/6/21.
//  Copyright © 2021 Dan Romik. All rights reserved.
//

#import "MHSourceCodeEditorThemeManager.h"
#import "MHSourceCodeEditorTheme.h"
#import "NSFileManager+DirectoryLocations.h"
#import "MHUserDefaults.h"

static NSString * const kDefaultEditorTheme = @"Light";
static NSString * const kDefaultEditorThemeForQuotedCodeName = @"Light";

// FIXME: convert to static after eliminating obsolete code from the MHSourceCodeEditorTheme class
NSString * const kMHSourceCodeEditorThemesPlistBundledWithAppFilename = @"default-editor-themes";
NSString * const kMHSourceCodeEditorThemesPlistBundledWithAppFileExtension = @"plist";
NSString * const kMHSourceCodeEditorThemesPlistUserCreatedFilename = @"editor-themes";
NSString * const kMHSourceCodeEditorThemesPlistUserCreatedFileExtension = @"plist";

NSString * const kMHSourceCodeEditorThemeManagerThemesChangedNotification = @"MHSourceCodeEditorThemeManagerThemesChangedNotification";

NSString * const kMHSourceCodeEditorThemeManagerThemeWasRenamedNotification = @"MHSourceCodeEditorThemeManagerThemeWasRenamedNotification";
NSString * const kMHSourceCodeEditorEditorThemeChangeAffectedThemeName = @"name";
NSString * const kMHSourceCodeEditorEditorThemeRenamingNewNameKey = @"new name";



@interface MHSourceCodeEditorTheme (Private)
// Declaring a private method of MHSourceCodeEditorTheme that is used to facilitate the -defaultThemeForQuotedCode method
- (MHSourceCodeEditorTheme *)copyWithErrorHighlightingDisabled;
@end



@interface MHSourceCodeEditorThemeManager ()
{
    NSArray <MHSourceCodeEditorTheme *> *_themes;
    MHSourceCodeEditorTheme *_defaultTheme;
    MHSourceCodeEditorTheme *_defaultThemeForQuotedCode;
    NSUInteger _numberOfPresetThemes;
    NSString *_userDefaultThemeName;
}

@end

@implementation MHSourceCodeEditorThemeManager

+ (instancetype)defaultManager
{
    static MHSourceCodeEditorThemeManager *_defaultManager;
    if (!_defaultManager) {
        _defaultManager = [[MHSourceCodeEditorThemeManager alloc] init];
    }
    return _defaultManager;
}

- (NSArray <MHSourceCodeEditorTheme *> *)themes
{
    NSMutableArray <MHSourceCodeEditorTheme *> *themesMutableArray = [[NSMutableArray alloc] initWithCapacity:0];
    if (!_themes) {
        // load the editor themes bundled with the app
        NSString *editorThemesBundledWithAppFilename = [[NSBundle mainBundle]
                                                        pathForResource:kMHSourceCodeEditorThemesPlistBundledWithAppFilename
                                                        ofType:kMHSourceCodeEditorThemesPlistBundledWithAppFileExtension];
        NSArray *allBundledEditorThemesArray = [NSArray arrayWithContentsOfFile:editorThemesBundledWithAppFilename];
        
        if (allBundledEditorThemesArray) {
            [themesMutableArray addObjectsFromArray:[self themesFromArrayOfDictionaries:allBundledEditorThemesArray
                                       makeEditable:NO]];
        }
        
        _numberOfPresetThemes = themesMutableArray.count;
        
        // load the user-created editor themes
        NSString *userCreatedEditorThemesFilepath = [self filepathForUserCreatedThemesFile];
        if (userCreatedEditorThemesFilepath) {
            NSArray *allUserCreatedEditorThemesArray = [NSArray arrayWithContentsOfFile:userCreatedEditorThemesFilepath];
            if (allUserCreatedEditorThemesArray) {
                [themesMutableArray addObjectsFromArray:[self themesFromArrayOfDictionaries:allUserCreatedEditorThemesArray
                                                                               makeEditable:YES]];
            }
            else {
                // no user-created themes found - no need to do anything
            }
        }
        
        if (themesMutableArray.count == 0) {
            // FIXME: as a failsafe in case we haven't managed to load any themes, create a default one programmatically to ensure we always have something
        }
        
        _themes = [NSArray arrayWithArray:themesMutableArray];
        
        _userDefaultThemeName = [[NSUserDefaults standardUserDefaults] stringForKey:kMHUserDefaultsEditorThemeKey];
        if (![self themeWithName:_userDefaultThemeName]) {
            // if the theme associated with the default theme name does not exist, use the first theme on the list as a default
            _userDefaultThemeName = _themes[0].name;
        }
    }
    return _themes;
}

- (NSUInteger)numberOfPresetThemes
{
    return _numberOfPresetThemes;
}

- (NSString *)userDefaultThemeName
{
    if (![self themeWithName:_userDefaultThemeName]) {
        // if the theme associated with the default theme name does not exist, use the first theme on the list as a default
        _userDefaultThemeName = _themes[0].name;
    }
    return _userDefaultThemeName;
}

- (MHSourceCodeEditorTheme *)userDefaultTheme
{
    MHSourceCodeEditorTheme *theme = [self themeWithName:self.userDefaultThemeName];
    if (!theme)
        theme = self.themes[0];
    return theme;
}

- (void)setUserDefaultThemeName:(NSString *)userDefaultThemeName
{
    _userDefaultThemeName = [userDefaultThemeName copy];
    [[NSUserDefaults standardUserDefaults] setValue:_userDefaultThemeName forKey:kMHUserDefaultsEditorThemeKey];
}

- (NSArray <MHSourceCodeEditorTheme *> *)themesFromArrayOfDictionaries:(NSArray <NSDictionary *> *)arrayOfDicts
                                                          makeEditable:(BOOL)editable
{
    NSMutableArray *mutableArray = [[NSMutableArray alloc] initWithCapacity:0];
    for (NSDictionary *editorThemeDict in arrayOfDicts) {
        MHSourceCodeEditorTheme *editorTheme = [MHSourceCodeEditorTheme themeWithDictionaryRepresentation:editorThemeDict];
        editorTheme.editable = editable;
        [mutableArray addObject:editorTheme];
    }
    return mutableArray;
}

- (MHSourceCodeEditorTheme *)themeWithName:(NSString *)name
{
    for (MHSourceCodeEditorTheme *theme in self.themes) {
        if ([name isEqualToString:theme.name]) {
            return theme;
        }
    }
    return nil;
}

- (MHSourceCodeEditorTheme *)defaultTheme
{
    if (!_defaultTheme) {
        _defaultTheme = [[self themeWithName:kDefaultEditorTheme] copy];
        _defaultTheme.editable = NO;
    }
    return _defaultTheme;
}

- (MHSourceCodeEditorTheme *)defaultThemeForQuotedCode
{
    if (!_defaultThemeForQuotedCode) {
        _defaultThemeForQuotedCode = [[self themeWithName:kDefaultEditorThemeForQuotedCodeName] copyWithErrorHighlightingDisabled];
        _defaultThemeForQuotedCode.name = [NSString stringWithFormat:@"%@ (help)", kDefaultEditorThemeForQuotedCodeName];
        _defaultThemeForQuotedCode.editable = NO;
    }
    return _defaultThemeForQuotedCode;
}









- (MHSourceCodeEditorTheme *)duplicateEditorThemeAndReturnNewThemeName:(NSString *)nameOfThemeToDuplicate
{
    MHSourceCodeEditorTheme *themeToDuplicate = [self themeWithName:nameOfThemeToDuplicate];
    if (!themeToDuplicate)
        return nil;
    
    NSString *copySuffix = @" copy";
    NSUInteger copySuffixLength = copySuffix.length;
    NSUInteger nameOfThemeToDuplicateLength = nameOfThemeToDuplicate.length;
    NSString *simplifiedThemeNameForCopying;
    
    if (nameOfThemeToDuplicateLength > copySuffixLength &&
        [[nameOfThemeToDuplicate substringFromIndex:nameOfThemeToDuplicateLength-copySuffixLength]
         isEqualToString:copySuffix]) {
        simplifiedThemeNameForCopying = [nameOfThemeToDuplicate substringToIndex:nameOfThemeToDuplicateLength-copySuffixLength];
    }
    else {
        simplifiedThemeNameForCopying = nameOfThemeToDuplicate;
    }
    
    NSUInteger index = 2;
    NSString *newThemeName = [NSString stringWithFormat:NSLocalizedString(@"%@ copy", @""), simplifiedThemeNameForCopying];
    while ([self themeWithName:newThemeName] != nil && index < 500) {
        newThemeName = [NSString stringWithFormat:NSLocalizedString(@"%@ copy %lu", @""), simplifiedThemeNameForCopying, index];
        index++;
    }
    if (index == 500) { // this should never happen, but fail gracefully if it does
        NSBeep();
        return nil;
    }
    
    MHSourceCodeEditorTheme *newTheme = [themeToDuplicate copy];
    newTheme.editable = YES;
    newTheme.name = newThemeName;
    NSMutableArray *newThemesMutableArray = [[NSMutableArray alloc] initWithArray:self.themes];
    [newThemesMutableArray addObject:newTheme];
    _themes = [NSArray arrayWithArray:newThemesMutableArray];
    
    [self saveUserCreatedThemes];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kMHSourceCodeEditorThemeManagerThemesChangedNotification
                                                        object:self];
    
    return newTheme;
}

- (BOOL)applyAndSaveTheme:(MHSourceCodeEditorTheme *)workingCopyOfThemeToSave
{
    NSString *name = workingCopyOfThemeToSave.name;
    MHSourceCodeEditorTheme *currentlySavedTheme = [self themeWithName:name];
    if (currentlySavedTheme) {
        NSMutableArray *newThemesMutableArray = [[NSMutableArray alloc] initWithArray:self.themes];
        NSUInteger indexOfCurrentlySavedTheme = [newThemesMutableArray indexOfObject:currentlySavedTheme];
        MHSourceCodeEditorTheme *freshCopyOfThemeToSave = [workingCopyOfThemeToSave copy];
        [newThemesMutableArray replaceObjectAtIndex:indexOfCurrentlySavedTheme withObject:freshCopyOfThemeToSave];
        _themes = [NSArray arrayWithArray:newThemesMutableArray];

        NSNotification *notification = [NSNotification notificationWithName:kMHSourceCodeEditorThemeManagerThemesChangedNotification
                                                                     object:self
                                                                    userInfo:@{
                                                                        kMHSourceCodeEditorEditorThemeChangeAffectedThemeName : name
                                                                    }];
        
        [self saveUserCreatedThemes];
        
        [[NSNotificationCenter defaultCenter] postNotification:notification];

        return YES;
    }
    
    return NO;
}

- (BOOL)renameThemeWithName:(NSString *)oldName toName:(NSString *)newName
{
    // Check if the new name clashes with an existing theme name
    if ([self themeWithName:newName])
        return NO;
    
    MHSourceCodeEditorTheme *themeBeingRenamed = [self themeWithName:oldName];
    if (!themeBeingRenamed)
        return NO;      // the theme to rename doesn't exist
    
    if (!themeBeingRenamed.editable)
        return NO;      // the theme to rename exists but isn't editable
    
    NSString *userDefaultThemeName = self.userDefaultThemeName;

    themeBeingRenamed.name = newName;
    
    if ([userDefaultThemeName isEqualToString:oldName])
        self.userDefaultThemeName = newName;
    
    [self saveUserCreatedThemes];

    NSNotification *notification = [NSNotification notificationWithName:kMHSourceCodeEditorThemeManagerThemeWasRenamedNotification
                                                                  object:self
                                                                userInfo:@{
                                                                    kMHSourceCodeEditorEditorThemeChangeAffectedThemeName : oldName,
                                                                    kMHSourceCodeEditorEditorThemeRenamingNewNameKey : newName
                                                                }];
    [[NSNotificationCenter defaultCenter] postNotification:notification];
    
    return YES;
}

- (BOOL)deleteThemeWithName:(NSString *)name
{
    MHSourceCodeEditorTheme *theme = [self themeWithName:name];
    if (!theme)
        return NO;  // the theme was not found
    
    NSMutableArray *newThemesMutableArray = [[NSMutableArray alloc] initWithArray:self.themes];
    [newThemesMutableArray removeObject:theme];
    _themes = [NSArray arrayWithArray:newThemesMutableArray];
    
    [self saveUserCreatedThemes];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kMHSourceCodeEditorThemeManagerThemesChangedNotification
                                                        object:self];
    
    return YES;
}

- (BOOL)reorderThemesByMovingThemeWithIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex
{
    if (toIndex == fromIndex)
        return NO;
    
    NSMutableArray *newThemesMutableArray = [[NSMutableArray alloc] initWithArray:self.themes];
    MHSourceCodeEditorThemeManager *theme = newThemesMutableArray[fromIndex];
    [newThemesMutableArray removeObjectAtIndex:fromIndex];
    [newThemesMutableArray insertObject:theme atIndex:(fromIndex < toIndex ? toIndex-1 : toIndex)];
    _themes = [NSArray arrayWithArray:newThemesMutableArray];
    
    [self saveUserCreatedThemes];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kMHSourceCodeEditorThemeManagerThemesChangedNotification
                                                        object:self];
    
    return YES;
}


- (nullable NSString *)filepathForUserCreatedThemesFile
{
    NSString *applicationSupportDirectory = [[NSFileManager defaultManager] applicationSupportDirectory];
    if (!applicationSupportDirectory)
        return nil;
    
    NSString *userCreatedEditorThemesFilename = [kMHSourceCodeEditorThemesPlistUserCreatedFilename
                          stringByAppendingPathExtension:kMHSourceCodeEditorThemesPlistUserCreatedFileExtension];
    NSString *userCreatedEditorThemesFilepath = [applicationSupportDirectory
                                                 stringByAppendingPathComponent:userCreatedEditorThemesFilename];
    return userCreatedEditorThemesFilepath;
}

- (void)saveUserCreatedThemes
{
    NSMutableArray *arrayOfThemeDictionaries = [[NSMutableArray alloc] initWithCapacity:self.themes.count];
    for (MHSourceCodeEditorTheme *theme in self.themes) {
        if (theme.editable) {
            NSDictionary *themeDict = [theme dictionaryRepresentation];
            [arrayOfThemeDictionaries addObject:themeDict];
        }
    }
    
    NSString *filepathToSave = [self filepathForUserCreatedThemesFile];
    [arrayOfThemeDictionaries writeToFile:filepathToSave atomically:YES];
}

@end
