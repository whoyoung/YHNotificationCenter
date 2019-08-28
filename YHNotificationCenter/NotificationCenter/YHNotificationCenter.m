//
//  YHNotificationCenter.m
//  YHNotificationCenter
//
//  Created by 杨虎 on 2019/7/3.
//  Copyright © 2019 杨虎. All rights reserved.
//

#import "YHNotificationCenter.h"
#import <UIKit/UIKit.h>

@interface YHNotificationCenter ()

/** 观察者字典 */
@property (nonatomic, strong) NSMutableDictionary<NSNotificationName, NSPointerArray *> *observerDict;

/** 观察信息字典 */
@property (nonatomic, strong) NSMutableDictionary<NSNotificationName, NSMutableSet<YHObserverInfo *> *> *observerInfoDict;

/** 锁。防止线程竞争 */
@property (nonatomic, strong) NSLock *lock;

@end

@implementation YHNotificationCenter

+ (instancetype)defaultCenter {
    static YHNotificationCenter *center;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        center = [[YHNotificationCenter alloc] init];
        [[NSNotificationCenter defaultCenter] addObserver:center selector:@selector(didReceiveMemoryWarning) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    });
    return center;
}

- (NSMutableDictionary<NSNotificationName,NSPointerArray *> *)observerDict {
    if (!_observerDict) {
        _observerDict = [NSMutableDictionary dictionary];
    }
    return _observerDict;
}

- (NSMutableDictionary<NSNotificationName,NSMutableSet<YHObserverInfo *> *> *)observerInfoDict {
    if (!_observerInfoDict) {
        _observerInfoDict = [NSMutableDictionary dictionary];
    }
    return _observerInfoDict;
}

/*
 伪代码：
 通知名 或 观察者 不存在，return;
 if (观察者字典中不存在以通知名为 key 的 NSPointerArray) {
     观察者字典中添加以通知名为 key，以 弱引用的 NSPointerArray 空对象 为 value 的 key-value
 }
 if (观察者字典中以通知名为 key 的 NSPointerArray value 中，不存在 要添加的观察者) {
     观察者字典中以通知名为 key 的 NSPointerArray value 中，添加该观察者
 }
 if (观察者信息字典中以通知名为 key 的 通知信息 集合中，不存在 完全一致的通知信息) {
     观察者信息字典中添加以通知名为 key ，以该 通知信息 为首个元素的集合作为 value 的 key-value
 }
 */
- (void)addObserver:(id)observer selector:(SEL)aSelector name:(nullable NSNotificationName)aName object:(nullable id)anObject {
    if (!aName || !aName.length || !observer) {
        return;
    }
    [self.lock lock];
    NSPointerArray *array = [self.observerDict objectForKey:aName];
    if (!array) {
        array = [NSPointerArray weakObjectsPointerArray];
        [self.observerDict setObject:array forKey:aName];
    }
    BOOL hasExisted = [self hasExistedObserver:observer pointerArray:array];
    if (!hasExisted) {
        [array addPointer:(void *)observer];
    }
    
    YHObserverInfo *info = [[YHObserverInfo alloc] initWithObserver:observer selector:aSelector name:aName object:anObject];
    if (![self hasExistedObserverInfo:info]) {
        NSMutableSet *set = [self.observerInfoDict objectForKey:aName];
        if (!set) {
            set = [NSMutableSet set];
            [self.observerInfoDict setObject:set forKey:aName];
        }
        [set addObject:info];
    }
    [self.lock unlock];
}

- (void)addObserverForName:(nullable NSNotificationName)aName observer:(nullable id)observer queue:(nullable NSOperationQueue *)queue usingBlock:(void (^)(YHObserverInfo *info))block {
    if (!aName || !aName.length || !observer) {
        return;
    }
    [self.lock lock];
    NSPointerArray *array = [self.observerDict objectForKey:aName];
    if (!array) {
        array = [NSPointerArray weakObjectsPointerArray];
        [self.observerDict setObject:array forKey:aName];
    }
    BOOL hasExisted = [self hasExistedObserver:observer pointerArray:array];
    if (!hasExisted) {
        [array addPointer:(void *)observer];
    }
    
    YHObserverInfo *info = [[YHObserverInfo alloc] initWithObserver:observer name:aName queue:queue block:block];
    if (![self hasExistedObserverInfo:info]) {
        NSMutableSet *set = [self.observerInfoDict objectForKey:aName];
        if (!set) {
            set = [NSMutableSet set];
            [self.observerInfoDict setObject:set forKey:aName];
        }
        [set addObject:info];
    }
    [self.lock unlock];
}

- (BOOL)hasExistedObserver:(id)observer pointerArray:(NSPointerArray *)array {
    BOOL existed = NO;
    for (id tempObserver in array) {
        if (tempObserver == observer) {
            existed = YES;
            break;
        }
    }
    return existed;
}

