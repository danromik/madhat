//
//  MHVideo.m
//  MadHat
//
//  Created by Dan Romik on 8/27/21.
//  Copyright © 2021 Dan Romik. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "MHVideo.h"
#import "SKVideoNodeWithBugWorkaround.h"

NSString * const kMHVideoCommandName = @"video";

static const CGFloat kMHVideoMinVideoScale = 0.01;
static const CGFloat kMHVideoMaxVideoScale = 10.0;
static const CGFloat kMHVideoDefaultVideoWidth = 320.0;
static const CGFloat kMHVideoDefaultVideoHeight = 240.0;

static const CGFloat kMHVideoControlsFadeInOutAnimationDuration = 0.18;

typedef enum {
    MHVideoPlayingStatePlaying,
    MHVideoPlayingStatePausedInGenericPosition,
    MHVideoPlayingStatePausedAtEndOfVideo,
} MHVideoPlayingState;

NSString * _Nonnull const kMHInteractiveEventAnimationStartedNotification = @"MHInteractiveEventAnimationStartedNotification";
NSString * _Nonnull const kMHInteractiveEventAnimationEndedNotification = @"MHInteractiveEventAnimationEndedNotification";



@interface NSString (UserFriendlyTimeDurationString)
+ (NSString *)userFriendlyTimeDurationString:(NSUInteger)timeDurationInSeconds includeHours:(bool)includeHours;
@end


@interface MHVideo ()
{
    NSString *_videoIdentifier;
    SKVideoNodeWithBugWorkaround *_videoNode;
    AVPlayer *_videoPlayer;
    CGFloat _widthOverride;     // defaults to -1 which means a specific width isn't specified
    MHVideoPlayingState _videoCurrentlyPlaying;
    double _videoDurationInSeconds;
    
    SKShapeNode *_controlsNode;
    SKNode *_playControlNode;
    SKNode *_pauseControlNode;
    SKNode *_replayControlNode;
    SKLabelNode *_currentTimeLabelNode;
    SKLabelNode *_timeRemainingLabelNode;
    SKShapeNode *_positionSliderNode;
    SKShapeNode *_positionSliderKnobNode;
}

@property MHVideoPlayingState videoCurrentlyPlaying;

@property (readonly) AVPlayer *videoPlayer;
@property (readonly) double videoDurationInSeconds;
@property (readonly) SKLabelNode *currentTimeLabelNode;
@property (readonly) SKLabelNode *timeRemainingLabelNode;
@property (readonly) SKShapeNode *positionSliderNode;

@property CGFloat scale; // defaults to 1

@end

@implementation MHVideo

+ (instancetype)videoWithVideoIdentifier:(NSString *)identifier
{
    return [[self alloc] initWithVideoIdentifier:identifier];
}

- (instancetype)initWithVideoIdentifier:identifier
{
    if (self = [super init]) {
        _videoIdentifier = identifier;
        _videoCurrentlyPlaying = MHVideoPlayingStatePausedInGenericPosition;
        self.scale = 1;
    }
    return self;
}



#pragma mark - MHCommand protocol

+ (nonnull MHExpression *)commandNamed:(nonnull NSString *)name
                        withParameters:(nullable NSDictionary *)parameters
                              argument:(nonnull MHHorizontalLayoutContainer *)argument
{
    if ([name isEqualToString:kMHVideoCommandName]) {
        
        
        
        NSString *videoIdentifier;
        CGFloat argumentProvidedScale = -1.0; // an initial value less than 0 signifies that no scale was provided
        NSUInteger argNumberOfDelimitedBlocks = [argument numberOfDelimitedBlocks];
        if (argNumberOfDelimitedBlocks == 1) {
            videoIdentifier = [argument stringValue];
        }
        else {
            // at least two delimited blocks - in that case the first block will be read for the filename and the second block will provide the scale (defaults to 1 unless some other number is provided that is between the two values kMHVideoMinVideoScale and kMHVideoMaxVideoScale)
            videoIdentifier = [[argument expressionFromDelimitedBlockAtIndex:0] stringValue];
            argumentProvidedScale = [[argument expressionFromDelimitedBlockAtIndex:1] floatValue];
        }
        MHVideo *videoExpression = [self videoWithVideoIdentifier:videoIdentifier];
        if (argumentProvidedScale > kMHVideoMinVideoScale && argumentProvidedScale < kMHVideoMaxVideoScale) {
            videoExpression.scale = argumentProvidedScale;
        }

        return videoExpression;
    }
    return nil;
}

