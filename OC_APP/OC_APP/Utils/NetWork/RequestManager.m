//
//  RequestManager.m
//  OC_APP
//
//  Created by xingl on 2017/8/16.
//  Copyright © 2017年 兴林. All rights reserved.
//

/*！定义请求类型的枚举 */
typedef NS_ENUM(NSUInteger, HttpRequestType) {
    /*! get请求 */
    GET = 0,
    /*! post请求 */
    POST,
    /*! put请求 */
    PUT,
    /*! delete请求 */
    DELETE
};

#import "RequestManager.h"
#import <AFNetworking.h>
#import <AFNetworkActivityIndicatorManager.h>
#import "RequestManagerCache.h"

/*! 系统相册 */
#import <Photos/Photos.h>



@interface RequestManager ()

@property(nonatomic, strong) AFHTTPSessionManager *sessionManager;

@end

@implementation RequestManager


+ (instancetype)sharedRequestManager {
    /*! 为单例对象创建的静态实例，置为nil，因为对象的唯一性，必须是static类型 */
    static id sharedRequestManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedRequestManager = [[super allocWithZone:NULL] init];
    });
    return sharedRequestManager;
}

+ (void)initialize {
    
    [self setupRequestManager];
}
+ (void)setupRequestManager {
    [RequestManager sharedRequestManager].sessionManager = [AFHTTPSessionManager manager];
    
    [RequestManager sharedRequestManager].requestSerializer = HttpRequestSerializerJSON;
    [RequestManager sharedRequestManager].responseSerializer = HttpResponseSerializerJSON;
    
    /*! 设置请求超时时间，默认：30秒 */
    [RequestManager sharedRequestManager].timeoutInterval = 30;
    /*! 打开状态栏的等待菊花 */
    [AFNetworkActivityIndicatorManager sharedManager].enabled = YES;
    /*! 设置返回数据类型为 json, 分别设置请求以及相应的序列化器 */
    /*!
     根据服务器的设定不同还可以设置：
     json：[AFJSONResponseSerializer serializer](常用)
     http：[AFHTTPResponseSerializer serializer]
     */
    //    AFJSONResponseSerializer *response = [AFJSONResponseSerializer serializer];
    //    /*! 这里是去掉了键值对里空对象的键值 */
    ////    response.removesKeysWithNullValues = YES;
    //    NetManagerShare.sessionManager.responseSerializer = response;
    
    /* 设置请求服务器数类型式为 json */
    /*!
     根据服务器的设定不同还可以设置：
     json：[AFJSONRequestSerializer serializer](常用)
     http：[AFHTTPRequestSerializer serializer]
     */
    //    AFJSONRequestSerializer *request = [AFJSONRequestSerializer serializer];
    //    NetManagerShare.sessionManager.requestSerializer = request;
    /*! 设置apikey ------类似于自己应用中的tokken---此处仅仅作为测试使用*/
    //        [manager.requestSerializer setValue:apikey forHTTPHeaderField:@"apikey"];
    
    /*! 复杂的参数类型 需要使用json传值-设置请求内容的类型*/
    //        [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    /*! 设置响应数据的基本类型 */
    [RequestManager sharedRequestManager].sessionManager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/json", @"text/javascript", @"text/html", @"text/css", @"text/xml", @"text/plain", @"application/javascript", @"image/*", nil];
    
    // 配置自建证书的Https请求
    [self setupSecurityPolicy];
}
/**
 配置自建证书的Https请求，只需要将CA证书文件放入根目录就行
 */
+ (void)setupSecurityPolicy
{
    //    NSData *cerData = [NSData dataWithContentsOfFile:cerPath];
    NSSet <NSData *> *cerSet = [AFSecurityPolicy certificatesInBundle:[NSBundle mainBundle]];
    
    if (cerSet.count == 0) {
        /*!
         采用默认的defaultPolicy就可以了. AFN默认的securityPolicy就是它, 不必另写代码. AFSecurityPolicy类中会调用苹果security.framework的机制去自行验证本次请求服务端放回的证书是否是经过正规签名.
         */
        AFSecurityPolicy *securityPolicy = [AFSecurityPolicy defaultPolicy];
        securityPolicy.allowInvalidCertificates = YES;
        securityPolicy.validatesDomainName = NO;
        [RequestManager sharedRequestManager].sessionManager.securityPolicy = securityPolicy;
    } else {
        /*! 自定义的CA证书配置如下： */
        /*! 自定义security policy, 先前确保你的自定义CA证书已放入工程Bundle */
        /*!
         https://api.github.com网址的证书实际上是正规CADigiCert签发的, 这里把Charles的CA根证书导入系统并设为信任后, 把Charles设为该网址的SSL Proxy (相当于"中间人"), 这样通过代理访问服务器返回将是由Charles伪CA签发的证书.
         */
        // 使用证书验证模式
        AFSecurityPolicy *securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate withPinnedCertificates:cerSet];
        // 如果需要验证自建证书(无效证书)，需要设置为YES
        securityPolicy.allowInvalidCertificates = YES;
        // 是否需要验证域名，默认为YES
        //    securityPolicy.pinnedCertificates = [[NSSet alloc] initWithObjects:cerData, nil];
        
        [RequestManager sharedRequestManager].sessionManager.securityPolicy = securityPolicy;
        
        
        /*! 如果服务端使用的是正规CA签发的证书, 那么以下几行就可去掉: */
        //            NSSet <NSData *> *cerSet = [AFSecurityPolicy certificatesInBundle:[NSBundle mainBundle]];
        //            AFSecurityPolicy *policy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate withPinnedCertificates:cerSet];
        //            policy.allowInvalidCertificates = YES;
        //            NetManagerShare.sessionManager.securityPolicy = policy;
    }
}

