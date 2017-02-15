//
//  SatManager.mm
//  SI201
//
//  Created by qlync on 12/11/01.
//  Copyright (c) 2012年 Qlync Inc. All rights reserved.
//

#import "SatManager.h"

@implementation SatManager

#pragma mark - Common

// TODO: Assign mac address.
NSString *mac = @"101910199999";

- (void)setDebugLevel:(NSInteger)level
{
    //------------------------------------------------------------------------------------------
    // void SAT_SDK_LIB_Debug::SetDebugLevel(DEBUG_LEVEL　debug_level);
    //-----------------------------------------------------------------
    // Define the minimum set of debugging output level.
    // debug_level is in a range of 1 to 10.
    //------------------------------------------------------------------------------------------
    NSLog(@"%s Set SAT_SDK_LIB debug level to %d.", __PRETTY_FUNCTION__, level);
    SAT_SDK_LIB_Debug::SetDebugLevel((DEBUG_LEVEL)level);
}


#pragma mark - SAT

- (BOOL)initSat:(NSString*)username password:(NSString*)password
{
    NSLog(@"%s Initial SAT with username: %@, password: %@", __PRETTY_FUNCTION__, username, password);
    if (username == nil || password == nil) {
        NSLog(@"%s Username and password cannot be empty.", __PRETTY_FUNCTION__);
        return NO;
    }
    
    // Load license.
    NSString *licenseFilename = @"license";
    NSString *licensePath =  [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:licenseFilename];
    NSLog(@"%s Load license at path: %@", __PRETTY_FUNCTION__, licensePath);
	IP2PLicense *license = P2PFactory::CreateLicense([licensePath UTF8String]);
    
    NSString *certificateFilename = @"certificate";
    NSString *certificatePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:certificateFilename];
    NSLog(@"%s Load certificate at path: %@", __PRETTY_FUNCTION__, certificatePath);
    
    // Request SAT Server and verify license file.
    NSLog(@"%s Create SAT Request.", __PRETTY_FUNCTION__);
    p2pSatRequest = P2PFactory::CreateSATRequest([username UTF8String], [password UTF8String], license, [certificatePath UTF8String]);
    if (!license->IsValid()) {
        NSLog(@"%s Verify license failed.", __PRETTY_FUNCTION__);
        delete license;
        return NO;
    }
    p2pLicense = license;
    
    // Get signal server address/port from license.
    NSLog(@"%s Get signal server address/port.", __PRETTY_FUNCTION__);
    p2pLicense->GetSignalServer(signal_server, &signal_server_port);
    
    return YES;
}

- (BOOL)destroySat
{
    NSLog(@"%s Destroy SAT.", __PRETTY_FUNCTION__);
    if (p2pSatRequest) {
        delete p2pSatRequest;
        p2pSatRequest = NULL;
    }
    
    if (p2pLicense) {
        delete p2pLicense;
        p2pLicense = NULL;
    }
    
    return YES;
}

- (void)getDeviceEntryList {
    const std::vector<DeviceEntry *> *device_entries;
    
    //------------------------------------------------------------------------------------------
    // int GetDeviceEntryList(const std::vector<DeviceEntry *>** device_entry_list, const char*　service_type=NULL, const char* device_type=NULL)
    //-----------------------------------------------------------------
    // Get SAT Device List　which devices belongs to the account (username/password)
    //------------------------------------------------------------------------------------------
    NSInteger ret = p2pSatRequest->GetDeviceEntryList(&device_entries, "camera", "p2p");
    if (ret != SAT_SDK_LIB_RET_NULL_SUCCESS) {
        NSLog(@"%s Get device entry list fail.", __PRETTY_FUNCTION__);
        return;
    }
    
    int n_device_entries = device_entries->size();
    NSLog(@"Number of device entries: %d", n_device_entries);
    for (int i = 0; i < n_device_entries; i++) {
        DeviceEntry *device_entry = (*device_entries)[i];
        std::cout << *device_entry << std::endl;
        //std::cout << (*device_entry).cloud_client_id << std::endl;
        //std::cout << (*device_entry).cloud_secret << std::endl;
        //std::cout << (*device_entry).cloud_refresh_id << std::endl;
    }
    return;
}


#pragma mark - P2P

