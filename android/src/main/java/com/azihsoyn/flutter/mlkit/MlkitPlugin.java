package com.azihsoyn.flutter.mlkit;

import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.PluginRegistry.Registrar;
import io.flutter.view.FlutterView;

import android.content.Context;
import android.content.res.AssetManager;
import android.graphics.BitmapFactory;
import android.net.Uri;
import com.google.common.collect.ImmutableList;
import com.google.common.collect.ImmutableMap;
import android.support.annotation.NonNull;
import com.google.android.gms.tasks.OnFailureListener;
import com.google.android.gms.tasks.OnSuccessListener;
import com.google.firebase.ml.vision.text.FirebaseVisionTextDetector;
import com.google.firebase.ml.vision.FirebaseVision;
import com.google.firebase.ml.vision.cloud.FirebaseVisionCloudDetectorOptions;
import com.google.firebase.ml.vision.cloud.text.FirebaseVisionCloudDocumentTextDetector;
import com.google.firebase.ml.vision.cloud.text.FirebaseVisionCloudText;
import com.google.firebase.ml.vision.common.FirebaseVisionImage;
import com.google.firebase.ml.vision.text.FirebaseVisionText;
import com.google.firebase.ml.vision.common.FirebaseVisionImageMetadata;

import android.graphics.Bitmap;
import android.media.Image;
import java.io.IOException;
import android.util.Log;

import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

/**
 * MlkitPlugin
 */
public class MlkitPlugin implements MethodCallHandler {
  private static Context context;
  /**
   * Plugin registration.
   */
  public static void registerWith(Registrar registrar) {
    final MethodChannel channel = new MethodChannel(registrar.messenger(), "plugins.flutter.io/firebase_mlkit/vision_text");
    channel.setMethodCallHandler(new MlkitPlugin());
    context = registrar.context();
  }

  @Override
  public void onMethodCall(MethodCall call, final Result result) {
    if (call.method.equals("detectFromPath")) {
      String path = call.argument("filepath");
      try {
        File file = new File(path);
        FirebaseVisionImage image = FirebaseVisionImage.fromFilePath(context, Uri.fromFile(file));
        FirebaseVisionTextDetector detector = FirebaseVision.getInstance()
                .getVisionTextDetector();
        detector.detectInImage(image)
                .addOnSuccessListener(
                        new OnSuccessListener<FirebaseVisionText>() {
                          @Override
                          public void onSuccess(FirebaseVisionText texts) {
                            result.success(processTextRecognitionResult(texts));
                          }
                        })
                .addOnFailureListener(
                        new OnFailureListener() {
                          @Override
                          public void onFailure(@NonNull Exception e) {
                            // Task failed with an exception
                            e.printStackTrace();
                          }
                        });
      } catch (IOException e) {
        Log.e("error", e.getMessage());
        return;
      }
    } else {
      result.notImplemented();
    }
  }

  private ImmutableList<ImmutableMap<String, Object>> processTextRecognitionResult(FirebaseVisionText texts) {
    ImmutableList.Builder<ImmutableMap<String, Object>> dataBuilder =
            ImmutableList.<ImmutableMap<String, Object>>builder();

    List<FirebaseVisionText.Block> blocks = texts.getBlocks();
    if (blocks.size() == 0) {
      return null;
    }
    for (int i = 0; i < blocks.size(); i++) {
      ImmutableMap.Builder<String, Object> blockBuilder = ImmutableMap.<String, Object>builder();
      blockBuilder.put("text", blocks.get(i).getText());

      List<FirebaseVisionText.Line> lines = blocks.get(i).getLines();
      ImmutableList.Builder<ImmutableMap<String, Object>> linesBuilder = ImmutableList.<ImmutableMap<String, Object>>builder();
      for (int j = 0; j < lines.size(); j++) {
        ImmutableMap.Builder<String, Object> lineBuilder = ImmutableMap.<String, Object>builder();
        lineBuilder.put("text", lines.get(j).getText());
        List<FirebaseVisionText.Element> elements = lines.get(j).getElements();

        ImmutableList.Builder<ImmutableMap<String, Object>> elementsBuilder = ImmutableList.<ImmutableMap<String, Object>>builder();
        for (int k = 0; k < elements.size(); k++) {
          ImmutableMap.Builder<String, Object> elementBuilder = ImmutableMap.<String, Object>builder();
          elementBuilder.put("text", elements.get(k).getText());
          elementsBuilder.add(elementBuilder.build());
        }
        lineBuilder.put("elements", elementsBuilder.build());
        linesBuilder.add(lineBuilder.build());
      }
      blockBuilder.put("lines", linesBuilder.build());
      dataBuilder.add(blockBuilder.build());
    }
    return dataBuilder.build();
  }
}
