//
//  MHSourceCodeGutterView.h
//  MadHat
//
//  Created by Dan Romik on 1/6/20.
//  Copyright © 2020 Dan Romik. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@protocol MHSourceCodeGutterViewDelegate;
@interface MHSourceCodeGutterView : NSView

@property CGFloat scrollOffset;
@property NSArray <NSValue *> *paragraphRects;  // an array of NSRect-valued NSValue

@property NSColor *backgroundColor;
@property NSColor *markerColor;

@property (weak) NSObject <MHSourceCodeGutterViewDelegate> *delegate;

@end


@protocol MHSourceCodeGutterViewDelegate <NSObject>

- (void)paragraphClicked:(NSUInteger)paragraphIndex;

@end


NS_ASSUME_NONNULL_END
