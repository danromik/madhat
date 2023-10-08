//
//  MHAssetLibraryController.m
//  MadHat
//
//  Created by Dan Romik on 10/16/20.
//  Copyright © 2020 Dan Romik. All rights reserved.
//

#import <AVKit/AVKit.h>
#import "NSImageViewWithOutboundDragging.h"
#import "MHAssetLibraryController.h"
#import "MHNotebook.h"

// Note: Make sure that these defines match the ordering of the segments in the segmented control as defined in AssetLibrary.xib
#define kMHAssetLibraryActionAddAssetSegmentIndex       0
#define kMHAssetLibraryActionDeleteAssetSegmentIndex    1

#define kMHAssetLibraryNoSelectedAsset             (-1)

NSString * const kMHAssetLibraryAssetDraggingPasteboardType = @"design.madhat.asset";
NSString * const kMHAssetLibraryAssetDraggingPasteboardTypeRowIndexKey = @"rowindex";
NSString * const kMHAssetLibraryAssetDraggingPasteboardTypeFilenameKey = @"filename";
NSString * const kMHAssetLibraryAssetDraggingPasteboardTypeAssetTypeKey = @"assettype";

NSString * const kMHAssetLibraryAssetInfoFilesizeKey = @"filesize";



@interface NSString (UserFriendlyFileSizeStrings)

// A convenience method defined at the end of this source file
+ (NSString *)userFriendlyFilesizeStringForFilesize:(NSUInteger)filesize;

@end




@interface MHAssetLibraryController ()
{
    __weak NSObject <MHAssetLibraryDelegate> *_assetLibraryDelegate;
    
//    NSMutableArray <NSString *> *_imageFilenames;
//    NSInteger _selectedImageIndex;           // a value of kMHAssetLibraryNoSelectedAsset means there is no selected image
    
    MHAssetType _currentAssetType;          // the asset type for the part of the asset library currently being viewed
    NSArray <NSTableView *> *_filenameTablesByAssetType;
    NSArray <NSTextField *> *_libraryInfoLabelsByAssetType;
    NSArray <NSTextField *> *_filenameLabelsByAssetType;
    NSArray <NSTextField *> *_fileSizeLabelsByAssetType;
    NSArray <NSTextField *> *_assetPointSizeLabelsByAssetType;
    NSArray <NSTextField *> *_assetFormatLabelsByAssetType;
    NSArray <NSSegmentedControl *> *_assetActionSegmentedControlsByAssetType;

    NSMutableArray <NSNumber *> *_selectedAssetIndicesByAssetType;         // each NSNumber contains an NSInteger data type. A value of kMHAssetLibraryNoSelectedAsset signifies no selection for that asset type
    NSArray <NSMutableArray <NSString *> *> *_listsOfAssetFilenamesByAssetType;
}

@property IBOutlet NSTabView *mainTabView;

@property IBOutlet NSTableView *imageFilenamesTable;
@property IBOutlet NSTextField *imageLibraryInfoLabel;
@property IBOutlet NSTextField *imageFilenameLabel;
@property IBOutlet NSTextField *imageFilesizeLabel;
@property IBOutlet NSTextField *imageFormatLabel;
@property IBOutlet NSTextField *imageSizeLabel;
@property IBOutlet NSView *imageContainerView;
@property IBOutlet NSSegmentedControl *imageActionsSegmentedControl;

@property IBOutlet NSTableView *videoFilenamesTable;
@property IBOutlet NSTextField *videoLibraryInfoLabel;
@property IBOutlet NSTextField *videoFilenameLabel;
@property IBOutlet NSTextField *videoFilesizeLabel;
@property IBOutlet NSTextField *videoFormatLabel;
@property IBOutlet NSTextField *videoSizeLabel;
@property IBOutlet NSTextField *videoDurationLabel;
@property IBOutlet AVPlayerView *videoPlayerView;
@property IBOutlet NSSegmentedControl *videoActionsSegmentedControl;

@end

@implementation MHAssetLibraryController




#pragma mark - Initialization

