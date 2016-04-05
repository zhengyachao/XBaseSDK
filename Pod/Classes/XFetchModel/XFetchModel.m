//
//  XFetchModel.m
//  XStaiticLibrary
//
//  Created by clio on 15/9/9.
//  Copyright (c) 2015年 X. All rights reserved.
//
#import "XTool.h"
#import "XFetchModel.h"
#import "XModuleInfo.h"
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "AFNetworking.h"
#import "XFetchPropertiesModel.h"
#import "UIImageView+WebCache.h"
#define BizErrorDomain @"BizErrorDomain"

#define QSREQUEST_API_HOST @"10.8.1.60"
#define QSREQUEST_API_PORT @"8888"
#define QSREQUEST_API_VER  @""

#define ISLOWIOS7 [[UIDevice currentDevice].systemVersion floatValue] < 7.0 ? 1 : 0

static NSDateFormatter *errorDateFormatter;
static const char *XFecthModelKeyMapperKey;
static const char *XFetchModelPropertiesKey;

@interface XFetchModel (){
    AFHTTPRequestOperation *requestOperation;
    NSURLSessionDataTask *dataTask;
}
@property(nonatomic, strong) AFHTTPRequestOperationManager *operationManager;
@property (nonatomic, strong) AFHTTPSessionManager *sessionManager;

@property (nonatomic, strong) NSString *path;

- (void)setupCachedKeyMapper;
- (void)setupCachedProperties;
- (instancetype)initWithJSONDict:(NSDictionary *)dict;
@end

#pragma mark - NSArray+XFetchModel
@interface NSArray (XFetchModel)
- (NSArray *)modelArrayWithClass:(Class)modelClass;
@end

@implementation NSArray (XFetchModel)
- (NSArray *)modelArrayWithClass:(Class)modelClass{
    NSMutableArray *modelArray = [NSMutableArray array];
    for (id object in self) {
        if ([object isKindOfClass:[NSArray class]]) {
            [modelArray addObject:[object modelArrayWithClass:modelClass]];
        } else if ([object isKindOfClass:[NSDictionary class]]){
            [modelArray addObject:[[modelClass alloc] initWithJSONDict:object]];
        } else {
            [modelArray addObject:object];
        }
    }
    
    return modelArray;
}
@end

#pragma mark - NSDictionary+XFetchModel
@interface NSDictionary (XFetchModel)
- (NSDictionary *)modelDictionaryWithClass:(Class)modelClass;
@end

@implementation NSDictionary (XFetchModel)
- (NSDictionary *)modelDictionaryWithClass:(Class)modelClass{
    NSMutableDictionary *modelDictionary = [NSMutableDictionary dictionary];
    for (NSString *key in self) {
        id object = [self objectForKey:key];
        if ([object isKindOfClass:[NSDictionary class]]) {
            [modelDictionary setObject:[[modelClass alloc] initWithJSONDict:object] forKey:key];
        }else if ([object isKindOfClass:[NSArray class]]){
            [modelDictionary setObject:[object modelArrayWithClass:modelClass] forKey:key];
        }else{
            [modelDictionary setObject:object forKey:key];
        }
    }
    return modelDictionary;
}
@end

extern NSString *networkStatus;

@implementation XFetchModel
#pragma mark -life cycle
- (void)dealloc{
    if (requestOperation) {
        [requestOperation cancel];
    }
}

- (instancetype)init{
    self = [super init];
    if (self) {
        [self setupCachedKeyMapper];
        [self setupCachedProperties];
    }
    return self;
}




#pragma mark -customUserAgent
+ (NSString *)customUserAgent {
    
    
    return [NSString stringWithFormat:@"( QF; Client/%@ %@ )"
            ,[XTool platfromStr], [UIDevice currentDevice].systemVersion];
}

#pragma mark -initWithJSONDict
- (instancetype)initWithJSONDict:(NSDictionary *)dict{
    self = [self init];
    if (self) {
        [self injectJSONData:dict];
    }
    return self;
}

