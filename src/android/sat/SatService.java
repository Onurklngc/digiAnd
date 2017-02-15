package com.qlync.android.sat;

import com.qlync.android.network.WifiUtils;
import com.qlync.android.storage.StorageUtils;
import com.qlync.sat.DeviceEntryRequest;
import com.qlync.sat.SatManager;

import android.app.Service;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.os.Bundle;
import android.os.Environment;
import android.os.IBinder;
import android.os.Message;
import android.os.Messenger;
import android.os.RemoteException;
import android.util.Log;

import java.io.IOException;

public class SatService extends Service {
	
	public final static String SAT_SERVICE_BROADCAST_ACTION = 
			"com.qlync.android.sat.SatService.BROADCAST_ACTION";
	public final static String UID_MSG_BROADCAST_ACTION = 
		"com.qlync.android.sat.UidMsg.BROADCAST_ACTION";
	
	private SatManager satManager;
	private String licenseFilePath;
	private String caFilePath;
	private String username;
	private String password;
	private String macAddress;
	private String cloudClientId;
	private String cloudSecret;
	private String cloudRefreshId;
	
	private SatServiceReceiver satServiceReceiver;
	
	@Override
	public void onCreate() {
		super.onCreate();
		
		// Register SAT service broadcast receiver.
		this.satServiceReceiver = new SatServiceReceiver();
		IntentFilter intentFilter = new IntentFilter();
		intentFilter.addAction(SatService.SAT_SERVICE_BROADCAST_ACTION);
		this.registerReceiver(this.satServiceReceiver, intentFilter);
		
		// TODO For C2DM
		//new SatC2DM(this).register();
	}

	@Override
	public int onStartCommand(Intent intent, int flags, int startId) {	
		Bundle bundle = intent.getExtras();
		//!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
		//Usage:
		//  Input SAT USERNAME and PASSWORD 
		//!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
		this.username = "admin";
		this.password = "admin";
		
		//!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
		//Usage:
		//  Input google authentication data or google relay will be disabled.
		//!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
		this.cloudClientId = "";
		this.cloudSecret = "";
		this.cloudRefreshId = "";
		
		new SatServiceWorker().start();

		return Service.START_REDELIVER_INTENT;
	}

	@Override
	public IBinder onBind(Intent intent) {
		return null;
	}
	
	@Override
	public void onDestroy() {
		this.unregisterReceiver(this.satServiceReceiver);
		
		super.onDestroy();
	}

	/**
	 * Run SAT initialization on thread. 
	 */
	private class SatServiceWorker extends Thread {

		@Override
		public void run() {
			// Get mac address
			macAddress = WifiUtils.getMacAddress(getApplicationContext());
			if (macAddress == null)
				macAddress = "AABBCCDDEEFF";
			Log.d(getClass().getName() + "::run", "mac address " + macAddress);
			
			// Get license
			try {
				licenseFilePath = StorageUtils.writeAssetsFile(getApplicationContext(), "licenseDigitus");
			} catch (IOException e) {
				licenseFilePath = "";
			}
			Log.d(getClass().getName() + "::run", "licenseDigitus file path " + licenseFilePath);
			
			// Get certificate
            try {
                caFilePath = StorageUtils.writeAssetsFile(getApplicationContext(), "certificateDigitus");
            } catch (IOException e) {
                caFilePath = "";
            }
            Log.d(getClass().getName() + "::run", "certificateDigitus file path " + caFilePath);
		}

	}
	
	
	/////////////////////////////////////////////////////////////////////////
	// BroadcastReceiver
	/////////////////////////////////////////////////////////////////////////
	
	private class SatServiceReceiver extends BroadcastReceiver {
		
		@Override
		public void onReceive(Context context, Intent intent) {
			Log.d(getClass().getName() + "::onReceive", " ");
			
			// Create a new thread to handle command.
			new SatServiceReceiverWorker(context, intent).start();
		}
		
		private void sendMessage(Messenger messenger, Message message) {
			try {
				messenger.send(message);
			}
			catch (RemoteException e) {
				e.printStackTrace();
			}
		}
		
		/**
		 * Parse broadcast by thread.
		 */
		public class SatServiceReceiverWorker extends Thread {
			private Context context;
			private Intent intent;
			
			public SatServiceReceiverWorker(Context context, Intent intent) {
				this.context = context;
				this.intent = intent;
			}
			
			@Override
			public void run() {
				Bundle bundle = this.intent.getExtras();
				String command = bundle.getString("command");
				Messenger messenger = (Messenger) bundle.get("messenger");
				Message message = Message.obtain();
				
				if (command.equals("start_caller")) {
					String uid = bundle.getString("uid");
					int port = bundle.getInt("port");
					
					// Connect to remote client
					satManager = new SatManager(licenseFilePath, caFilePath, username, password, macAddress);
					String deviceEntryList = satManager.getDeviceEntryList();
					//!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
					//Usage:
					//  List all Device under the SAT Username in JASON Format
					//!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
					Log.d(getClass().getName() + "::run", deviceEntryList);
					
					String path = "";
					if (Environment.getExternalStorageState().equals(android.os.Environment.MEDIA_MOUNTED))
		 	    	{
		 	    		path = Environment.getExternalStorageDirectory().getAbsolutePath() + "/config_cache.dat";
		 	    	}
					String localPort = satManager.startCaller(uid, port, cloudClientId, cloudSecret, cloudRefreshId, path);
					String connectionType = satManager.getNegotiationResult(uid);
					String googleDriveInfo = "";
					String googleDriveList = "";
					if (!cloudClientId.equals("") && !cloudSecret.equals("") && !cloudRefreshId.equals(""))
					{
						googleDriveInfo = satManager.googleInfo(cloudClientId, cloudSecret, cloudRefreshId);
						googleDriveList = satManager.googleBackup(cloudClientId, cloudSecret, cloudRefreshId, "", uid, ""); //fill in all fields to download a file to the device 
					}
					// Send message
					message.obj = connectionType + ":;" + localPort + ":;" + googleDriveInfo + ":;" + googleDriveList;
					sendMessage(messenger, message);
				}
				else if (command.equals("stop_caller")) {
					satManager.stopCaller();
				}
				else if (command.equals("start_callee")) {
					DeviceEntryRequest deviceEntryRequest = new DeviceEntryRequest();
					deviceEntryRequest.device_name = "ANDROID_CALLEE";
					deviceEntryRequest.url_prefix = "rtsp://";
					deviceEntryRequest.port = 554;
					deviceEntryRequest.url_path = "/";
					deviceEntryRequest.internal_ip = "";
					deviceEntryRequest.internal_port = 80;
					
					satManager = new SatManager(licenseFilePath, caFilePath, username, password, macAddress);
					String uid = satManager.startCallee(deviceEntryRequest);
					// Send message to SatService
					Intent intent = new Intent();
					intent.setAction(UID_MSG_BROADCAST_ACTION);
					intent.putExtra("uid", uid);
					context.sendBroadcast(intent);
				}
				else if (command.equals("stop_callee")) {
					satManager.stopCallee();
				}
			}
		}
	}
}
