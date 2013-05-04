//
//  INFlickrAPI.m
//  Interesting
//
//  Created by Jesse Hammons on 4/21/13.
//  Copyright (c) 2013 Zaggle, Inc. All rights reserved.
//

#import "INFlickrAPI.h"

#import "INDispatch.h"
#import "INDiskCache.h"

#import "AFNetworking.h"

@implementation INFlickrAPI

+(NSString*)urlEscapeString:(NSString *)unencodedString
{
    CFStringRef originalStringRef = (__bridge_retained CFStringRef)unencodedString;
    NSString *s = (__bridge_transfer NSString *)CFURLCreateStringByAddingPercentEscapes(NULL,originalStringRef, NULL, NULL,kCFStringEncodingUTF8);
    CFRelease(originalStringRef);
    return s;
}


+(NSString*)addQueryStringToUrlString:(NSString *)urlString withDictionary:(NSDictionary *)dictionary
{
    NSMutableString *urlWithQuerystring = [[NSMutableString alloc] initWithString:urlString];
    
    for (id key in dictionary) {
        NSString *keyString = [key description];
        NSString *valueString = [[dictionary objectForKey:key] description];
        
        if ([urlWithQuerystring rangeOfString:@"?"].location == NSNotFound) {
            [urlWithQuerystring appendFormat:@"?%@=%@", [self urlEscapeString:keyString], [self urlEscapeString:valueString]];
        } else {
            [urlWithQuerystring appendFormat:@"&%@=%@", [self urlEscapeString:keyString], [self urlEscapeString:valueString]];
        }
    }
    return urlWithQuerystring;
}

+ (instancetype)shared
{
    static INFlickrAPI *singleton = nil;
    if (singleton == nil) {
        singleton = [[[self class] alloc] init];
    }
//    [INFlickrAPI shared].API_KEY = @"435c14c7bdc0148def43bf41534e81c7";
//    [INFlickrAPI shared].API_SECRET = @"000e2bd4a3d4ae32";
    singleton.API_KEY = @"435c14c7bdc0148def43bf41534e81c7";
    singleton.API_SECRET = @"000e2bd4a3d4ae32";
    return singleton;
}

- (void)flickrAPICallMethod:(NSString*)method arguments:(NSDictionary*)arguments completion:(void (^)(id JSON, NSError *error))completion
{
    ZG_ASSERT_IS_MAIN_THREAD();
    NSAssert(self.API_KEY, @"required");
    NSAssert(self.API_SECRET, @"required");
    NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                       @"json", @"format",
                                        @"1", @"nojsoncallback",
                                       nil];
    [parameters addEntriesFromDictionary:arguments];
    NSString *HOST = @"http://api.flickr.com";
    NSString *API = @"/services/rest";
    NSString *p1 = [NSString stringWithFormat:@"%@%@/?api_key=%@&method=%@", HOST, API, self.API_KEY, method];
    NSString *url = [[self class] addQueryStringToUrlString:p1 withDictionary:parameters];

    NSData *data = [[INDiskCache shared] dataForKey:url];
    if (data != nil) {
        [[INBlockDispatch shared] dispatchBackground:^{
            id JSON = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            completion(JSON, nil);
        }];
    }
    else {
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
        AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request
        success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON)
        {
            ZG_ASSERT_IS_BACKGROUND_THREAD();
            completion(JSON, nil);
            [[INDiskCache shared] setData:[NSJSONSerialization dataWithJSONObject:JSON options:0 error:nil] forKey:url];
            //NSLog(@"success %@", JSON);
        }
        failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON)
        {
            ZG_ASSERT_IS_BACKGROUND_THREAD();
            completion(nil, error);
            //NSLog(@"FAIL %@, %@", error, JSON);
        }];
        operation.successCallbackQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
        operation.failureCallbackQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
        [operation start];
    }
}

- (void)interestingPhotosForTags:(NSArray*)tags section:(NSInteger)section filterPredicate:(NSPredicate *)filterPredicate completion:(void (^)(NSArray *photos, NSError *error))completion
{
    ZG_ASSERT_IS_MAIN_THREAD();
    NSString *method = @"flickr.photos.search";
    NSDictionary *arguments = @{
                                @"tags" : [tags componentsJoinedByString:@","],
                                @"sort" : @"interestingness-desc",
                                @"content_type" : @"1", //photos only
                                @"page" : [NSString stringWithFormat:@"%d", section+1], //flickr api is 1-based
                                @"per_page" : @"100",
//                                @"is_commons" : @"1",
                                @"license" : @"1,2,3,4,5,6,7",
                                @"extras" : @"owner_name,license,original_format,tags,o_dims,url_z,url_n,url_c,url_o,url_b,url_t",
                                };
    if (filterPredicate == nil) {
        filterPredicate = [NSPredicate predicateWithBlock:^(id obj, NSDictionary *bindings){
            return (BOOL)([obj objectForKey:@"url_o"] != nil &&
                          [[obj objectForKey:@"width_o"] integerValue] >= 2048 &&
                          [[obj objectForKey:@"width_o"] integerValue] >= [[obj objectForKey:@"height_o"] integerValue]);
        }];
    }
    [self flickrAPICallMethod:method arguments:arguments completion:^(id JSON, NSError *error) {
        NSArray *photos = nil;
        if (error == nil) {
            photos = [[[JSON objectForKey:@"photos"] objectForKey:@"photo"] filteredArrayUsingPredicate:filterPredicate];
        }
        else {
            NSLog(@"error %@", error);
        }
        completion(photos, error);
    }];
}

//NSString *HOST = @"http://api.flickr.com";
//NSString *API = @"/services/rest";
//NSString *API_KEY = @"435c14c7bdc0148def43bf41534e81c7";
////    NSString *API_SECRET = @"000e2bd4a3d4ae32";
//NSString *method = @"flickr.photos.search";
//NSDictionary *arguments = @{
//                            @"tags" : @"exotic",
//                            @"sort" : @"interestingness-desc@",
//                            @"content_type" : @"1", //photos only
//                            @"format" : @"json",
//                            @"page" : @"1",
//                            @"nojsoncallback" : @"1",
//                            @"extras" : @"tags,o_dims,url_z,url_n",
//                            };
////    NSString *argStr = [[self class] addQueryStringToUrlString:@"" withDictionary:arguments];
////    NSString *url = [NSString stringWithFormat:@"%@%@/?api_key=%@&method=%@&%@%@'% (HOST, API, API_KEY, method, urllib.urlencode(params), _get_auth_url_suffix(method, auth, params))
////    NSString *authSuffix = @"";
////    NSString *url = [NSString stringWithFormat:@"%@%@/?api_key=%@&method=%@&%@%@", HOST, API, API_KEY, method, argStr, authSuffix];
//NSString *p1 = [NSString stringWithFormat:@"%@%@/?api_key=%@&method=%@", HOST, API, API_KEY, method];
//NSString *url = [[self class] addQueryStringToUrlString:p1 withDictionary:arguments];
//NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
//AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request

                                //                                @"extras" : @"tags,o_dims,url_a,url_b,url_c,url_d,url_e,url_f,url_g,url_h,url_i, url_j,url_k,url_m,url_n,url_o,url_p,url_q,url_r,url_s,url_t,url_u,url_v,url_w,url_x,url_y,url_z,url_A,url_B,url_C,url_D,url_E,url_F,url_G,url_H,url_I, url_J,url_K,url_M,url_N,url_O,url_P,url_Q,url_R,url_S,url_T,url_U,url_V,url_W,url_X,url_Y,url_Z",
@end
