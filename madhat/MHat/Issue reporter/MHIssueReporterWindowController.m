//
//  MHIssueReporterWindowController.m
//  MadHat
//
//  Created by Dan Romik on 8/14/21.
//  Copyright © 2021 Dan Romik. All rights reserved.
//

#import <mach-o/arch.h>
#import "MHIssueReporterWindowController.h"
#import "NSURL+Compression.h"

static const NSUInteger kMHIssueReporterMaxAttachmentSizeInMB = 10;
static const NSUInteger kMHIssueReporterMaxAttachmentSize = kMHIssueReporterMaxAttachmentSizeInMB * 1024 * 1024;

static NSString * const kMHIssueReporterSubmissionURL = @"https://madhat.design/madhat-app/submit-report.php";

static NSString *kMHMadhatNotebookExtension = @"mhat";  // FIXME: this should be retrieved from the Info.plist or some other more canonical place

static NSUInteger maxReportCharacters = 2000;



//
// Some useful categories with auxiliary methods for use when sending an HTTP POST request.
// The implementation is at the bottom of this file
//
// Adapted from
// https://stackoverflow.com/questions/24250475/post-multipart-form-data-with-objective-c
//
@interface NSString (HTTPRequestExtension)
+ (NSString *)boundaryStringForHTTPRequest;
+ (NSString *)mimeTypeForPath:(NSString *)path;
@end
@interface NSData (HTTPRequestExtension)
+ (NSData *)createHTTPRequestBodyWithBoundary:(NSString *)boundary
                                   parameters:(NSDictionary *)parameters
                                  attachments:(NSDictionary <NSString *, NSDictionary <NSString *, id> *> *)attachments;
@end






@interface MHIssueReporterWindowController ()
{
    NSURL *_imageAttachmentURL;
    NSString *_droppedImageFilepath;
    NSURL *_notebookAttachmentURL;
    NSString *_droppedNotebookFilepath;
    
    NSAlert *_uploadProgressWindow;
    NSProgressIndicator *_uploadProgressIndicator;
    NSTextView *_uploadProgressReportLinkLabel;
    NSURLSessionTask *_uploadTask;
}

@property IBOutlet NSPopUpButton *reportCategoryPopUp;
@property IBOutlet NSTextField *reportSubjectTextField;
@property IBOutlet NSTextView *reportBodyTextView;
@property IBOutlet NSTextField *reportNameTextField;
@property IBOutlet NSTextField *reportEmailTextField;
@property IBOutlet NSButton *agreeToEmailCheckbox;
@property IBOutlet NSButton *submitReportButton;
@property IBOutlet NSTextField *maxNumberOfCharactersTextField;
@property IBOutlet NSTextView *sendReportsEmailInfoLabel;

@property IBOutlet MHResourceDroppingView *resourceDroppingView;
@property IBOutlet NSTextField *resourceDroppingViewInfoLabel;
@property IBOutlet NSTextField *resourceDroppingViewMaxFileSizeInfoLabel;

@property IBOutlet NSView *attachmentDetailsContainerView;
@property IBOutlet NSTextField *imageViewFilenameLabel;
@property IBOutlet NSTextField *imageViewFileSizeLabel;
@property IBOutlet NSButton *clearImageAttachmentButton;
@property IBOutlet NSTextField *notebookAttachmentFilenameLabel;
@property IBOutlet NSTextField *notebookAttachmentFileSizeLabel;
@property IBOutlet NSButton *clearNotebookAttachmentButton;

@property IBOutlet NSButton *dismissCancelButton;
@property IBOutlet NSTextField *successfulSubmissionInfoLabel;

@property (nullable) NSURL *imageAttachmentURL;
@property (nullable) NSURL *notebookAttachmentURL;


@end

@implementation MHIssueReporterWindowController