- (NSDictionary *)startCaller:(NSString *)targetUid port:(NSUInteger)targetPort
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    NSInteger ret;
    
    // ==================
    // SAT Part
    // ==================
    //-------------------------------------------------------------------------------------------
    // int GetUid(char* uid, const char* mac_addr=NULL)
    //-------------------------------------
    // Set local UID.
    // uid must be char array and larger than 64 bytes.
    // mac_addr should be NULL at callee mode.
    //-------------------------------------------------------------------------------------------
    NSLog(@"%s Get caller ID.", __PRETTY_FUNCTION__);
    p2pSatRequest->GetUid(uid, [mac UTF8String]);
    
    
    // ==================
    // P2P Part
    // ==================
    // Create P2P Tunnel
    NSLog(@"%s Create P2P tunnel.", __PRETTY_FUNCTION__);
	p2pTunnel = P2PFactory::CreateTunnelCaller();
    
    //------------------------------------------------------------------------------------------
    // int SetSignalServer(const char* address , unsigned short port)
    //-----------------------------------------------------------------
    // Set signal address and port which are got from License. This function should be called before Start().
    //------------------------------------------------------------------------------------------
    NSLog(@"%s Set signal address and port.", __PRETTY_FUNCTION__);
    p2pTunnel->SetSignalServer(signal_server, signal_server_port);
    
    //------------------------------------------------------------------------------------------
    // int EnableConfigCache(const char* config_cache_filename, const unsigned short timeout_in_sec)
    //-----------------------------------------------------------------
    // Store some connecting information in a file cache to speed up the connection time before the cache is timed out.
    // It is not necessary to enable the cache for Callee.
    //------------------------------------------------------------------------------------------
    NSString* cacheFilename = @"config_cache.dat";
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	NSString *cacheFilePath = [documentsDirectory stringByAppendingPathComponent:cacheFilename];
    NSLog(@"%s Enable config cache. %@", __PRETTY_FUNCTION__, cacheFilePath);
    p2pTunnel->EnableConfigCache([cacheFilePath UTF8String], 3600);
    
    //------------------------------------------------------------------------------------------
    // int Start()
    //--------------
    // Start a persistent connection to signal server. This connection will be used to exchange information with other peers.
    //------------------------------------------------------------------------------------------
    NSLog(@"%s Start P2P.", __PRETTY_FUNCTION__);
	ret = p2pTunnel->Start();
    if (ret != SAT_SDK_LIB_RET_NULL_SUCCESS) {
        [self stopP2p];
        return nil;
    }
    
    //------------------------------------------------------------------------------------------
    // int Authenticate(const char* uid, const char* password)
    //---------------------------------------------------------------
    // Verify Activated Code (*password)
    // Authentication function will block calling and waiting for signal server until getting response to continued.
    // This function should be called after calling Start().
    //------------------------------------------------------------------------------------------
    NSLog(@"%s Authenticate.", __PRETTY_FUNCTION__);
	ret = p2pTunnel->Authenticate(uid);
    if (ret != SAT_SDK_LIB_RET_NULL_SUCCESS) {
        [self stopP2p];
        return nil;
    }
    
    //------------------------------------------------------------------------------------------
    // int SetGoogleAuthentication( const char* client_id, const char* client_secret, const char* refresh_token )
    //---------------------------------------------------------------
    // Set google authentication to enable google relay.
    // This function should be called before calling Connect().
    //------------------------------------------------------------------------------------------
    if (cloudProvider) {
        if ([cloudProvider isEqualToString:@"google"]) {
            NSLog(@"%s Google authenticate.", __PRETTY_FUNCTION__);
            const char *client = [clientId UTF8String];
            const char *secret = [clientSecret UTF8String];
            const char *token = [refreshToken UTF8String];
            
            ret = p2pTunnel->SetGoogleAuthentication(client, secret, token);
            if (ret != SAT_SDK_LIB_RET_NULL_SUCCESS) {
                NSLog(@"%s Set google authentification failed.", __PRETTY_FUNCTION__);
            }
        }
        else {
            NSLog(@"%s Unsupported cloud provider.", __PRETTY_FUNCTION__);
        }
    }
    else {
        NSLog(@"%s No cloud provider.", __PRETTY_FUNCTION__);
    }
    
    //-------------------------------------------------------------------------------------------
    // int Connect(const char* remote_id)
    //-------------------------------------
    // Connect to a peer with the ID specified in the remote_id argument.
    // The two peers will automatically negotiate how to send data to each other.
    // This function should be called after calling Authenticate().
    // Connect function will block calling and waiting for signal server until getting response to continued.
    //-------------------------------------------------------------------------------------------
    NSLog(@"%s Connect to callee %@", __PRETTY_FUNCTION__, targetUid);
    ret = p2pTunnel->Connect([targetUid UTF8String]);
    if (ret != SAT_SDK_LIB_RET_NULL_SUCCESS) {
        return nil;
    }
    
    // Connect tunnel to device <uid> on port.
    NSLog(@"%s Connect tunnel to callee %@ on port %d", __PRETTY_FUNCTION__, targetUid, targetPort);
    unsigned short localPort;
    std::string localAddr = "127.0.0.1";
    
    NSInteger count = 20;
    while (YES) {
        //------------------------------------------------------------------------------------------------
        // int ConnectTunnel(const char* remote_id, unsigned char protocol, const char* target_addr, unsigned short target_port, unsigned short* p_local_port)
        //------------------------------------------------------------------------------------------------
        // Establish a TCP over UDP tunnel to a peer with the ID specified in the remote_id argument.
        // The target server address is specified in target_addr and target_port argument.
        // The local address and port for connection is returned in p_local_port and p_local_addr arguments.
        // Users have to call connect before calling this function, and users can establish multiple TCP over UDP tunnels on the same UDP connection.
        // However, the performance is not guaranteed.
        //------------------------------------------------------------------------------------------------
        ret = p2pTunnel->ConnectTunnel([targetUid UTF8String], IPPROTO_TCP, "127.0.0.1", targetPort, &localPort);
        if (ret != SAT_SDK_LIB_RET_NULL_TRY_AGAIN_LATER) {
            break;
        }
        
        // Timeout.
        if (count <= 0) {
            NSLog(@"%s Connect tunnel to callee %@ on port %d timeout.", __PRETTY_FUNCTION__, targetUid, targetPort);
            return nil;
        }
        sleep(1);
        count = count - 1;
    }
    
    if (ret != SAT_SDK_LIB_RET_NULL_SUCCESS) {
        NSLog(@"%s Connect to callee %@ on port %d failed.", __PRETTY_FUNCTION__, targetUid, targetPort);
        return nil;
    }
    
    NSString *localAddrInString = [NSString stringWithCString:localAddr.c_str() encoding:NSUTF8StringEncoding];
    NSNumber *localPortInNumber = [NSNumber numberWithUnsignedShort:localPort];
    NSDictionary *tunnelInfo = [[NSDictionary alloc] initWithObjectsAndKeys:localAddrInString, @"address", localPortInNumber, @"port", nil];
    return tunnelInfo;
}

