//
//  MHAssetLibraryController.h
//  MadHat
//
//  Created by Dan Romik on 10/16/20.
//  Copyright © 2020 Dan Romik. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NSTableViewWithDeleteShortcut.h"

// Note: if changing the enum, for example to add more asset types, the methods -indexFilenamesByAssetType and assetFolderNamesByAssetType of MHNotebook+AssetLibrary will need to be updated
// Note: the tabs of the main tab view in AssetLibrary.xib correspond exactly to the values of this enum. Make sure to update the tabs if the enum is changed
typedef enum {
    MHAssetImage = 0,
    MHAssetVideo = 1
} MHAssetType;
#define kMHAssetNumberOfAssetTypes      2



NS_ASSUME_NONNULL_BEGIN

extern NSString * const kMHAssetLibraryAssetDraggingPasteboardType; // the dragging info associated with this pasteboard type carries a dictionary with the keys being given by the string constants below

extern NSString * const kMHAssetLibraryAssetDraggingPasteboardTypeRowIndexKey;
extern NSString * const kMHAssetLibraryAssetDraggingPasteboardTypeFilenameKey;
extern NSString * const kMHAssetLibraryAssetDraggingPasteboardTypeAssetTypeKey;


// keys for the dictionary returned by the -assetMetadataForAssetType: method
extern NSString * const kMHAssetLibraryAssetInfoFilesizeKey;




@protocol MHAssetLibraryDelegate;

@interface MHAssetLibraryController : NSWindowController <NSTableViewDelegate, NSTableViewDataSource, NSTableViewWithDeleteShortcutDelegate, NSTabViewDelegate>

@property (weak) NSObject <MHAssetLibraryDelegate> *assetLibraryDelegate;
- (MHAssetType)currentlyShowingAssetTypeSublibrary;
- (void)setCurrentlyShowingAssetTypeSublibrary:(MHAssetType)assetType;


@end




@protocol MHAssetLibraryDelegate <NSObject>

- (NSArray <NSString *> *)indexOfAssetsOfType:(MHAssetType)assetType;       // returns an array of the filenames of images in the image library
- (NSUInteger)totalSizeOfAssetsOfType:(MHAssetType)assetType;

- (void)assetTypeSublibraryChanged:(MHAssetType)newAssetType;

// Library operations
- (void)reorderAssetsOfType:(MHAssetType)assetType newOrdering:(NSArray <NSString *> *)list;

// Returns the actual filename that was assigned to the asset
- (NSString *)addAssetOfType:(MHAssetType)assetType
                   assetData:(NSData *)assetData
           preferredFilename:(NSString *)assetFilename
              insertionIndex:(NSUInteger)index;

- (void)deleteAssetOfType:(MHAssetType)assetType withIndex:(NSUInteger)assetIndex;
- (void)renameAssetOfType:(MHAssetType)assetType withIndex:(NSUInteger)assetIndex newFilename:(NSString *)newAssetFilename;

// Retrieving an asset
- (nullable NSData *)assetDataForAssetType:(MHAssetType)assetType filename:(NSString *)assetFilename;
- (nullable NSURL *)assetURLForAssetType:(MHAssetType)assetType filename:(NSString *)assetFilename;

// Retrieving various useful parameters associated with a filename
- (nullable NSDictionary <NSString *, id> *)assetMetadataForAssetType:(MHAssetType)assetType filename:(NSString *)assetFilename;


// some methods that allow MHAssetLibraryController to serve as a bridge for certain UI operations that really should go to the MHNotebook (or other delegate) class
- (void)toggleAssetLibrary:(nullable id)sender;
- (void)updateUserInterfaceForAssetLibraryVisibilityState;

@end


NS_ASSUME_NONNULL_END