#pragma mark - request

+ (NSURLSessionTask *)GET:(NSString *)urlString
              isNeedCache:(BOOL)isNeedCache
               parameters:(NSDictionary *)parameters
             successBlock:(ResponseSuccess)successBlock
             failureBlock:(ResponseFail)failureBlock
                 progress:(DownloadProgress)progress {
    
    return [self request:GET
             isNeedCache:isNeedCache
               urlString:urlString
              parameters:parameters
            successBlock:successBlock
            failureBlock:failureBlock
                progress:progress];
}

+ (NSURLSessionTask *)POST:(NSString *)urlString
               isNeedCache:(BOOL)isNeedCache
                parameters:(NSDictionary *)parameters
              successBlock:(ResponseSuccess)successBlock
              failureBlock:(ResponseFail)failureBlock
                  progress:(DownloadProgress)progress {
    
    return [self request:POST
             isNeedCache:isNeedCache
               urlString:urlString
              parameters:parameters
            successBlock:successBlock
            failureBlock:failureBlock
                progress:progress];
}

+ (NSURLSessionTask *)PUT:(NSString *)urlString
               parameters:(NSDictionary *)parameters
             successBlock:(ResponseSuccess)successBlock
             failureBlock:(ResponseFail)failureBlock
                 progress:(DownloadProgress)progress {
    return [self request:PUT
             isNeedCache:NO
               urlString:urlString
              parameters:parameters
            successBlock:successBlock
            failureBlock:failureBlock
                progress:progress];
}

+ (NSURLSessionTask *)DELETE:(NSString *)urlString
                  parameters:(NSDictionary *)parameters
                successBlock:(ResponseSuccess)successBlock
                failureBlock:(ResponseFail)failureBlock
                    progress:(DownloadProgress)progress {
    return [self request:DELETE
             isNeedCache:NO
               urlString:urlString
              parameters:parameters
            successBlock:successBlock
            failureBlock:failureBlock
                progress:progress];
}

#define XD_ERROR_IMFORMATION @"网络出现错误，请检查网络连接"