- (BOOL)startCallee
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    NSInteger ret;
    
    // ==================
    // SAT Part
    // ==================
    //-------------------------------------------------------------------------------------------
    // int Register(const char *sid, DeviceEntryRequest*, const　char*　activated_code, P2PRegisterResponse&　reg_response);
    //-------------------------------------
    // Register or update SAT Device information to SAT Web service.
    // Need to call this function on callee mode.
    //-------------------------------------------------------------------------------------------
    NSString *activatedCode = @"";
    DeviceEntryRequest device_entry_request = DeviceEntryRequest();
    device_entry_request.device_name = "TEST";
    device_entry_request.mac_address = [mac UTF8String];
    //device_entry_request.url_prefix = "rtsp://";
    //device_entry_request.port = 554;
    //device_entry_request.url_path = "";
    device_entry_request.internal_ip = "";
    //device_entry_request.internal_port = 554;
    P2PRegisterResponse reg_response;
    p2pSatRequest->Register([mac UTF8String], &device_entry_request, [activatedCode UTF8String], reg_response);
    NSLog(@"Register result: %s", reg_response.message.c_str());
    
    //-------------------------------------------------------------------------------------------
    // int GetUid(char* uid, const char* mac_addr=NULL)
    //-------------------------------------
    // Set local UID.
    // uid must be char array and larger than 64 bytes.
    // mac_addr should be NULL on callee mode.
    //-------------------------------------------------------------------------------------------
    NSLog(@"%s Get callee ID.", __PRETTY_FUNCTION__);
    p2pSatRequest->GetUid(uid);
    
    
    // ==================
    // P2P Part
    // ==================
    // Create P2P Tunnel
    NSLog(@"%s Create P2P tunnel.", __PRETTY_FUNCTION__);
	p2pTunnel = P2PFactory::CreateTunnelCallee();
    
    //------------------------------------------------------------------------------------------
    // int SetSignalServer(const char* address , unsigned short port)
    //-----------------------------------------------------------------
    // Set signal address and port which are got from License. This function should be called before Start().
    //------------------------------------------------------------------------------------------
    NSLog(@"%s Set signal address and port.", __PRETTY_FUNCTION__);
    p2pTunnel->SetSignalServer(signal_server, signal_server_port);
    
    //------------------------------------------------------------------------------------------
    // int Start()
    //--------------
    // Start a persistent connection to signal server. This connection will be used to exchange information with other peers.
    //------------------------------------------------------------------------------------------
    NSLog(@"%s Start P2P.", __PRETTY_FUNCTION__);
	ret = p2pTunnel->Start();
    if (ret != SAT_SDK_LIB_RET_NULL_SUCCESS) {
        [self stopP2p];
        return nil;
    }
    
    //------------------------------------------------------------------------------------------
    // int Authenticate(const char* uid, const char* password)
    //---------------------------------------------------------------
    // Verify Activated Code (*password)
    // Authentication function will block calling and waiting for signal server until getting response to continued.
    // This function should be called after calling Start().
    // password is got from Register, and it should be set on callee mode.
    //------------------------------------------------------------------------------------------
    NSLog(@"%s Authenticate.", __PRETTY_FUNCTION__);
	ret = p2pTunnel->Authenticate(uid, reg_response.password.c_str());
    if (ret != SAT_SDK_LIB_RET_NULL_SUCCESS) {
        [self stopP2p];
        return nil;
    }
    
    return YES;
}