- (void)windowDidLoad {
    [super windowDidLoad];
    
    self.dismissCancelButton.title = NSLocalizedString(@"Cancel", @"");
    self.submitReportButton.enabled = NO;
    
    self.resourceDroppingView.maxResourceSizeInBytes = kMHIssueReporterMaxAttachmentSize;
    
    self.imageAttachmentURL = nil;
    self.notebookAttachmentURL = nil;
    [self updateUserInterfaceAfterAttachmentAction:NO];
    
    self.imageViewFilenameLabel.cell.lineBreakMode = NSLineBreakByTruncatingTail;
    self.notebookAttachmentFilenameLabel.cell.lineBreakMode = NSLineBreakByTruncatingTail;
    
    NSTextField *maxNumberOfCharsTextField = self.maxNumberOfCharactersTextField;
    NSRect maxNumberOfCharsTextFieldFrameFromNib = maxNumberOfCharsTextField.frame;
    NSRect updatedMaxNumberOfCharsTextFieldFrame = maxNumberOfCharsTextFieldFrameFromNib;
    NSString *maxNumCharsStringFromNib = maxNumberOfCharsTextField.stringValue;
    NSString *updatedMaxNumCharsString = [maxNumCharsStringFromNib
                                          stringByReplacingOccurrencesOfString:@"*****"
                                          withString:[NSString stringWithFormat:@"%lu", maxReportCharacters]];
    maxNumberOfCharsTextField.stringValue = updatedMaxNumCharsString;
    [maxNumberOfCharsTextField sizeToFit];
    updatedMaxNumberOfCharsTextFieldFrame.size.width = maxNumberOfCharsTextField.frame.size.width;
    updatedMaxNumberOfCharsTextFieldFrame.origin.x =
    maxNumberOfCharsTextFieldFrameFromNib.origin.x + maxNumberOfCharsTextFieldFrameFromNib.size.width -
    updatedMaxNumberOfCharsTextFieldFrame.size.width;
    maxNumberOfCharsTextField.frame = updatedMaxNumberOfCharsTextFieldFrame;
    
    static NSString *suggestionsEmailAddress = @"suggestions@madhat.design";    // FIXME: put all web-related definitions in a single place
    NSTextView *sendReportsEmailInfoLabel = self.sendReportsEmailInfoLabel;
    NSAttributedString *emailInfoMessage = sendReportsEmailInfoLabel.attributedString;
    NSRange emailAddressRange = [emailInfoMessage.string rangeOfString:suggestionsEmailAddress];
    if (emailAddressRange.location != NSNotFound) {
        [sendReportsEmailInfoLabel.textStorage addAttribute:NSLinkAttributeName
                                                      value:[NSString stringWithFormat:@"mailto:%@", suggestionsEmailAddress]
                                                      range:emailAddressRange];
    }
}

- (IBAction)updateSubmitButtonEnabledState:(id)sender
{
    NSUInteger reportCategoryIndex = self.reportCategoryPopUp.indexOfSelectedItem;
    NSUInteger reportSubjectLength = self.reportSubjectTextField.stringValue.length;
    NSUInteger reportBodyLength = self.reportBodyTextView.string.length;
    BOOL reportReadyToSubmit = (reportCategoryIndex > 0 && reportSubjectLength > 0 && reportBodyLength > 0
                                && reportBodyLength <= maxReportCharacters);
    self.submitReportButton.enabled = reportReadyToSubmit;
}

- (void)textDidChange:(NSNotification *)notification
{
    [self updateSubmitButtonEnabledState:nil];
}

- (void)controlTextDidChange:(NSNotification *)obj
{
    [self updateSubmitButtonEnabledState:nil];
}