- (BOOL)hasExistedObserverInfo:(YHObserverInfo *)newInfo {
    NSMutableSet *set = [self.observerInfoDict objectForKey:newInfo.name];
    if (!set || !set.count) {
        return NO;
    }
    for (YHObserverInfo *info in set) {
        if ([info isEqual:newInfo]) {
            return YES;
        }
    }
    return NO;
}

- (void)postNotification:(NSNotification *)notification {
    [self postNotificationName:notification.name object:notification.object userInfo:notification.userInfo];
}

- (void)postNotificationName:(NSNotificationName)aName {
    [self postNotificationName:aName object:nil userInfo:nil];
}

- (void)postNotificationName:(NSNotificationName)aName object:(nullable id)anObject {
    [self postNotificationName:aName object:anObject userInfo:nil];
}

/*
 伪代码：
 通知名 不存在，return;
 if (观察者字典中不存在以通知名为 key 的 NSPointerArray) return;
 if (观察者信息字典中以通知名为 key 的 通知信息集合 value 不存在) return;
 遍历观察者信息字典中以通知名为 key 的 通知信息集合 value 中的 通知信息对象 info
    if (info.observer == observer && info.object == anObject) { // 通知信息完全相同
         if (info.aSelector) {
             执行 selector
         } else if (info.block) {
             执行 block
         }
     } else { // 通知信息不完全相同
         return;
     }
 */
