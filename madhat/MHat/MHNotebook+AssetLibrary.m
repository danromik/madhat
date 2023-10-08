//
//  MHNotebook+AssetLibrary.m
//  MadHat
//
//  Created by Dan Romik on 10/16/20.
//  Copyright © 2020 Dan Romik. All rights reserved.
//

#import "MHNotebook+AssetLibrary.h"

#import <AppKit/AppKit.h>

NSString * const kMHAssetLibraryIBFileName = @"AssetLibrary";


@implementation MHNotebook (AssetLibrary)



#pragma mark - User actions

- (void)setAssetLibraryVisibleAndUpdateUserInterface:(BOOL)newValue
{
    _assetLibraryVisible = newValue;
    [self updateUserInterfaceForAssetLibraryVisibilityState];
}

- (void)updateUserInterfaceForAssetLibraryVisibilityState
{
    NSMenu *mainMenu = [[NSApplication sharedApplication] mainMenu];
    NSMenuItem *viewMenuItem = [mainMenu itemWithTag:kViewMenuItemTag];
    NSMenu *viewMenu = viewMenuItem.submenu;
    NSMenuItem *showHideAssetLibraryMenuItem = [viewMenu itemWithTag:kShowHideAssetLibraryMenuItemTag];
    showHideAssetLibraryMenuItem.title = (_assetLibraryVisible ?
                                          NSLocalizedString(@"Hide Media Library", @"") :
                                          NSLocalizedString(@"Show Media Library", @""));
}

- (IBAction)toggleAssetLibrary:(nullable id)sender
{
    if (_assetLibraryVisible)
        [self closeAssetLibrary:nil];
    else
        [self openAssetLibrary:nil];
}

- (IBAction)openAssetLibrary:(nullable id)sender
{
    if (_assetLibraryVisible)
        return;     // the asset library is already open - do nothing

    // Create and show the asset library window
    _assetLibraryWindowController = [[MHAssetLibraryController alloc] initWithWindowNibName:kMHAssetLibraryIBFileName];
    _assetLibraryWindowController.assetLibraryDelegate = self;
    [_assetLibraryWindowController showWindow:nil];
    // Important note: it's critical to set the "file's owner" object's "window" property in Interface Builder to the actual window in the xib file. Otherwise the window property of the window controller will be nil and this messes up notifications, programmatically closing the window etc
    
    if (_assetLibraryWindowController) {
        [self setAssetLibraryVisibleAndUpdateUserInterface:YES];
    }
    else {
        NSLog(@"Unable to load asset library window");
    }
    
    NSWindow *assetLibraryWindow = _assetLibraryWindowController.window;
    
    // Register as an observer for a window-closing operation on the asset library window
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(assetLibraryWindowWillClose:)
                                                 name:NSWindowWillCloseNotification
                                               object:assetLibraryWindow];
    
    NSString *windowTitleFromXib = [_assetLibraryWindowController.window title];
    NSString *notebookDisplayName = self.displayName;
    NSString *newWindowTitle = [NSString stringWithFormat:@"%@ (%@)", windowTitleFromXib, notebookDisplayName];
    assetLibraryWindow.title = newWindowTitle;
    
    [self setCurrentAssetTypeSublibrary:_currentAssetTypeSublibrary];
}

- (IBAction)closeAssetLibrary:(nullable id)sender
{
    if (!_assetLibraryVisible)
        return;     // the asset library is already closed - do nothing

    // Programmatically close the asset library window
    [_assetLibraryWindowController close];
    _assetLibraryWindowController = nil;
    [self setAssetLibraryVisibleAndUpdateUserInterface:NO];
    
    // FIXME: add functionality to toggle a menu item in the "View" menu between "Show Asset Library" and "Hide Asset Library"
    // see similar code in the -toggleMathFontEditor method of the AppDelegate class
}