- (AFHTTPRequestOperationManager *)operationManager {
    if (!_operationManager) {
        NSURL *baseURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@:%@/%@", QSREQUEST_API_HOST, QSREQUEST_API_PORT,QSREQUEST_API_VER]];
        if (![XTool isEmpty:[XModuleInfo shareInstance].baseURL]) {
            baseURL = [NSURL URLWithString:[XModuleInfo shareInstance].baseURL];
        }
        _operationManager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:baseURL];
        _operationManager.requestSerializer.timeoutInterval = 20;
        AFHTTPRequestSerializer *reqSerializer = _operationManager.requestSerializer;
        if (![XTool isEmpty:[XModuleInfo shareInstance].tradeAppId]) {
            for(NSString *key in [XModuleInfo shareInstance].requestHeaderDic.allKeys){
                [reqSerializer setValue:[[XModuleInfo shareInstance].requestHeaderDic objectForKey:key] forHTTPHeaderField:key];
            }
        }
        [reqSerializer setValue:[[self class] customUserAgent] forHTTPHeaderField:@"User-Agent"];
    }
    AFHTTPRequestSerializer *reqSerializer = _operationManager.requestSerializer;
    NSString *cookie = [[NSUserDefaults standardUserDefaults] objectForKey:@"Cookie"];
    if (![XTool isEmpty:cookie]) {
        [reqSerializer setValue:[[NSUserDefaults standardUserDefaults] objectForKey:@"Cookie"] forHTTPHeaderField:@"Cookie"];
    }
    return _operationManager;
}
- (AFHTTPSessionManager *)sessionManager
{
    if (!_sessionManager) {
         NSURL *baseURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@:%@/%@", QSREQUEST_API_HOST, QSREQUEST_API_PORT,QSREQUEST_API_VER]];
        if (![XTool isEmpty:[XModuleInfo shareInstance].baseURL]) {
            baseURL = [NSURL URLWithString:[XModuleInfo shareInstance].baseURL];
        }
        _sessionManager = [[AFHTTPSessionManager alloc] initWithBaseURL:baseURL];
        _sessionManager.requestSerializer.timeoutInterval = 20;
        AFHTTPRequestSerializer *reqSerializer = _sessionManager.requestSerializer;
       
        if (![XTool isEmpty:[XModuleInfo shareInstance].tradeAppId]) {
            for(NSString *key in [XModuleInfo shareInstance].requestHeaderDic.allKeys){
                [reqSerializer setValue:[[XModuleInfo shareInstance].requestHeaderDic objectForKey:key] forHTTPHeaderField:key];
            }
        }
        [reqSerializer setValue:[[self class] customUserAgent] forHTTPHeaderField:@"User-Agent"];
    }
    AFHTTPRequestSerializer *reqSerializer = _sessionManager.requestSerializer;
    NSString *cookie = [[NSUserDefaults standardUserDefaults] objectForKey:@"Cookie"];
    if (![XTool isEmpty:cookie]) {
        [reqSerializer setValue:[[NSUserDefaults standardUserDefaults] objectForKey:@"Cookie"] forHTTPHeaderField:@"Cookie"];
    }
    return _sessionManager;
}


#pragma mark -isSessionValid
- (BOOL)isSessionValid{
    NSURL *url = self.operationManager.baseURL;
    NSArray *cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:url];
    for (NSHTTPCookie *cookie in cookies) {
        if ([cookie.name isEqualToString:@"kdAuthToken"] && (cookie.expiresDate.timeIntervalSinceNow < 0)) {
            return NO;
        }
    
    }
    return YES;
}

#pragma mark -clearCookiesForBaseURL
- (void)clearCookiesForBaseURL {
    NSURL *url = self.operationManager.baseURL;
    NSArray *cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:url];
    for (NSHTTPCookie *cookie in cookies) {
        [[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:cookie];
    }
}
#pragma mark --
- (void)setImageWithURL:(NSURL *)imgUrl placeHolderImage:(UIImage *)image imageDownLoadCompletion:(ImageDownLoadCompletion)completion withImageView:(UIImageView *)imageView {
    
    [imageView sd_setImageWithURL:imgUrl placeholderImage:image completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
        if (completion) {
            completion(image,error,imageURL);
        }
    }];
}

