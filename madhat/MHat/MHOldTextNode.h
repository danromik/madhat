////
////  MHOldTextNode.h
////  MadHat
////
////  Created by Dan Romik on 7/9/20.
////  Copyright © 2020 Dan Romik. All rights reserved.
////
//
//// How to use this class: create an instance using the +textNodeWithString: method.
//// Then configure it with a call to -configureWithFont:color:backgroundColor: once those parameters are known
//// As part of the configuration in that method, the dimension property is set and can then be inspected
//
//#import "MHOldTextualElementNode.h"
//
//NS_ASSUME_NONNULL_BEGIN
//
//@interface MHOldTextNode : MHOldTextualElementNode
//
//@property (nonatomic, readonly) NSString *text;
//
//+ (instancetype)textNodeWithString:(NSString *)string;
//
//- (NSArray <MHOldTextNode *> *)createTextNodesForIndividualGlyphs; // FIXME: improve
//
//
//@end
//
//NS_ASSUME_NONNULL_END