- (BOOL)stopP2p
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    if (p2pTunnel != NULL) {
        //--------------------------------------------------------------------------------
        // P2PSignalClientEntryState GetState()
        //-------------
        // Get the current state of the link to the signal server.
        //---------------------------------------------------------------------------------
        if (p2pTunnel->GetState() != P2PSignalClientEntryState_Disconnected) {
            //--------------------------------------------------------------------------------
            // int Stop()
            //-------------
            // Stop the connection to signal server. After calling Stop(),
            // you will need to call Start() again to do NAT traversal and transmit data.
            //---------------------------------------------------------------------------------
            p2pTunnel->Stop();
        }
        delete p2pTunnel;
        p2pTunnel = NULL;
    }
    return YES;
}

- (NSInteger)getP2pStatus:(NSString *)targetUid {
    //------------------------------------------------------------------------------------------
    // TunnelLinkState GetTunnelLinkState(const char *client_id)
    //---------------------------------------------------------------
    // Get current connection status between the Callee/Caller.
    //------------------------------------------------------------------------------------------
    return p2pTunnel->GetTunnelLinkState([targetUid UTF8String]);
}

// get the connect mode of device uid
- (NSString*)getNegotiationResult:(NSString*)targetUid
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    if (targetUid == nil) {
        NSLog(@"%s Target UID cannot be null.", __PRETTY_FUNCTION__);
        return @"";
    }
    
    string type; // relay cloud
    string laddr;
    string raddr;
    
    if (p2pTunnel == nil) {
        return @"";
    }
    
    //------------------------------------------------------------------------------------------
    // int GetNegotiationResult(const std::string*, std::string*　p_laddr, std::string*　p_raddr)
    //---------------------------------------------------------------
    // Get P2P Connection Type and IPs
    //------------------------------------------------------------------------------------------
    p2pTunnel->GetNegotiationResult([targetUid UTF8String], &type, &laddr, &raddr);
    
    NSString *connectionType = [NSString stringWithCString:type.c_str() encoding:[NSString defaultCStringEncoding]];
    NSLog(@"%s P2P connection type: %@", __PRETTY_FUNCTION__, connectionType);
    return connectionType;
}


