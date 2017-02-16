package com.qlync.android;

import android.app.Activity;
import android.graphics.Color;
import android.os.Bundle;
import android.os.Handler;
import android.os.Message;
import android.os.Messenger;
import android.util.Log;
import android.content.ContentResolver;
import android.content.Intent;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.IntentFilter;
import android.os.Build;
import android.widget.Toast;

import java.util.Iterator;
import org.json.JSONArray;
import org.json.JSONObject;
import org.json.JSONException;
import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaInterface;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.PluginResult;

import com.qlync.android.sat.SatService;
import com.qlync.sat.SatManager;

public class Digitus extends CordovaPlugin {

	public static final String ACTION_START = "runSDK";
	public static final String ACTION_STOP = "stopSDK";
	public static final String ACTION_INIT = "initSDK";
	public static final String TAG = "Digitus";
	private CallbackContext callbackContext;
	Context context;
	Intent intent;
	WebLiveViewHandler messageHandler;

	@Override
	public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {
		this.callbackContext = callbackContext;
		this.context = cordova.getActivity();
		this.intent = new Intent(cordova.getActivity(), SatService.class);;
		messageHandler = new WebLiveViewHandler();
		JSONObject options;
		Log.v("I am here 1", "String");
		if (ACTION_START.equals(action)) {
			options = args.getJSONObject(1);
			return runSDK(args.getString(0), options);
		} else if (ACTION_STOP.equals(action)) {
			stopSDK();
			return true;
		}else if (ACTION_INIT.equals(action)) {
			initSDK();
			return true;
		}else {
			callbackContext.error("Digitus." + action + " is not a supported method.");
			return false;
		}
	}

	private class WebLiveViewHandler extends Handler {
		public WebLiveViewHandler() {
			super();
		}

		@Override
		public void handleMessage(Message message) {
			// Parse message
			String[] data = ((String) message.obj).split(":;");
			String connectionType = data[0];
			String localPort = data[1];
			Log.d(TAG,"connectionType: " + connectionType + "localPort: " + localPort + ", message: " + message);
			callbackContext.success(localPort);
		}
	}
	private void initSDK() throws JSONException {
		Log.v("I am here 5", "String");
		Intent intent = new Intent(cordova.getActivity(), SatService.class);
		context.startService(intent);
	}

	private boolean runSDK(final String url, JSONObject options) throws JSONException {
		Log.v("I am here", url);
		int port = 554;
		if (options.has("port")){
			port=options.getInt("port");
			Log.v("I am here", Integer.toString(port));
		}
		Messenger messenger = new Messenger(messageHandler);
		Intent intent = new Intent();
		intent.setAction(SatService.SAT_SERVICE_BROADCAST_ACTION);
		intent.putExtra("command", "start_caller");
		intent.putExtra("messenger", messenger);
		intent.putExtra("uid", url);
		intent.putExtra("port", port);
		context.sendBroadcast(intent);

		return true;
	}
	private void stopSDK() throws JSONException {
		Log.v("I am here 4", "String");

		// Send message to SatService
		Messenger messenger = new Messenger(messageHandler);
		Intent intent = new Intent();
		intent.setAction(SatService.SAT_SERVICE_BROADCAST_ACTION);
		intent.putExtra("command", "stop_caller");
		intent.putExtra("messenger", messenger);
		context.sendBroadcast(intent);


		Intent intent2 = new Intent(cordova.getActivity(), SatService.class);
		context.stopService(intent2);
	}
}