#define XD_ERROR [NSError errorWithDomain:@"com.caixindong.XDNetworking.ErrorDomain" code:-999 userInfo:@{ NSLocalizedDescriptionKey:XD_ERROR_IMFORMATION}]



#pragma mark - 网络请求的类方法 --- get / post / put / delete
/*!
 *  网络请求的实例方法
 *
 *  @param type         get / post / put / delete
 *  @param isNeedCache  是否需要缓存，只有 get / post 请求有缓存配置
 *  @param urlString    请求的地址
 *  @param parameters    请求的参数
 *  @param successBlock 请求成功的回调
 *  @param failureBlock 请求失败的回调
 *  @param progress 进度
 */
+ (NSURLSessionTask *)request:(HttpRequestType)type
                  isNeedCache:(BOOL)isNeedCache
                    urlString:(NSString *)urlString
                   parameters:(NSDictionary *)parameters
                 successBlock:(ResponseSuccess)successBlock
                 failureBlock:(ResponseFail)failureBlock
                     progress:(DownloadProgress)progress {
 

//    [RequestManager startNetWorkMonitoringWithBlock:^(NetworkStatus status) {
//        if (status == NetworkStatusNotReachable) {
//            if (failureBlock) failureBlock(XD_ERROR);
//            return nil;
//        }
//    }];
    
    WeakSelf(self);
   
    urlString = XL_FilterString(urlString);
    
    if ([urlString respondsToSelector:@selector(stringByAddingPercentEncodingWithAllowedCharacters:)]) {
        
        urlString = [urlString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    }
    else{
        
        urlString = [urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    }
    
    NSString *requestType;
    switch (type) {
        case 0:
            requestType = @"GET";
            break;
        case 1:
            requestType = @"POST";
            break;
        case 2:
            requestType = @"PUT";
            break;
        case 3:
            requestType = @"DELETE";
            break;
            
        default:
            break;
    }
    
    AFHTTPSessionManager *scc = [RequestManager sharedRequestManager].sessionManager;
    AFHTTPResponseSerializer *scc2 = scc.responseSerializer;
    AFHTTPRequestSerializer *scc3 = scc.requestSerializer;
    NSTimeInterval timeoutInterval = [RequestManager sharedRequestManager].timeoutInterval;
    
    NSString *isCache = isNeedCache ? @"开启":@"关闭";
    CGFloat allCacheSize = [RequestManagerCache getAllHttpCacheSize];
    
    NSLog(@"\n******************** 请求参数 ***************************");
    NSLog(@"\n请求头: %@\n超时时间设置：%.1f 秒【默认：30秒】\nAFHTTPResponseSerializer：%@【默认：AFJSONResponseSerializer】\nAFHTTPRequestSerializer：%@【默认：AFJSONRequestSerializer】\n请求方式: %@\n请求URL: %@\n请求param: %@\n是否启用缓存：%@【默认：开启】\n目前总缓存大小：%.6fM\n", [RequestManager sharedRequestManager].sessionManager.requestSerializer.HTTPRequestHeaders, timeoutInterval, scc2, scc3, requestType, urlString, parameters, isCache, allCacheSize);
    NSLog(@"\n********************************************************");
    
    
    
    NSURLSessionTask *sessionTask = nil;
    // 读取缓存
    id responseCacheData = [RequestManagerCache httpCacheWithUrlString:urlString parameters:parameters];
    
    if (isNeedCache && responseCacheData != nil) {
        if (successBlock) {
            successBlock(responseCacheData);
        }
        NSLog(@"取用缓存数据成功： *** %@", responseCacheData);
        
//        [[weakself tasks] removeObject:sessionTask];
//        return nil;
    }
    
    if (type == GET) {
        sessionTask = [[RequestManager sharedRequestManager].sessionManager GET:urlString parameters:parameters  progress:^(NSProgress * _Nonnull downloadProgress) {
            
        } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            
            if (successBlock) {
                successBlock(responseObject);
            }
            // 对数据进行异步缓存
            [RequestManagerCache setHttpCache:responseObject urlString:urlString parameters:parameters];
            [[weakself tasks] removeObject:sessionTask];
            
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            
            if (failureBlock) {
                failureBlock(error);
            }
            [[weakself tasks] removeObject:sessionTask];
            
        }];
        
    }
    else if (type == POST) {
        sessionTask = [[RequestManager sharedRequestManager].sessionManager POST:urlString parameters:parameters progress:^(NSProgress * _Nonnull uploadProgress) {
            
        } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            
            if (successBlock) {
                successBlock(responseObject);
            }
            NSLog(@"post请求数据成功： *** %@", responseObject);
            
            // 对数据进行异步缓存
            [RequestManagerCache setHttpCache:responseObject urlString:urlString parameters:parameters];
            [[weakself tasks] removeObject:sessionTask];
            
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            
            if (failureBlock) {
                failureBlock(error);
                NSLog(@"错误信息：%@",error);
            }
            [[weakself tasks] removeObject:sessionTask];
            
        }];
    }
    else if (type == PUT) {
        sessionTask = [[RequestManager sharedRequestManager].sessionManager PUT:urlString parameters:parameters success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            
            if (successBlock){
                successBlock(responseObject);
            }
            
            [[weakself tasks] removeObject:sessionTask];
            
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            
            if (failureBlock) {
                failureBlock(error);
            }
            [[weakself tasks] removeObject:sessionTask];
            
        }];
    }
    else if (type == DELETE) {
        sessionTask = [[RequestManager sharedRequestManager].sessionManager DELETE:urlString parameters:parameters success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            if (successBlock) {
                successBlock(responseObject);
            }
            
            [[weakself tasks] removeObject:sessionTask];
            
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            
            if (failureBlock) {
                failureBlock(error);
            }
            [[weakself tasks] removeObject:sessionTask];
            
        }];
    }
    
    if (sessionTask) {
        [[weakself tasks] addObject:sessionTask];
    }
    
    return sessionTask;
}


