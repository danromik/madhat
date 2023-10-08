//
//  MHMathFontManager.m
//  MadHat
//
//  Created by Dan Romik on 7/7/20.
//  Copyright © 2020 Dan Romik. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MHMathFontManager.h"
#import "MHMathFontSystem.h"

NSString * const kMHFontsResourceFolderRelativePath = @"math-kerning"; // the path is relative to the application's Application Support folders
NSString * const kMHMathFontsFileExtension = @"mhkrn";       // FIXME: Maybe this file extension should be specified in the Info.Plist file?

NSString * const kMHMathFontParametersChangedNotification = @"MHMathFontParametersChangedNotification";

@interface MHMathFontManager ()
{
    NSArray <NSURL *> *_availableMathFontURLs;
    NSArray <NSString *> *_availableMathFontNames;
    
    NSMutableDictionary <NSString *, MHMathFontSystem *> *_cachedFonts;
    
    MHMathFontSystem * _Nullable _currentlyEditingFont;
}

@property (readonly) NSArray <NSURL *> *availableMathFontURLs;


@end


@implementation MHMathFontManager


#pragma mark - Getter for singleton object

+ (instancetype)defaultManager
{
    static MHMathFontManager *_MHFontManagerSingletonInstance = nil;

    if (!_MHFontManagerSingletonInstance) {
        _MHFontManagerSingletonInstance = [[MHMathFontManager alloc] init];
    }
    return _MHFontManagerSingletonInstance;
}


#pragma mark - Constructor


- (instancetype)init
{
    if (self = [super init]) {
        _cachedFonts = [[NSMutableDictionary alloc] initWithCapacity:0];
    }
    return self;
}




#pragma mark - Getting all fonts or a specific font

- (NSArray <NSString *> *)availableMathFonts
{
    if (_availableMathFontNames)
        return _availableMathFontNames;
    [self lazilyLoadListOfAvailableMathFonts];
    return _availableMathFontNames;
}

- (MHMathFontSystem * _Nullable)mathFontWithName:(NSString *)mathFontName
{
    // If we are currently editing a font with this name, return it
    if ([_currentlyEditingFont.fontFamilyName isEqualToString:mathFontName]) {
        return _currentlyEditingFont;
    }
    
    // Next, look in the cache and return the cached font if found there
    MHMathFontSystem *font = _cachedFonts[mathFontName];
    if (font) {
        return font;
    }
    
    // Otherwise, look for the font in the list of available ones and read it from the URL, also caching it for future use
    NSURL *fontURL = [self urlForFontWithName:mathFontName];
    if (fontURL) {
        NSError *myError;
        NSString *fontFamilySerializedString = [NSString stringWithContentsOfURL:fontURL
                                                                        encoding:NSUTF8StringEncoding
                                                                           error:&myError];
        if (myError) {
            return nil;     // FIXME: Log some diagnostic information?
        }
        else {
            MHMathFontSystem *fontFromFile = [MHMathFontSystem fontFamilyFromSerializedStringRepresentation:fontFamilySerializedString];
            if (fontFromFile) {
                // add it to the cache for later use
                _cachedFonts[mathFontName] = fontFromFile;
            }
            return fontFromFile;
        }
    }
    return nil;     // FIXME: Log some diagnostic information?
}


#pragma mark - Operations on fonts: creation, deletion, saving

- (bool)createNewMathFontWithName:(NSString *)name
{
    MHMathFontSystem *newMathFontSystem = [[MHMathFontSystem alloc] initWithFontFamilyName:name];
    NSString *newMathFontString = [newMathFontSystem serializedStringRepresentation];
    
    NSString *familyNameWithExtension = [name stringByAppendingPathExtension:kMHMathFontsFileExtension];
    NSURL *fontFolderURL = [self userDomainMathFontFolder];
    
    NSError *myError;
    [[NSFileManager defaultManager] createDirectoryAtURL:fontFolderURL
                             withIntermediateDirectories:YES
                                              attributes:nil
                                                   error:&myError];
    if (myError)
        return false;   // FIXME: log some diagnostic information?
    
    NSURL *newFileURL = [fontFolderURL URLByAppendingPathComponent:familyNameWithExtension isDirectory:NO];
    
    [newMathFontString writeToURL:newFileURL
                       atomically:NO
                         encoding:NSUTF8StringEncoding
                            error:&myError];
    
    [self invalidateCachedData]; // FIXME: a bit wasteful since we're getting rid of some data that doesn't need to be reloaded, but should be okay for now
    
    return (myError == nil);    // FIXME: log some diagnostic information in case of error?
}

- (bool)deleteMathFontWithName:(NSString *)name
{
    NSURL *mathFontURL = [self urlForFontWithName:name];
    if (mathFontURL) {
        NSError *myError;
        [[NSFileManager defaultManager] removeItemAtURL:mathFontURL error:&myError];
        [self invalidateCachedData];    // FIXME: a bit wasteful since we're getting rid of some data that doesn't need to be reloaded, but doesn't seem like a big issue
        return (myError == nil);    // FIXME: log some diagnostic information in case of error?
    }
    return false;   // FIXME: log some diagnostic information?
}

- (bool)saveMathFont:(MHMathFontSystem *)font
{
    NSString *serializedStringRepresentation = [font serializedStringRepresentation];
    NSString *fontName = font.fontFamilyName;
    NSURL *fontURL = [self urlForFontWithName:fontName];
    if (fontURL) {
        NSError *myError;
        [serializedStringRepresentation writeToURL:fontURL
                                        atomically:NO
                                          encoding:NSUTF8StringEncoding
                                             error:&myError];
        [self invalidateCachedData]; // FIXME: a bit wasteful since we're getting rid of some data that doesn't need to be reloaded, but doesn't seem like a big issue
        return (myError == nil);     // FIXME: log some diagnostic information in case of error?
    }
    return false;   // FIXME: log some diagnostic information?
}