- (void)assetLibraryWindowWillClose:(NSNotification *)notification
{
    if (_assetLibraryWindowController && [notification.object isEqualTo:_assetLibraryWindowController.window]) {
        // The user clicked the close button on the asset library editor window

        _assetLibraryWindowController = nil;

        // FIXME: add functionality to toggle a menu item in the "View" menu between "Show Asset Library" and "Hide Asset Library"
        // see similar code in the -toggleMathFontEditor method of the AppDelegate class

        // Update the boolean var keeping track of whether the asset library is open
        [self setAssetLibraryVisibleAndUpdateUserInterface:NO];
    }
}

- (MHAssetType)currentAssetTypeSublibrary
{
    return _currentAssetTypeSublibrary;
}

- (void)setCurrentAssetTypeSublibrary:(MHAssetType)assetType
{
    _currentAssetTypeSublibrary = assetType;
    if (_assetLibraryVisible) {
        [_assetLibraryWindowController setCurrentlyShowingAssetTypeSublibrary:assetType];
    }
}

- (void)assetTypeSublibraryChanged:(MHAssetType)newAssetType
{
    _currentAssetTypeSublibrary = newAssetType;
}





#pragma mark - Properties

// Note: a private declaration of this method is inserted in the main MHNotebook.m class implementation file. I declared it under a different category name AssetLibrarySilencingAWarning to silence a compiler warning. If the method here is changed, that declaration should be updated as well
- (NSArray <NSString *> *)indexFilenamesByAssetType
{
    static NSArray *indexFilenamesByAssetType;
    if (!indexFilenamesByAssetType) {
        // This will run just once
        indexFilenamesByAssetType = @[ kMHNotebookImageIndexFileName, kMHNotebookVideoIndexFileName ];
    }
    return indexFilenamesByAssetType;
}

// Note: a private declaration of this method is inserted in the main MHNotebook.m class implementation file. I declared it under a different category name AssetLibrarySilencingAWarning to silence a compiler warning. If the method here is changed, that declaration should be updated as well
- (NSArray <NSString *> *)assetFolderNamesByAssetType
{
    static NSArray *assetFolderNamesByAssetType;
    if (!assetFolderNamesByAssetType) {
        // This will run just once
        assetFolderNamesByAssetType = @[ kMHNotebookImagesFolderName, kMHNotebookVideoFolderName ];
    }
    return assetFolderNamesByAssetType;
}

- (NSArray <NSString *> *)indexOfAssetsOfType:(MHAssetType)assetType
{
    if (!_notebookFileWrapper) {
        // if there is no file wrapper for the notebook, that means there cannot be any assets in the assets library
        return @[ ];
    }
    
    NSDictionary <NSString *, NSFileWrapper *> *fileWrappers = _notebookFileWrapper.fileWrappers;
    NSFileWrapper *assetIndexFileWrapperForGivenAssetType = [fileWrappers objectForKey:[self.indexFilenamesByAssetType objectAtIndex:assetType]];
    
    if (!assetIndexFileWrapperForGivenAssetType) {
        // if there is no file wrapper for an index, that again means there are no asset of the specified type in the asset library
        return @[ ];
    }
    
    // Found the index, so read its contents and parse into an array of file names for the assets
    NSData *assetIndexData = [assetIndexFileWrapperForGivenAssetType regularFileContents];
    NSString *assetIndexString = [[NSString alloc] initWithData:assetIndexData encoding:NSUTF8StringEncoding];
    NSArray <NSString *> *assetFileNames = [assetIndexString componentsSeparatedByString:@"\n"];

    return assetFileNames;
}


- (NSData *)assetDataForAssetType:(MHAssetType)assetType filename:(NSString *)assetFilename
{
    if (!_notebookFileWrapper)
        return nil;
        
    NSDictionary <NSString *, NSFileWrapper *> *fileWrappers = _notebookFileWrapper.fileWrappers;
    NSFileWrapper *assetsFolderFileWrapper = [fileWrappers objectForKey:[self.assetFolderNamesByAssetType objectAtIndex:assetType]];
    NSDictionary <NSString *, NSFileWrapper *> *assetsOfGivenTypeFileWrappers = assetsFolderFileWrapper.fileWrappers;
    
    // Get the file wrapper associated with the filename
    NSFileWrapper *assetFileWrapperForFilename = assetsOfGivenTypeFileWrappers[assetFilename];
    if (!assetFileWrapperForFilename) {
        // If we didn't find the file wrapper right away, allow for the possibility that the file extension is missing
        // In that case we look for the first file wrapper whose filename without the path extension matches the
        // one provided
        
        for (NSString *filenameWithExtension in assetsOfGivenTypeFileWrappers) {
            if ([[filenameWithExtension stringByDeletingPathExtension] isEqualToString:assetFilename]) {
                assetFileWrapperForFilename = assetsOfGivenTypeFileWrappers[filenameWithExtension];
                break;
            }
        }
    }
    
    NSData *assetData = [assetFileWrapperForFilename regularFileContents];

    return assetData;
}