- (instancetype)initWithWindowNibName:(NSNibName)windowNibName
{
    if (self = [super initWithWindowNibName:windowNibName]) {
        // initialize some useful data structure to keep track of the lists of filenames for assets of different types, and which asset of each type is selected
        
        _selectedAssetIndicesByAssetType = [[NSMutableArray alloc] initWithCapacity:kMHAssetNumberOfAssetTypes];
        NSMutableArray *listsOfAssetFilenamesByAssetType = [[NSMutableArray alloc] initWithCapacity:kMHAssetNumberOfAssetTypes];
        
        for (MHAssetType assetType = 0; assetType < kMHAssetNumberOfAssetTypes; assetType++) {
            [_selectedAssetIndicesByAssetType addObject:[NSNumber numberWithInteger:kMHAssetLibraryNoSelectedAsset]];
            NSMutableArray <NSString *> *listOfAssetFilenames = [[NSMutableArray alloc] initWithCapacity:0];
            [listsOfAssetFilenamesByAssetType addObject:listOfAssetFilenames];
        }
        _listsOfAssetFilenamesByAssetType = [NSArray arrayWithArray:listsOfAssetFilenamesByAssetType];
    }
    return self;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Store the UI elements in array indexed by asset type for easy access
    _filenameTablesByAssetType = @[ self.imageFilenamesTable, self.videoFilenamesTable ];
    _libraryInfoLabelsByAssetType = @[ self.imageLibraryInfoLabel, self.videoLibraryInfoLabel ];
    _filenameLabelsByAssetType = @[ self.imageFilenameLabel, self.videoFilenameLabel ];
    _fileSizeLabelsByAssetType = @[ self.imageFilesizeLabel, self.videoFilesizeLabel ];
    _assetPointSizeLabelsByAssetType = @[ self.imageSizeLabel, self.videoSizeLabel ];
    _assetFormatLabelsByAssetType = @[ self.imageFormatLabel, self.videoFormatLabel ];
    _assetActionSegmentedControlsByAssetType = @[ self.imageActionsSegmentedControl, self.videoActionsSegmentedControl ];

    for (MHAssetType assetType = 0; assetType < kMHAssetNumberOfAssetTypes; assetType++) {
        [self reloadAssetLibraryForAssetType:assetType];
        [self setSelectedAssetIndexForAssetType:assetType toIndex:kMHAssetLibraryNoSelectedAsset];
        [_filenameTablesByAssetType[assetType] registerForDraggedTypes:@[ kMHAssetLibraryAssetDraggingPasteboardType, NSPasteboardTypeFileURL ]];
    }
}


- (MHAssetType)currentlyShowingAssetTypeSublibrary
{
    return (MHAssetType)[self.mainTabView indexOfTabViewItem:[self.mainTabView selectedTabViewItem]];
}

- (void)setCurrentlyShowingAssetTypeSublibrary:(MHAssetType)assetType
{
    if (assetType >= 0 && assetType < kMHAssetNumberOfAssetTypes) {
        [self.mainTabView selectTabViewItemAtIndex:assetType];
    }
}


#pragma mark - Properties

- (NSObject <MHAssetLibraryDelegate> *)assetLibraryDelegate
{
    return _assetLibraryDelegate;
}

- (void)setAssetLibraryDelegate:(NSObject <MHAssetLibraryDelegate> *)delegate
{
    _assetLibraryDelegate = delegate;
    
    // Load and cache the image index
    for (MHAssetType assetType = 0; assetType < kMHAssetNumberOfAssetTypes; assetType++) {
        [_listsOfAssetFilenamesByAssetType[assetType] removeAllObjects];
        [_listsOfAssetFilenamesByAssetType[assetType] addObjectsFromArray:[delegate indexOfAssetsOfType:assetType]];
    }
}

- (NSInteger)selectedAssetIndexForAssetType:(MHAssetType)assetType;
{
    NSNumber *selectedAssetIndexNumber = _selectedAssetIndicesByAssetType[assetType];
    return [selectedAssetIndexNumber integerValue];
}

