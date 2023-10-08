//
//  MHLink.h
//  MadHat
//
//  Created by Dan Romik on 10/22/20.
//  Copyright © 2020 Dan Romik. All rights reserved.
//

#import "MHWrapper.h"
#import "MHCommand.h"

extern char kMHLinkLinkedExpressionAssociatedObjectKey;

NS_ASSUME_NONNULL_BEGIN

@interface MHLink : MHWrapper <MHCommand>

+ (instancetype)linkWithUrlString:(NSString *)urlString;
+ (instancetype)linkWithUrlString:(NSString *)urlString contents:(MHExpression *)contents;
+ (instancetype)intralinkWithPageName:(NSString *)pageName;
+ (instancetype)intralinkWithPageName:(NSString *)pageName contents:(MHExpression *)contents;
+ (instancetype)intralinkWithPageName:(NSString *)pageName slideNumber:(NSUInteger)slideNumber;
+ (instancetype)intralinkWithPageName:(NSString *)pageName slideNumber:(NSUInteger)slideNumber contents:(MHExpression *)contents;
+ (instancetype)commandHelpLinkWithCommandName:(NSString *)commandName;
+ (instancetype)commandHelpLinkWithCommandName:(NSString *)commandName contents:(MHExpression *)contents;
+ (instancetype)helpPageLinkWithHelpPageName:(NSString *)helpPageName;
+ (instancetype)helpPageLinkWithHelpPageName:(NSString *)helpPageName contents:(MHExpression *)contents;




- (void)addPDFLinkForExpression:(MHExpression *)expression
             withContextManager:(MHPDFRenderingContextManager  *)contextManager;   // used as a substitute for renderToPDFWithContextManager in MHTextParagraph's implementation of renderToPDFWithContextManager in the part that adds links to unsplittable expressions contained inside an MHLink. FIXME: A bit of a hack and duplicates some of the functionality and code of renderToPDFWithContextManager, but it works


@end

NS_ASSUME_NONNULL_END
