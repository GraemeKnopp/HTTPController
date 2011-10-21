//
//  HTTPController.m
//
//  Created by Graeme Knopp on 11-09-09.
//

#import "HTTPController.h"


@implementation HTTPController


@synthesize delegate;
@synthesize queue = queue_;
@synthesize state;
@synthesize urlConnection;



#pragma mark - Init and Dealloc


- (id)init {
  self = [super init];
  
  self.delegate = nil;
  queue_ = [[NSMutableArray alloc] init];
  self.state = CONTROLLER_READY;
  self.urlConnection = nil;
  
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startQueue) name:NOTIF_NEXTHTTPREQUEST object:nil];
  
  return self;
}

-(void) dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [queue_ release];
  [super dealloc];
}


#pragma mark - Miscellaneous Methods

-(void) processRequest:(HTTPRequestor*)theRequest {
  
  NSLog(@"HTTP > PROCESSING");
  
  // change controller state
  if (theRequest.requestMethod == HTTP_GET) {
    self.state = CONTROLLER_DOWNLOADING;
  } else {
    self.state =  CONTROLLER_UPLOADING;
  }
  
  // determine what to do with the request
  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:theRequest.url]];
  [request setHTTPMethod:theRequest.requestMethod];
  if (theRequest.requestMethod == HTTP_POST) {
    if ([self state] != CONTROLLER_STOPPED)
      self.state = CONTROLLER_UPLOADING;
    
    for(NSString* keyName in theRequest.requestHeaders) {
      [request addValue:[theRequest.requestHeaders objectForKey:keyName] forHTTPHeaderField:keyName];
    }
    [request setHTTPBody:theRequest.postData];
  } else {
    if ([self state] != CONTROLLER_STOPPED)
      self.state = CONTROLLER_DOWNLOADING;
  }
  
  if (self.urlConnection != nil) [self.urlConnection release];
  self.urlConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
  if (!self.urlConnection) {
    if (self.delegate != self) {
      // set error in theRequest to indicate what happened
      NSError* newError = [[NSError alloc] initWithDomain:@"Failed to create a connection." code:4004 userInfo:nil];
      [theRequest setError:newError];
      [newError release];
      
      // let delegate know
      [self.delegate requestFailed:theRequest];
    }
    
    // post notification to trigger next request
    [self.queue removeObjectAtIndex:0];
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIF_NEXTHTTPREQUEST object:nil];
  }
}


#pragma mark - Connection Methods

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {

  // verify connection
  NSHTTPURLResponse * httpResponse = (NSHTTPURLResponse *)response;
  //NSAssert(![httpResponse isKindOfClass:[NSHTTPURLResponse class]], @"NOT A CORRECT URL RESPONSE");
  //assert([httpResponse isKindOfClass:[NSHTTPURLResponse class]]);
  
  [[self.queue objectAtIndex:0] setResponseHeaders:httpResponse.allHeaderFields];;
  [[self.queue objectAtIndex:0] setResponseCode:(int)httpResponse.statusCode];
  
  if ([[self.queue objectAtIndex:0] requestMethod] == HTTP_POST) {
    if ((httpResponse.statusCode / 100) == 2) {
      [[self.queue objectAtIndex:0] setComplete:YES];
    }
  }
  NSLog(@"HTTP > RECEIVED > RESPONSE > %ld", httpResponse.statusCode);
  
}

- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace {
  // to deal with self-signed certificates
  return [protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust];
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
  
  NSURLCredential *credential;
  
  NSLog(@"HTTP > CHALLENGED");
  
  if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
    
    // asked for a signed certificate
    NSLog(@"HTTP > CHALLENGED > BY > %@", challenge.protectionSpace.host);
    
    // we only trust our own domain
    if ([challenge.protectionSpace.host isEqualToString:BASE_URI]) {
      NSLog(@"HTTP > TRUSTED");
      credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
      [[challenge sender] useCredential:credential forAuthenticationChallenge:challenge];
    } else {
      [[challenge sender] continueWithoutCredentialForAuthenticationChallenge:challenge];
    }
    
  } else {
    HTTPRequestor* theRequest = [self.queue objectAtIndex:0];
    credential = [NSURLCredential credentialWithUser:[theRequest userName] password:[theRequest passWord] persistence:NSURLCredentialPersistenceForSession];
    [[challenge sender] useCredential:credential forAuthenticationChallenge:challenge];
  }
  
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
  
  // Append the new data to receivedData.
  [[self.queue objectAtIndex:0] addToResponseData:data];
}

