//
//  WebViewController.m
//  iOS10CellularAuthorizeFix
//
//  Created by zuik on 2017/2/4.
//  Copyright © 2017年 zuik. All rights reserved.
//

#import "WebViewController.h"

@interface WebViewController ()
@property (weak, nonatomic) IBOutlet UIWebView *webView;

@end

@implementation WebViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://www.baidu.com"]]];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    self.navigationItem.prompt = [NSString stringWithFormat:@"加载失败:%@",error.localizedDescription];
}

@end