+ (NSURLSessionTask *)uploadImage:(NSString *)urlString
                       parameters:(NSDictionary *)parameters
                       imageArray:(NSArray *)imageArray
                        fileNames:(NSArray<NSString *> *)fileNames
                        imageType:(NSString *)imageType
                       imageScale:(CGFloat)imageScale
                     successBlock:(ResponseSuccess)successBlock
                      failurBlock:(ResponseFail)failureBlock
                   uploadProgress:(UploadProgress)progress {
    
    WeakSelf(self);
    
    urlString = XL_FilterString(urlString);
    
    if ([urlString respondsToSelector:@selector(stringByAddingPercentEncodingWithAllowedCharacters:)]) {
        
        urlString = [urlString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    }
    else{
        
        urlString = [urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    }
    
    NSLog(@"******************** 请求参数 ***************************");
    NSLog(@"请求头: %@\n请求方式: %@\n请求URL: %@\n请求param: %@\n\n",[RequestManager sharedRequestManager].sessionManager.requestSerializer.HTTPRequestHeaders, @"POST",urlString, parameters);
    NSLog(@"********************************************************");
    
    NSURLSessionTask *sessionTask = nil;
    sessionTask = [[RequestManager sharedRequestManager].sessionManager POST:urlString parameters:parameters constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        
        /*! 出于性能考虑,将上传图片进行压缩 */
        [imageArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            
            /*! image的压缩方法 */
            UIImage *resizedImage;
            /*! 此处是使用原生系统相册 */
            if ([obj isKindOfClass:[PHAsset class]]) {
                PHAsset *asset = (PHAsset *)obj;
                PHCachingImageManager *imageManager = [[PHCachingImageManager alloc] init];
                [imageManager requestImageForAsset:asset targetSize:CGSizeMake(asset.pixelWidth , asset.pixelHeight) contentMode:PHImageContentModeAspectFit options:nil resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
                    
                    NSLog(@" width:%f height:%f",result.size.width,result.size.height);
                    
                    [self uploadImageWithFormData:formData resizedImage:result imageType:imageType imageScale:imageScale fileNames:fileNames index:idx];
                }];
            } else {
                /*! 此处是使用其他第三方相册，可以自由定制压缩方法 */
                resizedImage = obj;
                [self uploadImageWithFormData:formData resizedImage:resizedImage imageType:imageType imageScale:imageScale fileNames:fileNames index:idx];
            }
            
        }];
        
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        
        NSLog(@"上传进度--%lld,总进度---%lld",uploadProgress.completedUnitCount,uploadProgress.totalUnitCount);
        
        if (progress) {
            progress(uploadProgress.completedUnitCount, uploadProgress.totalUnitCount);
        }
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        NSLog(@"上传图片成功 = %@",responseObject);
        if (successBlock) {
            successBlock(responseObject);
        }
        
        [[weakself tasks] removeObject:sessionTask];
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        if (failureBlock) {
            failureBlock(error);
        }
        [[weakself tasks] removeObject:sessionTask];
    }];
    
    if (sessionTask) {
        [[self tasks] addObject:sessionTask];
    }
    
    return sessionTask;
}

