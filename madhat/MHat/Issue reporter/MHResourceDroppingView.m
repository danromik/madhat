//
//  MHImageReceiverView.m
//  MadHat
//
//  Created by Dan Romik on 8/14/21.
//  Copyright © 2021 Dan Romik. All rights reserved.
//

#import "MHResourceDroppingView.h"




@interface MHResourceDroppingView ()
{
    __weak id <MHResourceDroppingViewDelegate> _dropReceivingDelegate;
    NSDictionary <NSPasteboardReadingOptionKey, id> *_pasteboardReadingOptions;
}

@end

@implementation MHResourceDroppingView

- (id <MHResourceDroppingViewDelegate>)dropReceivingDelegate
{
    return _dropReceivingDelegate;
}

- (void)setDropReceivingDelegate:(id<MHResourceDroppingViewDelegate>)dropReceivingDelegate
{
    _dropReceivingDelegate = dropReceivingDelegate;
}

- (void)awakeFromNib
{
    _pasteboardReadingOptions = @{
            NSPasteboardURLReadingFileURLsOnlyKey : [NSNumber numberWithBool:YES],
    };
    
    self.enabled = YES;
    [self registerForDraggedTypes:@[ NSPasteboardTypeFileURL ]];
}

- (BOOL)prepareForDragOperation:(id<NSDraggingInfo>)sender
{
    return YES;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
    NSPasteboard *pasteboard = sender.draggingPasteboard;
    NSURL *imageURL = [NSURL URLFromPasteboard:pasteboard];
    [self.dropReceivingDelegate resourceDroppingView:self receivedResource:imageURL];

    return YES;
}

- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender
{
    if (!(self.enabled))
        return NSDragOperationNone;
    
    NSPasteboard *pasteboard = sender.draggingPasteboard;
    
    NSArray <NSURL *> *draggedFileURLs = [pasteboard readObjectsForClasses:@[ [NSURL class] ] options:_pasteboardReadingOptions];
    
    if (draggedFileURLs.count != 1) {
        // we could not find a dragged file URL item or there was more than one URL - reject the drop
        return NSDragOperationNone;
    }
    
    NSURL *draggedFileURL = draggedFileURLs[0];
    NSUInteger fileSize = [draggedFileURL sizeOfFileOrDirectory];
    if (fileSize == 0)
        return NSDragOperationNone;
    NSUInteger maxFileSize = self.maxResourceSizeInBytes;
    if (maxFileSize > 0 && fileSize > maxFileSize) {
        // change the cursor type to operationNotAllowedCursor;
        [[NSCursor operationNotAllowedCursor] push];
        [self.dropReceivingDelegate showFileTooLargeIndicator:self];
        return NSDragOperationNone;
    }
    
    return ([self.dropReceivingDelegate resourceDroppingView:self shouldAcceptResource:draggedFileURL] ? NSDragOperationCopy
            : NSDragOperationNone);
}

- (void)draggingExited:(id<NSDraggingInfo>)sender
{
    [NSCursor pop];
    [self.dropReceivingDelegate hideFileTooLargeIndicator:self];
}




@end



@implementation NSURL (AuxiliaryMethods)

- (unsigned long long int)sizeOfFileOrDirectory
{
    if (!(self.isFileURL))
        return 0;               // not a file URL

    NSString *filePath = [self path];

    BOOL isDirectory;
    if (![[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:&isDirectory])
        return 0;               // file does not exist
    
    if (isDirectory) {
        // sum up the file sizes for the files in the directory
        // adapted from: https://stackoverflow.com/questions/2188469/how-can-i-calculate-the-size-of-a-folder
        
        NSArray *filesArray = [[NSFileManager defaultManager] subpathsOfDirectoryAtPath:filePath error:nil];
        NSEnumerator *filesEnumerator = [filesArray objectEnumerator];
        NSString *fileName;
        unsigned long long int fileSize = 0;

        while (fileName = [filesEnumerator nextObject]) {
            NSDictionary *fileDictionary = [[NSFileManager defaultManager] attributesOfItemAtPath:[filePath stringByAppendingPathComponent:fileName] error:nil];
            fileSize += [fileDictionary fileSize];
        }

        return fileSize;
    }
    else {
        NSDictionary *fileDictionary = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
        return [fileDictionary fileSize];
    }
}

- (BOOL)isImageType
{
    NSString * UTI = (__bridge NSString *)UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension,(__bridge CFStringRef)[self pathExtension],NULL);
    return UTTypeConformsTo((__bridge CFStringRef)UTI, kUTTypeImage);
}



@end
