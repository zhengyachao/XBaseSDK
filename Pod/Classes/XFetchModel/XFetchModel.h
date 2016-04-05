//
//  XFetchModel.h
//  XStaiticLibrary
//
//  Created by clio on 15/9/9.
//  Copyright (c) 2015年 X. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#define isGetKey @"isGetKey" //默认为Post

/**
 *  请求完成的回调
 *
 *  @param isSucceeded 成功返回YES, 失败返回NO
 *  @param error       错误信息
 */
typedef void (^FetchCompletionHandler) (BOOL isSucceeded, NSError *error);

typedef void (^FetchCompletionHandlerData) (NSDictionary *dic, BOOL isSucceed, NSError *error);
typedef void(^FetchFinishBlock) (BOOL isSuccessed, id responseObject,NSError *error);

typedef void(^ImageDownLoadCompletion)(UIImage *image, NSError *error, NSURL *imageURL);
@interface XFetchModel : NSObject

@property (nonatomic, assign) BOOL bizResult;
@property (nonatomic, assign) BOOL bizDataIsNull;
@property (nonatomic, strong) FetchFinishBlock finish;
/**
 *  给用户的信息
 */
@property (nonatomic, copy) NSString *msg;
/**
 *  错误码
 */
@property(nonatomic,copy) NSNumber *status;
/**
 *  错误信息（用于开发者调试）
 */
@property(nonatomic,copy) NSString *details;
/**
 *  请求参数
 *  如果是get请求的话，添加isGetKey:@(1)这对键值
 */
@property(nonatomic,strong) NSDictionary *requestParams;
/**
 *  请求数据
 *
 *  @param path    接口
 *  @param handler 请求完成的block
 */
- (void)fetchWithPath:(NSString *)path completionHandler:(FetchCompletionHandler)handler;

///**
// *  返回结果为data
// *
// *  @param path    接口
// *  @param handler 请求完成block
// */
//- (void)fetchWithPathData:(NSString *)path completionHandlerData:(FetchCompletionHandlerData)handler;

/**
 *  相关映射
 */
-(NSDictionary *)modelKeyJSONKeyMapper;
/**
 *  字典转model
 *
 *  @param dataObject 
 */
- (void)injectJSONData:(id)dataObject;
/**
 *  加载图片
 *
 *  @param imgUrl    图片的URL
 *  @param image     默认加载的图片
 *  @param imageView 图片
 */
- (void)setImageWithURL:(NSURL *)imgUrl placeHolderImage:(UIImage *)image imageDownLoadCompletion:(ImageDownLoadCompletion)completion withImageView:(UIImageView *)imageView;

@end
