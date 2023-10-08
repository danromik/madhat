//
//  NSImageViewWithOutboundDragging.m
//  MadHat
//
//  Created by Dan Romik on 10/19/20.
//  Copyright © 2020 Dan Romik. All rights reserved.
//

#import "NSImageViewWithOutboundDragging.h"
#import <AVFoundation/AVFoundation.h>


// NSFilePromiseProviderWithAlternativePasteboardContent
// A simple subclass of NSFilePromiseProvider to add the option of an alternative pasteboard type and content
// The implementation is at the bottom of the source file
//
// Based on an idea that's described here:
// https://buckleyisms.com/blog/how-to-actually-implement-file-dragging-from-your-app-on-mac/
//
API_AVAILABLE(macos(10.12))
@interface NSFilePromiseProviderWithAlternativePasteboardContent : NSFilePromiseProvider
{
@private
    NSPasteboardType _alternativePasteboardType;
    NSObject *_alternativePasteboardContents;   // must be a property list object
}

- (instancetype)initWithFileType:(NSString *)fileType
       alternativePasteboardType:(NSPasteboardType)alternativePasteboardType
propertyListForAlternativePasteboardType:(NSObject *)propertyListObject
                        delegate:(id<NSFilePromiseProviderDelegate>)delegate;

@end





@implementation NSImageViewWithOutboundDragging



#pragma mark - Starting a dragging session

// Can initiate dragging from mouseDragged: instead, this may be preferable in some situations
- (void)mouseDown:(NSEvent *)event
{
    
    // Get the UTI for the filename we are dragging to register with the file promise provider
    CFStringRef imageUTICFString = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension,
                                                                 (__bridge CFStringRef)[_imageFilename pathExtension], NULL);
    NSString *imageUTI = (__bridge NSString *)imageUTICFString;
    
    // Create the file promise provider
    NSFilePromiseProviderWithAlternativePasteboardContent *filePromiseProvider =
    [[NSFilePromiseProviderWithAlternativePasteboardContent alloc] initWithFileType:imageUTI
                                                          alternativePasteboardType:_alternativePasteboardType
        propertyListForAlternativePasteboardType:_propertyListDraggingContentForAlternativePasteboardType
                                                                           delegate:self];
     
    // Clean up
    CFRelease(imageUTICFString);
    
    // Compute the actual rectangle occupied by the image inside our image view
    // (this approach suggested in
    // https://stackoverflow.com/questions/4711615/how-to-get-the-displayed-image-frame-from-uiimageview )
    CGRect actualImageRect = AVMakeRectWithAspectRatioInsideRect(self.image.size, self.bounds);

    // Create a dragging item with the file promise provider as pasteboard writer
    NSDraggingItem *draggingItem = [[NSDraggingItem alloc] initWithPasteboardWriter:filePromiseProvider];
    
    // Set the dragging frame
    [draggingItem setDraggingFrame:actualImageRect contents:self.image];
    
    // Begin the dragging session
    [self beginDraggingSessionWithItems:@[ draggingItem ] event:event source:self];
}



#pragma mark - NSDraggingSource

- (NSDragOperation)draggingSession:(NSDraggingSession *)session
        sourceOperationMaskForDraggingContext:(NSDraggingContext)context
{
    return NSDragOperationCopy;
}



#pragma mark - NSFilePromiseProviderDelegate

- (NSString *)filePromiseProvider:(NSFilePromiseProvider *)filePromiseProvider fileNameForType:(NSString *)fileType
API_AVAILABLE(macos(10.12))API_AVAILABLE(macos(10.12)){
    return self.imageFilename;
}

- (void)filePromiseProvider:(NSFilePromiseProvider *)filePromiseProvider writePromiseToURL:(NSURL *)url completionHandler:(void (^)(NSError *errorOrNil))completionHandler
API_AVAILABLE(macos(10.12)){
    // Write the image file data to the URL
    [self.imageFileData writeToURL:url atomically:YES];
    
    // Call the completion handler
    completionHandler(nil);
}

@end




@implementation NSFilePromiseProviderWithAlternativePasteboardContent

- (instancetype)initWithFileType:(NSString *)fileType
       alternativePasteboardType:(NSPasteboardType)alternativePasteboardType
propertyListForAlternativePasteboardType:(NSObject *)propertyListObject
                        delegate:(id<NSFilePromiseProviderDelegate>)delegate
{
    if (self = [super initWithFileType:fileType delegate:delegate]) {
        _alternativePasteboardType  = alternativePasteboardType;
        _alternativePasteboardContents = propertyListObject;
    }
    return self;
}

- (NSArray<NSPasteboardType> *)writableTypesForPasteboard:(NSPasteboard *)pasteboard
{
    NSArray <NSPasteboardType> *superWritableTypes = [super writableTypesForPasteboard:pasteboard];
    
    return [superWritableTypes arrayByAddingObject:_alternativePasteboardType];
}

- (NSPasteboardWritingOptions)writingOptionsForType:(NSPasteboardType)type pasteboard:(NSPasteboard *)pasteboard
{
    if ([type isEqualToString:_alternativePasteboardType]) {
        return 0;
    }
    
    return [super writingOptionsForType:type pasteboard:pasteboard];
}

- (id)pasteboardPropertyListForType:(NSPasteboardType)type
{
    if ([type isEqualToString:_alternativePasteboardType]) {
        return _alternativePasteboardContents;
    }
    
    return [super pasteboardPropertyListForType:type];
}



@end
