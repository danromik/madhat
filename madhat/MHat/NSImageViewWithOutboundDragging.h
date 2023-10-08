//
//  NSImageViewWithOutboundDragging.h
//  MadHat
//
//  Created by Dan Romik on 10/19/20.
//  Copyright © 2020 Dan Romik. All rights reserved.
//

// A simple NSImage subclass that enables dragging and dropping a file from the image view (typically the file for the image itself, but it can be any file)
// The class also allows setting an alternative pasteboard type and corresponding property list object for dropping

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSImageViewWithOutboundDragging : NSImageView <NSDraggingSource, NSFilePromiseProviderDelegate>


@property NSString *imageFilename;      // This filename will be used to create the file for dragging and dropping
@property NSData *imageFileData;        // This data will be used to create the file for dragging and dropping
@property NSString *alternativePasteboardType;
@property NSObject *propertyListDraggingContentForAlternativePasteboardType;


@end

NS_ASSUME_NONNULL_END
