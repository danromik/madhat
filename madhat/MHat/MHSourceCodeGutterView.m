//
//  MHSourceCodeGutterView.m
//  MadHat
//
//  Created by Dan Romik on 1/6/20.
//  Copyright © 2020 Dan Romik. All rights reserved.
//

#import "MHSourceCodeGutterView.h"

@interface MHSourceCodeGutterView ()
{
    NSColor *_backgroundColor;
    NSColor *_markerColor;
    NSDictionary *_markerAttributes;
    NSArray <NSValue *> *_paragraphRects;
}
@end

@implementation MHSourceCodeGutterView

#pragma mark - Initialization

- (instancetype)initWithFrame:(NSRect)frameRect
{
    if (self = [super initWithFrame:frameRect]) {
        self.backgroundColor = [NSColor clearColor];
        self.markerColor = [NSColor blackColor];
    }
    return self;
}


- (NSArray <NSValue *> *)paragraphRects
{
    return _paragraphRects;
}

- (void)setParagraphRects:(NSArray <NSValue *> *)paragraphRects
{
    _paragraphRects = paragraphRects;
    
    [self setNeedsDisplay:true];
}

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];
    
//    NSLog(@"gutter view drawing content, %d paragraphs",(int)(self.paragraphRects.count));
    
    [self.backgroundColor setFill];
    NSRectFill(dirtyRect);
    
    static CGFloat fontSize = 8.0;
    if (!_markerAttributes) {
        NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        style.alignment = NSTextAlignmentCenter;

        _markerAttributes = @{ NSFontAttributeName : [NSFont fontWithName:@"Helvetica Neue" size:fontSize],
                        NSForegroundColorAttributeName : _markerColor,
                        NSParagraphStyleAttributeName : style
        };
    }
    
//    NSScrollView *scrollView = self.enclosingScrollView;
//    NSClipView *clipView = scrollView.contentView;
//    NSRect clipViewBounds = clipView.bounds;
    
    NSColor *fillColor = [NSColor colorWithRed:0.0 green:0.0 blue:0.3 alpha:0.1];
    NSColor *strokeColor = [NSColor colorWithWhite:0.5 alpha:0.5];


    // Drawing code here.
    NSRect myBounds = self.bounds;
    NSUInteger markerIndex = 1;
    
//    NSLog(@"paragraphrects=%@",_paragraphRects);
    
    // FIXME: seems wasteful to draw graphics for all the paragraphs - would be better to do it for just the "dirty" ones
    for (NSValue *rectValue in _paragraphRects) {
        NSRect rect = [rectValue rectValue];
        CGFloat yCoordinate = _scrollOffset + myBounds.size.height - rect.origin.y - 16.0;

        [fillColor setFill];
        [strokeColor setStroke];
//        NSRect markerRect1 = NSMakeRect(3.0, yCoordinate - rect.size.height + 18.0, 1.0, rect.size.height - 4.0);
//        NSRect markerRect2 = NSMakeRect(3.0, yCoordinate - rect.size.height + 18.0, 3.0, 1.0);
//        NSRect markerRect3 = NSMakeRect(3.0, yCoordinate + 14.0 - 1.0, 3.0, 1.0);
//
//        NSRect markerRect4 = NSMakeRect(myBounds.size.width - 4.0, yCoordinate - rect.size.height + 18.0, 1.0, rect.size.height - 4.0);
//        NSRect markerRect5 = NSMakeRect(myBounds.size.width - 6.0, yCoordinate - rect.size.height + 18.0, 3.0, 1.0);
//        NSRect markerRect6 = NSMakeRect(myBounds.size.width - 6.0, yCoordinate + 14.0 - 1.0, 3.0, 1.0);
//
//        NSRectFill(markerRect1);
//        NSRectFill(markerRect2);
//        NSRectFill(markerRect3);
//        NSRectFill(markerRect4);
//        NSRectFill(markerRect5);
//        NSRectFill(markerRect6);

        NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:NSMakeRect(4.0, yCoordinate - rect.size.height + 14.0, myBounds.size.width-8.0, rect.size.height) xRadius:6.0 yRadius:6.0];
        [path fill];
        [path stroke];

        NSString *markerLabel = [NSString stringWithFormat:@"%lu", markerIndex];
        [markerLabel drawInRect:NSMakeRect(4.0, yCoordinate, myBounds.size.width-8.0, fontSize+6.0) withAttributes:_markerAttributes];
//        [markerLabel drawAtPoint:NSMakePoint(4.0, yCoordinate) withAttributes:attributes];

        markerIndex++;
    }
}


- (NSColor *)backgroundColor
{
    return _backgroundColor;
}
- (void)setBackgroundColor:(NSColor *)backgroundColor
{
    _backgroundColor = backgroundColor;
    [self setNeedsDisplay:YES];
}

- (NSColor *)markerColor
{
    return _markerColor;
}
- (void)setMarkerColor:(NSColor *)markerColor
{
    _markerColor = markerColor;
    _markerAttributes = nil;
    [self setNeedsDisplay:YES];
}



#pragma mark - Handling mouse clicks

- (void)mouseDown:(NSEvent *)event
{
    NSPoint clickPointInWindowCoordinates = [event locationInWindow];
    NSPoint clickPointInViewCoordinates = [self convertPoint:clickPointInWindowCoordinates fromView:nil];
    
    NSRect myBounds = self.bounds;
    NSUInteger paragraphIndex = 0;
    for (NSValue *rectValue in _paragraphRects) {
        NSRect rect = [rectValue rectValue];
        CGFloat yCoordinate = _scrollOffset + myBounds.size.height - rect.origin.y - 16.0;
        CGFloat paragraphYMin = yCoordinate - rect.size.height + 14.0;
        CGFloat paragraphYMax = paragraphYMin + rect.size.height;
        
        if (paragraphYMin <= clickPointInViewCoordinates.y && clickPointInViewCoordinates.y <= paragraphYMax) {
            [self.delegate paragraphClicked:paragraphIndex];
            return;
        }
        paragraphIndex++;
    }
}

@end