#pragma mark -- 请求开始
- (void)fetchModelBeginRequest:(NSString *)path {
    
}
#pragma mark -- 请求成功
- (void)fetchModelSuccessRequest:(NSString *)path responseObject:(id)responseObject {
    
}
#pragma mark -- 请求失败
- (void)fetchModelFailureRequest:(NSString *)path error:(NSError *)error {
    
}
#pragma mark -fetchWithPath ....
- (void)fetchWithPath:(NSString *)path completionHandler:(FetchCompletionHandler)handler {
    self.path = path;
    __weak typeof(self) wSelf = self;
    if (requestOperation)
    {
        [requestOperation cancel];
    }
    if (dataTask) {
        [dataTask cancel];
    }
    
    NSString *scheme = nil;
    if (![XTool isEmpty:path]) {
        if (path.length > 4) {
            scheme = [path substringWithRange:NSMakeRange(0, 4)];
            if ([scheme isEqualToString:@"http"]) {
                [XModuleInfo shareInstance].baseURL = @"";
                
            } else {
                // api.kkkdgamma.com:8888 
                [XModuleInfo shareInstance].baseURL = @"http://api.kkkdgamma.com:8888";

            }
            
        }
    }
#pragma mark -- 请求开始
    [self fetchModelBeginRequest:path];
    
    NSMutableDictionary *requestDic = [NSMutableDictionary dictionaryWithDictionary:[_requestParams mutableCopy]];
    //上传图片的处理
//    NSData *imageData = [requestDic objectForKey:@"imageFile"];
    NSArray *imageArr = [requestDic objectForKey:@"imageFile"];
    [requestDic removeObjectForKey:@"imageFile"];
    NSArray * filesArray = [requestDic objectForKey:@"files"];
    [requestDic removeObjectForKey:@"files"];
    
    BOOL isGet = [[requestDic objectForKey:@"isGetKey"] boolValue];
    [requestDic removeObjectForKey:@"isGetKey"];
    
        if (ISLOWIOS7) {
        if (isGet) {
            requestOperation = [self.operationManager GET:path parameters:requestDic success:^(AFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {
                if (!wSelf) {
                    return;
                }
                [wSelf successWithOperation:operation responseObject:responseObject completionHandler:handler];
            } failure:^(AFHTTPRequestOperation * _Nullable operation, NSError * _Nonnull error) {
                if (!wSelf) {
                    return;
                }
                [wSelf failureWithOperation:operation error:error completionHandler:handler];
                
            }];
        } else {
            
            if (imageArr.count > 0 || filesArray.count > 0) { //专门用于上传图片
                requestOperation = [self.operationManager POST:path parameters:requestDic constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
//                    [formData appendPartWithFileData:imageData name:@"imageFile" fileName:@"1.jpg" mimeType:@"image/jpeg"];
                    
                    for (int i = 0; i < imageArr.count; i++) {
                        [formData appendPartWithFileData:imageArr[i] name:@"imageFile" fileName:[NSString stringWithFormat:@"%@.jpg",@(i)] mimeType:@"image/jpeg"];
                    }
                    
                    for (int i = 0;  i< filesArray.count; i++) {
                        NSString * str = [NSString stringWithFormat:@"files[%d]", i];
                        [formData appendPartWithFileData:filesArray[i] name:str fileName:[NSString stringWithFormat:@"%@.jpg",@(i)] mimeType:@"image/jpeg"];
                    }
                } success:^(AFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {
                    if (!wSelf) {
                        return;
                    }
                    [wSelf successWithOperation:operation responseObject:responseObject completionHandler:handler];
                    
                    
                } failure:^(AFHTTPRequestOperation * _Nullable operation, NSError * _Nonnull error) {
                    if (!wSelf) {
                        return;
                    }
                    [wSelf failureWithOperation:operation error:error completionHandler:handler];
                }];
                
            } else { //防止修改地址地址,中文乱码
                requestOperation = [self.operationManager POST:path parameters:requestDic success:^(AFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {
                    if (!wSelf) {
                        return;
                    }
                    [wSelf successWithOperation:operation responseObject:responseObject completionHandler:handler];
                } failure:^(AFHTTPRequestOperation * _Nullable operation, NSError * _Nonnull error) {
                    if (!wSelf) {
                        return;
                    }
                    [wSelf failureWithOperation:operation error:error completionHandler:handler];
                }];
            }

        }
    } else {
        if (isGet) {
            dataTask = [self.sessionManager GET:path parameters:requestDic success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {
                if (!wSelf) {
                    return ;
                }
                [wSelf successWithTask:task responseObject:responseObject completionHandler:handler];
                
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                [wSelf failureWithTask:task error:error completionHandler:handler];
            }];
        } else {
            if (imageArr.count > 0 || filesArray.count > 0) { //专门用于上传图片

                dataTask = [self.sessionManager POST:path parameters:requestDic constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
                    for (int i = 0; i < imageArr.count; i++) {
                        [formData appendPartWithFileData:imageArr[i] name:@"imageFile" fileName:[NSString stringWithFormat:@"%@.jpg",@(i)] mimeType:@"image/jpeg"];

                    }
                    
                    for (int i = 0;  i< filesArray.count; i++) {
                        NSString * str = [NSString stringWithFormat:@"files[%d]", i];
                        [formData appendPartWithFileData:filesArray[i] name:str fileName:[NSString stringWithFormat:@"%@.jpg",@(i)] mimeType:@"image/jpeg"];
                    }
                } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {
                    if (!wSelf) {
                        return ;
                    }
                    
                    [wSelf successWithTask:task responseObject:responseObject completionHandler:handler];
                } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                    if (!wSelf) {
                        return ;
                    }
                    [wSelf failureWithTask:task error:error completionHandler:handler];
                }];
            } else { //防止修改地址地址,中文乱码
                dataTask = [self.sessionManager POST:path parameters:requestDic success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {
                    if (!wSelf) {
                        return ;
                    }
                    [wSelf successWithTask:task responseObject:responseObject completionHandler:handler];
                } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                    if (!wSelf) {
                        return ;
                    }
                    [wSelf failureWithTask:task error:error completionHandler:handler];
                }];
            }
        }
    }
}
#pragma mark --
- (void)successWithTask:(NSURLSessionDataTask *)task responseObject:(id)responseObject completionHandler:(FetchCompletionHandler)handler {
    self.bizResult = NO;
    self.bizDataIsNull = NO;

    if ([task.originalRequest.URL.absoluteString hasSuffix:@"uc/uclogin"]) {
        NSHTTPURLResponse *response = (NSHTTPURLResponse *)task.response;
        NSString *cookieStr = [response.allHeaderFields objectForKey:@"Set-Cookie"];
        NSString *cookie = nil;
        if (cookieStr) {
            NSRange range = [cookieStr rangeOfString:@";"];
            cookie = [cookieStr substringToIndex:range.location];
            NSLog(@"cookie == %@",cookie);
            [[NSUserDefaults standardUserDefaults] setObject:cookie forKey:@"Cookie"];
        }
    }
    if ([XModuleInfo shareInstance].isDebug) {
        NSLog(@"RESPONSE URL:%@", task.originalRequest.URL);
        NSLog(@"RESPONSE JSON:%@", responseObject);
        NSLog(@"RESPONSE reqParams%@",_requestParams);
    }
    
    // additional Info
    self.details = [responseObject objectForKey:@"details"];
    self.status = [responseObject objectForKey:@"status"];
    self.msg = [responseObject objectForKey:@"msg"];
    // handle Task
    id data = [responseObject objectForKey:@"data"];
    if (self.status.integerValue == 1) {
        if ([data isKindOfClass:[NSArray class]] || [data isKindOfClass:[NSDictionary class]] || [data isKindOfClass:[NSString class]]) {
            self.bizResult = YES;
            [self injectJSONData:data];
        } else if ([data isKindOfClass:[NSNumber class]]) {
            if ([NSStringFromClass([data class]) hasSuffix:@"CFBoolean"]) {
                self.bizResult = [data boolValue];
            } else {
                self.bizResult = YES;
                [self injectJSONData:data];
            }
        } else if ([data isKindOfClass:[NSNull class]]) {
            self.bizDataIsNull = YES;
        }
        handler(YES, nil);
        if (self.finish) {
            self.finish(YES,responseObject,nil);
        }
    } else {
        NSString *errorInfo = nil;
        if (![XTool isEmpty:[responseObject objectForKey:@"msg"]]) {
            errorInfo = [responseObject objectForKey:@"msg"];
        } else if (![XTool isEmpty:[responseObject objectForKey:@"details"]]) {
            errorInfo = [responseObject objectForKey:@"details"];
        } else {
            errorInfo = @"msg和detail均无值";
        }
        NSDictionary *dict = @{NSLocalizedDescriptionKey:errorInfo};
        NSError *bizError = [NSError errorWithDomain:BizErrorDomain
                                                code:self.status.integerValue
                                            userInfo:dict];
        handler(NO, bizError);
        if (self.finish) {
            self.finish(NO,responseObject,bizError);
        }
    }
    [self fetchModelSuccessRequest:self.path responseObject:responseObject];
}

