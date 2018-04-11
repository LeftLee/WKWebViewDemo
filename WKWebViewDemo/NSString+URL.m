//
//  NSString+URL.m
//  WKWebViewDemo
//
//  Created by Azzan on 2018/4/10.
//  Copyright © 2018年 Azzan. All rights reserved.
//

#import "NSString+URL.h"

@implementation NSString (URL)

- (NSURL *)url{
#pragma clang diagnostic push
#pragma clang diagnostic ignored"-Wdeprecated-declarations"
    return [NSURL URLWithString:(NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)self, (CFStringRef)@"!$&'()*+,-./:;=?@_~%#[]", NULL,kCFStringEncodingUTF8))];
#pragma clang diagnostic pop
}

@end