- (IBAction)submitIssueReporterForm:(id)sender
{
    // FIXME: add form validation
    
    NSString *name = self.reportNameTextField.stringValue;
    NSString *email = self.reportEmailTextField.stringValue;
    NSString *subject = self.reportSubjectTextField.stringValue;
    NSString *body = self.reportBodyTextView.string;
    NSString *category = self.reportCategoryPopUp.titleOfSelectedItem;
    bool agreeToEmail = (self.agreeToEmailCheckbox.state == NSControlStateValueOn ? true : false);

    //
    // the code below to submit the form as an HTTP POST request is adapted from
    // https://stackoverflow.com/questions/24250475/post-multipart-form-data-with-objective-c
    //
    
    // get the OS version to include in the report
    NSOperatingSystemVersion operatingSystemVersion = [[NSProcessInfo processInfo] operatingSystemVersion];
    NSString *operatingSystemVersionString = [NSString stringWithFormat:@"%lu.%lu.%lu",
                                              operatingSystemVersion.majorVersion,
                                              operatingSystemVersion.minorVersion,
                                              operatingSystemVersion.patchVersion];
    
    // get the system architecture
    // copied from https://stackoverflow.com/questions/19859388/how-can-i-get-the-ios-device-cpu-architecture-in-runtime
    const NXArchInfo *systemArchitectureInfo = NXGetLocalArchInfo();
    NSString *systemArchitectureString = [NSString stringWithUTF8String:systemArchitectureInfo->description];
    
    // get the app version info, see related discussions at
    // https://stackoverflow.com/questions/16888780/ios-app-programmatically-get-build-version
    // https://stackoverflow.com/questions/19726988/what-values-should-i-use-for-cfbundleversion-and-cfbundleshortversionstring
    NSString *appUserFacingVersionString = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    NSString *appBuildNumberString = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleVersionKey];
    NSString *appHumanReadableNameString = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleNameKey];
    
    NSString *appVersionInfoString = [NSString stringWithFormat:@"%@ %@ (%@)", appHumanReadableNameString,
                                      appUserFacingVersionString, appBuildNumberString];
    
    // create a dictionary with the report parameters.
    NSDictionary *params = @{
        @"name" : (name ? name : @"[unknown]"),
        @"email" : (email ? email : @"[unknown]"),
        @"agreeemail" : (agreeToEmail ? @"yes" : @"no"),
        @"category" : (category ? category : @"[unknown]"),
        @"subject" : (subject ? subject : @"[unknown]"),
        @"report" : (body ? body : @"[unknown]"),
        @"appversion" : appVersionInfoString,
        @"osversion" : operatingSystemVersionString,
        @"systemarchitecture" : systemArchitectureString,
        @"imagefilename" : (_droppedImageFilepath ? [_droppedImageFilepath lastPathComponent] : @""),
        @"notebookfilename" : (_droppedNotebookFilepath ?
                               [[_droppedNotebookFilepath lastPathComponent] stringByAppendingPathExtension:@"zip"] : @""),
    };

    // create the request boundary string
    NSString *boundary = [NSString boundaryStringForHTTPRequest];

    // create and configure the URL request
    NSURL *url = [NSURL URLWithString:kMHIssueReporterSubmissionURL];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    [request setHTTPMethod:@"POST"];

    // set the content type
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary];
    [request setValue:contentType forHTTPHeaderField: @"Content-Type"];

    // are we including any attachments? put them in a dictionary
    NSMutableDictionary *attachmentsDict = [[NSMutableDictionary alloc] initWithCapacity:0];
    if (_imageAttachmentURL) {
        NSString *imageFilename = [_droppedImageFilepath lastPathComponent];
        NSData *imageData = [NSData dataWithContentsOfURL:_imageAttachmentURL];
        attachmentsDict[@"imageattachment"] = @{
            @"filename" : imageFilename,
            @"data" : imageData
        };
    }
    if (_notebookAttachmentURL) {
        NSString *notebookZippedFilename = [[_droppedNotebookFilepath lastPathComponent] stringByAppendingPathExtension:@"zip"];
        NSData *notebookData = [_notebookAttachmentURL zippedContents];
        attachmentsDict[@"notebookattachment"] = @{
            @"filename" : notebookZippedFilename,
            @"data" : notebookData
        };
    }

    // create the request body with the parameters and attachments
    NSData *httpBody = [NSData createHTTPRequestBodyWithBoundary:boundary parameters:params attachments:attachmentsDict];
        
    // create a URL session and configure it
    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfiguration
                                                          delegate:self
                                                     delegateQueue:[NSOperationQueue mainQueue]];
    
    // create the upload task
    _uploadTask = [session uploadTaskWithRequest:request fromData:httpBody completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        // in the task completion handler we determine how the task ended and report the result to the user
        
        // was the task canceled by the user?
        bool uploadTaskCanceled = [error.domain isEqualToString:NSURLErrorDomain] && error.code == NSURLErrorCancelled;
        
        // if not, look at the data received back from the server
        NSString *result = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        
        // the server returns a comma-separated list of strings. The first string is either "success" or "error"
        NSArray <NSString *> *resultComponents = [result componentsSeparatedByString:@","];
        NSString *status = resultComponents[0];
        if (uploadTaskCanceled) {
            // report that the task was canceled, on the main thread since UI can only be updated there
            [self performSelectorOnMainThread:@selector(reportUploadCanceled) withObject:nil waitUntilDone:YES];
        }
        else if ([status isEqualToString:@"success"]) {
            // report upload success, on the main thread since UI can only be updated there
            // the second string in the list is the reference code
            // the third string in the list is a link to view the report
            NSString *referenceCode = resultComponents[1];
            NSString *reportLink = resultComponents[2];
            NSDictionary *successfulSubmissionParameters = @{
                @"referenceCode" : referenceCode,   // FIXME: literal string
                @"reportLink" : reportLink          // FIXME: literal string
            };
            [self performSelectorOnMainThread:@selector(reportSuccessfulSubmission:)
                                   withObject:successfulSubmissionParameters
                                waitUntilDone:YES];
        }
        else if (error || [status isEqualToString:@"error"]) {
            // report a problem with the upload, on the main thread since UI can only be updated there
            [self performSelectorOnMainThread:@selector(reportUnsuccessfulSubmission) withObject:nil waitUntilDone:YES];
        }
    }];


    // we will present an NSAlert to report on the upload progress and completion, and allow the user to cancel the request if it's taking too long
    
    // create and configure the NSAlert and the UI elements it contains
    _uploadProgressWindow = [[NSAlert alloc] init];
    _uploadProgressWindow.messageText = [NSString stringWithFormat:NSLocalizedString(@"Uploading report to server", @"")];
    [_uploadProgressWindow setInformativeText:NSLocalizedString(@"0 bytes uploaded\n\n", @"")];
    [_uploadProgressWindow addButtonWithTitle:NSLocalizedString(@"Done", @"")];
    [_uploadProgressWindow addButtonWithTitle:NSLocalizedString(@"Cancel", @"")];
   
    NSRect accessoryViewFrame = NSMakeRect(0.0, 0.0, 240.0, 44.0);
    NSView *uploadProgressAccessoryView = [[NSView alloc] initWithFrame:accessoryViewFrame];

    _uploadProgressIndicator = [[NSProgressIndicator alloc] initWithFrame:accessoryViewFrame];
    _uploadProgressIndicator.indeterminate = NO;
    _uploadProgressIndicator.doubleValue = 0.0;
    
    _uploadProgressReportLinkLabel = [[NSTextView alloc] initWithFrame:accessoryViewFrame];
    _uploadProgressReportLinkLabel.drawsBackground = NO;
    _uploadProgressReportLinkLabel.editable = NO;
    _uploadProgressReportLinkLabel.selectable = YES;
    _uploadProgressReportLinkLabel.hidden = YES;
    
    [uploadProgressAccessoryView addSubview:_uploadProgressIndicator];
    [uploadProgressAccessoryView addSubview:_uploadProgressReportLinkLabel];

    _uploadProgressWindow.accessoryView = uploadProgressAccessoryView;

    // there are two buttons, a "Done" button that is enabled when the upload task finishes or is canceled, and a "Cancel" button that is initially enabled and disabled when the task finishes or is canceled
    NSButton *doneButton = [[_uploadProgressWindow buttons] objectAtIndex:0];
    doneButton.enabled = NO;
    NSButton *cancelButton = [[_uploadProgressWindow buttons] objectAtIndex:1];
    [cancelButton setTarget:self];
    [cancelButton setAction:@selector(cancelUpload:)];
    
    // The completion handler for the alert: release the relevant instance variables storing the upload task and UI elements
    void (^uploadProgressWindowCompletionHandler)(NSModalResponse) = ^void(NSModalResponse returnCode) {
        self->_uploadProgressWindow = nil;
        self->_uploadProgressReportLinkLabel = nil;
        self->_uploadProgressIndicator = nil;
        self->_uploadTask = nil;
    };

    // present the alert as a modal sheet
    [_uploadProgressWindow beginSheetModalForWindow:self.window completionHandler:uploadProgressWindowCompletionHandler];

    // start the upload task
    [_uploadTask resume];
}

