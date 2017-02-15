package com.qlync.sat;

public class SatManager {
	public SatManager(String licenseFilePath, String caFilePath, String satUsername, String satPassword, String macAddress) {
		this.initSat(licenseFilePath, caFilePath, satUsername, satPassword, macAddress);
	}
	
	protected void finalize() throws Throwable {
		this.destroySat();
		
		super.finalize();
	}
	
	private native String initSat(String licenseFilePath, String caFilePath, String satUsername, String satPassword, String macAddress);
	private native String destroySat();
	
	public native String getDeviceEntryList();
	
	// Caller
	public native String startCaller(String targetUid, int targetPort, String cloudClientId, String cloudSecret, String cloudRefreshId, String cachePath);
	public native String stopCaller();
	
	// Callee
	public String startCallee(DeviceEntryRequest deviceEntryRequest) {
		return this.startCallee(deviceEntryRequest.device_name, 
				deviceEntryRequest.url_prefix, deviceEntryRequest.port, deviceEntryRequest.url_path, 
				deviceEntryRequest.internal_ip, deviceEntryRequest.internal_port);
	}
	public native String startCallee(String device_name, 
			String url_prefix, int port, String url_path, 
			String internal_ip, int internal_port);
	public native String stopCallee();
	
	public native String getNegotiationResult(String target_uid);
	
	//get connection state
	public native String getState(String uid);
	
	//set debug log path
	public static native void setDebug(String path);
	
	//get google drive info
	public native String googleInfo(String clientId, String clientSecret, String refreshToken);
	
	//google backup
	public native String googleBackup(String clientId, String clientSecret, String refreshToken, 
			String fileName, String deviceUid, String localPath);

	// Load library
	static {
		System.loadLibrary("p2pTunnel-jni");
	}
}
