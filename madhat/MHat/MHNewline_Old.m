////
////  MHNewline.m
////  MadHat
////
////  Created by Dan Romik on 12/11/19.
////  Copyright © 2019 Dan Romik. All rights reserved.
////
//
//#import "MHNewline.h"
//
//NSString * const kMHNewlineCommandName = @"newline";
//
//@implementation MHNewline
//
//
//#pragma mark - Constructor method
//
//+ (instancetype)newline
//{
//    return [self expression];
//}
//
//
//#pragma mark - MHCommand protocol
//
//+ (MHExpression *)commandNamed:(NSString *)name withParameters:(nullable NSDictionary *)parameters argument:(MHHorizontalLayoutContainer *)argument
//{
//    if ([name isEqualToString:kMHNewlineCommandName]) {
//        return [self newline];
//    }
//    
//    return nil;
//}
//
//+ (NSArray <NSString *> *)recognizedCommands
//{
//    return @[ kMHNewlineCommandName ];
//}
//
//
//
//#pragma mark - Properties
//
//- (MHTypographyClass)typographyClass
//{
//    return MHTypographyClassWhiteSpace;
//}
//
//
//#pragma mark - Expression copying
//
//- (instancetype)logicalCopy
//{
//    MHNewline *myCopy = [[self class] newline];
//    myCopy.codeRange = self.codeRange;
//    return myCopy;
//}
//
//
//
//
//@end
