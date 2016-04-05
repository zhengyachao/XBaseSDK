

//
//  XRegisterModel.m
//  OEProductSDK
//
//  Created by chiyou on 15/9/25.
//  Copyright © 2015年 MK. All rights reserved.
//

#import "XRegisterApp.h"
#import "XModuleInfo.h"
static XRegisterApp *registerApp;
@implementation XRegisterApp

+ (instancetype)shareInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        registerApp = [[XRegisterApp alloc] init];
    });
    
    return registerApp;
}


-  (void)registerWithAppId:(NSString *)appId isDeug:(BOOL)isDebug withModuleType:(XModuleType)moduleType
{
    
    [XModuleInfo shareInstance];    
    if (moduleType == XModuleProduct) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"XProductNotification" object:@{@"_appid":appId?:@"",@"isDebug":@(isDebug),@"ModuleType":@(XModuleProduct)}];
    }
    
    if (moduleType == XModuleTrade) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"XTradeNotification" object:@{@"_appid":appId?:@"",@"isDebug":@(isDebug),@"ModuleType":@(XModuleTrade)}];
    }
    if (moduleType == XModulePay) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"XPayNotification" object:@{@"_appid":appId?:@"",@"isDebug":@(isDebug),@"ModuleType":@(XModulePay)}];
    }
    
    if (moduleType == XModuleAll) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"XAllNotificaion" object:@{@"_appid":appId?:@"",@"isDebug":@(isDebug),@"ModuleType":@(XModuleAll)}];
    }
    
}

- (void)setEnvironmentIsRelease:(BOOL)isRelease
{
    if (isRelease) {
        [XModuleInfo shareInstance].baseURL = @"http://10.8.73.3:8080/product";
    } else {
        [XModuleInfo shareInstance].baseURL = @"http://10.8.73.3:8080/product";
    }
}

@end
