//
//  SatManager.h
//  SI201
//
//  Created by qlync on 12/11/01.
//  Copyright (c) 2012年 Qlync Inc. All rights reserved.
//

#ifdef __cplusplus
#include "sat_sdk_lib_config.h"
#include "sat_sdk_lib_debug.h"
#include "sat_sdk_lib_client.h"
#include "sat_sdk_lib_license.h"
#include "GoogleOAuth2.h"
#include "GoogleDocListDownloader.h"
#include "GoogleDocListEntry.h"
#endif

#import <Foundation/Foundation.h>

#define SAT_P2P_ENABLE_DIRECT_LINK  0x0001
#define SAT_P2P_ENABLE_ICE          0x0002
#define SAT_P2P_ENABLE_CLOUD        0x0004


@interface SatManager : NSObject {
#ifdef __cplusplus
    IP2PLicense *p2pLicense;
    IP2PSATRequest *p2pSatRequest;
    IP2PTunnel *p2pTunnel;
    
    GoogleOAuth2 *googleOAuth2;
    GoogleDocListDownloader *googleDocListDownloader;
    
    char signal_server[1024];
    unsigned short signal_server_port;
    char uid[1024];
#endif
    
    NSString *cloudProvider;
    NSString *clientId;
    NSString *clientSecret;
    NSString *refreshToken;
}

// Common
- (void)setDebugLevel:(NSInteger)level;

// SAT
- (BOOL)initSat:(NSString*)username password:(NSString*)password;
- (BOOL)destroySat;
- (void)getDeviceEntryList;

// P2P
- (NSDictionary *)startCaller:(NSString *)targetUid port:(NSUInteger)targetPort;
- (BOOL)startCallee;
- (BOOL)stopP2p;
- (NSInteger)getP2pStatus:(NSString *)targetUid;
- (NSString *)getNegotiationResult:(NSString*)deviceUid;

// Cloud
- (void)connectGoogleService:(NSString *)cid secret:(NSString *)secret token:(NSString *)token;
- (void)getGoogleInfo;
- (void)getDeviceBackupFromGoogle:(NSString *)targetUid filename:(NSString *)filename;

@end