- (NSURL *)assetURLForAssetType:(MHAssetType)assetType filename:(NSString *)assetFilename
{
    if (!_notebookFileWrapper)
        return nil;
    
    NSDictionary <NSString *, NSFileWrapper *> *fileWrappers = _notebookFileWrapper.fileWrappers;
    NSFileWrapper *assetsFolderFileWrapper = [fileWrappers objectForKey:[self.assetFolderNamesByAssetType objectAtIndex:assetType]];
    NSDictionary <NSString *, NSFileWrapper *> *assetsOfGivenTypeFileWrappers = assetsFolderFileWrapper.fileWrappers;
    
    // Get the file wrapper associated with the filename
    NSFileWrapper *assetFileWrapperForFilename = assetsOfGivenTypeFileWrappers[assetFilename];
    if (!assetFileWrapperForFilename) {
        // If we didn't find the file wrapper right away, allow for the possibility that the file extension is missing
        // In that case we look for the first file wrapper whose filename without the path extension matches the
        // one provided
        
        for (NSString *filenameWithExtension in assetsOfGivenTypeFileWrappers) {
            if ([[filenameWithExtension stringByDeletingPathExtension] isEqualToString:assetFilename]) {
                assetFileWrapperForFilename = assetsOfGivenTypeFileWrappers[filenameWithExtension];
                break;
            }
        }
    }

    if (!assetFileWrapperForFilename)
        return nil;
    
    NSURL *notebookURL = self.fileURL;
    NSURL *assetsFolderForGivenAssetTypeURL = [notebookURL URLByAppendingPathComponent:
                                               [[self assetFolderNamesByAssetType] objectAtIndex:assetType]];
    NSURL *assetURL = [assetsFolderForGivenAssetTypeURL URLByAppendingPathComponent:assetFilename];
    return assetURL;
}


- (NSDictionary <NSString *, id> *)assetMetadataForAssetType:(MHAssetType)assetType filename:(NSString *)assetFilename
{
    if (!_notebookFileWrapper)
        return nil;
        
    NSDictionary <NSString *, NSFileWrapper *> *fileWrappers = _notebookFileWrapper.fileWrappers;
    NSFileWrapper *assetsFolderFileWrapper = [fileWrappers objectForKey:[self.assetFolderNamesByAssetType objectAtIndex:assetType]];
    NSDictionary <NSString *, NSFileWrapper *> *assetsOfGivenTypeFileWrappers = assetsFolderFileWrapper.fileWrappers;
    NSFileWrapper *assetFileWrapperForFilename = assetsOfGivenTypeFileWrappers[assetFilename];
    
    NSDictionary <NSString *,id> *assetFileAttributes = assetFileWrapperForFilename.fileAttributes;
    NSNumber *fileSizeNumber = assetFileAttributes[NSFileSize];
    NSUInteger fileSize = [fileSizeNumber integerValue];
    
    NSDictionary *assetInfo = @{
        kMHAssetLibraryAssetInfoFilesizeKey : [NSNumber numberWithUnsignedLong:fileSize]
        // FIXME: add additional fields, e.g. for image type, user notes, ... ?
    };
    
    return assetInfo;
}

