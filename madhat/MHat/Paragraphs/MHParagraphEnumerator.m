//
//  MHParagraphEnumerator.m
//  MadHat
//
//  Created by Dan Romik on 8/18/20.
//  Copyright © 2020 Dan Romik. All rights reserved.
//

#import "MHParagraphEnumerator.h"

@interface MHParagraphEnumerator ()
{
    NSArray <MHParagraph *> *_paragraphs;

    // old:
//    NSEnumerator <MHParagraph *> *_topLevelParagraphEnumerator;
//    NSEnumerator <MHParagraph *> *_attachedParagraphEnumerator;
    
    // new:
    NSInteger _topLevelParagraphIndex;
    NSUInteger _paragraphsCount;
    NSArray <MHParagraph *> *_attachedParagraphs;
    NSEnumerator <MHParagraph *> *_attachedParagraphEnumerator;
}

@end

@implementation MHParagraphEnumerator

- (instancetype)initWithArrayOfParagraphsWithAttachedContent:(NSArray <MHParagraph *> *)paragraphs
{
    return [self initWithArrayOfParagraphsWithAttachedContent:paragraphs startingParagraphIndex:0];
}

- (instancetype)initWithArrayOfParagraphsWithAttachedContent:(NSArray <MHParagraph *> *)paragraphs
                                      startingParagraphIndex:(NSUInteger)index
{
    if (self = [super init]) {
        _paragraphs = paragraphs;

        // old:
//        _topLevelParagraphEnumerator = [_paragraphs objectEnumerator];
//        _attachedParagraphEnumerator = nil;
        
        // new:
        _topLevelParagraphIndex = 0;
        _attachedParagraphs = nil;
        _paragraphsCount = _paragraphs.count;
        _attachedParagraphEnumerator = nil;
        _topLevelParagraphIndex = index;
    }
    return self;
}

- (NSArray <MHParagraph *> *)allParagraphs
{
    NSMutableArray *allParagraphsMutableArray = [[NSMutableArray alloc] initWithCapacity:0];
    MHParagraphEnumerator *myEnumerator = [[MHParagraphEnumerator alloc] initWithArrayOfParagraphsWithAttachedContent:_paragraphs];
    MHParagraph *paragraph;
    while ((paragraph = [myEnumerator nextParagraph])) {
        [allParagraphsMutableArray addObject:paragraph];
    }
    return [NSArray arrayWithArray:allParagraphsMutableArray];
}

- (nullable MHParagraph *)nextParagraph
{
    MHParagraph *paragraph;
    
    // old:
//    if (_attachedParagraphEnumerator == nil) {
//        // When _attachedParagraphEnumerator is nil, we return the next paragraph associated with the top level enumerator ...
//        paragraph = [_topLevelParagraphEnumerator nextObject];
//
//        // ... and also set up the attached paragraph/second-level enumerator so that the next paragraphs to be returned are
//        // the ones returned by that enumerator
//        _attachedParagraphEnumerator = (NSEnumerator <MHParagraph *> *)[paragraph.attachedContent objectEnumerator];    // this may be nil in which case in the next iteration we'll move to the next top-level paragraph
//
//        return paragraph;
//    }
    
    // new:
    if (_attachedParagraphEnumerator == nil) {
        // When _attachedParagraphEnumerator is nil, we return the next top-level paragraph...

        if (_topLevelParagraphIndex >= _paragraphsCount)
            return nil; // we've gone through all the paragraphs, nothing more to return
        
        paragraph = _paragraphs[_topLevelParagraphIndex];
        _topLevelParagraphIndex++;
        
        // ... and also set up the attached paragraph/second-level enumerator so that the next paragraphs to be returned are
        // the ones returned by that enumerator
        _attachedParagraphEnumerator = (NSEnumerator <MHParagraph *> *)[paragraph.attachedContent objectEnumerator];    // this may be nil in which case in the next iteration we'll move to the next top-level paragraph

        return paragraph;
    }

    // If we reached here, we have an active second level enumerator, so get the next object it returns
    paragraph = [_attachedParagraphEnumerator nextObject];
    
    // Do we have something? If yes, return it
    if (paragraph)
        return paragraph;
    
    // Otherwise, return the next object from the top level enumerator, and prepare the attached paragraph enumerator for the next iteration
    
    // old:
//    paragraph = [_topLevelParagraphEnumerator nextObject];
    
    // new:
    if (_topLevelParagraphIndex >= _paragraphsCount)
        return nil; // we've gone through all the paragraphs, nothing more to return
    paragraph = _paragraphs[_topLevelParagraphIndex];
    _topLevelParagraphIndex++;

    _attachedParagraphEnumerator = (NSEnumerator <MHParagraph *> *)[paragraph.attachedContent objectEnumerator];
    
    return paragraph;
}


@end
