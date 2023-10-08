//
//  MHLink.m
//  MadHat
//
//  Created by Dan Romik on 10/22/20.
//  Copyright © 2020 Dan Romik. All rights reserved.
//

#import "MHLink.h"
#import "MHStyleIncludes.h"
#import "MHTextAtom.h"
#import "MHSpriteKitScene.h"
#import "AppDelegate.h"
#import "MHParser+SpecialSymbols.h"
#import "MHQuotedCodeExpression.h"
#import <objc/runtime.h>

typedef enum {
    MHHyperlinkWithURLOnly,
    MHHyperlinkWithURLAndContents,
    MHIntraLink,
    MHCommandHelpLink,  // FIXME: figure out how to include information about math/text mode and math keyword
    MHHelpPageLink
} MHLinkType;


char kMHLinkLinkedExpressionAssociatedObjectKey;

NSString * const kMHHyperlinkCommandName = @"hyperlink";
NSString * const kMHIntralinkCommandName = @"intralink";
NSString * const kMHCommandHelpLinkCommandName = @"command help link";
NSString * const kMHHelpPageLinkCommandName = @"help page link";

NSString * const kMHLinkSlideNumberAttributeName = @"slide";

@interface MHLink ()
{
    MHLinkType _linkType;
    NSString *_linkDestinationString;   // this will be either the URL string for a URL link or the page name for an intralink
    NSInteger _linkDestinationSlideNumber;  // for intralinks, this will be the slide number to link to, if a slide number is included in the arguments, or NSNotFound otherwise
}

@end

@implementation MHLink

#pragma mark - Constructors

+ (instancetype)intralinkWithPageName:(NSString *)pageName
{
    MHHorizontalLayoutContainer *contentsContainer = [MHHorizontalLayoutContainer containerWithPlainTextString:pageName];
    return [[self alloc] initWithType:MHIntraLink
                    destinationString:pageName
                          slideNumber:NSNotFound
                             contents:contentsContainer];
}

+ (instancetype)intralinkWithPageName:(NSString *)pageName contents:(MHExpression *)contents
{
    return [[self alloc] initWithType:MHIntraLink
                    destinationString:pageName
                          slideNumber:NSNotFound
                             contents:contents];
}

+ (instancetype)intralinkWithPageName:(NSString *)pageName slideNumber:(NSUInteger)slideNumber
{
    MHHorizontalLayoutContainer *contentsContainer = [MHHorizontalLayoutContainer containerWithPlainTextString:pageName];
    return [[self alloc] initWithType:MHIntraLink
                    destinationString:pageName
                          slideNumber:slideNumber
                             contents:contentsContainer];
}

+ (instancetype)intralinkWithPageName:(NSString *)pageName slideNumber:(NSUInteger)slideNumber contents:(MHExpression *)contents
{
    return [[self alloc] initWithType:MHIntraLink
                    destinationString:pageName
                          slideNumber:slideNumber
                             contents:contents];
}


+ (instancetype)commandHelpLinkWithCommandName:(NSString *)commandName
{
//    MHHorizontalLayoutContainer *contentsContainer = [MHHorizontalLayoutContainer containerWithPlainTextString:commandName];
    NSString *commandCode = [NSString stringWithFormat:@"%C%@",  kMHParserCharStartCommand, commandName];
    MHQuotedCodeExpression *contents = [MHQuotedCodeExpression quotedCodeExpressionWithCodeString:commandCode inTextMode:true];
    return [[self alloc] initWithType:MHCommandHelpLink
                    destinationString:commandName
                          slideNumber:NSNotFound
                             contents:contents];
}

+ (instancetype)commandHelpLinkWithCommandName:(NSString *)commandName contents:(MHExpression *)contents
{
    return [[self alloc] initWithType:MHCommandHelpLink
                    destinationString:commandName
                          slideNumber:NSNotFound
                             contents:contents];
}