- (NSUInteger)totalSizeOfAssetsOfType:(MHAssetType)assetType;
{
    NSUInteger totalBytes = 0;
    NSArray <NSString *> *assetsIndexForGivenAssetType = [self indexOfAssetsOfType:assetType];
    
    for (NSString *filename in assetsIndexForGivenAssetType) {
        NSDictionary <NSString *, id> *assetMetadata = [self assetMetadataForAssetType:assetType filename:filename];
        NSNumber *assetFileSizeNumber = (NSNumber *)(assetMetadata[kMHAssetLibraryAssetInfoFilesizeKey]);
        NSUInteger assetFileSize = [assetFileSizeNumber integerValue];
        totalBytes += assetFileSize;
    }
    
    return totalBytes;
}


#pragma mark - Library operations

- (void)createAssetIndexFileWrapperForAssetType:(MHAssetType)assetType withAssetIndexArray:(NSArray <NSString *> *)assetIndex
{
    [self invalidateAssetIndexFileWrapperForAssetType:assetType];
    
    NSUInteger numberOfAssets = assetIndex.count;
    NSUInteger counter = 0;
    NSMutableString *assetIndexString = [[NSMutableString alloc] initWithCapacity:0];
    for (NSString *assetFilename in assetIndex) {
        [assetIndexString appendFormat:(counter+1 < numberOfAssets ? @"%@\n" : @"%@"), assetFilename];
        counter++;
    }
    
    NSData *assetIndexStringData = [assetIndexString dataUsingEncoding:NSUTF8StringEncoding];
    
    // Here we're assuming that the image index either doesn't yet exist or it has been invalidated (through a call to invalidateAssetIndexFileWrapperForAssetType:) so it does not already exist within the root notebook file wrapper
    [_notebookFileWrapper addRegularFileWithContents:assetIndexStringData preferredFilename:[self.indexFilenamesByAssetType objectAtIndex:assetType]];
}

- (void)reorderAssetsOfType:(MHAssetType)assetType newOrdering:(NSArray <NSString *> *)list;
{
    // Note: this performs no validation of the new list, the assumption is that it contains the same images as the existing one
    [self createAssetIndexFileWrapperForAssetType:assetType withAssetIndexArray:list];
}

- (NSString *)addAssetOfType:(MHAssetType)assetType
                   assetData:(NSData *)assetData
           preferredFilename:(NSString *)assetFilename
              insertionIndex:(NSUInteger)index;
{
    // 1. Validate the asset filename. If it coincides with the filename of an asset that's already in the library or has other issues (for example if it begins with an underscore), find a unique new name
    NSString *actualAssetFilename = [self filenameForNewAssetOfType:assetType withPreferredFilename:assetFilename];
    
    
    // 2. Make sure we have a root folder file wrapper for the notebook
    if (!_notebookFileWrapper) {
        // calling the fileWrapperOfType: error: method simulates saving the notebook, and forces the creation of a file wrapper

        // FIXME: this seems like a reasonable approach, and seems to work in practice, but it's not clear
        // in the documentation of the NSDocument class if it should be considered okay to programmatically invoke this method
        // so this leaves a bit of doubt in my mind
        _notebookFileWrapper = [self fileWrapperOfType:kMHNotebookDocumentType error:nil];  // FIXME: also, actually calling this method already assigns the file wrapper that was created to the _notebookFileWrapper instance variable, so making the assignment again seems a bit pointless and potentially error-prone, or at least confusing. (Conceptually it's a violation of what is known as the single responsibility principle.) Consider improving
    }
    
    // 3. Update the asset index for the given asset type
    NSArray <NSString *> *oldAssetIndexOfGivenAssetType = [self indexOfAssetsOfType:assetType];
    NSMutableArray <NSString *> *newAssetIndex = [[NSMutableArray alloc] initWithArray:oldAssetIndexOfGivenAssetType];
    [newAssetIndex insertObject:actualAssetFilename atIndex:index];
    [self createAssetIndexFileWrapperForAssetType:assetType withAssetIndexArray:newAssetIndex];

    
    // 4. Make sure we have a folder file wrapper for the assets of the given type
    NSDictionary <NSString *, NSFileWrapper *> *fileWrappers = _notebookFileWrapper.fileWrappers;
    NSString *assetsFolderNameForGivenAssetType = [self.assetFolderNamesByAssetType objectAtIndex:assetType];
    NSFileWrapper *assetsFolderFileWrapperForGivenAssetType = fileWrappers[assetsFolderNameForGivenAssetType];
    if (!assetsFolderFileWrapperForGivenAssetType) {
        // create the file wrapper for the images folder
        assetsFolderFileWrapperForGivenAssetType = [[NSFileWrapper alloc] initDirectoryWithFileWrappers:@{ } ];
        assetsFolderFileWrapperForGivenAssetType.preferredFilename = assetsFolderNameForGivenAssetType;
        [_notebookFileWrapper addFileWrapper:assetsFolderFileWrapperForGivenAssetType];
    }
    
    // 5. Add the file wrapper for the new asset to the assets folder file wrapper
    [assetsFolderFileWrapperForGivenAssetType addRegularFileWithContents:assetData preferredFilename:actualAssetFilename];
    
    return actualAssetFilename;
}