+ (void)uploadVideo:(NSString *)urlString
         parameters:(NSDictionary *)parameters
          videoPath:(NSString *)videoPath
       successBlock:(ResponseSuccess)successBlock
       failureBlock:(ResponseFail)failureBlock
     uploadProgress:(UploadProgress)progress {
    
    /*! 获得视频资源 */
    AVURLAsset *avAsset = [AVURLAsset URLAssetWithURL:[NSURL URLWithString:videoPath]  options:nil];
    
    /*! 压缩 */
    
    //    NSString *const AVAssetExportPreset640x480;
    //    NSString *const AVAssetExportPreset960x540;
    //    NSString *const AVAssetExportPreset1280x720;
    //    NSString *const AVAssetExportPreset1920x1080;
    //    NSString *const AVAssetExportPreset3840x2160;
    
    /*! 创建日期格式化器 */
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    
    [formatter setDateFormat:@"yyyy-MM-dd-HH:mm:ss"];
    
    /*! 转化后直接写入Library---caches */
    NSString *videoWritePath = [NSString stringWithFormat:@"output-%@.mp4",[formatter stringFromDate:[NSDate date]]];
    NSString *outfilePath = [NSHomeDirectory() stringByAppendingFormat:@"/Documents/%@", videoWritePath];
    
    AVAssetExportSession *avAssetExport = [[AVAssetExportSession alloc] initWithAsset:avAsset presetName:AVAssetExportPresetMediumQuality];
    
    avAssetExport.outputURL = [NSURL fileURLWithPath:outfilePath];
    avAssetExport.outputFileType =  AVFileTypeMPEG4;
    
    [avAssetExport exportAsynchronouslyWithCompletionHandler:^{
        switch ([avAssetExport status]) {
            case AVAssetExportSessionStatusCompleted:
            {
                [[RequestManager sharedRequestManager].sessionManager POST:urlString parameters:parameters constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
                    
                    NSURL *filePathURL2 = [NSURL URLWithString:[NSString stringWithFormat:@"file://%@", outfilePath]];
                    // 获得沙盒中的视频内容
                    [formData appendPartWithFileURL:filePathURL2 name:@"video" fileName:outfilePath mimeType:@"application/octet-stream" error:nil];
                    
                } progress:^(NSProgress * _Nonnull uploadProgress) {
                    NSLog(@"上传进度--%lld,总进度---%lld",uploadProgress.completedUnitCount,uploadProgress.totalUnitCount);
                    if (progress) {
                        progress(uploadProgress.completedUnitCount, uploadProgress.totalUnitCount);
                    }
                } success:^(NSURLSessionDataTask * _Nonnull task, NSDictionary *  _Nullable responseObject) {
                    NSLog(@"上传视频成功 = %@",responseObject);
                    if (successBlock) {
                        successBlock(responseObject);
                    }
                } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                    NSLog(@"上传视频失败 = %@", error);
                    if (failureBlock) {
                        failureBlock(error);
                    }
                }];
                break;
            }
            default:
                break;
        }
    }];
}