- (void)cancelUpload:(NSButton *)sender
{
    [_uploadTask cancel];

    NSButton *doneButton = [[_uploadProgressWindow buttons] objectAtIndex:0];
    doneButton.enabled = YES;
    NSButton *cancelButton = [[_uploadProgressWindow buttons] objectAtIndex:1];
    cancelButton.enabled = NO;
    
    _uploadProgressWindow.informativeText = @"Upload canceled";
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didSendBodyData:(int64_t)bytesSent totalBytesSent:(int64_t)totalBytesSent totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend
{
    double dataSentInMB = (double)totalBytesSent / 1024.0 / 1024;
    double dataExpectedToSendInMB = (double)totalBytesExpectedToSend / 1024.0 / 1024;
    NSString *statusUpdateString = [NSString stringWithFormat:NSLocalizedString(@"Sent %.1f MB of %.1f MB", @""),
                                    dataSentInMB, dataExpectedToSendInMB];
    [_uploadProgressWindow setInformativeText:statusUpdateString];
    _uploadProgressIndicator.doubleValue = (double)totalBytesSent / (double)totalBytesExpectedToSend * 100.0;
}

- (void)reportSuccessfulSubmission:(NSDictionary *)parameters
{
    NSString *referenceCode = parameters[@"referenceCode"];
    NSString *linkURL = parameters[@"reportLink"];
    
    NSString *statusString = [NSString stringWithFormat:NSLocalizedString(@"The reference code is %@\nUse the link below to view your report:", @""), referenceCode];
    
    _uploadProgressIndicator.doubleValue = 100.0;
    _uploadProgressWindow.messageText = @"Report submitted successfully";
    _uploadProgressWindow.informativeText = statusString;
    
    _uploadProgressIndicator.hidden = YES;
    _uploadProgressReportLinkLabel.hidden = NO;
    
    NSMutableAttributedString *linkAttribString = [[NSMutableAttributedString alloc] initWithString:linkURL];
    [linkAttribString addAttribute:NSLinkAttributeName value:linkURL range:NSMakeRange(0, linkAttribString.length)];
    
    _uploadProgressReportLinkLabel.editable = YES;
    [_uploadProgressReportLinkLabel insertText:linkAttribString replacementRange:NSMakeRange(0, 0)];
    _uploadProgressReportLinkLabel.editable = NO;

    
    NSButton *doneButton = [[_uploadProgressWindow buttons] objectAtIndex:0];
    doneButton.enabled = YES;
    NSButton *cancelButton = [[_uploadProgressWindow buttons] objectAtIndex:1];
    cancelButton.enabled = NO;
    
    self.dismissCancelButton.title = NSLocalizedString(@"Close", @"");
    
    // The report has been submitted - disable any UI elements related to entering report data to freeze them in their current state
    self.reportNameTextField.enabled = NO;
    self.reportEmailTextField.enabled = NO;
    self.agreeToEmailCheckbox.enabled = NO;
    self.reportSubjectTextField.enabled = NO;
    self.reportBodyTextView.editable = NO;
    self.submitReportButton.enabled = NO;
    self.reportCategoryPopUp.enabled = NO;
    self.resourceDroppingView.enabled = NO;
    self.clearImageAttachmentButton.enabled = NO;
    self.clearNotebookAttachmentButton.enabled = NO;
    
    // display an info message
    NSString *successfulSubmissionInfoMessageFromNib = self.successfulSubmissionInfoLabel.stringValue;
    NSString *successfulSubmissionInfoMessageToDisplay =
    [successfulSubmissionInfoMessageFromNib stringByReplacingOccurrencesOfString:@"*****"
                                                                      withString:referenceCode];
    self.successfulSubmissionInfoLabel.stringValue = successfulSubmissionInfoMessageToDisplay;
    self.successfulSubmissionInfoLabel.hidden = NO;
}

- (void)reportUnsuccessfulSubmission
{
    NSString *statusString = NSLocalizedString(@"Error: unable to upload your report", @"");
    
    _uploadProgressWindow.informativeText = statusString;
    
    NSButton *doneButton = [[_uploadProgressWindow buttons] objectAtIndex:0];
    doneButton.enabled = YES;
    NSButton *cancelButton = [[_uploadProgressWindow buttons] objectAtIndex:1];
    cancelButton.enabled = NO;
}

- (void)reportUploadCanceled
{
    NSString *statusString = NSLocalizedString(@"The report submission was canceled", @"");
    
    _uploadProgressWindow.informativeText = statusString;
    
    NSButton *doneButton = [[_uploadProgressWindow buttons] objectAtIndex:0];
    doneButton.enabled = YES;
    NSButton *cancelButton = [[_uploadProgressWindow buttons] objectAtIndex:1];
    cancelButton.enabled = NO;
}


- (void)resourceDroppingView:(MHResourceDroppingView *)resourceDroppingView receivedResource:(NSURL *)fileResourceURL
{
    NSString *filePath = [fileResourceURL path];
    NSString *fileExtension = [filePath pathExtension];
    if ([fileExtension isEqualToString:kMHMadhatNotebookExtension]) {
        self.notebookAttachmentURL = fileResourceURL;
        [self updateUserInterfaceAfterAttachmentAction:YES];
    }
    else {
        // we assume that the URL is for an image file
        self.imageAttachmentURL = fileResourceURL;
        [self updateUserInterfaceAfterAttachmentAction:YES];
    }
}

- (BOOL)resourceDroppingView:(MHResourceDroppingView *)resourceDroppingView shouldAcceptResource:(NSURL *)fileResourceURL
{
    NSString *filePath = [fileResourceURL path];
    NSString *fileExtension = [filePath pathExtension];
    return ([fileExtension isEqualToString:kMHMadhatNotebookExtension] || [fileResourceURL isImageType]);
}

- (void)showFileTooLargeIndicator:(MHResourceDroppingView *)sender
{
    self.resourceDroppingViewMaxFileSizeInfoLabel.hidden = NO;
}

- (void)hideFileTooLargeIndicator:(MHResourceDroppingView *)sender
{
    self.resourceDroppingViewMaxFileSizeInfoLabel.hidden = YES;
}



- (IBAction)clearImageAttachment:(id)sender
{
    self.imageAttachmentURL = nil;
    [self updateUserInterfaceAfterAttachmentAction:YES];
}

- (IBAction)clearNotebookAttachment:(id)sender
{
    self.notebookAttachmentURL = nil;
    [self updateUserInterfaceAfterAttachmentAction:YES];
}

- (IBAction)dismiss:(id)sender
{
    [self.window close];
}


- (NSURL *)imageAttachmentURL
{
    return _imageAttachmentURL;
}

- (void)setImageAttachmentURL:(NSURL *)imageURL
{
    _imageAttachmentURL = imageURL;
    
    if (_imageAttachmentURL) {
        _droppedImageFilepath = [imageURL path];
        NSData *droppedImageData = [NSData dataWithContentsOfURL:imageURL];
        
        NSUInteger droppedImageLength = droppedImageData.length;
        if (droppedImageLength > kMHIssueReporterMaxAttachmentSize) {
            self.imageAttachmentURL = nil;
            return;
        }
        self.imageViewFilenameLabel.stringValue = [_droppedImageFilepath lastPathComponent];
        self.imageViewFileSizeLabel.stringValue = [NSString stringWithFormat:NSLocalizedString(@"%lu bytes", @""), droppedImageData.length];
        self.clearImageAttachmentButton.hidden = NO;
    }
    else {
        self.clearImageAttachmentButton.hidden = YES;
        self.imageViewFilenameLabel.stringValue = @"--";
        self.imageViewFileSizeLabel.stringValue = @"";
    }
}

- (NSURL *)notebookAttachmentURL
{
    return _notebookAttachmentURL;
}

- (void)setNotebookAttachmentURL:(NSURL *)notebookURL
{
    _notebookAttachmentURL = notebookURL;
    
    if (_notebookAttachmentURL) {
        _droppedNotebookFilepath = [notebookURL path];
        NSUInteger droppedNotebookSize = [_notebookAttachmentURL sizeOfFileOrDirectory];
        if (droppedNotebookSize > kMHIssueReporterMaxAttachmentSize) {
            self.notebookAttachmentURL = nil;
            return;
        }
        self.notebookAttachmentFilenameLabel.stringValue = [_droppedNotebookFilepath lastPathComponent];
        self.notebookAttachmentFileSizeLabel.stringValue = [NSString stringWithFormat:NSLocalizedString(@"%lu bytes", @""), droppedNotebookSize];
        self.clearNotebookAttachmentButton.hidden = NO;
    }
    else {
        self.clearNotebookAttachmentButton.hidden = YES;
        self.notebookAttachmentFilenameLabel.stringValue = @"--";
        self.notebookAttachmentFileSizeLabel.stringValue = @"";
    }
}



- (void)updateUserInterfaceAfterAttachmentAction:(BOOL)animated
{
    NSView *resourceDroppingView = self.resourceDroppingView.superview;
    NSView *attachmentDetailsContainerView = self.attachmentDetailsContainerView;
    NSRect resourceDroppingViewFrame = resourceDroppingView.frame;
    NSRect attachmentDetailsContainerViewFrame = attachmentDetailsContainerView.frame;
    
    bool resourceDroppingViewExpanded = (resourceDroppingViewFrame.origin.x + resourceDroppingViewFrame.size.width ==
                                         attachmentDetailsContainerViewFrame.origin.x + attachmentDetailsContainerViewFrame.size.width);

    if (_imageAttachmentURL == nil && _notebookAttachmentURL == nil) {
        // no attachments - expand the resource dropping view if it is not already expanded
        self.attachmentDetailsContainerView.hidden = YES;
        if (!resourceDroppingViewExpanded) {
            resourceDroppingViewFrame.size.width =
            attachmentDetailsContainerViewFrame.origin.x + attachmentDetailsContainerViewFrame.size.width - resourceDroppingViewFrame.origin.x;
            
            if (animated) {
                [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
                    context.duration = 0.25;
                    resourceDroppingView.animator.frame = resourceDroppingViewFrame;
                }
                completionHandler:^{}];
            }
            else {
                resourceDroppingView.frame = resourceDroppingViewFrame;
            }
        }
    }
    else {
        // we have attachments - collapse the resource dropping view and show the attachment detail interface elements
        self.attachmentDetailsContainerView.hidden = NO;
        if (resourceDroppingViewExpanded) {
            resourceDroppingViewFrame.size.width =
            attachmentDetailsContainerViewFrame.origin.x - 26.0;
            
            if (animated) {
                [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
                    context.duration = 0.25;
                    resourceDroppingView.animator.frame = resourceDroppingViewFrame;
                }
                completionHandler:^{}];
            }
            else {
                resourceDroppingView.frame = resourceDroppingViewFrame;
            }
        }

    }
}




