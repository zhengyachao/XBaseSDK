//
//  XTool.h
//  XStaiticLibrary
//
//  Created by clio on 15/9/9.
//  Copyright (c) 2015年 X. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface XTool : NSObject
+ (NSString *)platfromStr;
+ (BOOL)isEmpty:(NSString *)string;
+ (void)showAlert:(NSString *)message;
+ (NSString *)md5:(NSString *)originalStr;
+ (NSUInteger)calculateCharacterLength:(NSString *)str;

@end
