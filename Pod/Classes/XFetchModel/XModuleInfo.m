//
//  XModuleInfo.m
//  OEProductSDK
//
//  Created by chiyou on 15/9/25.
//  Copyright © 2015年 MK. All rights reserved.
//

#import "XModuleInfo.h"
static XModuleInfo *moduleInfo = nil;

@implementation XModuleInfo

+ (instancetype)shareInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        moduleInfo = [[XModuleInfo alloc] init];
    });
    
    return moduleInfo;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getModuleInfo:) name:@"XProductNotification" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getModuleInfo:) name:@"XPayNotification" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getModuleInfo:) name:@"XTradeNotification" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getModuleInfo:) name:@"XAllNotificaion" object:nil];
    }
    return self;
}
- (void)getModuleInfo:(NSNotification *)noti {
    
    
    NSDictionary *object = noti.object;
    
    NSString *appId = [object objectForKey:@"_appid"];
    BOOL isDebug = [[object objectForKey:@"isDebug"] boolValue];
    NSInteger type = [[object objectForKey:@"ModuleType"] integerValue];
    
    switch (type) {
        case 0:
            self.productAppId = appId;
            self.isDebug = isDebug;
            break;
        case 1:
            self.tradeAppId = appId;
            self.isDebug = isDebug;
            break;
        case 2:
            self.payAppId = appId;
            self.isDebug = isDebug;
            break;
        default:
            self.productAppId = appId;
            self.tradeAppId = appId;
            self.payAppId = appId;
            self.isDebug = isDebug;
            break;
    }
}

- (NSDictionary *)requestHeaderDic{
    return @{
             @"Content-Type":@"application/x-www-form-urlencoded; charset=UTF-8",
             @"_appid":@"49",
             };
}

@end
