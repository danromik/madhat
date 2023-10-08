////
////  MHFancySpace.m
////  MadHat
////
////  Created by Dan Romik on 1/24/20.
////  Copyright © 2020 Dan Romik. All rights reserved.
////
//
//#import "MHFancySpace.h"
//
//NSString * const kMHFancySpaceCommandName = @"space";
//
//@interface MHFancySpace ()
//{
//    CGFloat _width;
//}
//@end
//
//@implementation MHFancySpace
//
//
//#pragma mark - Constructors
//
//+ (instancetype)fancySpaceWithWidth:(CGFloat)width
//{
//    return [[self alloc] initWithWidth:width];
//}
//
//- (instancetype)initWithWidth:(CGFloat)width
//{
//    if (self = [super initWithType:MHSpaceTypeOther]) {
//        _width = width;
//    }
//    return self;
//}
//
//
//#pragma mark - Expression copying
//
//- (instancetype)logicalCopy
//{
//    MHFancySpace *myCopy = [[self class] fancySpaceWithWidth:_width];
//    myCopy.codeRange = self.codeRange;
//    return myCopy;
//}
//
//
//#pragma mark - MHCommand protocol
//
//+ (MHExpression *)commandNamed:(NSString *)name withParameters:(NSDictionary *)parameters argument:(MHHorizontalLayoutContainer *)argument
//{
//    if ([name isEqualToString:kMHFancySpaceCommandName]) {
//        NSString *argumentString = argument.stringValue;
//        if (!argumentString || argumentString.length == 0)
//            return [MHSpace space];
//        CGFloat width = [argumentString floatValue];
//        if (width < 0.0)
//            width = 0.0;
//        return [[self class] fancySpaceWithWidth:width];
//    }
//    
//    return nil;
//}
//
//+ (NSArray <NSString *> *)recognizedCommands
//{
//    return @[ kMHFancySpaceCommandName ];
//}
//
//
//
//#pragma mark - Properties
//
//- (CGFloat)widthWithContextManager:(MHTypesettingContextManager *)contextManager
//{
//    return _width;
//}
//
//@end