+ (instancetype)helpPageLinkWithHelpPageName:(NSString *)helpPageName
{
    MHHorizontalLayoutContainer *contentsContainer = [MHHorizontalLayoutContainer containerWithPlainTextString:helpPageName];
    return [[self alloc] initWithType:MHHelpPageLink
                    destinationString:helpPageName
                          slideNumber:NSNotFound
                             contents:contentsContainer];
}

+ (instancetype)helpPageLinkWithHelpPageName:(NSString *)helpPageName contents:(MHExpression *)contents
{
    return [[self alloc] initWithType:MHHelpPageLink
                    destinationString:helpPageName
                          slideNumber:NSNotFound
                             contents:contents];
}


+ (instancetype)linkWithUrlString:(NSString *)urlString contents:(MHExpression *)contents
{
    return [[self alloc] initWithType:MHHyperlinkWithURLAndContents
                    destinationString:urlString
                          slideNumber:NSNotFound
                             contents:contents];
}

+ (instancetype)linkWithUrlString:(NSString *)urlString
{
    NSUInteger urlStringLength = urlString.length;
    
    // Should we remove percent encoding to get the string to display? I decided not to
//    NSString *unescapedUrlString = [urlString stringByRemovingPercentEncoding]; // this is the text that will be displayed
    
    MHExpression *linkContents = (urlString.length > 0 ?
                                  [MHTextAtom textAtomWithString:urlString] : [MHExpression expression]);
                    
    NSString *detectedURLString = nil;

    // Scan the provided string with an NSDataDetector to see if it matches the pattern for a URL
    NSError *error = nil;
    NSDataDetector *detector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeLink error:&error];
    NSTextCheckingResult *result = [detector firstMatchInString:urlString
                                                        options:0
                                                          range:NSMakeRange(0, urlStringLength)];

    NSRange resultRange = result.range;

    if (resultRange.location == 0 && resultRange.length == urlStringLength) {
        // if the NSDataDetector found a match and that match encompasses the entire string, use the detected URL string
        detectedURLString = result.URL.absoluteString;
        
        //
        // Okay, we detected the URL string but need to make one last tweak. When a URL scheme is not provided
        // as part of the URL string, NSDataDetector assumes the scheme HTTP by default. We prefer HTTPS,
        // so the code below checks whether the following two conditions are satisfied:
        // 1. the original URL string did not contain the prefix http://
        // 2. the detected URL string does contain the prefix http://
        // When both conditions are satisfied, the prefix http:// in the detected string is substituted with https://
        //
        // For a related discussion, see:
        // https://stackoverflow.com/questions/53525537/detecting-url-in-a-text-with-https-format
        //

        NSString * const httpPrefix = @"http://";
        NSString * const httpsPrefix = @"https://";
        NSRange rangeOfHTTPPrefixInURLString = [urlString rangeOfString:httpPrefix];
        NSRange rangeOfHTTPPrefixInDetectedURLString = [detectedURLString rangeOfString:httpPrefix];
        const NSRange comparisonRangeOfHTTPPrefix = NSMakeRange(0, 7);
        
        if (NSEqualRanges(rangeOfHTTPPrefixInDetectedURLString, comparisonRangeOfHTTPPrefix)
            && !NSEqualRanges(rangeOfHTTPPrefixInURLString, comparisonRangeOfHTTPPrefix)) {
            NSString *modifiedDetectedURLString = [NSString stringWithFormat:@"%@%@", httpsPrefix,
                                                   [detectedURLString substringFromIndex:7]];
            
            detectedURLString = modifiedDetectedURLString;
        }
    }

    return [[self alloc] initWithType:MHHyperlinkWithURLOnly
                    destinationString:(detectedURLString ? detectedURLString : urlString)
                          slideNumber:NSNotFound
                             contents:linkContents];
}

- (instancetype)initWithType:(MHLinkType)type
           destinationString:(NSString *)destinationString
                 slideNumber:(NSInteger)slideNumber
                    contents:(MHExpression *)contents
{
//    if ([contents stringValue].length == 0) {
//        return nil;
//    }
    if (self = [super initWithContents:contents]) {
        _linkType = type;
        _linkDestinationString = destinationString;
        _linkDestinationSlideNumber = slideNumber;
    }
    return self;
}