#pragma mark - Cloud

- (void)connectGoogleService:(NSString *)cid secret:(NSString *)secret token:(NSString *)token
{
    cloudProvider = @"google";
    clientId = cid;
    clientSecret = secret;
    refreshToken = token;
    
    googleOAuth2 = new GoogleOAuth2([clientId UTF8String], [clientSecret UTF8String], [refreshToken UTF8String]);
    googleOAuth2->GetAccessToken();
    googleDocListDownloader = new GoogleDocListDownloader(googleOAuth2);
}

- (void)getGoogleInfo
{
    if (googleOAuth2 == nil || googleDocListDownloader == nil) {
        return;
    }
    
    // Get email.
    std::string email = googleOAuth2->GetUserEmail();
    
    // Get quota.
    pj_uint64_t total = 0, used = 0;
    googleDocListDownloader->GetQuota(&total, &used, NULL);
    
    NSLog(@"%s Email: %s, Quota: %llu/%llu", __PRETTY_FUNCTION__, email.c_str(), used, total);
}

- (void)getDeviceBackupFromGoogle:(NSString *)targetUid filename:(NSString *)filename
{
    if (googleDocListDownloader == nil) {
        return;
    }
    
    std::vector<GoogleDocListEntry *> entry_list;
    GoogleDocListEntry root_list;
    
    // Get google documents.
    NSLog(@"%s Start to get google entry list.", __PRETTY_FUNCTION__);
    
    // - Get 'root' entry
    if (googleDocListDownloader->GetEntryList(entry_list) != 0) {
        NSLog(@"%s Get google 'root' entry list failed.", __PRETTY_FUNCTION__);
        return;
    }
    
    BOOL found = NO;
    for (int i = 0; i < entry_list.size(); i++) {
        // Find Recordings directory.
        if (entry_list[i]->m_title == "Recordings") {
            root_list = *entry_list[i];
            found = YES;
            break;
        }
    }
    if (found == NO) {
        NSLog(@"%s Google 'recordings' entry not found.", __PRETTY_FUNCTION__);
        return;
    }
    
    // - Get 'Recordings' entry
    if (googleDocListDownloader->GetEntryList(entry_list, &root_list) != 0) {
        NSLog(@"%s Get google 'recordings' entry list failed.", __PRETTY_FUNCTION__);
        return;
    }
    
    // Compute device UID.
    string targetUidStr([targetUid UTF8String]);
    found = NO;
    for (int i = 0; i < entry_list.size(); i++) {
        // Find the UID directory.
        if (entry_list[i]->m_title.compare(targetUidStr) == 0) {
            root_list = *entry_list[i];
            found = YES;
            break;
        }
    }
    if (found == NO) {
        NSLog(@"%s Google %@ entry not found.", __PRETTY_FUNCTION__, targetUid);
        return;
    }
    
    // - Iterative get 'uid' entry, 100 records a time.
    googleDocListDownloader->GetEntryList(entry_list, &root_list, true, true, NULL, false, 100);
    int ret = 0;
    while (ret == 0) {
        ret = googleDocListDownloader->GetEntryListNext(entry_list);
    }
    
    // If filename exists, we could download the file from google drive.
    BOOL needDownload = (filename == nil || filename.length == 0) ? NO : YES;
    if (needDownload) {
        // Download file path.
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *filePath = [documentsDirectory stringByAppendingPathComponent:filename];
        string filePathStr([filePath UTF8String]);
        
        for (int i = 0; i < entry_list.size(); i++) {
            // Find the file.
            if (entry_list[i]->m_title.compare(filePathStr) == 0) {
                // Downloadthe file.
                if (googleDocListDownloader->DownloadFile(entry_list[i], [filePath UTF8String]) == 0) {
                    NSLog(@"%s Download file success.", __PRETTY_FUNCTION__);
                }
                else {
                    NSLog(@"%s Download file failed.", __PRETTY_FUNCTION__);
                }
                break;
            }
        }
    }
    else {
        // Iterator files.
        for (int i = 0; i < entry_list.size(); i++) {
            GoogleDocListEntry* entry = entry_list[i];
        }
    }
    
    return;
}

@end