- (void)setSelectedAssetIndexForAssetType:(MHAssetType)assetType toIndex:(NSInteger)index
{
    static const NSInteger imageViewTag = 100;
    
    [_selectedAssetIndicesByAssetType replaceObjectAtIndex:assetType withObject:[NSNumber numberWithInteger:index]];
    
    if (index == kMHAssetLibraryNoSelectedAsset) {
        [_filenameTablesByAssetType[assetType] deselectAll:nil];

        if (assetType == MHAssetImage) {
            [(NSImageViewWithOutboundDragging *)[self.imageContainerView viewWithTag:imageViewTag] setImage:nil];
            self.imageFilenameLabel.stringValue = NSLocalizedString(@"(no image selected)", @"");
        }
        else {
            self.videoFilenameLabel.stringValue = NSLocalizedString(@"(no video selected)", @"");
            self.videoDurationLabel.stringValue = @"";
            self.videoPlayerView.player = nil;
            self.videoPlayerView.hidden = YES;
        }
        
        (_fileSizeLabelsByAssetType[assetType]).stringValue = @"";
        (_assetPointSizeLabelsByAssetType[assetType]).stringValue = @"";
        (_assetFormatLabelsByAssetType[assetType]).stringValue = @"";

        [_assetActionSegmentedControlsByAssetType[assetType] setEnabled:false forSegment:kMHAssetLibraryActionDeleteAssetSegmentIndex];
    }
    else {
        [_filenameTablesByAssetType[assetType] selectRowIndexes:[NSIndexSet indexSetWithIndex:index] byExtendingSelection:NO];
        
        NSString *selectedAssetName = [_listsOfAssetFilenamesByAssetType[assetType] objectAtIndex:index];
        NSDictionary *selectedAssetMetadata = [self.assetLibraryDelegate assetMetadataForAssetType:assetType filename:selectedAssetName];
        NSUInteger selectedAssetFileSize = [(NSNumber *)(selectedAssetMetadata[kMHAssetLibraryAssetInfoFilesizeKey]) integerValue];
        NSString *selectedAssetFileSizeString = [NSString userFriendlyFilesizeStringForFilesize:selectedAssetFileSize];
        
        [_filenameLabelsByAssetType[assetType] setStringValue:selectedAssetName];
        [_fileSizeLabelsByAssetType[assetType] setStringValue:selectedAssetFileSizeString];
        
        [_assetActionSegmentedControlsByAssetType[assetType] setEnabled:true forSegment:kMHAssetLibraryActionDeleteAssetSegmentIndex];
        
        CFStringRef assetUTICFString = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension,
                                                                     (__bridge CFStringRef)[selectedAssetName pathExtension], NULL);
        CFStringRef assetUTIDescriptionCFString = UTTypeCopyDescription(assetUTICFString);
        NSString *UTIDescription = (__bridge NSString *)assetUTIDescriptionCFString;
        (_assetFormatLabelsByAssetType[assetType]).stringValue = UTIDescription;
        CFRelease(assetUTICFString);
        CFRelease(assetUTIDescriptionCFString);


        // Some of the code for how to present the selected asset is specific to the asset type, so is listed as a switch statement:
        switch (assetType) {
            case MHAssetImage: {
                NSString *imageName = selectedAssetName;

                // retrieve the image
                NSData *imageData = [self.assetLibraryDelegate assetDataForAssetType:MHAssetImage filename:imageName];
                NSImage *image = [[NSImage alloc] initWithData:imageData];
                
                NSSize imageSize = image.size;
                NSString *imageSizeString = [NSString stringWithFormat:NSLocalizedString(@"%ld × %ld pixels", @""), (NSUInteger)(imageSize.width), (NSUInteger)(imageSize.height)];

                self.imageSizeLabel.stringValue = imageSizeString;          // FIXME: this shows as 0 bytes if the notebook was created in this session, or if the image filename was renamed, and maybe other times - improve
                
                // Retrieve the image view (or create it if it doesn't yet exist)
                NSImageViewWithOutboundDragging *imageView = [self.imageContainerView viewWithTag:imageViewTag];
                if (!imageView) {
                    imageView = [NSImageViewWithOutboundDragging imageViewWithImage:image];
                    NSRect imageContainerViewBounds = self.imageContainerView.bounds;
                    static CGFloat horizontalPadding = 20.0; // FIXME: improve? Would be better if this were defined in the xib
                    static CGFloat verticalPadding = 16.0;   // FIXME: improve? Would be better if this were defined in the xib
                    imageView.frame = NSMakeRect(horizontalPadding, verticalPadding,
                                                 imageContainerViewBounds.size.width-2*horizontalPadding,
                                                 imageContainerViewBounds.size.height-2*verticalPadding);
                    imageView.tag = imageViewTag;
                    [self.imageContainerView addSubview:imageView];
                }
                
                // Set the image view's image to the selected image, and also store the image filename and file data for possible use later when the user wants to drag and drop the image file somewhere
                imageView.image = image;
                imageView.imageFilename = imageName;
                imageView.imageFileData = imageData;
                imageView.alternativePasteboardType = kMHAssetLibraryAssetDraggingPasteboardType;
                
                NSPasteboardItem *pasteboardWritingObject =
                (NSPasteboardItem *)[self tableView:self.imageFilenamesTable
                             pasteboardWriterForRow:index];
                NSObject *propertyListObject = [pasteboardWritingObject
                                                propertyListForType:kMHAssetLibraryAssetDraggingPasteboardType];
                
                imageView.propertyListDraggingContentForAlternativePasteboardType = propertyListObject;
            }
                break;
            case MHAssetVideo: {
                NSURL *videoURL = [self.assetLibraryDelegate assetURLForAssetType:assetType filename:selectedAssetName];
                AVPlayer *videoPlayer = [AVPlayer playerWithURL:videoURL];
                
                CGSize videoSize;
                AVPlayerItem *videoItem = videoPlayer.currentItem;
                AVAssetTrack *track = [[videoItem.asset tracksWithMediaType:AVMediaTypeVideo] firstObject];
                if (track)
                    videoSize = [track naturalSize];
                
                CMTime videoDuration = videoItem.asset.duration;    // for an explanation of why this is better than videoItem.duration, see: https://stackoverflow.com/questions/52664180/mojave-macos-10-14-0-avplayeritem-duration-is-always-indefinite
                double videoDurationInSeconds = (double)(CMTimeGetSeconds(videoDuration));
                NSUInteger videoDurationInSecondsAsInteger = (NSUInteger)videoDurationInSeconds;
                NSUInteger hours = videoDurationInSecondsAsInteger / 3600;
                NSUInteger minutes = (videoDurationInSecondsAsInteger-3600*hours) / 60;
                NSUInteger seconds = videoDurationInSecondsAsInteger-3600*hours - 60 * minutes;
                NSString *durationString;
                if (hours == 0)
                    durationString = [NSString stringWithFormat:@"%0.2lu:%0.2lu", minutes, seconds];
                else
                    durationString = [NSString stringWithFormat:@"%lu:%0.2lu:%0.2lu", hours, minutes, seconds];
                self.videoDurationLabel.stringValue = durationString;
                
                NSString *videoSizeString = [NSString stringWithFormat:NSLocalizedString(@"%ld × %ld pixels", @""), (NSUInteger)(videoSize.width), (NSUInteger)(videoSize.height)];

                self.videoSizeLabel.stringValue = videoSizeString;          // FIXME: this shows as 0 bytes if the notebook was created in this session, or if the image filename was renamed, and maybe other times - improve
                
                self.videoPlayerView.player = videoPlayer;
                if (@available(macOS 10.15, *)) {
                    self.videoPlayerView.showsTimecodes = YES;
                } else {
                    // it's okay, we can manage without the time codes
                }
                self.videoPlayerView.hidden = NO;
            }
                break;
        }
    }
}