#pragma mark - MHCommand protocol

+ (MHExpression *)commandNamed:(NSString *)name
                withParameters:(NSDictionary *)parameters
                      argument:(MHHorizontalLayoutContainer *)argument
{
    if ([name isEqualToString:kMHHyperlinkCommandName]) {
        NSUInteger numberOfDelimitedBlocks = [argument numberOfDelimitedBlocks];
        if (numberOfDelimitedBlocks == 1) {
            return [self linkWithUrlString:[argument stringValue]];
        }
        MHExpression *urlBlock = [argument expressionFromDelimitedBlockAtIndex:0];
        MHExpression *contentsBlock = [argument expressionFromDelimitedBlockAtIndex:1];
        return [self linkWithUrlString:[urlBlock stringValue] contents:contentsBlock];
    }
    if ([name isEqualToString:kMHIntralinkCommandName]) {
        NSInteger slideNumber = NSNotFound;
        NSDictionary *attributes = argument.attributes;
        MHExpression *slideNumberExpression = attributes[kMHLinkSlideNumberAttributeName];
        if (slideNumberExpression) {
            slideNumber = [slideNumberExpression intValue] - 1; // convert a user-specified slide number (where "1" would correspond to the first slide on the page) to the internal representation of slide numbres, in which slide numbers start at 0
        }
        
        NSUInteger numberOfDelimitedBlocks = [argument numberOfDelimitedBlocks];
        if (numberOfDelimitedBlocks == 1) {
            return [self intralinkWithPageName:[argument stringValue] slideNumber:slideNumber];
        }
        MHExpression *pageNameBlock = [argument expressionFromDelimitedBlockAtIndex:0];
        MHExpression *contentsBlock = [argument expressionFromDelimitedBlockAtIndex:1];
        return [self intralinkWithPageName:[pageNameBlock stringValue] slideNumber:slideNumber contents:contentsBlock];
    }
    if ([name isEqualToString:kMHCommandHelpLinkCommandName]) {
        NSUInteger numberOfDelimitedBlocks = [argument numberOfDelimitedBlocks];
        if (numberOfDelimitedBlocks == 1) {
            return [self commandHelpLinkWithCommandName:[argument stringValue]];
        }
        MHExpression *commandNameBlock = [argument expressionFromDelimitedBlockAtIndex:0];
        MHExpression *contentsBlock = [argument expressionFromDelimitedBlockAtIndex:1];
        return [self commandHelpLinkWithCommandName:[commandNameBlock stringValue] contents:contentsBlock];
    }
    if ([name isEqualToString:kMHHelpPageLinkCommandName]) {
        NSUInteger numberOfDelimitedBlocks = [argument numberOfDelimitedBlocks];
        if (numberOfDelimitedBlocks == 1) {
            return [self helpPageLinkWithHelpPageName:[argument stringValue]];
        }
        MHExpression *helpPageNameBlock = [argument expressionFromDelimitedBlockAtIndex:0];
        MHExpression *contentsBlock = [argument expressionFromDelimitedBlockAtIndex:1];
        return [self helpPageLinkWithHelpPageName:[helpPageNameBlock stringValue] contents:contentsBlock];
    }

    
    return nil;
}

+ (NSArray <NSString *> *)recognizedCommands
{
    return @[ kMHHyperlinkCommandName, kMHIntralinkCommandName, kMHHelpPageLinkCommandName ];
}


#pragma mark - Typesetting

