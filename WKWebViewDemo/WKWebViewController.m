//
//  WKWebViewController.m
//  WKWebViewDemo
//
//  Created by Azzan on 2018/4/9.
//  Copyright © 2018年 Azzan. All rights reserved.
//

#import "WKWebViewController.h"
#import <WebKit/WebKit.h>

#define KScreenHeight [UIScreen mainScreen].bounds.size.height
#define KScreenWidth [UIScreen mainScreen].bounds.size.width

/**
 WKNavigationDelegate主要处理一些跳转、加载处理操作。
 WKUIDelegate主要处理JS脚本，确认框，警告框等。
 因此WKNavigationDelegate更加常用
 */
@interface WKWebViewController ()<WKUIDelegate,WKNavigationDelegate,WKScriptMessageHandler,UIImagePickerControllerDelegate,UINavigationControllerDelegate>


@property (nonatomic, strong) UIProgressView *progressView;
@property (nonatomic, strong) WKWebView *wkWebview;


@end

@implementation WKWebViewController


- (void)setupWebview{
    
    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    config.selectionGranularity = WKSelectionGranularityDynamic;
    config.allowsInlineMediaPlayback = YES;
    WKPreferences *preferences = [WKPreferences new];
    preferences.javaScriptEnabled = YES;//是否支持JavaScript
    preferences.javaScriptCanOpenWindowsAutomatically = YES;//不通过用户交互，是否可以打开窗口
    config.preferences = preferences;
    
    
//    WKUserContentController *user = [[WKUserContentController alloc]init];
//    
//    [user addScriptMessageHandler:self name:@"takePicturesByNative"];
//    
//    config.userContentController =user;
    
    
    WKWebView *webview = [[WKWebView alloc] initWithFrame:CGRectMake(0, 64, KScreenWidth, KScreenHeight) configuration:config];
    self.wkWebview = webview;
    [self.view addSubview:webview];
    
    webview.navigationDelegate = self;
    webview.UIDelegate = self;
    [webview addObserver:self forKeyPath:@"estimatedProgress" options:NSKeyValueObservingOptionNew context:nil];
    [webview addObserver:self forKeyPath:@"title" options:NSKeyValueObservingOptionNew context:NULL];
    
    NSURL *urlStr = [NSURL URLWithString:_url];
    NSMutableURLRequest * request =[NSMutableURLRequest
                                    requestWithURL:urlStr cachePolicy:NSURLRequestReloadRevalidatingCacheData timeoutInterval:10.0f];
    [self.wkWebview loadRequest:request];
    
    
}
- (void)setProgressView{
    //进度条初始化
    self.progressView = [[UIProgressView alloc] initWithFrame:CGRectMake(0,64,KScreenWidth, 2)];
    self.progressView.backgroundColor = [UIColor blueColor];
    //设置进度条的高度，下面这句代码表示进度条的宽度变为原来的1倍，高度变为原来的1.5倍.
    self.progressView.transform = CGAffineTransformMakeScale(1.0f, 1.5f);
    [self.view addSubview:self.progressView];
    
}

- (void)setUrl:(NSString *)url{
    _url = url;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor groupTableViewBackgroundColor];
    
    [self setupWebview];
    [self setProgressView];
    
}

#pragma mark - WKNavigationDelegate
/* 页面开始加载 */
- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation{
    NSLog(@"页面开始加载");
    //开始加载网页时展示出progressView
    self.progressView.hidden = NO;
    //开始加载网页的时候将progressView的Height恢复为1.5倍
    self.progressView.transform = CGAffineTransformMakeScale(1.0f, 1.5f);
    //防止progressView被网页挡住
    [self.view bringSubviewToFront:self.progressView];
    
}

/* 开始返回内容 */

- (void)webView:(WKWebView *)webView didCommitNavigation:(WKNavigation *)navigation{
    NSLog(@"开始返回内容");

}

/* 页面加载完成 */
- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation{
    NSLog(@"页面加载完成");
    self.progressView.hidden = YES;


}

/* 页面加载失败 */

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation{
    NSLog(@"页面加载失败");
    self.progressView.hidden = YES;

    
}

/* 在发送请求之前，决定是否跳转 */

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler{
    
    //允许跳转
    
    decisionHandler(WKNavigationActionPolicyAllow);
    
    //不允许跳转
    
    //decisionHandler(WKNavigationActionPolicyCancel);
    
}

/* 在收到响应后，决定是否跳转 */

- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler{
    
    
    
    NSLog(@"在收到响应后，决定是否跳转%@",navigationResponse.response.URL.absoluteString);
    
    //允许跳转
    
    decisionHandler(WKNavigationResponsePolicyAllow);
    
    //不允许跳转
    
    //decisionHandler(WKNavigationResponsePolicyCancel);
    
}


#pragma mark - KVO回馈

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    
    if ([keyPath isEqualToString:@"estimatedProgress"]) {
        self.progressView.progress = self.wkWebview.estimatedProgress;
        if (self.progressView.progress == 1) {
            /*
             *添加一个简单的动画，将progressView的Height变为1.4倍，在开始加载网页的代理中会恢复为1.5倍
             *动画时长0.25s，延时0.3s后开始动画
             *动画结束后将progressView隐藏
             */
            __weak typeof (self)weakSelf = self;
            [UIView animateWithDuration:0.25f delay:0.3f options:UIViewAnimationOptionCurveEaseOut animations:^{
                weakSelf.progressView.transform = CGAffineTransformMakeScale(1.0f, 1.4f);
            } completion:^(BOOL finished) {
                weakSelf.progressView.hidden = YES;
                
            }];
        }
    }else if ([keyPath isEqualToString:@"title"]){
        
        self.title = change[@"new"];
        
    }
    
}

#pragma mark- WKScriptMessageHandler

-(void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message{
    
    NSLog(@"name--%@",message.name);
    
    NSLog(@"body--%@",message.body);
    
//    if ([message.name isEqualToString:@"takePicturesByNative"]) {
//
////        [self takePicturesByNative];
//
//    }
}


//- (void)takePicturesByNative{
//
//    UIImagePickerController *vc = [[UIImagePickerController alloc] init];
//
//    vc.delegate = self;
//
//    vc.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
//
//
//
//    [self presentViewController:vc animated:YES completion:nil];
//
//}

//- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
//
//    NSTimeInterval timeInterval = [[NSDate date]timeIntervalSince1970];
//
//    NSString *timeString = [NSString stringWithFormat:@"%.0f",timeInterval];
//
//
//
//    UIImage *image = [info  objectForKey:UIImagePickerControllerOriginalImage];
//
//    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES);
//
//    NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.png",timeString]];  //保存到本地
//
//    [UIImagePNGRepresentation(image) writeToFile:filePath atomically:YES];
//
//    NSString *str = [NSString stringWithFormat:@"%@",filePath];
//
//    [picker dismissViewControllerAnimated:YES completion:^{
//
//        // oc 调用js 并且传递图片路径参数
//
//        [self.wkWebview evaluateJavaScript:[NSString stringWithFormat:@"getImg('%@')",str] completionHandler:^(id _Nullable data, NSError * _Nullable error) {
//
//        }];
//
//
//
//    }];
//
//}

- (void)dealloc {
    [self.wkWebview removeObserver:self forKeyPath:@"estimatedProgress"];
}


@end
