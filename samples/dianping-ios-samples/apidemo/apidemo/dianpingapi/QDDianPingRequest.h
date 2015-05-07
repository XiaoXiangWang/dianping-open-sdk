//
//  DPRequest.h
//  apidemo
//
//  Created by ZhouHui on 13-1-28.
//  Copyright (c) 2013年 Dianping. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^QDDianPingRequestCompletionBlock)(NSHTTPURLResponse* response,id data,BOOL flag);
typedef void(^QDDianPingRequestFailureBlock)(NSError* error);
@interface QDDianPingRequest : NSObject

@property (nonatomic, strong) NSString *url;
@property (nonatomic, strong) NSDictionary *params;

+ (QDDianPingRequest *)requestWithURL:(NSString *)url
					   params:(NSDictionary *)params;

@property (nonatomic,copy) QDDianPingRequestCompletionBlock completionBlock;

@property (nonatomic,copy) QDDianPingRequestFailureBlock failureBlock;

- (void)connect;
- (void)disconnect;
- (void)setDelegateQueue:(NSOperationQueue*)queue;
@end

