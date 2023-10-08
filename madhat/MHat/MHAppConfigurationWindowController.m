//
//  MHAppConfigurationWindowController.m
//  MadHat
//
//  Created by Dan Romik on 10/12/21.
//  Copyright © 2021 Dan Romik. All rights reserved.
//

#import "MHAppConfigurationWindowController.h"
#import "MHDocumentController.h"

static NSArray <NSString *> *madHatFonts;  // it's an NSArray, so is only initialized at runtime, in the windowDidLoad method below
static NSArray <NSString *> *madHatFontDisplayStrings;  // it's an NSArray, so is only initialized at runtime, in the windowDidLoad method below
static NSArray <NSString *> *madHatConfigurationStepStrings;

static NSString * const kConfigurationIntroTextResourceFileName = @"confintrotext";
static NSString * const kConfigurationIntroTextResourceFileExtension = @"rtf";

static NSString * const kConfigurationTextResourceFileName = @"confstrings";
static NSString * const kConfigurationTextResourceFileExtension = @"rtf";

static NSMutableArray <NSAttributedString *> *madHatConfigurationStepDetailedInstructionStrings;

#define kMadHatConfigurationStepAnimationDuration   0.5

@interface MHAppConfigurationWindowController ()
{
    NSUInteger _configurationStep;
    NSRect _configurationStepLabelFrame;
    NSRect _configurationStepLabelAnimateFromRightFrame;
    NSRect _configurationStepLabelAnimateFromLeftFrame;
    BOOL _configurationStepAnimationInProgress;
    
    NSTimer *_periodicCheckingOfConfigurationStatusTimer;
}

@property NSUInteger configurationStep;

@property IBOutlet NSTextField *configurationStepLabel;
@property IBOutlet NSTextField *secondaryConfigurationStepLabel;
@property IBOutlet NSTextView *configurationIntroTextView;
@property IBOutlet NSTextView *configurationStepDetailedInstructionsTextView;
@property IBOutlet NSTableView *fontInstallationStatusTableView;

@property IBOutlet NSButton *beginConfigurationButton;
@property IBOutlet NSButton *previousConfigurationStepButton;
@property IBOutlet NSButton *nextConfigurationStepButton;
@property IBOutlet NSButton *finishButton;

@end

@implementation MHAppConfigurationWindowController

