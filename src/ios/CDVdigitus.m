#import "CDVdigitus.h"


@implementation CDVdigitus
    
    SatManager *satManager = nil;
- (void)runSDK:(CDVInvokedUrlCommand*) command
{

    [self.commandDelegate runInBackground:^{
        CDVPluginResult* pluginResult = nil;
        NSString* cameraUID = [command.arguments objectAtIndex:0];
        
//        cameraUID=@"A02CC-3C493707EB66";
        if (cameraUID != nil) {
        printf("hello digitus");
        
        
        // Initialize SAT.
        satManager = [[SatManager alloc] init];
        [satManager setDebugLevel:1];
        
        // TODO: Fill out username and password.
        NSInteger ret = [satManager initSat:@"admin" password:@"admin"];
        if (ret == NO) {
            // Do something.
        }
        
        NSString *calleeUid = cameraUID;
        NSUInteger calleeWebPort = 554;
        NSString *calleeWebPath = @"/11";
        
        
        NSDictionary *tunnelInfo = [satManager startCaller:calleeUid port:calleeWebPort];
        NSString *address = [tunnelInfo objectForKey:@"address"];
        NSUInteger port = [[tunnelInfo objectForKey:@"port"] integerValue];
        NSString *urlPath = [NSString stringWithFormat:@"http://%@:%d", address, port];
        
        NSLog(@"%s Open URL: %@", __PRETTY_FUNCTION__, urlPath);
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:urlPath];

    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Arg was null"];
	}
	[self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }];
}
- (void)stopSDK:(CDVInvokedUrlCommand*) command
{
    [self.commandDelegate runInBackground:^{
        [satManager stopP2p];
    }];
}
@end