#pragma mark - Font editing

- (MHMathFontSystem * _Nullable)currentlyEditingFont
{
    return _currentlyEditingFont;
}

- (void)setCurrentlyEditingFont:(MHMathFontSystem *)currentlyEditingFont
{
    _currentlyEditingFont = currentlyEditingFont;
    [self currentlyEditingFontUpdated];
}

- (void)currentlyEditingFontUpdated
{
    if (_currentlyEditingFont) {
        NSNotification *notification = [NSNotification notificationWithName:kMHMathFontParametersChangedNotification object:_currentlyEditingFont];
        [[NSNotificationCenter defaultCenter] postNotification:notification];
    }
    else {
        // FIXME: do we want to post a notification here?
    }
}



#pragma mark - Private methods

- (NSArray <NSURL *> *)availableMathFontURLs
{
    if (_availableMathFontURLs)
        return _availableMathFontURLs;
    [self lazilyLoadListOfAvailableMathFonts];
    return _availableMathFontURLs;
}

- (void)lazilyLoadListOfAvailableMathFonts
{
    // Get the list of folders where fonts may be stored (typically the various "Application Support" folders)
    NSArray <NSURL *> *fontFolders = [self mathFontFolders];

    NSMutableArray <NSURL *> *fontFiles = [[NSMutableArray alloc] initWithCapacity:0];
    NSMutableArray <NSString *> *fontNames = [[NSMutableArray alloc] initWithCapacity:0];

    for (NSURL *folderUrl in fontFolders) {
        NSError *directoryLoadingError = nil;
        NSArray <NSURL *> *filesInFolder = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:folderUrl
                                                                         includingPropertiesForKeys:@[ NSURLIsRegularFileKey ]
                                                                                            options:0
                                                                                              error:&directoryLoadingError];
        if (!directoryLoadingError) {
            for (NSURL *fileURL in filesInFolder) {
                NSString *fontName = [[fileURL lastPathComponent] stringByDeletingPathExtension];
                [fontFiles addObject:fileURL];
                [fontNames addObject:fontName];
            }
        }
        else {
            // FIXME: should we NSLog the error? Do something else with it?
        }
    }
    
    _availableMathFontURLs = [NSArray arrayWithArray:fontFiles];
    _availableMathFontNames = [NSArray arrayWithArray:fontNames];
}

- (NSURL * _Nullable)urlForFontWithName:(NSString *)name
{
    NSArray <NSURL *> *availableMathFontURLs = self.availableMathFontURLs;
    for (NSURL *mathFontURL in availableMathFontURLs) {
        NSString *fontName = [[mathFontURL lastPathComponent] stringByDeletingPathExtension];
        if ([fontName isEqualToString:name]) {
            return mathFontURL;
        }
    }
    return nil;
}


- (NSArray <NSURL *> *)mathFontFolders
{
    NSArray <NSURL *> *urls = [[NSFileManager defaultManager]
                               URLsForDirectory:NSApplicationSupportDirectory
                               inDomains:NSAllDomainsMask];

    NSMutableArray <NSURL *> *appSpecificURLs = [[NSMutableArray alloc] initWithCapacity:0];
    NSString* appBundleID = [[NSBundle mainBundle] bundleIdentifier];

    // create a URL for the folder of default math fonts provided with the app bundle
    NSURL *fontFolderInAppBundle = [NSURL fileURLWithPath:[[[NSBundle mainBundle] resourcePath]
                                                           stringByAppendingPathComponent:kMHFontsResourceFolderRelativePath]
                                              isDirectory:YES];
    [appSpecificURLs addObject:fontFolderInAppBundle];
    
    for (NSURL *url in urls) {
        // create a URL for each Application Support directory the system tells us about
        NSURL *directoryWithAppIDComponentAddedURL = [url URLByAppendingPathComponent:appBundleID isDirectory:YES];
        NSURL *directoryWithAppIDAndFontsComponentAddedURL = [directoryWithAppIDComponentAddedURL
                                                              URLByAppendingPathComponent:kMHFontsResourceFolderRelativePath
                                                              isDirectory:YES];
        [appSpecificURLs addObject:directoryWithAppIDAndFontsComponentAddedURL];
    }
    return [NSArray arrayWithArray:appSpecificURLs];
}


- (NSURL *)userDomainMathFontFolder
{
    NSArray <NSURL *> *urls = [[NSFileManager defaultManager]
                               URLsForDirectory:NSApplicationSupportDirectory
                               inDomains:NSUserDomainMask];

    NSUInteger numberOfURLs = urls.count;
    if (numberOfURLs == 0)
        return nil;

    NSURL *url = urls[0];
    NSString* appBundleID = [[NSBundle mainBundle] bundleIdentifier];
    NSURL *directoryWithAppIDComponentAddedURL = [url URLByAppendingPathComponent:appBundleID isDirectory:YES];
    NSURL *directoryWithAppIDAndFontsComponentAddedURL = [directoryWithAppIDComponentAddedURL
                                                          URLByAppendingPathComponent:kMHFontsResourceFolderRelativePath
                                                          isDirectory:YES];
    return directoryWithAppIDAndFontsComponentAddedURL;
}

- (void)invalidateCachedData
{
    _availableMathFontURLs = nil;
    _availableMathFontNames = nil;
    [_cachedFonts removeAllObjects];
}

@end