- (void)windowDidLoad {
    [super windowDidLoad];
    
    madHatFonts = @[
        @"Latin Modern Roman",
        @"Latin Modern Math",
        @"TeX Gyre Bonum",
        @"TeX Gyre Bonum Math",
        @"TeX Gyre Pagella",
        @"TeX Gyre Pagella Math",
        @"TeX Gyre Schola",
        @"TeX Gyre Schola Math",
        @"TeX Gyre Termes",
        @"TeX Gyre Termes Math",
    ];

    madHatFontDisplayStrings = @[
        @"Latin Modern",
        @"Latin Modern Math",
        @"TeX Gyre Bonum",
        @"TeX Gyre Bonum Math",
        @"TeX Gyre Pagella",
        @"TeX Gyre Pagella Math",
        @"TeX Gyre Schola",
        @"TeX Gyre Schola Math",
        @"TeX Gyre Termes",
        @"TeX Gyre Termes Math",
    ];
    
    madHatConfigurationStepStrings = @[
        @"Step 1: Download the Latin Modern font package",
        @"Step 2: Install the Latin Modern fonts",
        @"Step 3: Download the Latin Modern Math font",
        @"Step 4: Install the Latin Modern Math font",
        @"Step 5: Download the TeX Gyre font package",
        @"Step 6: Install the TeX Gyre font package",
        @"Step 7: Download the TeX Gyre Math font package",
        @"Step 8: Install the TeX Gyre Math font package",
        @"The configuration is complete. You are ready to start using MadHat!"
    ];
    
    NSString *configurationIntroTextFilePath = [[NSBundle mainBundle] pathForResource:kConfigurationIntroTextResourceFileName ofType:kConfigurationIntroTextResourceFileExtension];
    
    NSData *configurationIntroTextData = [NSData dataWithContentsOfFile:configurationIntroTextFilePath];
    NSAttributedString *configurationIntroTextAttribStr = [[NSAttributedString alloc]
                                                           initWithRTF:configurationIntroTextData
                                                           documentAttributes:nil];
    self.configurationIntroTextView.textStorage.attributedString = configurationIntroTextAttribStr;


    NSString *configurationInstructionsFilePath = [[NSBundle mainBundle] pathForResource:kConfigurationTextResourceFileName ofType:kConfigurationTextResourceFileExtension];
    
    NSData *configurationInstructionsData = [NSData dataWithContentsOfFile:configurationInstructionsFilePath];
    NSAttributedString *configurationInstructions = [[NSAttributedString alloc]
                                                     initWithRTF:configurationInstructionsData
                                                     documentAttributes:nil];
    NSString *configurationInstructionsPlainText = configurationInstructions.string;
    NSArray <NSString *> *components = [configurationInstructionsPlainText componentsSeparatedByString:@"\n"];
    madHatConfigurationStepDetailedInstructionStrings = [[NSMutableArray alloc] initWithCapacity:0];
    NSRange substringRange;
    substringRange.location = 0;
    substringRange.length = 0;
    for (NSString *component in components) {
        substringRange.length = component.length;
        NSAttributedString *componentAttributedString = [configurationInstructions attributedSubstringFromRange:substringRange];
        [madHatConfigurationStepDetailedInstructionStrings addObject:componentAttributedString];
        substringRange.location += substringRange.length + 1;
    }
    
    
    NSRect windowFrame = self.window.frame;
    _configurationStepLabelFrame = self.configurationStepLabel.frame;   // we will use this for animations
    _configurationStepLabelAnimateFromRightFrame = _configurationStepLabelFrame;
    _configurationStepLabelAnimateFromRightFrame.origin.x += windowFrame.size.width;
    _configurationStepLabelAnimateFromLeftFrame = _configurationStepLabelFrame;
    _configurationStepLabelAnimateFromLeftFrame.origin.x -= windowFrame.size.width;
    
    self.secondaryConfigurationStepLabel.frame = _configurationStepLabelAnimateFromRightFrame;

    [self.fontInstallationStatusTableView reloadData];
    
    self.previousConfigurationStepButton.alphaValue = 0.0;
    self.nextConfigurationStepButton.alphaValue = 0.0;
    self.configurationStepLabel.alphaValue = 0.0;
    self.secondaryConfigurationStepLabel.alphaValue = 0.0;
    self.configurationStepDetailedInstructionsTextView.alphaValue = 0.0;
    
    _periodicCheckingOfConfigurationStatusTimer = [NSTimer scheduledTimerWithTimeInterval:5.0 repeats:YES block:^(NSTimer * _Nonnull timer) {
        [self.fontInstallationStatusTableView reloadData];
        if ([MHDocumentController appConfigurationComplete]) {
            self.window.styleMask = self.window.styleMask |= NSWindowStyleMaskClosable;
        }
    }];
}

- (IBAction)beginConfiguration:(id)sender
{
    self.configurationStep = 0;
    self.configurationStepDetailedInstructionsTextView.string = @"";
    self.configurationStepDetailedInstructionsTextView.hidden = NO;
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        context.duration = 1.0; // kMadHatConfigurationStepAnimationDuration;
        self.beginConfigurationButton.animator.alphaValue = 0.0;
        self.previousConfigurationStepButton.animator.alphaValue = 1.0;
        self.nextConfigurationStepButton.animator.alphaValue = 1.0;
        self.configurationStepLabel.animator.alphaValue = 1.0;
        self.secondaryConfigurationStepLabel.animator.alphaValue = 1.0;
        self.configurationStepDetailedInstructionsTextView.animator.alphaValue = 1.0;
    } completionHandler:^{
        self.configurationStep = 0;
    }];
}

- (IBAction)finishConfiguration:(id)sender
{
    [_periodicCheckingOfConfigurationStatusTimer invalidate];
    [self.window close];
}

- (NSUInteger)configurationStep
{
    return _configurationStep;
}

