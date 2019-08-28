//
//  YHNotificationCenterViewController.m
//  YHNotificationCenter
//
//  Created by 杨虎 on 2019/7/3.
//  Copyright © 2019 杨虎. All rights reserved.
//

#import "CustomNotificationCenterViewController.h"
#import "YHNotificationCenter.H"

@interface CustomNotificationCenterViewController ()<UITableViewDelegate,UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, strong) NSArray<NSString *> *datas;

@end

@implementation CustomNotificationCenterViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 84, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height - 84) style:UITableViewStylePlain];
    [self.view addSubview:self.tableView];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    [self addNotifications];
    
}

- (void)addNotifications {
    [[YHNotificationCenter defaultCenter] addObserver:self selector:@selector(pureNotificationEvent) name:@"pureNotification" object:nil];
    [[YHNotificationCenter defaultCenter] addObserver:self selector:@selector(notiWithObjectEvent:) name:@"notiWithObject" object:self.datas];
    [[YHNotificationCenter defaultCenter] addObserver:self selector:@selector(notiWithUserInfoEvent:) name:@"notiWithUserInfo" object:nil];
    [[YHNotificationCenter defaultCenter] addObserver:self selector:@selector(notiWithObjectAndUserInfoEvent:) name:@"notiWithObjectAndUserInfo" object:self.datas];
    
    [[YHNotificationCenter defaultCenter] addObserverForName:@"notiWithDefaultQueue" observer:self queue:nil usingBlock:^(YHObserverInfo * _Nonnull info) {
        NSLog(@"notiWithDefaultQueue ======, info.userInfo = %@",info.userInfo);
    }];
    
    NSOperationQueue *customQueue = [[NSOperationQueue alloc] init];
    customQueue.name = @"yh_custom_queue";
    [[YHNotificationCenter defaultCenter] addObserverForName:@"notiWithCustomQueue" observer:self queue:customQueue usingBlock:^(YHObserverInfo * _Nonnull info) {
        NSLog(@"notiWithCustomQueue ==== %@ , queue's name ==== %@, info.userInfo = %@",info.name,info.queue.name,info.userInfo);
    }];
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.datas.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"UITableViewCell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"UITableViewCell"];
    }
    cell.textLabel.text = self.datas[indexPath.row];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *selString = self.datas[indexPath.row];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [self performSelector:NSSelectorFromString(selString)];
#pragma clang diagnostic pop
}

- (void)pureNotification {
    NSLog(@"trigger %s",__func__);
    [[YHNotificationCenter defaultCenter] postNotificationName:@"pureNotification"];
}
- (void)pureNotificationEvent {
    NSLog(@"trigger %s",__func__);
}

- (void)notiWithObject {
    NSLog(@"trigger %s",__func__);
    [[YHNotificationCenter defaultCenter] postNotificationName:@"notiWithObject" object:self.datas];
}
- (void)notiWithObjectEvent:(YHObserverInfo *)info {
    NSLog(@"trigger %s",__func__);
    NSLog(@"info.object = %p",info.object);
}

- (void)notiWithUserInfo {
    NSLog(@"trigger %s",__func__);
    [[YHNotificationCenter defaultCenter] postNotificationName:@"notiWithUserInfo" object:nil userInfo:@{@"param":@"i am param"}];

}
- (void)notiWithUserInfoEvent:(YHObserverInfo *)info {
    NSLog(@"trigger %s",__func__);
    NSLog(@"info.userInfo = %@",info.userInfo);
}

- (void)notiWithObjectAndUserInfo {
    NSLog(@"trigger %s",__func__);
    [[YHNotificationCenter defaultCenter] postNotificationName:@"notiWithObjectAndUserInfo" object:self.datas userInfo:@{@"param":@"i am new param"}];
}
- (void)notiWithObjectAndUserInfoEvent:(YHObserverInfo *)info {
    NSLog(@"trigger %s",__func__);
    NSLog(@"info.object = %p, info.userInfo = %@",info.object,info.userInfo);
}

- (void)notiWithDefaultQueue {
    NSLog(@"trigger %s",__func__);
    [[YHNotificationCenter defaultCenter] postNotificationName:@"notiWithDefaultQueue" object:nil userInfo:@{@"param":@"i am notiWithDefaultQueue"}];
}

- (void)notiWithCustomQueue {
    NSLog(@"trigger %s",__func__);
    [[YHNotificationCenter defaultCenter] postNotificationName:@"notiWithCustomQueue" object:nil userInfo:@{@"param":@"i am notiWithCustomQueue"}];
}

- (void)removePureNotification {
    NSLog(@"trigger %s",__func__);
    [[YHNotificationCenter defaultCenter] removeObserver:self name:@"pureNotification" object:nil];
}

- (void)removeNotiWithSameObject {
    NSLog(@"trigger %s",__func__);
    [[YHNotificationCenter defaultCenter] removeObserver:self name:@"notiWithObject" object:self.datas];
}

- (void)removeNotiWithNotSameObject {
    NSLog(@"trigger %s",__func__);
    [[YHNotificationCenter defaultCenter] removeObserver:self name:@"notiWithObject" object:@[]];
}

- (void)removeAllObserver {
    NSLog(@"trigger %s",__func__);
    [[YHNotificationCenter defaultCenter] removeObserver:self];
}

- (void)multiThreadSafe {
    NSLog(@"trigger %s",__func__);
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        for (NSUInteger i=0; i<10000; i++) {
            NSLog(@"add notification %ld",i);
            [[YHNotificationCenter defaultCenter] addObserver:self selector:@selector(pureNotificationEvent) name:@"pureNotification" object:nil];
        }
    });
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        for (NSUInteger i=0; i<10000; i++) {
            NSLog(@"remove notification %ld",i);
            [[YHNotificationCenter defaultCenter] removeObserver:self name:@"pureNotification" object:nil];
        }
    });
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        for (NSUInteger i=0; i<10000; i++) {
            NSLog(@"post notification %ld",i);
            [[YHNotificationCenter defaultCenter] postNotificationName:@"pureNotification" object:nil];
        }
    });
}

- (NSArray<NSString *> *)datas {
    if (!_datas) {
        _datas = @[@"pureNotification",@"notiWithObject",@"notiWithUserInfo",@"notiWithObjectAndUserInfo",@"notiWithDefaultQueue",@"notiWithCustomQueue",@"removePureNotification",@"removeNotiWithSameObject",@"removeNotiWithNotSameObject",@"removeAllObserver",@"multiThreadSafe"];
    }
    return _datas;
}

- (void)dealloc {
    NSLog(@"%s",__func__);
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidReceiveMemoryWarningNotification object:nil];
}

@end
