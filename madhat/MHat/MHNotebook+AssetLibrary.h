//
//  MHNotebook+AssetLibrary.h
//  MadHat
//
//  Created by Dan Romik on 10/16/20.
//  Copyright © 2020 Dan Romik. All rights reserved.
//

#import <AppKit/AppKit.h>

#import "MHNotebook.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString * const kMHAssetLibraryAssetInfoFilesizeKey;


@interface MHNotebook (AssetLibrary) <MHAssetLibraryDelegate, MHResourceProvider>


- (void)toggleAssetLibrary:(nullable id)sender;
- (void)openAssetLibrary:(nullable id)sender;
- (void)closeAssetLibrary:(nullable id)sender;

- (MHAssetType)currentAssetTypeSublibrary;
- (void)setCurrentAssetTypeSublibrary:(MHAssetType)assetType;

- (void)updateUserInterfaceForAssetLibraryVisibilityState;


@end


NS_ASSUME_NONNULL_END
