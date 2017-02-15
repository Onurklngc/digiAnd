package com.qlync.android.network;

import android.content.Context;
import android.net.wifi.WifiInfo;
import android.net.wifi.WifiManager;

public class WifiUtils {
	
	/**
	 * @param context
	 * @return
	 */
	public static String getMacAddress(Context context) {
		WifiManager wifiManager = (WifiManager) context.getSystemService(Context.WIFI_SERVICE);
		WifiInfo wifiInfo = wifiManager.getConnectionInfo();
		String macAddress = wifiInfo.getMacAddress();
		if (macAddress == null) {
			return "";
		}
		macAddress = macAddress.replace(":", "");
		macAddress = macAddress.toUpperCase();
		return macAddress;
	}
}