+ (nonnull NSArray<NSString *> *)recognizedCommands
{
    return @[ kMHVideoCommandName ];
}



#pragma mark - Typesetting

- (void)typesetWithContextManager:(MHTypesettingContextManager *)contextManager
{
    NSURL *videoURL = [contextManager videoResourceForIdentifier:_videoIdentifier];
    if (!videoURL) {
        NSLog(@"can't find video");
        // FIXME: have some fallback image/video to show to signify a missing video file
        return;
    }
    
    SKNode *mySpriteKitNode = self.spriteKitNode;
    [mySpriteKitNode removeAllChildren];
    
    // create the video player and video node
    _videoPlayer = [AVPlayer playerWithURL:videoURL];
    _videoPlayer.actionAtItemEnd = AVPlayerActionAtItemEndPause;
    _videoNode = [[SKVideoNodeWithBugWorkaround alloc] initWithAVPlayer:_videoPlayer];
    _videoNode.anchorPoint = CGPointZero;
    _videoNode.ownerExpressionAcceptsMouseClicks = YES;
    
    CGSize videoNaturalSize;
    AVPlayerItem *videoItem = _videoPlayer.currentItem;
    AVAsset *videoAsset = videoItem.asset;
    AVAssetTrack *track = [[videoAsset tracksWithMediaType:AVMediaTypeVideo] firstObject];
    if (track)
        videoNaturalSize = [track naturalSize];
    else {
        // set a default size if we were unable to determine the natural size
        videoNaturalSize = CGSizeMake(kMHVideoDefaultVideoWidth, kMHVideoDefaultVideoHeight);
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(videoFinishedPlaying:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:videoItem];

    _videoDurationInSeconds = CMTimeGetSeconds(videoAsset.duration);


    CGFloat myScale = self.scale;
    MHDimensions myDimensions;
    myDimensions.width = myScale * videoNaturalSize.width;
    myDimensions.height = myScale * videoNaturalSize.height;
    myDimensions.depth = 0.0;
    
    _videoNode.size = CGSizeMake(myDimensions.width, myDimensions.height);

    [mySpriteKitNode addChild:_videoNode];
    
    
    // set up the controls
    NSColor *controlsBackgroundColor = [NSColor colorWithDeviceWhite:0.2 alpha:1.0];
    
    CGSize controlsNodeSize = CGSizeMake(myDimensions.width-20.0, 24.0);
    _controlsNode = [SKShapeNode shapeNodeWithRect:CGRectMake(0.0, 0.0, controlsNodeSize.width, controlsNodeSize.height) cornerRadius:6];
    _controlsNode.strokeColor = [NSColor clearColor];
    _controlsNode.fillColor = controlsBackgroundColor;
    _controlsNode.position = CGPointMake((myDimensions.width - controlsNodeSize.width)/2.0, 10.0);
    _controlsNode.alpha = 0.0;                 // the controls are initially hidden, but become visible when the user hovers over the video
    [mySpriteKitNode addChild:_controlsNode];
    
    static const CGFloat playPauseControlNodeWidth = 24.0;
    _playControlNode = [MHVideo playControlNodeWithWidth:playPauseControlNodeWidth]; // [SKSpriteNode spriteNodeWithImageNamed:NSImageNameTouchBarPlayTemplate];
    _playControlNode.position = CGPointMake(myDimensions.width/2.0-playPauseControlNodeWidth,
                                            (myDimensions.height-playPauseControlNodeWidth) / 2.0);
    _playControlNode.ownerExpressionAcceptsMouseClicks = true;
    [_controlsNode addChild:_playControlNode];

    _pauseControlNode = [MHVideo pauseControlNodeWithWidth:playPauseControlNodeWidth]; //[SKSpriteNode spriteNodeWithImageNamed:NSImageNameTouchBarPauseTemplate];
    _pauseControlNode.position = CGPointMake(myDimensions.width/2.0-playPauseControlNodeWidth,
                                             (myDimensions.height-playPauseControlNodeWidth) / 2.0);
    _pauseControlNode.hidden = YES;
    _pauseControlNode.ownerExpressionAcceptsMouseClicks = true;
    [_controlsNode addChild:_pauseControlNode];
    
    _replayControlNode = [MHVideo replayControlNodeWithWidth:playPauseControlNodeWidth];
    _replayControlNode.position = CGPointMake(myDimensions.width/2.0-playPauseControlNodeWidth,
                                            (myDimensions.height-playPauseControlNodeWidth) / 2.0);
    _replayControlNode.ownerExpressionAcceptsMouseClicks = true;
    _replayControlNode.hidden = YES;
    [_controlsNode addChild:_replayControlNode];

    
    NSString *timeLabelFontName = @"Helvetica Neue";
    CGFloat timeLabelFontSize = 11.0;
    NSColor *timeLabelFontColor = [NSColor colorWithWhite:0.8 alpha:1.0];
    NSString *timeLabelString = [NSString userFriendlyTimeDurationString:0 includeHours:(_videoDurationInSeconds >= 3600)];
    _currentTimeLabelNode = [SKLabelNode labelNodeWithText:timeLabelString];
    _currentTimeLabelNode.fontColor = timeLabelFontColor;
    _currentTimeLabelNode.fontName = timeLabelFontName;
    _currentTimeLabelNode.fontSize = timeLabelFontSize;
    _currentTimeLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeLeft;
    CGSize currentTimeLabelSize = [_currentTimeLabelNode calculateAccumulatedFrame].size;
    _currentTimeLabelNode.position = CGPointMake(6.0, 7.5); //(controlsNodeSize.height - currentTimeLabelSize.height)/2.0);
    [_controlsNode addChild:_currentTimeLabelNode];

    _timeRemainingLabelNode = [SKLabelNode labelNodeWithText:timeLabelString];
    _timeRemainingLabelNode.fontColor = timeLabelFontColor;
    _timeRemainingLabelNode.fontName = timeLabelFontName;
    _timeRemainingLabelNode.fontSize = timeLabelFontSize;
    _timeRemainingLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeRight;
    CGSize timeRemainingLabelSize = [_timeRemainingLabelNode calculateAccumulatedFrame].size;
    _timeRemainingLabelNode.position = CGPointMake(controlsNodeSize.width - 6.0, 7.5); //(controlsNodeSize.height - currentTimeLabelSize.height)/2.0);
    [_controlsNode addChild:_timeRemainingLabelNode];

    _positionSliderNode = [SKShapeNode shapeNodeWithRect:CGRectMake(0.0, 0.0, controlsNodeSize.width - currentTimeLabelSize.width - timeRemainingLabelSize.width - 24.0, 4.0) cornerRadius:2.0];
    _positionSliderNode.strokeColor = [NSColor clearColor];
    _positionSliderNode.fillColor = [NSColor grayColor];
    _positionSliderNode.position = CGPointMake(currentTimeLabelSize.width + 12.0, (controlsNodeSize.height - 4.0)/2.0);
    _positionSliderNode.ownerExpressionAcceptsMouseClicks = true;
    [_controlsNode addChild:_positionSliderNode];
    
    _positionSliderKnobNode = [SKShapeNode shapeNodeWithRect:CGRectMake(0.0, 0.0, 2.0, 8.0) cornerRadius:1.0];
    _positionSliderKnobNode.strokeColor = [NSColor clearColor];
    _positionSliderKnobNode.fillColor = [NSColor colorWithRed:0.85 green:0.85 blue:0.85 alpha:1.0];
    _positionSliderKnobNode.ownerExpressionAcceptsMouseClicks = true;
    [_controlsNode addChild:_positionSliderKnobNode];

    [self updateControlsWithWeakSelf:self];
    
    // configure the video player (needs to be done after creating the controls)
    CMTime updateInterval = CMTimeMakeWithSeconds(0.2, NSEC_PER_SEC);
    dispatch_queue_t mainQueue = dispatch_get_main_queue();
    __weak typeof(self) weakSelf = self;
    [_videoPlayer addPeriodicTimeObserverForInterval:updateInterval
                                               queue:mainQueue
                                          usingBlock:^(CMTime time) {
        [weakSelf updateControlsWithWeakSelf:weakSelf];
    }];
    self.dimensions = myDimensions;
}

- (void)setHighlighted:(bool)highlighted
{
//    [super setHighlighted:highlighted];

    SKAction *action = [SKAction fadeAlphaTo:(highlighted ? 1.0 : 0.0) duration:kMHVideoControlsFadeInOutAnimationDuration];
    [_controlsNode runAction:action];
}

- (void)videoFinishedPlaying:(NSNotification *)notification
{
    [self updateControlsWithWeakSelf:self];
    self.videoCurrentlyPlaying = MHVideoPlayingStatePausedAtEndOfVideo;
}

- (void)updateControlsWithWeakSelf:(MHVideo *)weakSelf;
{
    double secondsElapsed = CMTimeGetSeconds(weakSelf.videoPlayer.currentTime);
    double videoDurationInSeconds = weakSelf.videoDurationInSeconds;
    weakSelf.currentTimeLabelNode.text = [NSString userFriendlyTimeDurationString:secondsElapsed
                                                                     includeHours:(videoDurationInSeconds >= 3600)];
    weakSelf.timeRemainingLabelNode.text = [NSString userFriendlyTimeDurationString:videoDurationInSeconds - secondsElapsed
                                                                       includeHours:(videoDurationInSeconds >= 3600)];

    [weakSelf.positionSliderNode removeAllChildren];
    CGFloat sliderWidth = secondsElapsed / weakSelf.videoDurationInSeconds * [weakSelf.positionSliderNode calculateAccumulatedFrame].size.width;
    SKShapeNode *positionSliderNodeFullPart = [SKShapeNode shapeNodeWithRect:CGRectMake(0.0, 0.0, sliderWidth, 4.0) cornerRadius:2.0];
    positionSliderNodeFullPart.fillColor = [NSColor lightGrayColor];
    positionSliderNodeFullPart.strokeColor = [NSColor clearColor];
    [weakSelf.positionSliderNode addChild:positionSliderNodeFullPart];
    
    CGPoint positionSliderNodePosition = weakSelf.positionSliderNode.position;
    _positionSliderKnobNode.position = CGPointMake(positionSliderNodePosition.x + sliderWidth-1.0, 8.0);
}





- (NSString *)mouseHoveringAuxiliaryTextWithHoveringNode:(SKNode *)node
{
    if ([node isEqual:_positionSliderNode] || [node.parent isEqual:_positionSliderNode] || [node isEqual:_positionSliderKnobNode])
        return NSLocalizedString(@"Seek video", @"");
    switch (_videoCurrentlyPlaying) {
        case MHVideoPlayingStatePlaying:
            return NSLocalizedString(@"Pause video", @"");
        case MHVideoPlayingStatePausedInGenericPosition:
            return NSLocalizedString(@"Play video", @"");
        case MHVideoPlayingStatePausedAtEndOfVideo:
            return NSLocalizedString(@"Replay video", @"");
    }
}

- (void)mouseClickWithEvent:(NSEvent *)event subnode:(SKNode *)node
{
    if ([node isEqual:_positionSliderNode]) {
        CGPoint pointInSlider = [event locationInNode:_positionSliderNode];
        CGSize sliderSize = [_positionSliderNode calculateAccumulatedFrame].size;
        double timeToSeek = _videoDurationInSeconds * pointInSlider.x / sliderSize.width;
        [_videoPlayer seekToTime:CMTimeMakeWithSeconds(timeToSeek, NSEC_PER_SEC)
                 toleranceBefore:CMTimeMakeWithSeconds(0.2, NSEC_PER_SEC)
                  toleranceAfter:CMTimeMakeWithSeconds(0.1, NSEC_PER_SEC)];
        
        if (self.videoCurrentlyPlaying == MHVideoPlayingStatePausedAtEndOfVideo) {
            self.videoCurrentlyPlaying = MHVideoPlayingStatePausedInGenericPosition;
        }
        return;
    }
    
    MHVideoPlayingState currentlyPlaying = self.videoCurrentlyPlaying;
    if (currentlyPlaying == MHVideoPlayingStatePlaying)
        [self stopPlaying];
    else
        [self startPlaying];
}

- (void)startPlaying
{
    switch (self.videoCurrentlyPlaying) {
        case MHVideoPlayingStatePausedAtEndOfVideo:
            [_videoPlayer seekToTime:CMTimeMakeWithSeconds(0.0, NSEC_PER_SEC)
                     toleranceBefore:CMTimeMakeWithSeconds(0.2, NSEC_PER_SEC)
                      toleranceAfter:CMTimeMakeWithSeconds(0.1, NSEC_PER_SEC)];
            // no break statement - falling through to the generic position case
        case MHVideoPlayingStatePausedInGenericPosition:
            self.videoCurrentlyPlaying = MHVideoPlayingStatePlaying;
            break;
        case MHVideoPlayingStatePlaying:
            // already playing - no need to do anything
            break;
    }
}

- (void)stopPlaying
{
    if (self.videoCurrentlyPlaying == MHVideoPlayingStatePlaying) {
        self.videoCurrentlyPlaying = MHVideoPlayingStatePausedInGenericPosition;
    }
}

// MHAnimatableExpression protocol method
- (void)stopAnimating {
    [self stopPlaying];
}



- (MHVideoPlayingState)videoCurrentlyPlaying
{
    return _videoCurrentlyPlaying;
}

- (void)setVideoCurrentlyPlaying:(MHVideoPlayingState)newState
{
    _videoCurrentlyPlaying = newState;
    
    switch (_videoCurrentlyPlaying) {
        case MHVideoPlayingStatePlaying:
            [_videoNode play];
            _pauseControlNode.hidden = NO;
            _playControlNode.hidden = YES;
            _replayControlNode.hidden = YES;
            [[NSNotificationCenter defaultCenter] postNotificationName:kMHInteractiveEventAnimationStartedNotification
                                                                object:self];
            break;
        case MHVideoPlayingStatePausedInGenericPosition:
            [_videoNode pause];
            _pauseControlNode.hidden = YES;
            _playControlNode.hidden = NO;
            _replayControlNode.hidden = YES;
            [[NSNotificationCenter defaultCenter] postNotificationName:kMHInteractiveEventAnimationEndedNotification
                                                                object:self];
            break;
        case MHVideoPlayingStatePausedAtEndOfVideo:
            [_videoNode pause];
            _pauseControlNode.hidden = YES;
            _playControlNode.hidden = YES;
            _replayControlNode.hidden = NO;
            [[NSNotificationCenter defaultCenter] postNotificationName:kMHInteractiveEventAnimationEndedNotification
                                                                object:self];
            break;
    }
}

#define M_SQRT3   1.7320508075688772935

+ (SKNode *)playControlNodeWithWidth:(CGFloat)width
{
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathMoveToPoint(path, nil, width, width/2.0);
    CGPathAddLineToPoint(path, nil, width/4.0, width/2.0 + width/2.0 * M_SQRT3/2.0);
    CGPathAddLineToPoint(path, nil, width/4.0, width/2.0 - width/2.0 * M_SQRT3/2.0);
    CGPathCloseSubpath(path);
    SKShapeNode *node = [SKShapeNode shapeNodeWithPath:path];
    CGPathRelease(path);
    node.fillColor = [NSColor colorWithWhite:0.8 alpha:1.0];
    node.strokeColor = [NSColor clearColor];
    return node;
}

+ (SKNode *)pauseControlNodeWithWidth:(CGFloat)width
{
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, nil, CGRectMake(0.0, 0.0, 18.0/45.0 * width, width));
    CGPathCloseSubpath(path);
    CGPathAddRect(path, nil, CGRectMake(27.0/45.0 * width, 0.0, 18.0/45.0 * width, width));
    CGPathCloseSubpath(path);
    SKShapeNode *node = [SKShapeNode shapeNodeWithPath:path];
    CGPathRelease(path);
    node.fillColor = [NSColor colorWithWhite:0.8 alpha:1.0];
    node.strokeColor = [NSColor clearColor];
    return node;
}