#pragma mark - Displaying the library

- (void)reloadAssetLibraryForAssetType:(MHAssetType)assetType
{
    [_filenameTablesByAssetType[assetType] reloadData];
    
    NSUInteger numberOfAssetsOfGivenType = [_listsOfAssetFilenamesByAssetType[assetType] count];
    if (numberOfAssetsOfGivenType == 0) {
        [_libraryInfoLabelsByAssetType[assetType] setStringValue:
         (assetType == MHAssetImage ? NSLocalizedString(@"No images", @"") : NSLocalizedString(@"No videos", @""))];
    }
    else {
        NSUInteger totalBytes = [self.assetLibraryDelegate totalSizeOfAssetsOfType:assetType];
        NSString *totalBytesString = [NSString userFriendlyFilesizeStringForFilesize:totalBytes];
        NSString *pluralSuffix = (numberOfAssetsOfGivenType > 1 ? @"s" : @"");
        NSString *infoString;
        if (assetType == MHAssetImage) {
            infoString = [NSString stringWithFormat:NSLocalizedString(@"%lu image%@ (%@ total)", @""),
                          numberOfAssetsOfGivenType, pluralSuffix, totalBytesString];
        }
        else {
            infoString = [NSString stringWithFormat:NSLocalizedString(@"%lu video%@ (%@ total)", @""),
                          numberOfAssetsOfGivenType, pluralSuffix, totalBytesString];
        }
        [_libraryInfoLabelsByAssetType[assetType] setStringValue:[NSString
                                                                  stringWithFormat:NSLocalizedString(@"%lu image%@ (%@ total)", @""), numberOfAssetsOfGivenType, pluralSuffix, totalBytesString]];
    }
}


#pragma mark - User actions

- (IBAction)segmentedControlAction:(NSSegmentedControl *)sender
{
    MHAssetType assetType = ([sender isEqual:self.imageActionsSegmentedControl] ? MHAssetImage : MHAssetVideo);
    
    switch (sender.selectedSegment) {
        case kMHAssetLibraryActionAddAssetSegmentIndex:
            [self presentOpenPanelForAddingAssetOfType:assetType];
            break;
        case kMHAssetLibraryActionDeleteAssetSegmentIndex:
            [self initiateDeletionSequenceForCurrentlySelectedAssetOfType:assetType];
            break;
    }
}


