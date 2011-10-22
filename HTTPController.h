//
//  HTTPController.h
//
//  Created by Graeme Knopp on 11-09-09.
//

#import <Foundation/Foundation.h>
#import "HTTPRequestor.h"


// custom defines
#define HTTP_GET  @"GET"
#define HTTP_POST @"POST"
#define NOTIF_NEXTHTTPREQUEST @"HTTPControllerNextRequest"

//#define BASE_URI  @"mypage.myserver.com"
#define REPO_LIST  @"/api/surveys/repository/?format=json"
#define BASE_URI  @"surveyapp.bawtreehostedapps.com"



//custom enums
typedef enum
{
  CONTROLLER_ERROR = -1,
  CONTROLLER_READY,
  CONTROLLER_DOWNLOADING,
  CONTROLLER_UPLOADING,
  CONTROLLER_STOPPED
  
} CONTROLLER_STATE;


// delegate protocol definitions
@protocol HTTPControllerDelegate <NSObject>
-(void) requestFinished:(HTTPRequestor*)request;
-(void) requestFailed:(HTTPRequestor*)request;
@optional
-(void) queueFinished;
@end


// interface definition
@interface HTTPController : NSObject
{
  id <HTTPControllerDelegate> delegate;
  NSMutableArray* queue_;
  int state;
  NSURLConnection* urlConnection;
  BOOL isRunning;
  
}

@property (nonatomic, assign) id delegate;
@property (nonatomic, readonly) NSMutableArray* queue;
@property (nonatomic, assign) int state;
@property (nonatomic, retain) NSURLConnection* urlConnection;
@property (nonatomic, assign) BOOL isRunning;


// define interface methods
-(HTTPRequestor*) requestSynchronousURL:(NSString*)url;     // send it right away !!
-(void) requestWithURL:(NSString*)url;                      // simple download request
-(void) queueRequest:(HTTPRequestor*)newRequest;            // complex (upload) request
-(void) startQueue;                                         // go !
-(void) stopQueue;                                          // stop !
-(void) cancelQueue;                                        // empty queue after current request

// informative methods
-(int) requestsInQueue;            // returns [queue count];
-(HTTPRequestor*) currentRequest;  // returns nil or [queue objectAtIndex:0];

@end