+ (NSURLSessionTask *)uploadFile:(NSString *)urlString
                      parameters:(NSDictionary *)parameters
                        fileName:(NSString *)fileName
                        filePath:(NSString *)filePath
                    successBlock:(ResponseSuccess)successBlock
                    failureBlock:(ResponseFail)failureBlock
             UploadProgressBlock:(UploadProgress)UploadProgressBlock {
    
    if (urlString == nil)
    {
        return nil;
    }
    
    NSLog(@"******************** 请求参数 ***************************");
    NSLog(@"请求头: %@\n请求方式: %@\n请求URL: %@\n请求param: %@\n\n",[RequestManager sharedRequestManager].sessionManager.requestSerializer.HTTPRequestHeaders, @"uploadFile", urlString, parameters);
    NSLog(@"******************************************************");
    
    NSURLSessionTask *sessionTask = nil;
    sessionTask = [[RequestManager sharedRequestManager].sessionManager POST:urlString parameters:parameters constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        
        NSError *error = nil;
        [formData appendPartWithFileURL:[NSURL URLWithString:filePath] name:fileName error:&error];
        if (failureBlock && error) {
            failureBlock(error);
        }
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        
        // 上传进度
        dispatch_async(dispatch_get_main_queue(), ^{
            if (UploadProgressBlock) {
                UploadProgressBlock(uploadProgress.completedUnitCount, uploadProgress.totalUnitCount);
            }
        });
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        [[self tasks] removeObject:sessionTask];
        if (successBlock) {
            successBlock(responseObject);
        }
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        [[self tasks] removeObject:sessionTask];
        if (failureBlock) {
            failureBlock(error);
        }
    }];
    
    /*! 开始启动任务 */
    [sessionTask resume];
    
    if (sessionTask) {
        [[self tasks] addObject:sessionTask];
    }
    return sessionTask;
}

+ (NSURLSessionTask *)downLoadFile:(NSString *)urlString
                        parameters:(NSDictionary *)parameters
                          savaPath:(NSString *)savePath
                      successBlock:(ResponseSuccess)successBlock
                      failureBlock:(ResponseFail)failureBlock
                  downLoadProgress:(DownloadProgress)progress {
    
    if (urlString == nil) {
        return nil;
    }
    
    NSURLRequest *downloadRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    
    NSLog(@"******************** 请求参数 ***************************");
    NSLog(@"请求头: %@\n请求方式: %@\n请求URL: %@\n请求param: %@\n\n",[RequestManager sharedRequestManager].sessionManager.requestSerializer.HTTPRequestHeaders, @"download",urlString, parameters);
    NSLog(@"******************************************************");
    
    
    NSURLSessionTask *sessionTask = nil;
    
    sessionTask = [[RequestManager sharedRequestManager].sessionManager downloadTaskWithRequest:downloadRequest progress:^(NSProgress * _Nonnull downloadProgress) {
        
        NSLog(@"下载进度：%.2lld%%",100 * downloadProgress.completedUnitCount/downloadProgress.totalUnitCount);
        /*! 回到主线程刷新UI */
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if (progress) {
                progress(downloadProgress.completedUnitCount, downloadProgress.totalUnitCount);
            }
            
        });
        
    } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
        
        if (!savePath) {
            NSURL *downloadURL = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];
            NSLog(@"默认路径--%@",downloadURL);
            return [downloadURL URLByAppendingPathComponent:[response suggestedFilename]];
        } else{
            return [NSURL fileURLWithPath:savePath];
        }
        
    } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
        
        [[self tasks] removeObject:sessionTask];
        
        NSLog(@"下载文件成功");
        if (error == nil) {
            if (successBlock) {
                /*! 返回完整路径 */
                successBlock([filePath path]);
            } else {
                if (failureBlock) {
                    failureBlock(error);
                }
            }
        }
    }];
    
    /*! 开始启动任务 */
    [sessionTask resume];
    
    if (sessionTask) {
        [[self tasks] addObject:sessionTask];
    }
    return sessionTask;
}

