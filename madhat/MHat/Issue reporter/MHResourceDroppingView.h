//
//  MHImageReceiverView.h
//  MadHat
//
//  Created by Dan Romik on 8/14/21.
//  Copyright © 2021 Dan Romik. All rights reserved.
//
//  A NSView subclass implementing a view you can drag and drop resources into.
//  Currently only file URL resources are accepted. A "drop receiving delegate" object controls whether the resource
//  should be accepted. The maxResourceSizeInBytes property controls the maximum resource size the view can accept.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN


@class MHResourceDroppingView;
@protocol MHResourceDroppingViewDelegate <NSObject>

- (BOOL)resourceDroppingView:(MHResourceDroppingView *)resourceDroppingView shouldAcceptResource:(NSURL *)fileResourceURL;
- (void)resourceDroppingView:(MHResourceDroppingView *)resourceDroppingView receivedResource:(NSURL *)fileResourceURL;
- (void)showFileTooLargeIndicator:(MHResourceDroppingView *)sender;
- (void)hideFileTooLargeIndicator:(MHResourceDroppingView *)sender;

@end


@interface MHResourceDroppingView : NSBox

@property (weak) IBOutlet id <MHResourceDroppingViewDelegate> dropReceivingDelegate;
@property NSUInteger maxResourceSizeInBytes;    // defaults to 0, which means there is no file size limit

@property BOOL enabled;

@end


// a useful NSURL category
@interface NSURL (AuxiliaryMethods)  // see the end of the .m file for the implementation
- (unsigned long long int)sizeOfFileOrDirectory;
- (BOOL)isImageType;
@end



NS_ASSUME_NONNULL_END