- (void)connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesOut totalBytesWritten:(NSInteger)totalBytesOut totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite {
  
  // if content is too large for the byte buffer multiple sends are executed
  // verify that data was sent out completely.
  
  NSLog(@"HTTP > POSTED > %d bytes.", (int)bytesOut);
  [[self.queue objectAtIndex:0] setTotalBytesSent:totalBytesOut];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
  
  NSLog(@"HTTP > FAILED ***");
  
  HTTPRequestor* theRequest = [self.queue objectAtIndex:0];
  [theRequest setError:error];
  [theRequest setFinished:YES];
  
  if (self.delegate != self) {
    // let delegate know
    [self.delegate requestFailed:theRequest];
  }
  
  // reset connection & state
  [self.urlConnection release];
  self.state = CONTROLLER_READY;
  
  // post notification to trigger next request
  [self.queue removeObjectAtIndex:0];
  [[NSNotificationCenter defaultCenter] postNotificationName:NOTIF_NEXTHTTPREQUEST object:nil];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {

  NSLog(@"HTTP > FINISHED");
  
  HTTPRequestor* theRequest = [self.queue objectAtIndex:0];
  [theRequest setFinished:YES];
  
  if (theRequest.requestMethod == HTTP_GET)
    [theRequest setComplete:YES];
  
  if (self.delegate != self) {
    // let delegate know
    [self.delegate requestFinished:theRequest];
  }
  
  // reset connection & state
  [self.urlConnection release];
  self.state = CONTROLLER_READY;
  
  // post notification to trigger next request
  [self.queue removeObjectAtIndex:0];
  [[NSNotificationCenter defaultCenter] postNotificationName:NOTIF_NEXTHTTPREQUEST object:nil];
}

#pragma mark - Interface Methods

-(void) requestWithURL:(NSString*)url {

  NSLog(@"HTTP > REQUEST > %@", url);
  
  HTTPRequestor* newRequest = [[HTTPRequestor alloc] init];
  [newRequest setUrl:url];
  [self queueRequest:newRequest];
  [newRequest release];
  [self startQueue];
}

-(void) queueRequest:(HTTPRequestor*)newRequest {
  [self.queue addObject:newRequest];
}

-(void) startQueue {
  
  NSLog(@"HTTP > QUEUE > %d", [self requestsInQueue]);  
  
  if ([self state] != CONTROLLER_STOPPED) {
    if ([self.queue count] > 0) {
      // process queue using FIFO
      HTTPRequestor* newRequest = [self.queue objectAtIndex:0];
      if (newRequest != nil) {
        [self processRequest:newRequest];
      }
    } else {
      if (self.delegate != self) {
        [self.delegate queueFinished];
      }
    }
  }
}

-(void) stopQueue {
  if ([self state] != CONTROLLER_READY) {
    self.state = CONTROLLER_STOPPED;
  }
}

-(void) cancelQueue {
  
  // stop processing of queue
  [self stopQueue];
  
  // flag requests as cancelled
  for(HTTPRequestor* req in queue_) {
    [req setCancelled:YES];
    if (self.delegate != self) {
      // notify delegate
      [self.delegate requestFinished:req];
    }
  }
  
  // empty the queue
  [queue_ removeAllObjects];
  if (self.delegate != self) {
    // flag queue as finished
    [self.delegate queueFinished];
  }
  
  // reset controller state
  self.state = CONTROLLER_READY;
}

-(int) requestsInQueue {
  return (int)[queue_ count];
}

-(HTTPRequestor*) currentRequest {
  return ([queue_ count] > 0) ? nil : [queue_ objectAtIndex:0];
}

@end

