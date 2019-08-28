//
//  ViewController.m
//  YHNotificationCenter
//
//  Created by young on 2019/8/29.
//  Copyright © 2019 young. All rights reserved.
//

#import "ViewController.h"
#import "CustomNotificationCenterViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    [btn setTitle:@"通知中心验证" forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    btn.frame = CGRectMake(0, 0, 100, 60);
    [btn addTarget:self action:@selector(testNotification) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
    btn.center = self.view.center;
}

- (void)testNotification {
    CustomNotificationCenterViewController *vc = [CustomNotificationCenterViewController new];
    [self.navigationController pushViewController:vc animated:YES];
}

@end
