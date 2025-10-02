#import <Foundation/Foundation.h>
#import <objc/runtime.h>

static NSString * const kBagHandledKey = @"StorefrontHandled";

@interface StoreFrontInterceptor : NSURLProtocol
@end

@implementation StoreFrontInterceptor

// these 2 things are the ONLY things that work for some reason its so strange

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    if ([NSURLProtocol propertyForKey:kBagHandledKey inRequest:request]) {
        return NO;
    }
    NSURL *url = request.URL;
    if (!url) return NO;

    if ([[url.host lowercaseString] isEqualToString:@"itunes.apple.com"]) {
        NSString *path = url.path ?: @"";
        if ([path caseInsensitiveCompare:@"/WebObjects/MZStore.woa/wa/storeFront"] == NSOrderedSame) {
            return YES;
        }
    }
    return NO;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    NSURLComponents *comps = [NSURLComponents componentsWithURL:request.URL resolvingAgainstBaseURL:NO];
    comps.query = nil;
    NSMutableURLRequest *mutableReq = (NSMutableURLRequest *)[request mutableCopy];
    mutableReq.URL = comps.URL;
    return mutableReq;
}

- (void)startLoading {
    id<NSURLProtocolClient> client = [self client];
    NSURLRequest *request = [self request];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *jsonPath = @"/Library/Application Support/org.jyvee8games.itunesfix/storefront.json";
        NSData *fileData = [NSData dataWithContentsOfFile:jsonPath];
        NSData *outData = nil;

        if (fileData) {
            outData = fileData;
            NSLog(@"[StoreFrontInterceptor] Loaded fake storefront JSON");
        } else {
            NSLog(@"[StoreFrontInterceptor] storefront.json missing, falling back");
            outData = [NSData dataWithContentsOfURL:request.URL];
        }

        if (outData) {
            NSDictionary *headers = @{
                @"Content-Type": @"application/json",
                @"Content-Length": [NSString stringWithFormat:@"%lu", (unsigned long)outData.length]
            };
            NSHTTPURLResponse *response =
                [[NSHTTPURLResponse alloc] initWithURL:request.URL
                                            statusCode:200
                                           HTTPVersion:@"HTTP/1.1"
                                          headerFields:headers];

            [client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
            [client URLProtocol:self didLoadData:outData];
            [client URLProtocolDidFinishLoading:self];
        } else {
            NSError *err = [NSError errorWithDomain:NSURLErrorDomain code:-1 userInfo:nil];
            [client URLProtocol:self didFailWithError:err];
        }
    });
}

- (void)stopLoading {}
@end

%ctor {
        NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
        if ([bundleID isEqualToString:@"com.apple.AppStore"])
        {
            [NSURLProtocol registerClass:[StoreFrontInterceptor class]];
        }
    NSLog(@"[StoreFrontInterceptor] Loaded storefront handler!");
}