#pragma mark - NSTableViewDelegate, NSTableViewDataSource and NSTableViewWithDeleteShortcutDelegate methods

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    MHAssetType assetType = ([tableView isEqual:self.imageFilenamesTable] ? MHAssetImage : MHAssetVideo);
    return _listsOfAssetFilenamesByAssetType[assetType].count;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    MHAssetType assetType = ([tableView isEqual:self.imageFilenamesTable] ? MHAssetImage : MHAssetVideo);
    return [_listsOfAssetFilenamesByAssetType[assetType] objectAtIndex:rowIndex];
}


- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
    MHAssetType assetType = ([notification.object isEqual:self.imageFilenamesTable] ? MHAssetImage : MHAssetVideo);
    NSInteger rowIndex = [_filenameTablesByAssetType[assetType] selectedRow];
    [self setSelectedAssetIndexForAssetType:assetType toIndex:rowIndex];
}

- (void)tableView:(NSTableView *)tableView
   setObjectValue:(NSString *)newImageFilename
   forTableColumn:(NSTableColumn *)tableColumn
              row:(NSInteger)row
{
    // Renaming a file
    MHAssetType assetType = ([tableView isEqual:self.imageFilenamesTable] ? MHAssetImage : MHAssetVideo);
    [self renameAssetOfType:assetType withIndex:row proposedNewFilename:newImageFilename];
}


#pragma mark - Handling drag and drop sessions

- (NSArray <NSString *> *)listOfUTITypesForAssetType:(MHAssetType)assetType
{
    switch (assetType) {
        case MHAssetImage:
            return [NSImage imageTypes];
        case MHAssetVideo:
            // list of UTIs for video files. FIXME: incomplete list, improve
            // see this page for related documentation: https://developer.apple.com/library/archive/documentation/Miscellaneous/Reference/UTIRef/Articles/System-DeclaredUniformTypeIdentifiers.html
            return @[ @"com.apple.quicktime-movie", @"public.mpeg-4", @"public.mpeg", @"public.avi", @"public.movie", @"public.video" ];
        default:
            return @[ ];
    }
}

- (id<NSPasteboardWriting>)tableView:(NSTableView *)tableView pasteboardWriterForRow:(NSInteger)row
{
    MHAssetType assetType = ([tableView isEqual:self.imageFilenamesTable] ? MHAssetImage : MHAssetVideo);
    NSString *assetFilename = [_listsOfAssetFilenamesByAssetType[assetType] objectAtIndex:row];
    
    // When the user initiates a drag action with a page, we store the row index for the page and the associated filename in a pasteboard item
    // This will be used at the drop action to reorder the images
    NSPasteboardItem *item = [[NSPasteboardItem alloc] init];
    NSDictionary *itemDictionary = @{
        kMHAssetLibraryAssetDraggingPasteboardTypeRowIndexKey : [NSNumber numberWithInteger:row],
        kMHAssetLibraryAssetDraggingPasteboardTypeFilenameKey : assetFilename,
        kMHAssetLibraryAssetDraggingPasteboardTypeAssetTypeKey : [NSNumber numberWithInteger:assetType]
    };
    [item setPropertyList:itemDictionary forType:kMHAssetLibraryAssetDraggingPasteboardType];
    return item;
}

- (NSDragOperation)tableView:(NSTableView *)tableView
                validateDrop:(id<NSDraggingInfo>)info
                 proposedRow:(NSInteger)toRow
       proposedDropOperation:(NSTableViewDropOperation)dropOperation
{
    if (dropOperation == NSTableViewDropOn)
        return NSDragOperationNone;             // we only consider dropping items between table rows, not on top of a row
    
    MHAssetType assetType = ([tableView isEqual:self.imageFilenamesTable] ? MHAssetImage : MHAssetVideo);
    
    // Get the pasteboard
    NSPasteboard *draggingPasteboard = info.draggingPasteboard;

    // Check if we are dragging a file URLs of some recognized file type for the asset type
    NSArray <NSString *> *assetUTITypes = [self listOfUTITypesForAssetType:assetType];
        
    NSDictionary <NSPasteboardReadingOptionKey, id> *assetTypeFilteringOptions = @{
        NSPasteboardURLReadingContentsConformToTypesKey : assetUTITypes
    };
    if ([draggingPasteboard canReadObjectForClasses:@[ [NSURL class] ] options:assetTypeFilteringOptions]) {
        // The pasteboard contains file URLs of the relevant asset type, so the drop is validated as a copy operation
        return NSDragOperationCopy;
    }

    // Next, check if we are dragging a table row, if so validate the drop as a move operation, otherwise do not validate
    NSDictionary *tableRowDraggingDict = [draggingPasteboard propertyListForType:kMHAssetLibraryAssetDraggingPasteboardType];
    return (tableRowDraggingDict != nil ? NSDragOperationMove : NSDragOperationNone);
}