- (void)failureWithTask:(NSURLSessionDataTask *)task error:(NSError *)error  completionHandler:(FetchCompletionHandler)handler {

    NSString *reqUrl = [dataTask.originalRequest.URL absoluteString];
    NSString *params = [[NSString alloc] initWithData:task.originalRequest.HTTPBody
                                             encoding:NSUTF8StringEncoding];
    if ([XModuleInfo shareInstance].isDebug) {
        NSLog(@"FAILURE URL:%@ \nPARAMS:%@ \nAND RESPONSE:%@", reqUrl, params, task.response);
    }
    if ([XModuleInfo shareInstance].isDebug) {
        NSLog(@"FAILURE RESPONSE URL:%@", task.originalRequest.URL);
        NSLog(@"FAILURE RESPONSE response:%@", task.response);
        NSLog(@"FAILURE RESPONSE reqParams%@",_requestParams);
    }
    handler(NO, error);
    if (self.finish) {
        self.finish(NO,nil,error);
    }
    [self fetchModelFailureRequest:self.path error:error];
}

#pragma mark -- successWithOperation:responseObject:completionHandler:
- (void)successWithOperation:(AFHTTPRequestOperation *)operation responseObject:(id)responseObject completionHandler:(FetchCompletionHandler)handler{
    self.bizResult = NO;
    self.bizDataIsNull = NO;
    
    if ([operation.request.URL.absoluteString isEqualToString:@"uc/uclogin"]) {
        NSHTTPURLResponse *response = (NSHTTPURLResponse *)operation.response;
        NSString *cookieStr = [response.allHeaderFields objectForKey:@"Set-Cookie"];
        NSString *cookie = nil;
        if (cookieStr) {
            NSRange range = [cookieStr rangeOfString:@";"];
            cookie = [cookieStr substringToIndex:range.location];
            NSLog(@"cookie == %@",cookie);
            [[NSUserDefaults standardUserDefaults] setObject:cookie forKey:@"Cookie"];
        }
    }
    if ([XModuleInfo shareInstance].isDebug) {
        NSLog(@"RESPONSE URL:%@", operation.request.URL);
        NSLog(@"RESPONSE JSON:%@", responseObject);
        NSLog(@"RESPONSE reqParams%@",_requestParams);
    }
    
    // additional Info
    self.details = [responseObject objectForKey:@"details"];
    self.status = [responseObject objectForKey:@"status"];
    self.msg = [responseObject objectForKey:@"msg"];
    // handle Task
    id data = [responseObject objectForKey:@"data"];
    if (self.status.integerValue == 1) {
        
        if ([data isKindOfClass:[NSArray class]] || [data isKindOfClass:[NSDictionary class]] || [data isKindOfClass:[NSString class]]) {
            self.bizResult = YES;
            [self injectJSONData:data];
        } else if ([data isKindOfClass:[NSNumber class]]) {
            if ([NSStringFromClass([data class]) hasSuffix:@"CFBoolean"]) {
                self.bizResult = [data boolValue];
            } else {
                self.bizResult = YES;
                [self injectJSONData:data];
            }
        } else if ([data isKindOfClass:[NSNull class]]) {
            self.bizDataIsNull = YES;
        }
        handler(YES, nil);
        if (self.finish) {
            self.finish(YES,responseObject,nil);
        }
    } else {
        NSString *errorInfo = nil;
        if (![XTool isEmpty:[responseObject objectForKey:@"msg"]]) {
            errorInfo = [responseObject objectForKey:@"msg"];
        } else if (![XTool isEmpty:[responseObject objectForKey:@"details"]]) {
            errorInfo = [responseObject objectForKey:@"details"];
        } else {
            errorInfo = @"msg和detail均无值";
        }
        NSDictionary *dict = @{NSLocalizedDescriptionKey:errorInfo};
        NSError *bizError = [NSError errorWithDomain:BizErrorDomain
                                                code:self.status.integerValue
                                            userInfo:dict];
        handler(NO, bizError);
        if (self.finish) {
            self.finish(NO,responseObject,bizError);
        }
    }
    [self fetchModelSuccessRequest:self.path responseObject:responseObject];
}

