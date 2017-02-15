package com.qlync.android.storage;

import android.content.Context;
import android.content.res.AssetManager;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;

public class StorageUtils {
	
	/**
	 * Read a file from assets and write to storage.
	 * 
	 * @param context
	 * @param filename a filename in assets
	 * @return target file path
	 * @throws IOException
	 */
	public static String writeAssetsFile(Context context, String filename) throws IOException {
		// Get target file path.
		File file = new File(context.getFilesDir(), filename);
    	String filePath = file.getAbsolutePath();

    	// Load file from assets and write to target file path.
    	AssetManager assetManager = context.getAssets();
		try {
			InputStream in = assetManager.open(filename);
			OutputStream out = new FileOutputStream(filePath);
			
			byte[] buffer = new byte[1024];
			int read;
			while ((read = in.read(buffer)) != -1) {
				out.write(buffer, 0, read);
			}
			in.close();
			out.flush();
			out.close();
		} catch (IOException e) {
			throw e;
		}
		
		return filePath;
	}
}
