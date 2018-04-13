//
//  WKWebViewController.m
//  WKWebViewDemo
//
//  Created by Azzan on 2018/4/9.
//  Copyright © 2018年 Azzan. All rights reserved.
//

#import "WKWebViewController.h"
#import <WebKit/WebKit.h>
#import "MyCustomURLProtocol.h"
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
@property (nonatomic, strong) WKWebViewConfiguration *configuration;


@end

@implementation WKWebViewController

- (void)setNavBar{
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(right:)];
    
}

- (void)right:(id)sender
{
    NSLog(@"rightBarButtonItem");
    
    //OC调用JS
    NSString *str = @"OC调用JC并传值给HTML";
    [self.wkWebview evaluateJavaScript:[NSString stringWithFormat:@"select('%@')",str]
                     completionHandler:^(id _Nullable data, NSError * _Nullable error) {
                         NSLog(@"OC调用JS成功吗？");
                         
                     }];
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor groupTableViewBackgroundColor];
    
    [self setupWebview];
    [self setProgressView];
    [self setNavBar];
    
}

- (void)setProtocol{
    //注册
    [NSURLProtocol registerClass:[MyCustomURLProtocol class]];
    
    //实现拦截功能
    Class cls = NSClassFromString(@"WKBrowsingContextController");
    SEL sel = NSSelectorFromString(@"registerSchemeForCustomProtocol:");
    if ([(id)cls respondsToSelector:sel]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [(id)cls performSelector:sel withObject:@"myapp"];
#pragma clang diagnostic pop
    }
}

- (void)setupWebview{
    
    [self setProtocol];
    
    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    config.selectionGranularity = WKSelectionGranularityDynamic;
    config.allowsInlineMediaPlayback = YES;
    WKPreferences *preferences = [WKPreferences new];
    preferences.javaScriptEnabled = YES;//是否支持JavaScript
    preferences.javaScriptCanOpenWindowsAutomatically = YES;//不通过用户交互，是否可以打开窗口
    config.preferences = preferences;
    self.configuration = config;
    WKWebView *webview = [[WKWebView alloc] initWithFrame:CGRectMake(0, 64, KScreenWidth, KScreenHeight) configuration:config];
    self.wkWebview = webview;
    [self.view addSubview:webview];
    
    webview.navigationDelegate = self;
    webview.UIDelegate = self;
    [webview addObserver:self forKeyPath:@"estimatedProgress" options:NSKeyValueObservingOptionNew context:nil];
    [webview addObserver:self forKeyPath:@"title" options:NSKeyValueObservingOptionNew context:NULL];
    
    
    
    /* 加载服务器url的方法*/
//    NSURL *urlStr = [NSURL URLWithString:_url];
//    NSMutableURLRequest * request =[NSMutableURLRequest
//                                    requestWithURL:urlStr cachePolicy:NSURLRequestReloadRevalidatingCacheData timeoutInterval:10.0f];
//    [self.wkWebview loadRequest:request];
    
    /* 加载本地html文件的方法 */
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"test" ofType:@"html"];
    NSString *htmlString = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
    [webview loadHTMLString:htmlString baseURL:nil];
    
    [self setAddMessageHandler];//注册方法名
}


- (void)setProgressView{
    
    self.progressView = [[UIProgressView alloc] initWithFrame:CGRectMake(0,64,KScreenWidth, 2)];
    self.progressView.backgroundColor = [UIColor blueColor];
    //设置进度条的高度，下面这句代码表示进度条的宽度变为原来的1倍，高度变为原来的1.5倍.
    self.progressView.transform = CGAffineTransformMakeScale(1.0f, 1.5f);
    [self.view addSubview:self.progressView];
    
}

- (void)setUrl:(NSString *)url{
    _url = url;
}

#pragma mark- 注册方法名（桥名）
- (void)setAddMessageHandler{
    
    [_configuration.userContentController
     addScriptMessageHandler:self name:@"takePicturesByNative"];
    
    [_configuration.userContentController
     addScriptMessageHandler:self name:@"selectPictures"];
    
}

#pragma mark- WKScriptMessageHandler   (与OC交互)

-(void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message{
    
    NSLog(@"name--%@",message.name);
    
    NSLog(@"body--%@",message.body);
    
    if ([message.name isEqualToString:@"takePicturesByNative"]) {
        
        [self takePicturesByNative];
    }
    
    if ([message.name isEqualToString:@"selectPictures"]) {
        
        NSLog(@"1238909218236-098765432987653276");
        
    }
}



#pragma mark - WKNavigationDelegate （加载过程、页面跳转）
/* 页面开始加载 */
- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation{
    self.progressView.hidden = NO;
    self.progressView.transform = CGAffineTransformMakeScale(1.0f, 1.5f);
    [self.view bringSubviewToFront:self.progressView];
    
}

/* 开始返回内容 */
- (void)webView:(WKWebView *)webView didCommitNavigation:(WKNavigation *)navigation{
}

/* 页面加载完成 */
- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation{
    self.progressView.hidden = YES;
}

/* 页面加载失败 */
- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation{
    self.progressView.hidden = YES;

    
}

/* 在发送请求之前，决定是否跳转 */

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler{
    
    //允许跳转
    
    decisionHandler(WKNavigationActionPolicyAllow);
    
}

/* 在收到响应后，决定是否跳转 */

- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler{
    NSLog(@"在收到响应后，决定是否跳转%@",navigationResponse.response.URL.absoluteString);
    
    //允许跳转
    decisionHandler(WKNavigationResponsePolicyAllow);
    
    
}

#pragma mark
#pragma mark - WKUIDelegate

- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler{
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"提醒" message:message preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        completionHandler();
    }]];
    [self presentViewController:alertController animated:YES completion:nil];
    
}



- (void)takePicturesByNative{
    
    
    UIImagePickerController *vc = [[UIImagePickerController alloc] init];
    vc.delegate = self;
    vc.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    [self presentViewController:vc animated:YES completion:nil];
    
    
}
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    
    NSTimeInterval timeInterval = [[NSDate date]timeIntervalSince1970];
    NSString *timeString = [NSString stringWithFormat:@"%.0f",timeInterval];
    
    UIImage *image = [info  objectForKey:UIImagePickerControllerOriginalImage];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES);
    NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.png",timeString]];  //保存到本地
    [UIImagePNGRepresentation(image) writeToFile:filePath atomically:YES];
    NSString *str = [NSString stringWithFormat:@"myapp://%@",filePath];
    [picker dismissViewControllerAnimated:YES completion:^{
        
        // oc 调用js 并且传递图片路径参数
        [self.wkWebview evaluateJavaScript:[NSString stringWithFormat:@"getImg('%@')",str] completionHandler:^(id _Nullable data, NSError * _Nullable error) {
            
        }];
        
    }];
}


#pragma mark - KVO反馈
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    
    if ([keyPath isEqualToString:@"estimatedProgress"]) {
        self.progressView.progress = self.wkWebview.estimatedProgress;
        if (self.progressView.progress == 1) {
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

- (void)dealloc {
    
    [self.wkWebview removeObserver:self forKeyPath:@"estimatedProgress"];
    [[_wkWebview configuration].userContentController removeScriptMessageHandlerForName:@"takePicturesByNative"];
    [_configuration.userContentController removeScriptMessageHandlerForName:@"selectPictures"];
}


@end