- (void)setConfigurationStep:(NSUInteger)configurationStep
{
    [self.fontInstallationStatusTableView reloadData];
    
    _configurationStep = configurationStep;
    self.configurationStepLabel.frame = _configurationStepLabelFrame;
    self.secondaryConfigurationStepLabel.frame = _configurationStepLabelAnimateFromRightFrame;
    self.configurationStepLabel.stringValue = (configurationStep >= madHatConfigurationStepStrings.count
                                               ? @"" : madHatConfigurationStepStrings[configurationStep]);
    
    [self.configurationStepDetailedInstructionsTextView.textStorage setAttributedString:
     (configurationStep >= madHatConfigurationStepStrings.count
      ? [[NSAttributedString alloc] initWithString:@""]
      : madHatConfigurationStepDetailedInstructionStrings[configurationStep])];
    
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        context.duration = kMadHatConfigurationStepAnimationDuration;
        self.configurationStepDetailedInstructionsTextView.animator.alphaValue = 1.0;
    } completionHandler:^{
    }];
    
    self.previousConfigurationStepButton.enabled = (_configurationStep > 0);
    self.nextConfigurationStepButton.enabled = (_configurationStep+1 < madHatConfigurationStepStrings.count);
    
    if (configurationStep+1 == madHatConfigurationStepStrings.count) {
        [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
            context.duration = kMadHatConfigurationStepAnimationDuration;
            self.previousConfigurationStepButton.animator.alphaValue = 0.0;
            self.nextConfigurationStepButton.animator.alphaValue = 0.0;
        } completionHandler:^{
            self.finishButton.hidden = NO;
            self.configurationStepDetailedInstructionsTextView.hidden = YES;
        }];
    }
}

- (IBAction)decrementConfigurationStep:(id)sender
{
    if (_configurationStepAnimationInProgress || _configurationStep == 0)
        return;
    
    _configurationStepAnimationInProgress = YES;

    self.secondaryConfigurationStepLabel.frame = _configurationStepLabelAnimateFromLeftFrame;
    self.secondaryConfigurationStepLabel.stringValue = madHatConfigurationStepStrings[_configurationStep-1];
    [self performSelector:@selector(continueDecrementConfigurationStepAfterShortDelay)
               withObject:nil afterDelay:0.005];    // this is a workaround to an issue with the NSView animation engine. If we simply run the code directly, the change to the frame in the command "self.secondaryConfigurationStepLabel.frame = ..." above doesn't take effect
}

- (void)continueDecrementConfigurationStepAfterShortDelay
{
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        context.duration = kMadHatConfigurationStepAnimationDuration;
        self.configurationStepLabel.animator.frame = _configurationStepLabelAnimateFromRightFrame;
        self.secondaryConfigurationStepLabel.animator.frame = _configurationStepLabelFrame;
        self.configurationStepDetailedInstructionsTextView.animator.alphaValue = 0.0;
    } completionHandler:^{
        self.configurationStep = self->_configurationStep-1;
        self->_configurationStepAnimationInProgress = NO;
    }];
}

- (IBAction)incrementConfigurationStep:(id)sender
{
    if (_configurationStepAnimationInProgress || _configurationStep+1 >= madHatConfigurationStepStrings.count)
        return;

    _configurationStepAnimationInProgress = YES;
    
    self.secondaryConfigurationStepLabel.frame = _configurationStepLabelAnimateFromRightFrame;
    self.secondaryConfigurationStepLabel.stringValue = madHatConfigurationStepStrings[_configurationStep+1];
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        context.duration = kMadHatConfigurationStepAnimationDuration;
        self.configurationStepLabel.animator.frame = _configurationStepLabelAnimateFromLeftFrame;
        self.secondaryConfigurationStepLabel.animator.frame = _configurationStepLabelFrame;
        self.configurationStepDetailedInstructionsTextView.animator.alphaValue = 0.0;
    } completionHandler:^{
        self.configurationStep = self->_configurationStep+1;
        self->_configurationStepAnimationInProgress = NO;
    }];
}


#pragma mark - NSTableView data source and delegate methods

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    return madHatFonts.count;
}

- (BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(NSInteger)rowIndex
{
    return NO;
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    int columnIndex = [aTableColumn.identifier intValue];
    
    if (columnIndex == 0) {
        return madHatFontDisplayStrings[rowIndex];
    }
    
    NSString *fontName = madHatFonts[rowIndex];
    NSFont *font = [NSFont fontWithName:fontName size:12.0];
    
    return (font ? NSLocalizedString(@"Installed", @"") : NSLocalizedString(@"Not installed", @""));
}


@end
