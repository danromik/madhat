//
//  MHCommand.m
//  MadHat
//
//  Created by Dan Romik on 10/31/19.
//  Copyright © 2019 Dan Romik. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>
#import "MHCommand.h"


@interface MHCommand ()
{
    MHHorizontalLayoutContainer *_argument;
}

@end


@implementation MHCommand


#pragma mark - Constructor methods

+ (instancetype)commandNamed:(NSString *)name withParameters:(NSDictionary *)parameters argument:(MHHorizontalLayoutContainer *)argument
{
    return [[self alloc] initWithName:name parameters:parameters argument:argument];
}


- (instancetype)initWithName:(NSString *)name parameters:(NSDictionary *)parameters argument:(MHHorizontalLayoutContainer *)argument
{
    if (self = [super init]) {
        _name = name;
        _parameters = parameters;
        self.argument = argument; // (argument ? argument : [MHExpression expression]);
    }
    return self;
}



#pragma mark - MHCommand protocol

+ (NSArray <NSString *> *)recognizedCommands
{
    return @[ ];
}






#pragma mark - Properties

- (MHHorizontalLayoutContainer *)argument
{
    return _argument;
}

- (void)setArgument:(MHHorizontalLayoutContainer *)argument
{
    _argument.parent = nil;
    _argument = argument;
    _argument.parent = self;
}

- (bool)splittable  // FIXME: seems unnecessary, this behavior is inherited from the superclass
{
    return NO;
}

- (MHExpression *)resolvedArgument
{
    return self.argument;   // default behavior is to return the argument as is with no further processing (subclasses will do more fancy things)
}

- (NSArray <MHExpression *> *)subexpressions
{
    return (_argument ? @[ _argument ] : @[ ]);
}

- (MHTypographyClass)typographyClass
{
    switch (self.presentationMode) {
        case MHExpressionPresentationModePublishing:
            return MHTypographyClassNone;
        case MHExpressionPresentationModeEditing:
            return MHTypographyClassText;
    }
}


#pragma mark - typeset and other methods


- (void)typesetWithContextManager:(MHTypesettingContextManager *)contextManager
{
    switch (self.presentationMode) {
        case MHExpressionPresentationModePublishing: {
            MHDimensions myDimensions;
            myDimensions.width = 0.0;
            myDimensions.height = 0.0;
            myDimensions.depth = 0.0;
            self.dimensions = myDimensions;
        }
            break;
        case MHExpressionPresentationModeEditing: {
            CGRect nodeFrame = _spriteKitNode.frame;
            MHDimensions myDimensions;
            myDimensions.width = nodeFrame.size.width;
            myDimensions.height = nodeFrame.size.height;
            self.dimensions = myDimensions;
        }
            break;
    }
}

- (SKNode *)spriteKitNode
{
    if (!_spriteKitNode) {
        switch (self.presentationMode) {
            case MHExpressionPresentationModePublishing: {
                SKNode *node = super.spriteKitNode;
                [node removeAllChildren];   // FIXME: it would be better not to have the children added in the first place
                _spriteKitNode.ownerExpression = self;
                return node;
            }
            case MHExpressionPresentationModeEditing: {
                SKLabelNode *textNode = [SKLabelNode
                                         labelNodeWithText:[NSString stringWithFormat:@"%@%@",
                                                            self.name,
                                                            (self.resolvedArgument ? [@":" stringByAppendingFormat:@"%@", self.resolvedArgument.stringValue] : @"")]];
                textNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeLeft;
                textNode.fontName = @"Courier";
                textNode.fontSize = 14.0;
                textNode.fontColor = ([self isMemberOfClass:[MHCommand class]] ? [NSColor redColor] : [NSColor blackColor]);
                textNode.position = CGPointMake(3.0, 3.0);
                CGRect textNodeFrame = textNode.frame;
                _spriteKitNode = [SKShapeNode shapeNodeWithRect:CGRectMake(0.0, 0.0, textNodeFrame.size.width+6.0, textNodeFrame.size.height+6.0)
                                                   cornerRadius:3.0];
                ((SKShapeNode *)_spriteKitNode).fillColor = [NSColor colorWithWhite:0.93 alpha:1.0];
                ((SKShapeNode *)_spriteKitNode).strokeColor = [NSColor orangeColor];
                [_spriteKitNode addChild:textNode];
                _spriteKitNode.ownerExpression = self;
            }
        }
    }
    return _spriteKitNode;
}




#pragma mark - Expression copying

- (instancetype)logicalCopy
{
    MHCommand *myCopy = [[self class] commandNamed:self.name withParameters:self.parameters argument:_argument];
    myCopy.codeRange = self.codeRange;
    return myCopy;
}





#pragma mark - Debugging

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@ name='%@' arg=%@", [self className], (self.name ? self.name : @""), self.argument.description];
}


@end