#pragma mark - 网络状态监测
/*!
 *  开启网络监测
 */
+ (void)startNetWorkMonitoringWithBlock:(NetworkStatusBlock)networkStatus {
    /*! 1.获得网络监控的管理者 */
    AFNetworkReachabilityManager *manager = [AFNetworkReachabilityManager sharedManager];
    /*! 当使用AF发送网络请求时,只要有网络操作,那么在状态栏(电池条)wifi符号旁边显示  菊花提示 */
    [AFNetworkActivityIndicatorManager sharedManager].enabled = YES;
    /*! 2.设置网络状态改变后的处理 */
    [manager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        /*! 当网络状态改变了, 就会调用这个block */
        switch (status) {
            case AFNetworkReachabilityStatusUnknown:
                NSLog(@"未知网络");
                networkStatus ? networkStatus(NetworkStatusUnknown) : nil;
                break;
            case AFNetworkReachabilityStatusNotReachable:
                NSLog(@"没有网络");
                networkStatus ? networkStatus(NetworkStatusNotReachable) : nil;
                break;
            case AFNetworkReachabilityStatusReachableViaWWAN:
                NSLog(@"手机自带网络");
                networkStatus ? networkStatus(NetworkStatusReachableViaWWAN) : nil;
                break;
            case AFNetworkReachabilityStatusReachableViaWiFi:
                NSLog(@"wifi 网络");
                networkStatus ? networkStatus(NetworkStatusReachableViaWiFi) : nil;
                break;
        }
    }];
    [manager startMonitoring];
}

#pragma mark - 取消 Http 请求
/*!
 *  取消所有 Http 请求
 */
+ (void)cancelAllRequest {
    
//    [[RequestManager sharedRequestManager].sessionManager.operationQueue cancelAllOperations];
    // 锁操作
    @synchronized(self) {
        [[self tasks] enumerateObjectsUsingBlock:^(NSURLSessionTask  *_Nonnull task, NSUInteger idx, BOOL * _Nonnull stop) {
            [task cancel];
        }];
        [[self tasks] removeAllObjects];
    }
}

/*!
 *  取消指定 URL 的 Http 请求
 */
+ (void)cancelRequestWithURL:(NSString *)URL {
    
    if (!URL) {
        return;
    }
    @synchronized (self) {
        [[self tasks] enumerateObjectsUsingBlock:^(NSURLSessionTask  *_Nonnull task, NSUInteger idx, BOOL * _Nonnull stop) {
            
            if ([task.currentRequest.URL.absoluteString hasPrefix:URL]) {
                [task cancel];
                [[self tasks] removeObject:task];
                *stop = YES;
            }
        }];
    }
}


static NSMutableArray *tasks;

#pragma mark - setter / getter
/**
 存储着所有的请求task数组
 
 @return 存储着所有的请求task数组
 */
+ (NSMutableArray *)tasks
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        tasks = [[NSMutableArray alloc] init];
    });
    return tasks;
}


- (void)setTimeoutInterval:(NSTimeInterval)timeoutInterval {
    _timeoutInterval = timeoutInterval;
    [RequestManager sharedRequestManager].sessionManager.requestSerializer.timeoutInterval = timeoutInterval;
}

- (void)setRequestSerializer:(HttpRequestSerializer)requestSerializer
{
    _requestSerializer = requestSerializer;
    switch (requestSerializer) {
        case HttpRequestSerializerJSON:
        {
            [RequestManager sharedRequestManager].sessionManager.requestSerializer = [AFJSONRequestSerializer serializer] ;
        }
            break;
        case HttpRequestSerializerHTTP:
        {
            [RequestManager sharedRequestManager].sessionManager.requestSerializer = [AFHTTPRequestSerializer serializer] ;
        }
            break;
            
        default:
            break;
    }
}

