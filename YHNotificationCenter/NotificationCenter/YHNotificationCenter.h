//
//  YHNotificationCenter.h
//  YHNotificationCenter
//
//  Created by 杨虎 on 2019/7/3.
//  Copyright © 2019 杨虎. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YHObserverInfo.h"

NS_ASSUME_NONNULL_BEGIN

@interface YHNotificationCenter : NSObject

+ (instancetype)defaultCenter;

/** 添加观察者 */
- (void)addObserver:(id)observer selector:(SEL)aSelector name:(nullable NSNotificationName)aName object:(nullable id)anObject;

- (void)addObserverForName:(nullable NSNotificationName)name observer:(nullable id)observer queue:(nullable NSOperationQueue *)queue usingBlock:(void (^)(YHObserverInfo *info))block;

/** 发送通知 */
- (void)postNotification:(NSNotification *)notification;

- (void)postNotificationName:(NSNotificationName)aName;

- (void)postNotificationName:(NSNotificationName)aName object:(nullable id)anObject;

- (void)postNotificationName:(NSNotificationName)aName object:(nullable id)anObject userInfo:(nullable NSDictionary *)aUserInfo;

/** 移除观察者 */
- (void)removeObserver:(id)observer;

- (void)removeObserver:(id)observer name:(nullable NSNotificationName)aName object:(nullable id)anObject;

@end

NS_ASSUME_NONNULL_END
