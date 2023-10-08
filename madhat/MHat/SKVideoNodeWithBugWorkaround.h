//
//  SKVideoNodeWithBugWorkaround.h
//  MadHat
//
//  Created by Dan Romik on 9/1/21.
//  Copyright © 2021 Dan Romik. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SKVideoNodeWithBugWorkaround : SKVideoNode

// an SKVideoNode sometimes starts playing spuriously when the video is paused and without any user action or programmatic intent, see this discussion
// https://stackoverflow.com/questions/31985073/why-does-skvideonode-automatically-starts-playing-video-on-ios9
//
// this class fixes the issue. It looks like the problem is SpriteKit calling the setPaused: method (of SKNode) with a value of false, and this triggers the video starting to play. The problem was fixed by overriding setPaused: and checking if the video is paused prior to the call to super setPaused:, then repausing the video if it was paused before.

@end

NS_ASSUME_NONNULL_END
