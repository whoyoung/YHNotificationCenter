//
//  YHObserverInfo.h
//  YHNotificationCenter
//
//  Created by 杨虎 on 2019/7/3.
//  Copyright © 2019 杨虎. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface YHObserverInfo : NSObject

@property (nonatomic, weak) id observer;

@property (nonatomic, assign) SEL aSelector;

@property (nonatomic, copy, nonnull) NSNotificationName name;

@property (nonatomic, strong) id object;

@property (nonatomic, strong) NSDictionary *userInfo;

@property (nonatomic, strong) NSOperationQueue *queue;

@property (nonatomic, copy) void (^block)(YHObserverInfo *info);

- (instancetype)initWithObserver:(id)observer selector:(SEL)aSelector name:(nullable NSNotificationName)aName object:(nullable id)anObject;

- (instancetype)initWithObserver:(id)observer name:(nullable NSNotificationName)aName queue:(nullable NSOperationQueue *)queue block:(void (^)(YHObserverInfo *info))block;

@end

NS_ASSUME_NONNULL_END
