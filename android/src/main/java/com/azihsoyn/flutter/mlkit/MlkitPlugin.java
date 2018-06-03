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
    final MethodChannel channel = new MethodChannel(registrar.messenger(), "plugins.flutter.io/mlkit");
    channel.setMethodCallHandler(new MlkitPlugin());
    context = registrar.context();
  }

  @Override
  public void onMethodCall(MethodCall call, final Result result) {
    if (call.method.equals("FirebaseVisionTextDetector#detectFromPath")) {
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
      blockBuilder.put("rect_bottom", (double)blocks.get(i).getBoundingBox().bottom);
      blockBuilder.put("rect_top", (double)blocks.get(i).getBoundingBox().top);
      blockBuilder.put("rect_right", (double)blocks.get(i).getBoundingBox().right);
      blockBuilder.put("rect_left", (double)blocks.get(i).getBoundingBox().left);
      ImmutableList.Builder<ImmutableMap<String, Integer>> blockPointsBuilder =
              ImmutableList.<ImmutableMap<String, Integer>>builder();
      for (int p = 0; p < blocks.get(i).getCornerPoints().length; p++) {
          ImmutableMap.Builder<String, Integer> pointBuilder = ImmutableMap.<String, Integer>builder();
          pointBuilder.put("x", blocks.get(i).getCornerPoints()[p].x);
          pointBuilder.put("y", blocks.get(i).getCornerPoints()[p].y);
          blockPointsBuilder.add(pointBuilder.build());
      }
      blockBuilder.put("points", blockPointsBuilder.build());

      List<FirebaseVisionText.Line> lines = blocks.get(i).getLines();
      ImmutableList.Builder<ImmutableMap<String, Object>> linesBuilder = ImmutableList.<ImmutableMap<String, Object>>builder();
      for (int j = 0; j < lines.size(); j++) {
        ImmutableMap.Builder<String, Object> lineBuilder = ImmutableMap.<String, Object>builder();
        lineBuilder.put("text", lines.get(j).getText());
        lineBuilder.put("rect_bottom", (double)lines.get(j).getBoundingBox().bottom);
        lineBuilder.put("rect_top", (double)lines.get(j).getBoundingBox().top);
        lineBuilder.put("rect_right", (double)lines.get(j).getBoundingBox().right);
        lineBuilder.put("rect_left", (double)lines.get(j).getBoundingBox().left);
        ImmutableList.Builder<ImmutableMap<String, Integer>> linePointsBuilder = ImmutableList.<ImmutableMap<String, Integer>>builder();
        for (int p = 0; p < lines.get(j).getCornerPoints().length; p++) {
          ImmutableMap.Builder<String, Integer> pointBuilder = ImmutableMap.<String, Integer>builder();
          pointBuilder.put("x", lines.get(j).getCornerPoints()[p].x);
          pointBuilder.put("y", lines.get(j).getCornerPoints()[p].y);
          linePointsBuilder.add(pointBuilder.build());
        }
        lineBuilder.put("points", linePointsBuilder.build());

        List<FirebaseVisionText.Element> elements = lines.get(j).getElements();

        ImmutableList.Builder<ImmutableMap<String, Object>> elementsBuilder = ImmutableList.<ImmutableMap<String, Object>>builder();
        for (int k = 0; k < elements.size(); k++) {
          ImmutableMap.Builder<String, Object> elementBuilder = ImmutableMap.<String, Object>builder();
          elementBuilder.put("text", elements.get(k).getText());
          elementBuilder.put("rect_bottom", (double)elements.get(k).getBoundingBox().bottom);
          elementBuilder.put("rect_top", (double)elements.get(k).getBoundingBox().top);
          elementBuilder.put("rect_right", (double)elements.get(k).getBoundingBox().right);
          elementBuilder.put("rect_left", (double)elements.get(k).getBoundingBox().left);
          ImmutableList.Builder<ImmutableMap<String, Integer>> elementPointsBuilder = ImmutableList.<ImmutableMap<String, Integer>>builder();
          for (int p = 0; p < elements.get(k).getCornerPoints().length; p++) {
            ImmutableMap.Builder<String, Integer> pointBuilder = ImmutableMap.<String, Integer>builder();
            pointBuilder.put("x", elements.get(k).getCornerPoints()[p].x);
            pointBuilder.put("y", elements.get(k).getCornerPoints()[p].y);
            elementPointsBuilder.add(pointBuilder.build());
          }
          elementBuilder.put("points", elementPointsBuilder.build());
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