- (void)postNotificationName:(NSNotificationName)aName object:(nullable id)anObject userInfo:(nullable NSDictionary *)aUserInfo {
    if (!aName || !aName.length) {
        return;
    }
    [self.lock lock];
    NSPointerArray *pointerA = [self.observerDict objectForKey:aName];
    if (!pointerA || !pointerA.allObjects.count) {
        [self.lock unlock];
        return;
    }
    NSMutableSet *set = [self.observerInfoDict objectForKey:aName];
    if (!set || !set.count) {
        [self.lock unlock];
        return;
    }
    for (id observer in pointerA) {
        for (YHObserverInfo *info in set) {
            if (info.observer == observer && info.object == anObject) {
                if (info.aSelector) {
                    NSString *selString = NSStringFromSelector(info.aSelector);
                    if ([selString hasSuffix:@":"]) {
                        info.userInfo = aUserInfo;
                    }
                    if ([observer respondsToSelector:info.aSelector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                        [observer performSelector:info.aSelector withObject:info];
#pragma clang diagnostic pop
                    }
                } else if (info.block) {
                    info.userInfo = aUserInfo;
                    if (info.queue) {
                        __weak typeof(info) weakInfo = info;
                        [info.queue addOperationWithBlock:^{
                            if (weakInfo) {
                                __strong typeof(weakInfo) strongInfo = weakInfo;
                                strongInfo.block(info);
                            }
                        }];
                    } else {
                        info.block(info);
                    }
                }
                
            }
        }
    }
    [self.lock unlock];
}


/** 收到内存警告，则清空 观察者字典 和 观察信息字典 中，观察者 为 nil 的 key-value 键值对 */
- (void)didReceiveMemoryWarning {
    @synchronized (self) {
        [self cleanObserverDict];
        [self cleanObserverInfoDict];
    };
}


/** 使用 compact 方法，删除 观察者 NSPointerArray 中，观察者为 nil 的对象 */
- (void)cleanObserverDict {
    if (!self.observerDict.count) {
        return;
    }
    [self.lock lock];
    [self.observerDict enumerateKeysAndObjectsUsingBlock:^(NSNotificationName _Nonnull key, NSPointerArray * _Nonnull obj, BOOL * _Nonnull stop) {
        if (obj.count) {
            [obj addPointer:nil]; // 不加上这句的话，直接调用compact，并不能清除 array 中的 nil。
            [obj compact];
        }
    }];
    [self.lock unlock];
}

/** 删掉观察者信息集合 NSMutableSet 中，观察者信息 YHObserverInfo 的 观察者 为 nil 的对象*/
- (void)cleanObserverInfoDict {
    if (!self.observerInfoDict.count) {
        return;
    }
    [self.lock lock];
    [self.observerInfoDict enumerateKeysAndObjectsUsingBlock:^(NSNotificationName _Nonnull key, NSMutableSet<YHObserverInfo *> * _Nonnull obj, BOOL * _Nonnull stop) {
        [obj enumerateObjectsUsingBlock:^(YHObserverInfo * _Nonnull infoObj, BOOL * _Nonnull stop) {
            if (!infoObj.observer) {
                [obj removeObject:infoObj];
                infoObj = nil;
            }
        }];
    }];
    [self.lock unlock];
}

- (void)removeObserver:(id)observer {
    [self removeObserver:observer name:nil object:nil];
}

/*
 伪代码：
 if (observer == nil ) return;
 if (aName != nil) {
     在 observerDict 中 以 aName 为 key 的 NSPointerArray
         if (NSPointerArray 中 有 pointer 和 observer 相同) {
             在 observerInfoDict 中查找 aName 和 observer 都相同的 YHObserverInfo
                 if (YHObserverInfo.object == anObject) {
                     将 YHObserverInfo 从 observerInfoDict 中移除
                 } else {
                     // 因为 YHObserverInfo.object != anObject，所以 observerDict 不能移除 pointer
                 }
                 if (所以的 YHObserverInfo.object == anObject) {
                     将 pointer 从 observerDict 中移除
                 }
         }
 } else if (!aName && anObject) {
     在 observerInfoDict 中遍历 YHObserverInfo
         if (YHObserverInfo.observer == observer && YHObserverInfo.object == anObject) {
             将 YHObserverInfo 从 observerInfoDict 中移除
         }
 } else if (!aName && !anObject) {
     移除 observerDict.NSPointerArray 中，所有 pointer == observer 的 pointer
     移除 observerInfoDict.NSMutableSet<YHObserverInfo *> 中，所有 YHObserverInfo.observer == observer 的 YHObserverInfo.observer
 }
 */
- (void)removeObserver:(id)observer name:(nullable NSNotificationName)aName object:(nullable id)anObject {
    if (!observer) {
        return;
    }
    [self.lock lock];
    [self.observerDict enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSPointerArray * _Nonnull obj, BOOL * _Nonnull stop) {
        if (aName && [key isEqualToString:aName]) { // 通知名一致
            for (NSInteger i = obj.count - 1; i >= 0; i--) {
                id pointer = [obj pointerAtIndex:i];
                if (observer == pointer) { // 观察者一致
                    NSMutableSet *set = [self.observerInfoDict objectForKey:aName]; // 观察信息集合
                    __block BOOL isInfoSame = YES;
                    if (set) {
                        [set enumerateObjectsUsingBlock:^(YHObserverInfo * _Nonnull obj, BOOL * _Nonnull stop) {
                            if (obj.observer == observer) {
                                if (obj.object == anObject) { // 观察信息完全一致，则移除该观察信息
                                    [set removeObject:obj];
                                } else { // 观察信息不完全一致，则保留该观察信息
                                    isInfoSame = NO;
                                }
                            }
                        }];
                        if (!set.count) { // 无观察者信息了，则观察者信息字典移除该通知
                            [self.observerInfoDict removeObjectForKey:aName];
                        }
                    }
                    if (isInfoSame) { // 观察者相同，且观察信息完全一致
                        [obj removePointerAtIndex:i]; // 观察者数组移除该观察者
                        if (!obj.allObjects.count) { // 如果观察者数组里非 nil 对象个数为零，则观察者字典移除该通知
                            [self.observerDict removeObjectForKey:aName];
                        }

                    }
                }
            }
        } else if (!aName && anObject) {
            [self.observerInfoDict enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSMutableSet<YHObserverInfo *> * _Nonnull set, BOOL * _Nonnull stop) {
                [set enumerateObjectsUsingBlock:^(YHObserverInfo * _Nonnull obj, BOOL * _Nonnull stop) {
                    if (obj.observer == observer && obj.object == anObject) { // 观察者信息一致
                        [set removeObject:obj];
                    }
                }];
                if (!set.count) { // 无观察者信息了，则观察者信息字典移除该通知
                    [self.observerInfoDict removeObjectForKey:key];
                }
            }];
            
        } else if (!aName && !anObject) {
            [self.observerDict enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSPointerArray * _Nonnull obj, BOOL * _Nonnull stop) {
                for (NSInteger i = obj.count - 1; i >= 0; i--) {
                    id pointer = [obj pointerAtIndex:i];
                    if (observer == pointer) { // 观察者一致
                        [obj removePointerAtIndex:i]; // 观察者数组移除该观察者
                    }
                }
                if (!obj.allObjects.count) { // 如果观察者数组里非 nil 对象个数为零，则观察者字典移除该通知
                    [self.observerDict removeObjectForKey:key];
                }
            }];
            
            [self.observerInfoDict enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSMutableSet<YHObserverInfo *> * _Nonnull set, BOOL * _Nonnull stop) {
                [set enumerateObjectsUsingBlock:^(YHObserverInfo * _Nonnull obj, BOOL * _Nonnull stop) {
                    if (obj.observer == observer) { // 观察者一致
                        [set removeObject:obj];
                    }
                }];
                if (!set.count) { // 无观察者信息了，则观察者信息字典移除该通知
                    [self.observerInfoDict removeObjectForKey:key];
                }
            }];
        }
    }];
    [self.lock unlock];
}

- (NSLock *)lock {
    if (!_lock) {
        _lock = [[NSLock alloc] init];
    }
    return _lock;
}

@end