- (BOOL)tableView:(NSTableView *)tableView
       acceptDrop:(id<NSDraggingInfo>)info
              row:(NSInteger)toRow
    dropOperation:(NSTableViewDropOperation)dropOperation
{
    MHAssetType assetType = ([tableView isEqual:self.imageFilenamesTable] ? MHAssetImage : MHAssetVideo);
    
    // Get the pasteboard
    NSPasteboard *draggingPasteboard = info.draggingPasteboard;
    
    // Are we dropping a table row? If so this is a reordering operation
    NSDictionary *tableRowDraggingDict = [draggingPasteboard propertyListForType:kMHAssetLibraryAssetDraggingPasteboardType];
    if (tableRowDraggingDict) {
        NSInteger fromRow = [(NSNumber *)tableRowDraggingDict[kMHAssetLibraryAssetDraggingPasteboardTypeRowIndexKey] integerValue];
        [self moveAssetOfType:assetType withIndex:fromRow toIndex:toRow];
        return YES;
    }
    
    // The other possibility is dropping image files. Need to filter them out from the pasteboard and then process them
    NSArray <NSString *> *assetUTITypes = [self listOfUTITypesForAssetType:assetType];
    NSDictionary <NSPasteboardReadingOptionKey, id> *assetTypeFilteringOptions = @{
        NSPasteboardURLReadingContentsConformToTypesKey : assetUTITypes
    };
    NSArray *assetURLs = [draggingPasteboard readObjectsForClasses:@[ [NSURL class] ] options:assetTypeFilteringOptions];
    if (assetURLs && assetURLs.count > 0) {
        BOOL success = NO;
        for (NSURL *url in assetURLs) {
            success = [self addAssetOfType:assetType fromURL:url assetIndex:toRow] || success;
        }
        return success;
    }
    
    return NO;
}

- (void)tableViewDeleteRowShortcutInvoked:(NSTableView *)tableView
{
    MHAssetType assetType = ([tableView isEqual:self.imageFilenamesTable] ? MHAssetImage : MHAssetVideo);
    [self initiateDeletionSequenceForCurrentlySelectedAssetOfType:assetType];
}

#pragma mark - Library operations

- (void)moveAssetOfType:(MHAssetType)assetType withIndex:(NSUInteger)oldIndex toIndex:(NSUInteger)newIndex
{
    // The asset will be moved - perform the reordering operation
    NSMutableArray <NSString *> *listOfFilenames = _listsOfAssetFilenamesByAssetType[assetType];
    NSString *assetToMove = [listOfFilenames objectAtIndex:oldIndex];
    [listOfFilenames removeObjectAtIndex:oldIndex];
    [listOfFilenames insertObject:assetToMove atIndex:(newIndex > oldIndex ? newIndex-1 : newIndex)];

    // FIXME: this doesn't give correct behavior
    NSInteger selectedAssetIndex = [self selectedAssetIndexForAssetType:assetType];
    if (selectedAssetIndex == oldIndex && oldIndex > newIndex) {
        [self setSelectedAssetIndexForAssetType:assetType toIndex:newIndex];
    }
    else if (selectedAssetIndex == oldIndex && oldIndex < newIndex) {
        [self setSelectedAssetIndexForAssetType:assetType toIndex:newIndex-1];
    }
    else if (oldIndex < selectedAssetIndex && selectedAssetIndex < newIndex) {
        [self setSelectedAssetIndexForAssetType:assetType toIndex:selectedAssetIndex-1];
    }
    else if (oldIndex > selectedAssetIndex && selectedAssetIndex > newIndex) {
        [self setSelectedAssetIndexForAssetType:assetType toIndex:selectedAssetIndex+1];
    }
    
    [self.assetLibraryDelegate reorderAssetsOfType:assetType newOrdering:listOfFilenames];
    [self reloadAssetLibraryForAssetType:assetType];
}