- (void)setResponseSerializer:(HttpResponseSerializer)responseSerializer
{
    _responseSerializer = responseSerializer;
    switch (responseSerializer) {
        case HttpResponseSerializerJSON:
        {
            [RequestManager sharedRequestManager].sessionManager.responseSerializer = [AFJSONResponseSerializer serializer] ;
        }
            break;
        case HttpResponseSerializerHTTP:
        {
            [RequestManager sharedRequestManager].sessionManager.responseSerializer = [AFHTTPResponseSerializer serializer] ;
        }
            break;
            
        default:
            break;
    }
}



- (void)setHttpHeaderFieldDictionary:(NSDictionary *)httpHeaderFieldDictionary {
    _httpHeaderFieldDictionary = httpHeaderFieldDictionary;
    
    if (![httpHeaderFieldDictionary isKindOfClass:[NSDictionary class]]) {
        NSLog(@"请求头数据有误，请检查！");
        return;
    }
    NSArray *keyArray = httpHeaderFieldDictionary.allKeys;
    
    if (keyArray.count <= 0) {
        NSLog(@"请求头数据有误，请检查！");
        return;
    }
    
    for (NSInteger i = 0; i < keyArray.count; i ++) {
        NSString *keyString = keyArray[i];
        NSString *valueString = httpHeaderFieldDictionary[keyString];
        
        [RequestManager setValue:valueString forHTTPHeaderKey:keyString];
    }
}

/**
 *  自定义请求头
 */
+ (void)setValue:(NSString *)value forHTTPHeaderKey:(NSString *)HTTPHeaderKey {
    [[RequestManager sharedRequestManager].sessionManager.requestSerializer setValue:value forHTTPHeaderField:HTTPHeaderKey];
}


/**
 删除所有请求头
 */
+ (void)clearAuthorizationHeader {
    [[RequestManager sharedRequestManager].sessionManager.requestSerializer clearAuthorizationHeader];
}



+ (void)uploadImageWithFormData:(id<AFMultipartFormData>  _Nonnull )formData
                      resizedImage:(UIImage *)resizedImage
                         imageType:(NSString *)imageType
                        imageScale:(CGFloat)imageScale
                         fileNames:(NSArray <NSString *> *)fileNames
                             index:(NSUInteger)index {
    /*! 此处压缩方法是jpeg格式是原图大小的0.8倍，要调整大小的话，就在这里调整就行了还是原图等比压缩 */
    if (imageScale == 0) {
        imageScale = 0.8;
    }
    NSData *imageData = UIImageJPEGRepresentation(resizedImage, imageScale ?: 1.f);
    
    /*! 拼接data */
    if (imageData != nil) {
        // 图片数据不为空才传递 fileName
        //                [formData appendPartWithFileData:imgData name:[NSString stringWithFormat:@"picflie%ld",(long)i] fileName:@"image.png" mimeType:@" image/jpeg"];
        
        // 默认图片的文件名, 若fileNames为nil就使用
        
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"yyyyMMddHHmmss";
        NSString *str = [formatter stringFromDate:[NSDate date]];
        NSString *imageFileName = [NSString stringWithFormat:@"%@%ld.%@",str, (unsigned long)index, imageType?:@"jpg"];
        
        [formData appendPartWithFileData:imageData
                                    name:[NSString stringWithFormat:@"picflie%ld", (unsigned long)index]
                                fileName:fileNames ? [NSString stringWithFormat:@"%@.%@",fileNames[index],imageType?:@"jpg"] : imageFileName
                                mimeType:[NSString stringWithFormat:@"image/%@",imageType ?: @"jpg"]];
        NSLog(@"上传图片 %lu 成功", (unsigned long)index);
    }
}


@end