+ (SKNode *)replayControlNodeWithWidth:(CGFloat)width
{
    // FIXME: the icon for replaying a video needs improving
    
//    static CGFloat angle = 3*M_PI/4+0.1;
    CGFloat startAngle = M_PI;
    CGFloat endAngle = startAngle + 2*M_PI - 0.7;
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddArc(path, nil, width/2.0, width/2.0, width/2.0-2.5, startAngle, endAngle, false);
    CGPathAddArc(path, nil, width/2.0, width/2.0, width/2.0+2.5, endAngle, startAngle, true);
    CGPathCloseSubpath(path);
    
    CGPoint arrowPoint1;
    CGPoint arrowPoint2;
    CGPoint arrowPoint3;
    arrowPoint1.x = width/2.0 + width/2.0 * cos(endAngle+0.4);
    arrowPoint1.y = width/2.0 + width/2.0 * sin(endAngle+0.4);
    arrowPoint2.x = width/2.0 + (width/2.0 + 5.0) * cos(endAngle);
    arrowPoint2.y = width/2.0 + (width/2.0 + 5.0) * sin(endAngle);
    arrowPoint3.x = width/2.0 + (width/2.0 - 5.0) * cos(endAngle);
    arrowPoint3.y = width/2.0 + (width/2.0 - 5.0) * sin(endAngle);
    CGPathMoveToPoint(path, nil, arrowPoint1.x, arrowPoint1.y);
    CGPathAddLineToPoint(path, nil, arrowPoint2.x, arrowPoint2.y);
    CGPathAddLineToPoint(path, nil, arrowPoint3.x, arrowPoint3.y);
    CGPathCloseSubpath(path);
    
    SKShapeNode *node = [SKShapeNode shapeNodeWithPath:path];
    CGPathRelease(path);
    node.strokeColor = [NSColor clearColor]; //[NSColor colorWithWhite:0.8 alpha:1.0];
    node.fillColor = [NSColor colorWithWhite:0.8 alpha:1.0];
    return node;
}




#pragma mark - Expression copying

- (instancetype)logicalCopy
{
    MHVideo *myCopy = [[self class] videoWithVideoIdentifier:[_videoIdentifier copy]];
    myCopy.codeRange = self.codeRange;
    return myCopy;
}

@end



@implementation NSString (UserFriendlyTimeDurationString)

+ (NSString *)userFriendlyTimeDurationString:(NSUInteger)timeDurationInSeconds includeHours:(bool)includeHours
{
    NSUInteger hours = timeDurationInSeconds / 3600;
    NSUInteger minutes = (timeDurationInSeconds-3600*hours) / 60;
    NSUInteger seconds = timeDurationInSeconds-3600*hours - 60 * minutes;
    NSString *durationString;
    if (hours == 0 && !includeHours)
        durationString = [NSString stringWithFormat:@"%0.2lu:%0.2lu", minutes, seconds];
    else
        durationString = [NSString stringWithFormat:@"%lu:%0.2lu:%0.2lu", hours, minutes, seconds];
    return durationString;
}

@end
