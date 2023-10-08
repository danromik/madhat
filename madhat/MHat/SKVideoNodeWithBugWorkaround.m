//
//  SKVideoNodeWithBugWorkaround.m
//  MadHat
//
//  Created by Dan Romik on 9/1/21.
//  Copyright © 2021 Dan Romik. All rights reserved.
//

#import <AVKit/AVKit.h>
#import "SKVideoNodeWithBugWorkaround.h"

@interface SKVideoNodeWithBugWorkaround ()
{
    AVPlayer *_avPlayer;
}

@end

@implementation SKVideoNodeWithBugWorkaround

- (instancetype)initWithAVPlayer:(AVPlayer *)player
{
    if (self = [super initWithAVPlayer:player]) {
        _avPlayer = player;     // save our own copy of the player for private use
    }
    return self;
}

- (void)setPaused:(BOOL)paused
{
    BOOL needToRepauseAfterCallingSuper = (_avPlayer.timeControlStatus == AVPlayerTimeControlStatusPaused) && (!paused);
    [super setPaused:paused];
    if (needToRepauseAfterCallingSuper) {
        [super pause];
    }
}


@end
