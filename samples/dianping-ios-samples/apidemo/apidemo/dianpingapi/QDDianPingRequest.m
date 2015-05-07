//
//  DPRequest.m
//  apidemo
//
//  Created by ZhouHui on 13-1-28.
//  Copyright (c) 2013年 Dianping. All rights reserved.
//

#import "QDDianPingRequest.h"
#import "QDDianPingAPIDefines.h"
#import "QDDianPingAPI.h"
#import <CommonCrypto/CommonDigest.h>

#define kDPRequestTimeOutInterval   30.0
#define kDPRequestStringBoundary    @"9536429F8AAB441bA4055A74B72B57DE"

#if !__has_feature(objc_arc)
#error QDDianPingRequest must be built with ARC.
// You can turn on ARC for files by adding -fobjc-arc to the build phase for each of its files.
#endif

@interface QDDianPingRequest () <NSURLConnectionDelegate>

@property(nonatomic,strong) NSURLConnection* connection;
@property(nonatomic,strong) NSMutableData* responseData;
@property(nonatomic,strong) NSHTTPURLResponse* httpResponse;

@end

@implementation QDDianPingRequest

#pragma mark - Private Methods

- (void)appendUTF8Body:(NSMutableData *)body dataString:(NSString *)dataString {
    [body appendData:[dataString dataUsingEncoding:NSUTF8StringEncoding]];
}