@end



@implementation NSString (HTTPRequestExtension)

+ (NSString *)boundaryStringForHTTPRequest
{
    return [NSString stringWithFormat:@"Boundary-%@", [[NSUUID UUID] UUIDString]];
}

+ (NSString *)mimeTypeForPath:(NSString *)path
{
    // get a mime type from a file extension

    CFStringRef extension = (__bridge CFStringRef)[path pathExtension];
    CFStringRef UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, extension, NULL);
    assert(UTI != NULL);

    NSString *mimetype = CFBridgingRelease(UTTypeCopyPreferredTagWithClass(UTI, kUTTagClassMIMEType));
    assert(mimetype != NULL);

    CFRelease(UTI);

    return mimetype;
}

@end


@implementation NSData (HTTPRequestExtension)

+ (NSData *)createHTTPRequestBodyWithBoundary:(NSString *)boundary
                                   parameters:(NSDictionary *)parameters
                                  attachments:(NSDictionary <NSString *, NSDictionary <NSString *, id> *> *)attachments
{
    NSMutableData *httpBody = [NSMutableData data];

    // add the request parameters
    [parameters enumerateKeysAndObjectsUsingBlock:^(NSString *parameterKey, NSString *parameterValue, BOOL *stop) {
        [httpBody appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [httpBody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", parameterKey] dataUsingEncoding:NSUTF8StringEncoding]];
        [httpBody appendData:[[NSString stringWithFormat:@"%@\r\n", parameterValue] dataUsingEncoding:NSUTF8StringEncoding]];
    }];

    // add attachments
    for (NSString *fieldName in attachments) {
        NSDictionary *attachmentDict = attachments[fieldName];
        NSString *filename  = attachmentDict[@"filename"];
        NSData   *data      = attachmentDict[@"data"];
        NSString *mimetype  = [NSString mimeTypeForPath:filename];

        [httpBody appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [httpBody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n", fieldName, filename] dataUsingEncoding:NSUTF8StringEncoding]];
        [httpBody appendData:[[NSString stringWithFormat:@"Content-Type: %@\r\n\r\n", mimetype] dataUsingEncoding:NSUTF8StringEncoding]];
        [httpBody appendData:data];
        [httpBody appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    }

    [httpBody appendData:[[NSString stringWithFormat:@"--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];

    return httpBody;
}


@end