- (void)typesetWithContextManager:(MHTypesettingContextManager *)contextManager
{    
    NSString *styleName = nil;
    switch (_linkType) {
        case MHHyperlinkWithURLOnly:
            styleName = kMHPredefinedTypesettingStateNameURLHyperlink;
            break;
        case MHHyperlinkWithURLAndContents:
            styleName = kMHPredefinedTypesettingStateNameTextHyperlink;
            break;
        case MHHelpPageLink:
            styleName = kMHPredefinedTypesettingStateNameIntralink;
            break;
        case MHIntraLink:
            styleName = kMHPredefinedTypesettingStateNameIntralink;
            break;

        default:
            break;
    }
    if (styleName) {

        MHExpression *myContents = self.contents;
        if (myContents.splittable) {
            // calculate the unsplittable components and associate the link with each of them. This is used during PDF exporting to add links in the PDF
            NSArray <MHExpression *> *components = [(MHExpression <MHSplittableExpression> *)(self.contents)
                                                    flattenedListOfUnsplittableComponents];
            for (MHExpression *subexpression in components) {
                objc_setAssociatedObject(subexpression, &kMHLinkLinkedExpressionAssociatedObjectKey, self, OBJC_ASSOCIATION_ASSIGN);
            }
        }
        
        [contextManager beginLocalScope];
        [contextManager loadSavedTypesettingStateWithStyleName:styleName];
        [super typesetWithContextManager:contextManager];
        [contextManager endLocalScope];
    }

    self.spriteKitNode.ownerExpressionAcceptsMouseClicks = true;
}


#pragma mark - Mouse clicks and hovering behavior

- (void)mouseClickWithEvent:(NSEvent *)event subnode:(SKNode *)node
{
    switch (_linkType) {
        case MHHyperlinkWithURLOnly:
        case MHHyperlinkWithURLAndContents: {
            NSURL *url = [NSURL URLWithString:_linkDestinationString];
            if (url)
                [[NSWorkspace sharedWorkspace] openURL:url];
        }
            break;
        case MHIntraLink: {
            MHSpriteKitScene *spriteKitScene = [self.spriteKitNode enclosingSpriteKitScene];
            [spriteKitScene invokeIntralinkToNotebookPage:_linkDestinationString slideNumber:_linkDestinationSlideNumber];
        }
            break;
        case MHCommandHelpLink: {
            AppDelegate *myAppDelegate = (AppDelegate *)[[NSApplication sharedApplication] delegate];
            [myAppDelegate openHelpPageForCommandName:_linkDestinationString];
        }
            break;
        case MHHelpPageLink: {
            AppDelegate *myAppDelegate = (AppDelegate *)[[NSApplication sharedApplication] delegate];
            [myAppDelegate openHelpPage:_linkDestinationString];
        }
            break;
    }
}

- (void)setHighlighted:(bool)highlighted
{
    // FIXME: disabling this for now
    // FIXME: I added code to modify the mouse cursor in the mouseMoved method of MHSpriteKitScene, but this is badly written code and needs to be completely rethought
//    [super setHighlighted:highlighted];
//    if (highlighted) {
//        [NSCursor.pointingHandCursor set];
//    }
//    else {
//        [NSCursor.arrowCursor set];
//    }
}

- (NSString *)mouseHoveringAuxiliaryTextWithHoveringNode:(SKNode *)node
{
    switch (_linkType) {
        case MHHyperlinkWithURLOnly:
        case MHHyperlinkWithURLAndContents:
            return [NSString stringWithFormat:NSLocalizedString(@"Open link: %@", @""), _linkDestinationString];
        case MHIntraLink:
            if (_linkDestinationSlideNumber == NSNotFound)
                return [NSString stringWithFormat:NSLocalizedString(@"Go to notebook page: %@", @""), _linkDestinationString];
            return [NSString stringWithFormat:NSLocalizedString(@"Go to notebook page: %@ / slide %lu", @""), _linkDestinationString, _linkDestinationSlideNumber+1];
        case MHCommandHelpLink:
            return [NSString stringWithFormat:NSLocalizedString(@"Open help page for command: %C%@", @""),  kMHParserCharStartCommand, _linkDestinationString];
        case MHHelpPageLink:
            return [NSString stringWithFormat:NSLocalizedString(@"Open help page: %@", @""),  _linkDestinationString];
    }
}


#pragma mark - Expression copying