- (NSString *)filenameForNewAssetOfType:(MHAssetType)assetType withPreferredFilename:(NSString *)preferredFilename
{
    NSString *actualFilenameToUse = nil;
    NSString *preferredFilenameWithoutExtension = [preferredFilename stringByDeletingPathExtension];
    NSString *preferredFilenameExtension = [preferredFilename pathExtension];
    
    NSString *preprocessedPreferredFilename;
    
    NSUInteger filenameWithoutExtensionLength = preferredFilenameWithoutExtension.length;
    
    if (filenameWithoutExtensionLength == 0) {
        // Don't want an empty filename
        preferredFilenameWithoutExtension = NSLocalizedString(@"New File", @"");
    }
    else {
        // Don't want a filename that begins with an underscore, so remove any leading underscores
        unichar aChar;
        NSUInteger charIndex = 0;
        while (charIndex < filenameWithoutExtensionLength &&
               (aChar = [preferredFilenameWithoutExtension characterAtIndex:charIndex]) == '_') {
            charIndex++;
        }
        
        if (charIndex > 0) {
            preferredFilenameWithoutExtension = [preferredFilenameWithoutExtension substringFromIndex:charIndex];
        }
    }
    
    preprocessedPreferredFilename = [preferredFilenameWithoutExtension stringByAppendingPathExtension:preferredFilenameExtension];

    
    // Now check if the filename clashes with an existing asset of the given type
    NSArray <NSString *> *assetIndexForGivenType = [self indexOfAssetsOfType:assetType];
    
    for (NSString *assetFilename in assetIndexForGivenType) {
        if ([preprocessedPreferredFilename isEqualToString:assetFilename]) {
            int duplicateFilenameIndex = 2;
            NSString *modifiedFilename;
            while (actualFilenameToUse == nil) {
                modifiedFilename = [NSString stringWithFormat:@"%@ %d.%@", preferredFilenameWithoutExtension,
                                    duplicateFilenameIndex, preferredFilenameExtension];
                bool modifiedFilenameAlreadyExistsInLibrary = false;
                for (NSString *anAsset in assetIndexForGivenType) {
                    if ([modifiedFilename isEqualToString:anAsset]) {
                        modifiedFilenameAlreadyExistsInLibrary = true;
                        duplicateFilenameIndex++;
                        break;
                    }
                }
                if (!modifiedFilenameAlreadyExistsInLibrary) {
                    actualFilenameToUse = modifiedFilename;
                }
            }
        }
        if (actualFilenameToUse)
            return actualFilenameToUse;
    }

    // if we ended up here, the preferred filename (after stripping udnerscores) is not a duplicate
    return preprocessedPreferredFilename;
}

