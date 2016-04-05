//
//  XFetchPropertiesModel.h
//  XStaiticLibrary
//
//  Created by clio on 15/9/9.
//  Copyright (c) 2015年 X. All rights reserved.
//

#import <Foundation/Foundation.h>
/*
 相关知识请参见Runtime文档
 Type Encodings https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtTypeEncodings.html#//apple_ref/doc/uid/TP40008048-CH100-SW1
 Property Type String https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtPropertyIntrospection.html#//apple_ref/doc/uid/TP40008048-CH101-SW6
 */
typedef NS_ENUM(NSUInteger, QSFetchModelPropertyValueType) {
    QSClassPropertyValueTypeNone = 0,
    QSClassPropertyTypeChar,
    QSClassPropertyTypeInt,
    QSClassPropertyTypeShort,
    QSClassPropertyTypeLong,
    QSClassPropertyTypeLongLong,
    QSClassPropertyTypeUnsignedChar,
    QSClassPropertyTypeUnsignedInt,
    QSClassPropertyTypeUnsignedShort,
    QSClassPropertyTypeUnsignedLong,
    QSClassPropertyTypeUnsignedLongLong,
    QSClassPropertyTypeFloat,
    QSClassPropertyTypeDouble,
    QSClassPropertyTypeBool,
    QSClassPropertyTypeVoid,
    QSClassPropertyTypeCharString,
    QSClassPropertyTypeObject,
    QSClassPropertyTypeClassObject,
    QSClassPropertyTypeSelector,
    QSClassPropertyTypeArray,
    QSClassPropertyTypeStruct,
    QSClassPropertyTypeUnion,
    QSClassPropertyTypeBitField,
    QSClassPropertyTypePointer,
    QSClassPropertyTypeUnknow
};

@interface XFetchPropertiesModel : NSObject

@property (nonatomic, assign) QSFetchModelPropertyValueType valueType;
@property (nonatomic, copy) NSString *name;
@property(nonatomic,  copy) NSString *errorCode;
@property (nonatomic, copy) NSString *typeName;
@property (nonatomic, assign) BOOL isReadonly;
@property (nonatomic, assign) Class objectClass;
@property (nonatomic, strong) NSArray *objectProtocols;

- (id)initWithName:(NSString *)name typeString:(NSString *)typeString;
@end