// returns YES if the operation was successful
- (BOOL)addAssetOfType:(MHAssetType)assetType fromURL:(NSURL *)assetURL assetIndex:(NSInteger)index
{
    // Get the filename
    NSString *assetFilename = [assetURL lastPathComponent];
    
    // Load the asset as an NSData object
    NSData *assetData = [NSData dataWithContentsOfURL:assetURL];
    
    // Validate that the data is a functioning asset of the given type
    switch (assetType) {
        case MHAssetImage: {
            // Initialize an image from the data to validate that the file is a valid image file
            NSImage *image = [[NSImage alloc] initWithData:assetData];
            
            if (!image) {
                NSLog(@"invalid image");
                return NO;
            }
        }
            break;
        case MHAssetVideo:
            // FIXME: add this
            break;
    }
    
    NSString *actualAssetFilename = [self.assetLibraryDelegate addAssetOfType:assetType
                                                                    assetData:assetData
                                                            preferredFilename:assetFilename
                                                               insertionIndex:index];
    
    [_listsOfAssetFilenamesByAssetType[assetType] insertObject:actualAssetFilename atIndex:index];

    [self reloadAssetLibraryForAssetType:assetType];
    [self setSelectedAssetIndexForAssetType:assetType toIndex:index];

    return YES;
}

- (void)renameAssetOfType:(MHAssetType)assetType withIndex:(NSInteger)index proposedNewFilename:(NSString *)newImageFilename
{
    NSMutableArray <NSString *> *listOfFilenamesForGivenAssetType = _listsOfAssetFilenamesByAssetType[assetType];
    // Start by applying a mild transformation to the proposed filename. If it has the same file extension as the current filename, use it as it is; otherwise, append the file extension of the current filename to make sure we have a file with the correct extension
    NSString *oldFilename = [listOfFilenamesForGivenAssetType objectAtIndex:index];
    NSString *oldFilenameExtension = [oldFilename pathExtension];
    NSString *newFilenameExtension = [newImageFilename pathExtension];
    NSString *actualNewFilenameToUse;
    if ([newFilenameExtension isEqualToString:oldFilenameExtension]) {
        actualNewFilenameToUse = newImageFilename;
    }
    else {
        actualNewFilenameToUse = [newImageFilename stringByAppendingPathExtension:oldFilenameExtension];
    }
    
    // Validate filename: we disallow filenames that contain a slash or begin with a kMHNotebookForbiddenPageFilenamePrefixChar character
    NSArray *pathComponents = [actualNewFilenameToUse pathComponents];
    if (pathComponents.count != 1 || [actualNewFilenameToUse characterAtIndex:0] == kMHNotebookForbiddenPageFilenamePrefixChar) {
        // We don't allow filenames that contain a path component separator (a slash)
        NSBeep();
        return;
    }
    
    // Check for duplicates: we don't allow a filename already taken by another image
    NSUInteger otherFilenameIndex = 0;
    for (NSString *otherFilename in listOfFilenamesForGivenAssetType) {
        if (otherFilenameIndex != index && [actualNewFilenameToUse isEqualToString:otherFilename]) {
            // Duplicate filename, beep and reject the edit
            NSBeep();
            return;
        }
        otherFilenameIndex++;
    }

    
    [listOfFilenamesForGivenAssetType replaceObjectAtIndex:index withObject:actualNewFilenameToUse];
    [self.assetLibraryDelegate renameAssetOfType:MHAssetImage withIndex:index newFilename:actualNewFilenameToUse];
    [self reloadAssetLibraryForAssetType:assetType];

    // FIXME: test whether this actually does what it should
    [self setSelectedAssetIndexForAssetType:assetType toIndex:index];
}

- (void)initiateDeletionSequenceForCurrentlySelectedAssetOfType:(MHAssetType)assetType
{
    NSMutableArray <NSString *> *listOfFilenamesForGivenAssetType = _listsOfAssetFilenamesByAssetType[assetType];
    
    NSUInteger selectedAssetIndex = [self selectedAssetIndexForAssetType:assetType];
    if ([self selectedAssetIndexForAssetType:assetType] == kMHAssetLibraryNoSelectedAsset) {
        NSBeep();
        return;
    }
    
    NSString *assetTypeLocalizedString = (assetType == MHAssetImage ? NSLocalizedString(@"image", @"") : NSLocalizedString(@"video", @""));
    NSString *assetName = listOfFilenamesForGivenAssetType[selectedAssetIndex];

    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:NSLocalizedString(@"Delete", @"")];
    [alert addButtonWithTitle:NSLocalizedString(@"Cancel", @"")];
    alert.messageText = [NSString stringWithFormat:NSLocalizedString(@"Delete the %@?", @""), assetTypeLocalizedString];
    alert.informativeText = [NSString stringWithFormat:NSLocalizedString(@"Are you sure you would like to delete the %@ \"%@\"?",@""),
                             assetTypeLocalizedString, assetName];
    alert.alertStyle = NSAlertStyleWarning;

    NSModalResponse result = [alert runModal];
    if (result == NSAlertFirstButtonReturn) {
        [self deleteCurrentlySelectedAssetOfType:assetType];
    }
    else {
        // if any action should be taken if the user cancels the deletion, add it here
    }
}