- (instancetype)logicalCopy
{
    MHLink *myCopy = [[[self class] alloc] initWithType:_linkType
                                              destinationString:_linkDestinationString
                                            slideNumber:_linkDestinationSlideNumber
                                               contents:[self.contents logicalCopy]];
    myCopy.codeRange = self.codeRange;
    return myCopy;
}



#pragma mark - Rendering to PDF contexts

// FIXME: there is a lot of repetition here - the code for adding the link to the PDF is repeated three times, two in the renderToPDFWithContextManager method and once in the addPDFLinkForExpression method
- (void)renderToPDFWithContextManager:(MHPDFRenderingContextManager *)contextManager
{
    [super renderToPDFWithContextManager:contextManager];
    CGContextRef pdfContext = contextManager.pdfContext;
    
    switch (_linkType) {
        case MHIntraLink:
        case MHHelpPageLink:    // FIXME: treating help links the same is intralinks so the user manual exports correctly, but in principle help links should behave differently. For now it doesn't matter very much since the help link command isn't a public one, but fix this at some point
        case MHHyperlinkWithURLOnly:
        case MHHyperlinkWithURLAndContents: {
            MHExpression *myContents = self.contents;
            if (myContents.splittable) {
                // Since the contents identify themselves as splittable, they can be safely assumed to conform to the MHSplittableExpression protocol
                NSArray <MHExpression *> *components = [(MHExpression <MHSplittableExpression> *)myContents flattenedListOfUnsplittableComponents];
                
                for (MHExpression *component in components) {
                    MHDimensions componentDimensions = component.dimensions;
                    NSPoint componentPositionInSelfCoordinates = [_spriteKitNode convertPoint:CGPointZero fromNode:component.spriteKitNode];
                    NSPoint componentPositionInDeviceSpace = CGContextConvertPointToDeviceSpace(pdfContext, componentPositionInSelfCoordinates);    // FIXME: should we convert to device space or user space? the conversion is used to define the link rectangle, which is fed to the CGPDFContextSetDestinationForRect and CGPDFContextSetURLForRect methods, both of which require the rectangle in default user space, so it's confusing why the current code works. However, it does work so I guess that's the main thing that matters...
                    CGRect linkRectangle = CGRectMake(componentPositionInDeviceSpace.x,
                                                      componentPositionInDeviceSpace.y - componentDimensions.depth,
                                                      componentDimensions.width, componentDimensions.depth + componentDimensions.height);
                    
                    if (_linkType == MHIntraLink || _linkType == MHHelpPageLink) {  // FIXME: help page links maybe should be treated separately than intralinks
                        CFStringRef cfstring = (__bridge CFStringRef)_linkDestinationString;
                        CGPDFContextSetDestinationForRect(pdfContext, cfstring, linkRectangle);
                        [contextManager declareDestinationLink:_linkDestinationString];
                    }
                    else {
                        NSURL *url = [NSURL URLWithString:_linkDestinationString];
                        if (url) {
                            CFURLRef cfurl = (__bridge CFURLRef)url;
                            CGPDFContextSetURLForRect(pdfContext, cfurl, linkRectangle);
                        }
                        else {
                            NSLog(@"Error: string '%@' not a valid URL string", _linkDestinationString);
                        }
                    }
                }
            }
            else {
                MHDimensions contentsDimensions = myContents.dimensions;
                NSPoint contentsPositionInSelfCoordinates = [_spriteKitNode convertPoint:CGPointZero fromNode:myContents.spriteKitNode];
                NSPoint contentsPositionInDeviceSpace = CGContextConvertPointToDeviceSpace(pdfContext, contentsPositionInSelfCoordinates);      // FIXME: should we convert to device space or user space? the conversion is used to define the link rectangle, which is fed to the CGPDFContextSetDestinationForRect and CGPDFContextSetURLForRect methods, both of which require the rectangle in default user space, so it's confusing why the current code works. However, it does work so I guess that's the main thing that matters...
                CGRect linkRectangle = CGRectMake(contentsPositionInDeviceSpace.x,
                                                  contentsPositionInDeviceSpace.y - contentsDimensions.depth,
                                                  contentsDimensions.width, contentsDimensions.depth + contentsDimensions.height);
                if (_linkType == MHIntraLink || _linkType == MHHelpPageLink) {  // FIXME: help page links maybe should be treated separately than intralinks
                    CFStringRef cfstring = (__bridge CFStringRef)_linkDestinationString;
                    CGPDFContextSetDestinationForRect(pdfContext, cfstring, linkRectangle);
                    [contextManager declareDestinationLink:_linkDestinationString];
                }
                else {
                    NSURL *url = [NSURL URLWithString:_linkDestinationString];
                    CFURLRef cfurl = (__bridge CFURLRef)url;
                    CGPDFContextSetURLForRect(pdfContext, cfurl, linkRectangle);
                }
            }
        }
            break;
        case MHCommandHelpLink:
//        case MHHelpPageLink:  // FIXME: for now I'm treating help links the same as intralinks, maybe change this later
            // FIXME: add this
            break;
    }
}