+ (NSDictionary *)parseQueryString:(NSString *)query {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithCapacity:6];
    NSArray *pairs = [query componentsSeparatedByString:@"&"];
    
    for (NSString *pair in pairs) {
        NSArray *elements = [pair componentsSeparatedByString:@"="];
		
		if ([elements count] <= 1) {
			return nil;
		}
		
        NSString *key = [[elements objectAtIndex:0] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSString *val = [[elements objectAtIndex:1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
        [dict setObject:val forKey:key];
    }
    return dict;
}

- (NSMutableData *)postBodyHasRawData:(BOOL*)hasRawData
{
    NSString *bodyPrefixString = [NSString stringWithFormat:@"--%@\r\n", kDPRequestStringBoundary];
    NSString *bodySuffixString = [NSString stringWithFormat:@"\r\n--%@--\r\n", kDPRequestStringBoundary];
    
    NSMutableDictionary *dataDictionary = [NSMutableDictionary dictionary];
    
    NSMutableData *body = [NSMutableData data];
    [self appendUTF8Body:body dataString:bodyPrefixString];
    
    for (id key in [self.params keyEnumerator])
    {
        if (([[self.params valueForKey:key] isKindOfClass:[UIImage class]]) || ([[self.params valueForKey:key] isKindOfClass:[NSData class]]))
        {
            [dataDictionary setObject:[self.params valueForKey:key] forKey:key];
            continue;
        }
        
        [self appendUTF8Body:body dataString:[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n%@\r\n", key, [self.params valueForKey:key]]];
        [self appendUTF8Body:body dataString:bodyPrefixString];
    }
    
    if ([dataDictionary count] > 0)
    {
        *hasRawData = YES;
        for (id key in dataDictionary)
        {
            NSObject *dataParam = [dataDictionary valueForKey:key];
            
            if ([dataParam isKindOfClass:[UIImage class]])
            {
                NSData* imageData = UIImagePNGRepresentation((UIImage *)dataParam);
                [self appendUTF8Body:body dataString:[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"file\"\r\n", key]];
                [self appendUTF8Body:body dataString:@"Content-Type: image/png\r\nContent-Transfer-Encoding: binary\r\n\r\n"];
                [body appendData:imageData];
            }
            else if ([dataParam isKindOfClass:[NSData class]])
            {
                [self appendUTF8Body:body dataString:[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"file\"\r\n", key]];
                [self appendUTF8Body:body dataString:@"Content-Type: content/unknown\r\nContent-Transfer-Encoding: binary\r\n\r\n"];
                [body appendData:(NSData*)dataParam];
            }
            [self appendUTF8Body:body dataString:bodySuffixString];
        }
    }
    
    return body;
}

- (void)_handleResponseData:(NSData *)data
{
    NSError* error  = nil;
    id result = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    if (error) {
		[self _failedWithError:error];
	} else {
		NSString *status = 0;
        if([result isKindOfClass:[NSDictionary class]]){
            status = [result objectForKey:@"status"];
        }
		
		if ([status isEqualToString:@"OK"]) {
            [self _completeWithHTTPResponse:self.httpResponse serializationObject:result];
        } else  if([status isEqualToString:@"ERROR"]){
            NSDictionary* errorDict = [result objectForKey:@"error"];
            long errorCode = [errorDict[@"errorCode"] longValue];
            NSString* errorReson = errorDict[@"errorMessage"];
            error = [NSError errorWithDomain:QDDianPingAPIErrorDomain
                                        code:errorCode
                                    userInfo:@{@"errorReson":errorReson}];
            [self _failedWithError:error];
        }else{
            NSError* error = [NSError errorWithDomain:QDDianPingAPIErrorDomain
                                                 code:-1
                                             userInfo:@{@"errorReson":@"未知错误"}];
            [self _failedWithError:error];
        }
	}
}

- (id)errorWithCode:(NSInteger)code userInfo:(NSDictionary *)userInfo
{
    return [NSError errorWithDomain:QDDianPingAPIErrorDomain code:code userInfo:userInfo];
}


-(void)_completeWithHTTPResponse:(NSHTTPURLResponse*)response serializationObject:(id)serializationObject{
    if (self.completionBlock) {
        self.completionBlock(response,serializationObject,YES);
    }
}
- (void)_failedWithError:(NSError *)error{
    if (self.failureBlock) {
        self.failureBlock(error);
    }
}

#pragma mark - Public Methods

+ (NSString *)getParamValueFromUrl:(NSString*)url paramName:(NSString *)paramName
{
    if (![paramName hasSuffix:@"="])
    {
        paramName = [NSString stringWithFormat:@"%@=", paramName];
    }
    
    NSString * str = nil;
    NSRange start = [url rangeOfString:paramName];
    if (start.location != NSNotFound)
    {
        // confirm that the parameter is not a partial name match
        unichar c = '?';
        if (start.location != 0)
        {
            c = [url characterAtIndex:start.location - 1];
        }
        if (c == '?' || c == '&' || c == '#')
        {
            NSRange end = [[url substringFromIndex:start.location+start.length] rangeOfString:@"&"];
            NSUInteger offset = start.location+start.length;
            str = end.location == NSNotFound ?
            [url substringFromIndex:offset] :
            [url substringWithRange:NSMakeRange(offset, end.location)];
            str = [str stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        }
    }
    return str;
}

+ (NSString *)_serializeURL:(NSString *)baseURL params:(NSDictionary *)params
{
	NSURL* parsedURL = [NSURL URLWithString:[baseURL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
	NSMutableDictionary *paramsDic = [NSMutableDictionary dictionaryWithDictionary:[self parseQueryString:[parsedURL query]]];
	if (params) {
		[paramsDic setValuesForKeysWithDictionary:params];
	}
	
	NSMutableString *signString = [NSMutableString stringWithString:QDDianPingAPIAppKey];
	NSMutableString *paramsString = [NSMutableString stringWithFormat:@"appkey=%@", QDDianPingAPIAppKey];
	NSArray *sortedKeys = [[paramsDic allKeys] sortedArrayUsingSelector: @selector(compare:)];
	for (NSString *key in sortedKeys) {
		[signString appendFormat:@"%@%@", key, [paramsDic objectForKey:key]];
		[paramsString appendFormat:@"&%@=%@", key, [paramsDic objectForKey:key]];
	}
	[signString appendString:QDDianPingAPIAppSecret];
	unsigned char digest[CC_SHA1_DIGEST_LENGTH];
	NSData *stringBytes = [signString dataUsingEncoding: NSUTF8StringEncoding];
	if (CC_SHA1([stringBytes bytes], (CC_LONG)[stringBytes length], digest)) {
		/* SHA-1 hash has been calculated and stored in 'digest'. */
		NSMutableString *digestString = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH];
		for (int i=0; i<CC_SHA1_DIGEST_LENGTH; i++) {
			unsigned char aChar = digest[i];
			[digestString appendFormat:@"%02X", aChar];
		}
		[paramsString appendFormat:@"&sign=%@", [digestString uppercaseString]];
		return [NSString stringWithFormat:@"%@://%@%@?%@", [parsedURL scheme], [parsedURL host], [parsedURL path], [paramsString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
	} else {
		return nil;
	}
}

+ (QDDianPingRequest *)requestWithURL:(NSString *)url
                              params:(NSDictionary *)params{
    QDDianPingRequest *request = [[QDDianPingRequest alloc] init];
    request.url = url;
    request.params = params;
    return request;
}

- (void)connect
{
    NSString* urlString = [[self class] _serializeURL:_url params:_params];
    NSMutableURLRequest* request =
    [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]
                            cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                        timeoutInterval:kDPRequestTimeOutInterval];
    
    [request setHTTPMethod:@"GET"];
    _connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES];
}

- (void)disconnect
{
    [self.connection cancel];
    self.responseData = nil;
    self.connection = nil;
    self.httpResponse = nil;
}
-(void)setDelegateQueue:(NSOperationQueue*)queue{
    [_connection setDelegateQueue:queue];
}

#pragma mark - NSURLConnection Delegate Methods
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response{
	self.responseData = [[NSMutableData alloc] init];
    if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
        self.httpResponse = (NSHTTPURLResponse*)response;
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data{
	[self.responseData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)theConnection{
	[self _handleResponseData:_responseData];
    self.httpResponse =nil;
	self.responseData = nil;
	self.connection = nil;
}

- (void)connection:(NSURLConnection *)theConnection didFailWithError:(NSError *)error{
	[self _failedWithError:error];
	self.responseData = nil;
	self.connection = nil;
    self.httpResponse = nil;
}


#pragma mark - Life Circle
- (void)dealloc{
    NSLog(@"dealloc:[%s,%s]",__FILE__,__FUNCTION__);
    [self disconnect];
}

@end