- (void)deleteCurrentlySelectedAssetOfType:(MHAssetType)assetType
{
    NSMutableArray <NSString *> *listOfFilenamesForGivenAssetType = _listsOfAssetFilenamesByAssetType[assetType];
    NSUInteger numberOfAssetsOfGivenType = listOfFilenamesForGivenAssetType.count;
    
    NSUInteger selectedAssetIndex = [self selectedAssetIndexForAssetType:assetType];
    if ([self selectedAssetIndexForAssetType:assetType] == kMHAssetLibraryNoSelectedAsset) {
        return;
    }
    [listOfFilenamesForGivenAssetType removeObjectAtIndex:selectedAssetIndex];
    [self.assetLibraryDelegate deleteAssetOfType:assetType withIndex:selectedAssetIndex];
    
    NSInteger newSelectedAssetIndex = (numberOfAssetsOfGivenType == 1 ? kMHAssetLibraryNoSelectedAsset :
                                       (selectedAssetIndex+1 == numberOfAssetsOfGivenType ? selectedAssetIndex-1 : selectedAssetIndex));
    
    [self reloadAssetLibraryForAssetType:assetType];

    [self setSelectedAssetIndexForAssetType:assetType toIndex:newSelectedAssetIndex];
}

- (void)presentOpenPanelForAddingAssetOfType:(MHAssetType)assetType
{
    NSOpenPanel* panel = [NSOpenPanel openPanel];
    panel.allowedFileTypes = [self listOfUTITypesForAssetType:assetType];  // restrict to the relevant file types
    panel.allowsMultipleSelection = YES;
    
    // This method displays the panel and returns immediately.
    // The completion handler is called when the user selects an
    // item or cancels the panel.
    [panel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result){
        if (result == NSModalResponseOK) {
            NSArray <NSURL *> *panelURLs = panel.URLs;
            for (NSURL *assetURL in panelURLs) {
                NSInteger indexOfSelectedAsset = [self selectedAssetIndexForAssetType:assetType];
                NSInteger indexOfAssetToAdd = (indexOfSelectedAsset == kMHAssetLibraryNoSelectedAsset ?
                                               [[self->_listsOfAssetFilenamesByAssetType objectAtIndex:assetType] count] : indexOfSelectedAsset);
                [self addAssetOfType:assetType fromURL:assetURL assetIndex:indexOfAssetToAdd];
            }
        }
    }];
}



- (void)tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
    MHAssetType selectedAssetType = [self currentlyShowingAssetTypeSublibrary];
    [self.assetLibraryDelegate assetTypeSublibraryChanged:selectedAssetType];
}


- (void)windowDidBecomeKey:(NSNotification *)notification
{
    [self.assetLibraryDelegate updateUserInterfaceForAssetLibraryVisibilityState];
}

- (void)toggleAssetLibrary:(nullable id)sender
{
    [self.assetLibraryDelegate toggleAssetLibrary:nil];
}


@end




#pragma mark - Formatting file size strings


@implementation NSString (UserFriendlyFileSizeStrings)

+ (NSString *)userFriendlyFilesizeStringForFilesize:(NSUInteger)filesize
{
    if (filesize <= 9999)
        return [NSString stringWithFormat:NSLocalizedString(@"%lu bytes", @""), filesize];
    NSUInteger numberOfKilobytes = filesize/1024;
    if (numberOfKilobytes < 9999)
        return [NSString stringWithFormat:NSLocalizedString(@"%lu KB", @""), numberOfKilobytes];
    NSUInteger numberOfMegabytes = filesize/(1024*1024);
    if (numberOfMegabytes < 9999)
        return [NSString stringWithFormat:NSLocalizedString(@"%lu MB", @""), numberOfMegabytes];
    NSUInteger numberOfGigabytes = filesize/(1024*1024*1024);
    return [NSString stringWithFormat:NSLocalizedString(@"%lu GB", @""), numberOfGigabytes];
}


@end