- (void)deleteAssetOfType:(MHAssetType)assetType withIndex:(NSUInteger)assetIndex
{
    NSArray <NSString *> *oldAssetIndexForGivenType = [self indexOfAssetsOfType:assetType];
    NSString *assetToDeleteFilename = oldAssetIndexForGivenType[assetIndex];
    
    NSMutableArray <NSString *> *newAssetIndexForGivenType = [[NSMutableArray alloc] initWithArray:oldAssetIndexForGivenType];
    [newAssetIndexForGivenType removeObjectAtIndex:assetIndex];
    [self createAssetIndexFileWrapperForAssetType:assetType withAssetIndexArray:newAssetIndexForGivenType];
    
    NSDictionary <NSString *, NSFileWrapper *> *fileWrappers = _notebookFileWrapper.fileWrappers;
    NSString *assetsFolderNameForGivenAssetType = [self.assetFolderNamesByAssetType objectAtIndex:assetType];
    NSFileWrapper *assetsFolderFileWrapperForGivenType = fileWrappers[assetsFolderNameForGivenAssetType];
    NSDictionary <NSString *, NSFileWrapper *> *assetFileWrappersForGivenType = assetsFolderFileWrapperForGivenType.fileWrappers;
    NSFileWrapper *assetToDeleteFileWrapper = assetFileWrappersForGivenType[assetToDeleteFilename];
    [assetsFolderFileWrapperForGivenType removeFileWrapper:assetToDeleteFileWrapper];
    
    if (oldAssetIndexForGivenType.count == 1 && assetIndex == 0) {
        // deleting the only asset in the library of the given type, so also delete the assets folder and the asset index for that type
        [self invalidateAssetIndexFileWrapperForAssetType:assetType];
        [self invalidateAssetFolderFileWrapperForAssetType:assetType];
    }
}

- (void)renameAssetOfType:(MHAssetType)assetType withIndex:(NSUInteger)assetIndex newFilename:(NSString *)newAssetFilename
{
    // Note: we perform no validation here of the new filename. Make sure whoever calls this method does the validation, otherwise we could end up in an inconsistent state
    // FIXME: would it be more logical to perform the validation here?
    
    
    // Update the image index
    NSArray <NSString *> *oldAssetIndexForGivenType = [self indexOfAssetsOfType:assetType];
    NSString *oldAssetFilename = oldAssetIndexForGivenType[assetIndex];
    NSMutableArray <NSString *> *newAssetIndexForGivenType = [[NSMutableArray alloc] initWithArray:oldAssetIndexForGivenType];
    [newAssetIndexForGivenType replaceObjectAtIndex:assetIndex withObject:newAssetFilename];
    [self createAssetIndexFileWrapperForAssetType:assetType withAssetIndexArray:newAssetIndexForGivenType];

    
    NSDictionary <NSString *, NSFileWrapper *> *fileWrappers = _notebookFileWrapper.fileWrappers;
    NSFileWrapper *assetFolderFileWrapperForGivenType = fileWrappers[[self.assetFolderNamesByAssetType objectAtIndex:assetType]];
    NSDictionary <NSString *, NSFileWrapper *> *assetFileWrappersForGivenType = assetFolderFileWrapperForGivenType.fileWrappers;
    NSFileWrapper *assetToRenameFileWrapper = assetFileWrappersForGivenType[oldAssetFilename];
    
    
    // FIXME: in the code below we rename the file wrapper by deleting the old one and adding a new one. This seems kind of inefficient, but it works, and the documentation doesn't explain what's the proper way to rename a file wrapper so it's not clear that there's a better way
    
    // Get the data from the file to be renamed
    NSData *assetData = [assetToRenameFileWrapper regularFileContents];
    
    // Add a new file wrapper with the new filename
    [assetFolderFileWrapperForGivenType addRegularFileWithContents:assetData preferredFilename:newAssetFilename];

    // Delete the old image file wrapper
    [assetFolderFileWrapperForGivenType removeFileWrapper:assetToRenameFileWrapper];
}



- (NSImage *)imageResourceForIdentifier:(NSString *)identifier
{
    // FIXME: also enable retrieving the image by providing the filename without the file extension
    NSData *imageData = [self assetDataForAssetType:MHAssetImage filename:identifier];
    return [[NSImage alloc] initWithData:imageData];
}

- (nullable NSURL *)videoResourceForIdentifier:(NSString *)identifier
{
    return [self assetURLForAssetType:MHAssetVideo filename:identifier];
}

@end