// FIXME: this repeats a lot of the code in the renderToPDFWithContextManager method - violates DRY, improve/refactor
- (void)addPDFLinkForExpression:(MHExpression *)expression
             withContextManager:(MHPDFRenderingContextManager  *)contextManager
{
    CGContextRef pdfContext = contextManager.pdfContext;
    switch (_linkType) {
        case MHIntraLink:
        case MHHelpPageLink:
        case MHHyperlinkWithURLOnly:
        case MHHyperlinkWithURLAndContents: {
            MHDimensions expressionDimensions = expression.dimensions;
            NSPoint expressionPositionInDeviceSpace = CGContextConvertPointToDeviceSpace(pdfContext, CGPointZero);      // FIXME: should we convert to device space or user space? the conversion is used to define the link rectangle, which is fed to the CGPDFContextSetDestinationForRect and CGPDFContextSetURLForRect methods, both of which require the rectangle in default user space, so it's confusing why the current code works. However, it does work so I guess that's the main thing that matters...
            CGRect linkRectangle = CGRectMake(expressionPositionInDeviceSpace.x,
                                              expressionPositionInDeviceSpace.y - expressionDimensions.depth,
                                              expressionDimensions.width, expressionDimensions.depth + expressionDimensions.height);
            if (_linkType == MHIntraLink || _linkType == MHHelpPageLink) {  // FIXME: help page links maybe should be treated separately than intralinks
//                CGContextTranslateCTM(pdfContext, 0.0, -200.0);
                CFStringRef cfstring = (__bridge CFStringRef)_linkDestinationString;
                CGPDFContextSetDestinationForRect(pdfContext, cfstring, linkRectangle);
//                CGContextTranslateCTM(pdfContext, 0.0, 200.0);
                [contextManager declareDestinationLink:_linkDestinationString];
            }
            else {
                NSURL *url = [NSURL URLWithString:_linkDestinationString];
                if (url) {
                    CFURLRef cfurl = (__bridge CFURLRef)url;
                    CGPDFContextSetURLForRect(pdfContext, cfurl, linkRectangle);
                }
            }
        }
            break;
        case MHCommandHelpLink:
    //        case MHHelpPageLink:  // FIXME: for now I'm treating help links the same as intralinks, maybe change this later
            // FIXME: add this
            break;
    }
}



- (NSString *)exportedLaTeXValue
{
    switch (_linkType) {
        case MHHyperlinkWithURLOnly:
            return [NSString stringWithFormat:@"\\url{%@}", _linkDestinationString];
        case MHHyperlinkWithURLAndContents:
            return [NSString stringWithFormat:@"\\href{%@}{%@}", _linkDestinationString, self.contents.exportedLaTeXValue];
        case MHIntraLink:
        case MHCommandHelpLink:
        case MHHelpPageLink:
            // FIXME: add this
            break;
    }
    
    return [super exportedLaTeXValue];  // if we reached here, give up and let the super method handle it
}


@end
