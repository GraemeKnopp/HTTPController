//
//  HTTPRequestor.m
//
//  Created by Graeme Knopp on 11-09-09.
//

#import "HTTPRequestor.h"


@implementation HTTPRequestor

@synthesize url = url_;
@synthesize requestMethod = requestType_;
@synthesize userInfo = userInfo_;
@synthesize userName = userName_;
@synthesize passWord = password_;
@synthesize timeOutInSeconds = timeOutSeconds_;
@synthesize responseCode = responseCode_;
@synthesize complete = isComplete_;
@synthesize finished = isFinished_;
@synthesize cancelled = wasCancelled_;
@synthesize error;

@synthesize totalBytesSent;
@synthesize contentLength = contentLength_;
@synthesize requestHeaders = requestHeaders_;
@synthesize responseHeaders = responseHeaders_;
@synthesize postData = postData_;
@synthesize rawData = rawResponseData_;


- (id)init
{
    self = [super init];
    if (self) {
      
      // Initialization code here.
      postData_ = [[NSMutableData alloc] init];
      rawResponseData_ = [[NSMutableData alloc] init];
      
      requestHeaders_ = [[NSMutableDictionary alloc] init];
      responseHeaders_ = [[NSDictionary alloc] init];
      userInfo_ = [[NSDictionary alloc] init];
      
      // defaults
      requestType_ = @"GET";
      userName_ = @"anonymous";
      password_ = @"email@someserver.com";
      timeOutSeconds_ = 60;      
      
      contentLength_ = 0;
      totalBytesSent = 0;
      
    }
    
    return self;
}

- (void)dealloc
{
  [postData_ release];
  [rawResponseData_ release];
  [requestHeaders_ release];
  [responseHeaders_ release];

  [userInfo_ release];
  
  [super dealloc];
}

-(void) addToRequestBody:(NSData *)newData {
  [postData_ appendData:newData];
}

-(void) addToResponseData:(NSData*)newData {
  [rawResponseData_ appendData:newData];
}

-(void) addToRequestHeader:(NSString *)header withValue:(NSString *)value {
  [requestHeaders_ setValue:value forKey:header];  
}

@end
