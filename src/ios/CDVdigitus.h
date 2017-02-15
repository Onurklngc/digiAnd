#import <Cordova/CDV.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "SatManager.h"













@interface CDVdigitus : CDVPlugin {

    
    SatManager *satManager;
    NSString *calleeUid;
    NSUInteger calleeWebPort;
    NSString *calleeWebPath;
    

}

@property (nonatomic, weak) CDVInvokedUrlCommand* lastCommand;

- (void)runSDK:(CDVInvokedUrlCommand*)command;
- (void)stopSDK:(CDVInvokedUrlCommand*)command;

@end
