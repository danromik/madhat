//
//  MHDocumentController.m
//  MadHat
//
//  Created by Dan Romik on 8/11/21.
//  Copyright © 2021 Dan Romik. All rights reserved.
//

#import "MHDocumentController.h"
#import "MHHelpNotebook.h"

// help pages
static NSString * const kMHHelpNotebookFilename = @"madhat help";
static NSString * const kMHHelpNotebookFileExtension = @"madhathelp";   // if this ever gets changed, it is also defined in the Info.plist so needs to be updated there as well

static const NSInteger kMHDocumentControllerNewDocumentMenuItemTag = 999;   // specified in MainMenu.xib
static const NSInteger kMHDocumentControllerOpenDocumentMenuItemTag = 998;   // specified in MainMenu.xib


@implementation MHDocumentController

+ (void) load
{
    // instantiate a new MHDocumentController object as soon as the class loads. This forces MHDocumentController as the class for the shared document controller object, since only one instance of NSDocumentController or a subclass is allowed to exist
    [MHDocumentController new];
    
    // this method is described on this stack overflow thread: (there are some other suggestions there of how to achieve the same effect, but this one seemed the most elegant)
    // https://stackoverflow.com/questions/7373446/how-do-i-use-a-subclass-of-nsdocumentcontroller-in-xcode-4
}

+ (BOOL)appConfigurationComplete
{
    return YES;
    
    // disabling this for now - I decided to bundle the required fonts in the app so there is no need for an installer
//    static NSArray <NSString *> *requiredFontNames;
//    static BOOL appConfigurationValidated;
//
//    if (appConfigurationValidated)
//        return YES;
//
//    if (!requiredFontNames) {
//        requiredFontNames = @[
//            @"Latin Modern Roman",
//            @"Latin Modern Math",
//            @"TeX Gyre Bonum",
//            @"TeX Gyre Bonum Math",
//            @"TeX Gyre Pagella",
//            @"TeX Gyre Pagella Math",
//            @"TeX Gyre Schola",
//            @"TeX Gyre Schola Math",
//            @"TeX Gyre Termes",
//            @"TeX Gyre Termes Math",
//        ];
//    }
//
//    for (NSString *fontName in requiredFontNames) {
//        NSFont *font = [NSFont fontWithName:fontName size:12.0];
//        if (!font)
//            return NO;
//    }
//
//    appConfigurationValidated = YES;
//    return YES;
}

- (void)noteNewRecentDocument:(NSDocument *)document
{
    if (![document.class isEqual:[MHHelpNotebook class]]) {
        [super noteNewRecentDocument:document];     // opening the help notebook should not register as a recent document
    }
}

- (NSString *)filePathForHelpPagesNotebook
{
    NSString *notebookFilenameWithExtension = [NSString stringWithFormat:@"%@.%@",
                                               kMHHelpNotebookFilename, kMHHelpNotebookFileExtension];
    NSString *helpPagesNotebookFilePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:notebookFilenameWithExtension];
    return helpPagesNotebookFilePath;
}

- (NSURL *)urlForHelpPagesNotebook
{
    NSString *helpPagesNotebookFilePath = [self filePathForHelpPagesNotebook];
    NSURL *fileURL = [NSURL fileURLWithPath:helpPagesNotebookFilePath isDirectory:YES];
    return fileURL;
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
    NSInteger menuItemTag = menuItem.tag;
    if (menuItemTag == kMHDocumentControllerNewDocumentMenuItemTag ||
        menuItemTag == kMHDocumentControllerOpenDocumentMenuItemTag) {
        return [MHDocumentController appConfigurationComplete];
    }

    return [super validateMenuItem:menuItem];
}



// This override attempts to prevent any document of the same type as the help pages notebook from being opened, except the help pages notebook itself
// FIXME: this doesn't work at all - after not calling super it seems impossible to open any documents. So it could be the wrong method to override. Maybe overriding -makeDocumentForURL:withContentsOfURL:ofType:error: instead will work?
//
//- (void)openDocumentWithContentsOfURL:(NSURL *)url display:(BOOL)displayDocument completionHandler:(void (^)(NSDocument *document, BOOL documentWasAlreadyOpen, NSError *error))completionHandler
//{
//    bool isAHelpTypeNotebook = [url.pathExtension isEqualToString:kMHHelpNotebookFileExtension];
//    bool isTheOfficialHelpPagesNotebook;
//    if (!isAHelpTypeNotebook)
//        isTheOfficialHelpPagesNotebook = NO;
//    else if (!url.fileURL)
//        isTheOfficialHelpPagesNotebook = NO;
//    else
//        isTheOfficialHelpPagesNotebook = [url.path isEqualToString:[self filePathForHelpPagesNotebook]];
//
//    if (!isAHelpTypeNotebook || isTheOfficialHelpPagesNotebook) {
//        [super openDocumentWithContentsOfURL:url display:displayDocument completionHandler:completionHandler];
//    }
//    else {
//        NSLog(@"cannot open unknown document of type %@", url.pathExtension);
//    }
//}


@end
