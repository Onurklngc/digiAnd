package com.qlync.sat;

public class DeviceEntryRequest {
	public String device_name;
	//public String mac_address;
	public String url_prefix;
	public int port;
	public String url_path;
	public String internal_ip;
	public int internal_port;
	
	public DeviceEntryRequest() {
		this.device_name = "DEFAULT";
		this.url_prefix = "http://";
		this.port = 0;
		this.url_path = "/";
		this.internal_ip = "";
		this.internal_port = 0;
	}
}