#pragma mark -- failureWithOperation:responseObject:completionHandler:
- (void)failureWithOperation:(AFHTTPRequestOperation *)operation error:(NSError *)error  completionHandler:(FetchCompletionHandler)handler{
    
    NSString *reqUrl = [operation.request.URL absoluteString];
    NSString *params = [[NSString alloc] initWithData:operation.request.HTTPBody
                                             encoding:NSUTF8StringEncoding];
    if ([XModuleInfo shareInstance].isDebug) {
        NSLog(@"FAILURE URL:%@ \nPARAMS:%@ \nAND RESPONSE:%@", reqUrl, params, operation.response);
    }
    if ([XModuleInfo shareInstance].isDebug) {
        NSLog(@"FAILURE RESPONSE URL:%@", operation.request.URL);
        NSLog(@"FAILURE RESPONSE response:%@", operation.response);
        NSLog(@"FAILURE RESPONSE reqParams%@",_requestParams);
    }
    handler(NO, error);
    if (self.finish) {
        self.finish(NO,nil,error);
    }
    [self fetchModelFailureRequest:self.path error:error];
}

#pragma mark - QSFetchModel Configuration
- (void)setupCachedKeyMapper {
    if (objc_getAssociatedObject(self.class, &XFecthModelKeyMapperKey) == nil) {
        NSDictionary *dict = [self modelKeyJSONKeyMapper];
        if (dict.count) {
            objc_setAssociatedObject(self.class, &XFecthModelKeyMapperKey, dict, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
    }
}

- (void)setupCachedProperties{
    if (objc_getAssociatedObject(self.class, &XFetchModelPropertiesKey) == nil) {
        NSMutableDictionary *propertyMap = [NSMutableDictionary dictionary];
        Class class = [self class];
        while (class != [XFetchModel class]) {
            unsigned int propertyCount;
            objc_property_t *properties = class_copyPropertyList(class, &propertyCount);
            for (unsigned int i = 0; i < propertyCount; i++) {
                
                objc_property_t property = properties[i];
                const char *propertyName = property_getName(property);
                NSString *name = [NSString stringWithUTF8String:propertyName];
                const char *propertyAttrs = property_getAttributes(property);
                NSString *typeString = [NSString stringWithUTF8String:propertyAttrs];
                XFetchPropertiesModel *modelProperty = [[XFetchPropertiesModel alloc] initWithName:name typeString:typeString];
                if (!modelProperty.isReadonly) {
                    [propertyMap setValue:modelProperty forKey:modelProperty.name];
                }
            }
            free(properties);
            
            class = [class superclass];
        }
        objc_setAssociatedObject(self.class, &XFetchModelPropertiesKey, propertyMap, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

- (NSDictionary *)modelKeyJSONKeyMapper{
    return @{};
}

#pragma mark - QSFetchModel Runtime Injection
- (void)injectJSONData:(id)dataObject{
    NSDictionary *keyMapper = objc_getAssociatedObject(self.class, &XFecthModelKeyMapperKey);
    NSDictionary *properties = objc_getAssociatedObject(self.class, &XFetchModelPropertiesKey);
    
    if ([dataObject isKindOfClass:[NSArray class]]) {
        XFetchPropertiesModel *arrayProperty = nil;
        Class class = NULL;
        for (XFetchPropertiesModel *property in [properties allValues]) {
            NSString *valueProtocol = [property.objectProtocols firstObject];
            class = NSClassFromString(valueProtocol);
            if ([valueProtocol isKindOfClass:[NSString class]] && [class isSubclassOfClass:[XFetchModel class]]) {
                arrayProperty = property;
                break;
            }
        }
        if (arrayProperty && class) {
            id value = [(NSArray *)dataObject modelArrayWithClass:class];
            [self setValue:value forKey:arrayProperty.name];
        }
    } else if ([dataObject isKindOfClass:[NSDictionary class]]) {
        for (XFetchPropertiesModel *property in [properties allValues]) {
            NSString *jsonKey = property.name;
            NSString *mapperKey = [keyMapper objectForKey:jsonKey];
            jsonKey = mapperKey ?: jsonKey;
            
            id jsonValue = [dataObject objectForKey:jsonKey];
            id propertyValue = [self valueForProperty:property withJSONValue:jsonValue];
            
            if (propertyValue) {
                [self setValue:propertyValue forKey:property.name];
            } else {
                id resetValue = (property.valueType == QSClassPropertyTypeObject) ? nil : @(0);
                [self setValue:resetValue forKey:property.name];
            }
        }
    } else if ([dataObject isKindOfClass:[NSString class]] || [dataObject isKindOfClass:[NSNumber class]]){
        for (XFetchPropertiesModel *property in [properties allValues]) {
            NSString *jsonKey = property.name;
            NSString *mapperKey = [keyMapper objectForKey:jsonKey];
            jsonKey = mapperKey ?: jsonKey;
            
            id propertyValue = [self valueForProperty:property withJSONValue:dataObject];
            
            if (propertyValue) {
                [self setValue:propertyValue forKey:property.name];
            } else {
                id resetValue = (property.valueType == QSClassPropertyTypeObject) ? nil : @(0);
                [self setValue:resetValue forKey:property.name];
            }
        }

    }
}

- (id)valueForProperty:(XFetchPropertiesModel *)property withJSONValue:(id)value{
    id resultValue = value;
    if (value == nil || [value isKindOfClass:[NSNull class]]) {
        resultValue = nil;
    } else {
        if (property.valueType != QSClassPropertyTypeObject) {
            
            if ([value isKindOfClass:[NSString class]]) {
                if (property.valueType == QSClassPropertyTypeInt ||
                    property.valueType == QSClassPropertyTypeUnsignedInt||
                    property.valueType == QSClassPropertyTypeShort||
                    property.valueType == QSClassPropertyTypeUnsignedShort) {
                    resultValue = [NSNumber numberWithInt:[(NSString *)value intValue]];
                }
                if (property.valueType == QSClassPropertyTypeLong ||
                    property.valueType == QSClassPropertyTypeUnsignedLong ||
                    property.valueType == QSClassPropertyTypeLongLong ||
                    property.valueType == QSClassPropertyTypeUnsignedLongLong){
                    resultValue = [NSNumber numberWithLongLong:[(NSString *)value longLongValue]];
                }
                if (property.valueType == QSClassPropertyTypeFloat) {
                    resultValue = [NSNumber numberWithFloat:[(NSString *)value floatValue]];
                }
                if (property.valueType == QSClassPropertyTypeDouble) {
                    resultValue = [NSNumber numberWithDouble:[(NSString *)value doubleValue]];
                }
                if (property.valueType == QSClassPropertyTypeChar) {
                    //对于BOOL而言，@encode(BOOL) 为 c 也就是signed char
                    resultValue = [NSNumber numberWithBool:[(NSString *)value boolValue]];
                }
            }
        } else {
            Class valueClass = property.objectClass;
            if ([valueClass isSubclassOfClass:[XFetchModel class]] &&
                [value isKindOfClass:[NSDictionary class]]) {
                resultValue = [[valueClass alloc] initWithJSONDict:value];
            }
            if ([valueClass isSubclassOfClass:[NSString class]] &&
                ![value isKindOfClass:[NSString class]]) {
                resultValue = [NSString stringWithFormat:@"%@",value];
            }
            if ([valueClass isSubclassOfClass:[NSNumber class]] &&
                [value isKindOfClass:[NSString class]]) {
                NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
                [numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
                resultValue = [numberFormatter numberFromString:value];
            }
            NSString *valueProtocol = [property.objectProtocols lastObject];
            if ([valueProtocol isKindOfClass:[NSString class]]) {
                Class valueProtocolClass = NSClassFromString(valueProtocol);
                if (valueProtocolClass != nil) {
                    if ([valueProtocolClass isSubclassOfClass:[XFetchModel class]]) {
                        //array of models
                        if ([value isKindOfClass:[NSArray class]]) {
                            resultValue = [(NSArray *)value modelArrayWithClass:valueProtocolClass];
                        }
                        //dictionary of models
                        if ([value isKindOfClass:[NSDictionary class]]) {
                            resultValue = [(NSDictionary *)value modelDictionaryWithClass:valueProtocolClass];
                        }
                    }
                }
            }
        }
    }
    return resultValue;
}

@end
