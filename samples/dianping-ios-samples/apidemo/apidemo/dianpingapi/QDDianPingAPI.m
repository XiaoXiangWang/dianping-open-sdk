//
//  DPAPI.m
//  apidemo
//
//  Created by ZhouHui on 13-1-28.
//  Copyright (c) 2013年 Dianping. All rights reserved.
//

#import "QDDianPingAPI.h"
#import "QDDianPingAPIDefines.h"


#if !__has_feature(objc_arc)
#error QDDianPingAPI must be built with ARC.
// You can turn on ARC for files by adding -fobjc-arc to the build phase for each of its files.
#endif

@interface QDDianPingAPI()
@property(nonatomic,strong) NSOperationQueue* operationQueue;
@end


@implementation QDDianPingAPI

- (id)init {
	self = [super init];
    if (self) {
        self.operationQueue = [[NSOperationQueue alloc] init];
        self.operationQueue.name = @"com.qdate.DianPingAPI";
    }
    return self;
}

+(instancetype)_shareInstance{
    static QDDianPingAPI* __dianPingAPI = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __dianPingAPI = [QDDianPingAPI new];
    });
    return __dianPingAPI;
}

- (QDDianPingRequest*)requestWithURL:(NSString *)url
                              params:(NSDictionary *)params
                     completionBlock:(QDDianPingRequestCompletionBlock)completionBlock
                        failureBlock:(QDDianPingRequestFailureBlock)failureBlock{
	QDDianPingRequest *_request = [QDDianPingRequest requestWithURL:url
                                                             params:params];
    _request.completionBlock = completionBlock;
    _request.failureBlock = failureBlock;
    [_request setDelegateQueue:self.operationQueue];
	[_request connect];
	return _request;
}

- (QDDianPingRequest *)requestWithURL:(NSString *)url
                          queryString:(NSString *)queryString
                      completionBlock:(QDDianPingRequestCompletionBlock)completionBlock
                         failureBlock:(QDDianPingRequestFailureBlock)failureBlock{
	return [self requestWithURL:[NSString stringWithFormat:@"%@?%@", url, queryString]
                         params:nil
                completionBlock:completionBlock
                   failureBlock:failureBlock];
}

+(QDDianPingRequest *)QDDianPingRequestWithURL:(NSString *)url
                                        params:(NSDictionary *)params
                               completionBlock:(QDDianPingRequestCompletionBlock)completionBlock
                                  failureBlock:(QDDianPingRequestFailureBlock)failureBlock{
    return [[[self class] _shareInstance] requestWithURL:url
                                                  params:params
                                         completionBlock:completionBlock
                                            failureBlock:failureBlock];

}
+(QDDianPingRequest *)QDDianPingRequestWithURL:(NSString *)url
                                   queryString:(NSString *)queryString
                               completionBlock:(QDDianPingRequestCompletionBlock)completionBlock
                                  failureBlock:(QDDianPingRequestFailureBlock)failureBlock{
    return [[[self class] _shareInstance] requestWithURL:url
                                             queryString:queryString
                                         completionBlock:completionBlock
                                            failureBlock:failureBlock];
}

@end
