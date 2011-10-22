//
//  HTTPRequestor.h
//
//  Created by Graeme Knopp on 11-09-09.
//

#import <Foundation/Foundation.h>


@interface HTTPRequestor : NSObject {

    NSString* url_;
    NSString* requestType_;
    
    // request content information
    NSMutableData* postData_;
    NSMutableDictionary* requestHeaders_;
    NSDictionary* responseHeaders_;
    NSMutableData* rawResponseData_;
    
    // customization elements
    NSDictionary* userInfo_;
    NSString* userName_;
    NSString* password_;
    NSTimeInterval timeOutSeconds_;
    
    // status of request
    int responseCode_;
    BOOL isComplete_;
    BOOL isFinished_;
    BOOL wasCancelled_;
    BOOL isSynchronous_;
  
    NSError* error_;
    
  @private
    unsigned long contentLength_;
    unsigned long postLength_;
    unsigned long totalBytesRead_;
    unsigned long totalBytesSent_;
    
  }
  
  @property (nonatomic, retain) NSString* url;
  @property (nonatomic, retain) NSString* requestMethod;
  @property (nonatomic, retain) NSDictionary* userInfo;
  @property (nonatomic, assign) NSTimeInterval timeOutInSeconds;
  @property (nonatomic, retain) NSString* userName;
  @property (nonatomic, retain) NSString* passWord;
  
  @property (nonatomic, assign) int responseCode;
  @property (nonatomic, assign) BOOL complete;
  @property (nonatomic, assign) BOOL finished;
  @property (nonatomic, assign) BOOL cancelled;
  @property (nonatomic, assign) BOOL sentSynchronously;
  @property (nonatomic, retain) NSError* error;
  @property (nonatomic, assign) unsigned long totalBytesSent;
  @property (nonatomic, assign) unsigned long contentLength;
  @property (nonatomic, retain) NSMutableDictionary* requestHeaders;
  @property (nonatomic, retain) NSDictionary* responseHeaders;
  @property (nonatomic, retain) NSMutableData* postData;
  @property (nonatomic, retain) NSMutableData* rawData;

  // Interface Methods
  -(void) addToRequestHeader:(NSString*)header withValue:(NSString*)value;
  -(void) addToRequestBody:(NSData*)newData;
  -(void) addToResponseData:(NSData*)newData;

@end
