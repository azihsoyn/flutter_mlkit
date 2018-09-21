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
import android.graphics.Point;
import android.graphics.Rect;
import android.net.Uri;
import com.google.common.collect.ImmutableList;
import com.google.common.collect.ImmutableMap;
import android.support.annotation.NonNull;
import com.google.android.gms.tasks.OnFailureListener;
import com.google.android.gms.tasks.OnSuccessListener;
import com.google.android.gms.tasks.Continuation;
import com.google.android.gms.tasks.Task;
import com.google.firebase.ml.vision.barcode.FirebaseVisionBarcode;
import com.google.firebase.ml.vision.barcode.FirebaseVisionBarcodeDetector;
import com.google.firebase.ml.vision.text.FirebaseVisionTextDetector;
import com.google.firebase.ml.vision.FirebaseVision;
import com.google.firebase.ml.vision.cloud.FirebaseVisionCloudDetectorOptions;
import com.google.firebase.ml.vision.cloud.text.FirebaseVisionCloudDocumentTextDetector;
import com.google.firebase.ml.vision.cloud.text.FirebaseVisionCloudText;
import com.google.firebase.ml.vision.common.FirebaseVisionImage;
import com.google.firebase.ml.vision.text.FirebaseVisionText;
import com.google.firebase.ml.vision.common.FirebaseVisionImageMetadata;
import com.google.firebase.ml.vision.face.FirebaseVisionFace;
import com.google.firebase.ml.vision.face.FirebaseVisionFaceDetector;
import com.google.firebase.ml.vision.face.FirebaseVisionFaceLandmark;
import com.google.firebase.ml.vision.face.FirebaseVisionFaceDetectorOptions;
import com.google.firebase.ml.vision.label.FirebaseVisionLabel;
import com.google.firebase.ml.vision.label.FirebaseVisionLabelDetector;
import com.google.firebase.ml.common.FirebaseMLException;
import com.google.firebase.ml.custom.FirebaseModelDataType;
import com.google.firebase.ml.custom.FirebaseModelInputOutputOptions;
import com.google.firebase.ml.custom.FirebaseModelInputs;
import com.google.firebase.ml.custom.FirebaseModelInterpreter;
import com.google.firebase.ml.custom.FirebaseModelManager;
import com.google.firebase.ml.custom.FirebaseModelOptions;
import com.google.firebase.ml.custom.FirebaseModelOutputs;
import com.google.firebase.ml.custom.model.FirebaseCloudModelSource;
import com.google.firebase.ml.custom.model.FirebaseLocalModelSource;
import com.google.firebase.ml.custom.model.FirebaseModelDownloadConditions;
import android.graphics.Bitmap;
import android.media.Image;
import java.io.IOException;
import android.util.Log;
import android.util.Pair;

import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.AbstractMap;
import java.util.List;
import java.util.Map;
import java.util.Collections;
import java.util.Iterator;
import java.util.PriorityQueue;
import java.util.Comparator;

/**
 * MlkitPlugin
 */
public class MlkitPlugin implements MethodCallHandler {
  private static Context context;

  private static final List<Integer> LandmarkTypes = Collections.unmodifiableList( new ArrayList<Integer>() {{
    add(FirebaseVisionFaceLandmark.BOTTOM_MOUTH);
    add(FirebaseVisionFaceLandmark.RIGHT_MOUTH);
    add(FirebaseVisionFaceLandmark.LEFT_MOUTH);
    add(FirebaseVisionFaceLandmark.RIGHT_EYE);
    add(FirebaseVisionFaceLandmark.LEFT_EYE);
    add(FirebaseVisionFaceLandmark.RIGHT_EAR);
    add(FirebaseVisionFaceLandmark.LEFT_EAR);
    add(FirebaseVisionFaceLandmark.RIGHT_CHEEK);
    add(FirebaseVisionFaceLandmark.LEFT_CHEEK);
    add(FirebaseVisionFaceLandmark.NOSE_BASE);
  }} );
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

    FirebaseVisionImage image = null;

    if(call.method.endsWith("#detectFromPath")) {
      String path = call.argument("filepath");
      File file = new File(path);

      try {
        image = FirebaseVisionImage.fromFilePath(context, Uri.fromFile(file));
      } catch (IOException e) {
        Log.e("error", e.getMessage());
        return;
      }
    } else if (call.method.endsWith("#detectFromBinary")) {
      byte[] bytes = call.argument("binary");
      Bitmap bitmap = BitmapFactory.decodeByteArray(bytes , 0, bytes.length);
      image = FirebaseVisionImage.fromBitmap(bitmap);
    } else {
      result.notImplemented();
    }

    if (call.method.startsWith("FirebaseVisionTextDetector#detectFrom")) {
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
    } else if (call.method.startsWith("FirebaseVisionBarcodeDetector#detectFrom")) {
      FirebaseVisionBarcodeDetector detector = FirebaseVision.getInstance()
              .getVisionBarcodeDetector();
      detector.detectInImage(image)
              .addOnSuccessListener(
                      new OnSuccessListener<List<FirebaseVisionBarcode>>() {
                        @Override
                        public void onSuccess(List<FirebaseVisionBarcode> barcodes) {
                          result.success(processBarcodeRecognitionResult(barcodes));
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
    } else if (call.method.startsWith("FirebaseVisionLabelDetector#detectFrom")){
      FirebaseVisionLabelDetector detector = FirebaseVision.getInstance()
              .getVisionLabelDetector();
      detector.detectInImage(image)
              .addOnSuccessListener(
                      new OnSuccessListener<List<FirebaseVisionLabel>>() {
                        @Override
                        public void onSuccess(List<FirebaseVisionLabel> labels) {
                          result.success(processImageLabelingResult(labels));
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
    } else if (call.method.startsWith("FirebaseVisionFaceDetector#detectFrom")){
      FirebaseVisionFaceDetector detector;
      if (call.argument("option") != null) {
        Map<String, Object> optionsMap = call.argument("option");
        FirebaseVisionFaceDetectorOptions options =
                new FirebaseVisionFaceDetectorOptions.Builder()
                        .setModeType((int)optionsMap.get("modeType"))
                        .setLandmarkType((int)optionsMap.get("landmarkType"))
                        .setClassificationType((int)optionsMap.get("classificationType"))
                        .setMinFaceSize((float)(double)optionsMap.get("minFaceSize"))
                        .setTrackingEnabled((boolean)optionsMap.get("isTrackingEnabled"))
                        .build();
        detector = FirebaseVision.getInstance()
                .getVisionFaceDetector(options);
      } else {
        detector = FirebaseVision.getInstance()
                .getVisionFaceDetector();
      }
      detector.detectInImage(image)
              .addOnSuccessListener(
                      new OnSuccessListener<List<FirebaseVisionFace>>() {
                        @Override
                        public void onSuccess(List<FirebaseVisionFace> faces) {
                          result.success(processFaceDetectionResult(faces));
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
    } else if (call.method.equals("FirebaseModelManager#registerCloudModelSource")) {
      FirebaseModelManager manager = FirebaseModelManager.getInstance();

      if (call.argument("source") != null) {
        Map<String, Object> sourceMap = call.argument("source");
        String modelName = (String)sourceMap.get("modelName");
        Boolean enableModelUpdates = (Boolean)sourceMap.get("enableModelUpdates");
        FirebaseCloudModelSource.Builder cloudSourceBuilder = new FirebaseCloudModelSource.Builder(modelName);
        cloudSourceBuilder.enableModelUpdates(enableModelUpdates);

        if(sourceMap.get("initialDownloadConditions") != null) {
          Map<String, Boolean> conditionMap = (Map<String, Boolean>)sourceMap.get("initialDownloadConditions");
          FirebaseModelDownloadConditions.Builder conditionsBuilder = new FirebaseModelDownloadConditions.Builder();
          if(conditionMap.get("requireWifi")) {
            conditionsBuilder.requireWifi();
          }
          if(conditionMap.get("requireDeviceIdle")) {
            conditionsBuilder.requireDeviceIdle();
          }
          if(conditionMap.get("requireCharging")) {
            conditionsBuilder.requireCharging();
          }
          cloudSourceBuilder.setInitialDownloadConditions(conditionsBuilder.build());
        }

        if(sourceMap.get("updatesDownloadConditions") != null) {
          Map<String, Boolean> conditionMap = (Map<String, Boolean>)sourceMap.get("updatesDownloadConditions");
          FirebaseModelDownloadConditions.Builder conditionsBuilder = new FirebaseModelDownloadConditions.Builder();
          if(conditionMap.get("requireWifi")) {
            conditionsBuilder.requireWifi();
          }
          if(conditionMap.get("requireDeviceIdle")) {
            conditionsBuilder.requireDeviceIdle();
          }
          if(conditionMap.get("requireCharging")) {
            conditionsBuilder.requireCharging();
          }
          cloudSourceBuilder.setUpdatesDownloadConditions(conditionsBuilder.build());
        }

        manager.registerCloudModelSource(cloudSourceBuilder.build());
      }
    } else if (call.method.equals("FirebaseModelManager#registerLocalModelSource")) {
        FirebaseModelManager manager = FirebaseModelManager.getInstance();
        // TODO: next release

    } else if (call.method.equals("FirebaseModelInterpreter#run")) {
      FirebaseModelInterpreter mInterpreter;
      String cloudModelName = call.argument("cloudModelName");
      try {
        FirebaseModelOptions modelOptions = new FirebaseModelOptions.Builder()
                .setCloudModelName(cloudModelName)
                // TODO: local model
                //.setLocalModelName("my_local_model")
                .build();

        Map<String, Object> inputOutputOptionsMap = call.argument("inputOutputOptions");
        int inputIndex = (int)inputOutputOptionsMap.get("inputIndex");
        int inputDataType = (int)inputOutputOptionsMap.get("inputDataType");
        ArrayList<Integer> _inputDims = (ArrayList<Integer>)inputOutputOptionsMap.get("inputDims");
        final int[] inputDims = toArray(_inputDims);
        int outputIndex = (int)inputOutputOptionsMap.get("outputIndex");
        final int outputDataType = (int)inputOutputOptionsMap.get("outputDataType");
        ArrayList<Integer> _outputDims = (ArrayList<Integer>)inputOutputOptionsMap.get("outputDims");
        int[] outputDims = toArray(_outputDims);
        FirebaseModelInputOutputOptions inputOutputOptions =
                new FirebaseModelInputOutputOptions.Builder()
                        .setInputFormat(inputIndex, inputDataType, inputDims)
                        .setOutputFormat(outputIndex, outputDataType, outputDims)
                        .build();

        byte[] data = (byte[])call.argument("inputBytes");

        mInterpreter = FirebaseModelInterpreter.getInstance(modelOptions);
        ByteBuffer buffer = ByteBuffer.allocateDirect(toDim(_inputDims));
        buffer.order(ByteOrder.nativeOrder());
        buffer.rewind();
        buffer.put(data);

        FirebaseModelInputs inputs = new FirebaseModelInputs.Builder().add(buffer).build();
        mInterpreter
                .run(inputs, inputOutputOptions)
                .addOnFailureListener(new OnFailureListener() {
                  @Override
                  public void onFailure(@NonNull Exception e) {
                    e.printStackTrace();
                    Log.e("error", e.toString());
                    return;
                  }
                })
                .continueWith(
                        new Continuation<FirebaseModelOutputs, List<String>>() {
                          @Override
                          public List<String> then(Task<FirebaseModelOutputs> task) {
                            switch(outputDataType){
                              case FirebaseModelDataType.BYTE:
                                result.success(task.getResult().<byte[][]>getOutput(0)[0]);
                              case FirebaseModelDataType.FLOAT32:
                                result.success(task.getResult().<float[][]>getOutput(0)[0]);
                              case FirebaseModelDataType.INT32:
                                result.success(task.getResult().<int[][]>getOutput(0)[0]);
                              case FirebaseModelDataType.LONG:
                                result.success(task.getResult().<long[][]>getOutput(0)[0]);
                              default:
                                result.success(null);
                            }
                            return null;
                          }
                        });
      } catch (FirebaseMLException e) {
        e.printStackTrace();
        Log.e("error",e.getMessage());
        return;
      }
    } else {
      result.notImplemented();
    }
  }

  public static int[] toArray(ArrayList<Integer> list){
    // List<Integer> -> int[]
    int l = list.size();
    int[] arr = new int[l];
    Iterator<Integer> iter = list.iterator();
    for (int i=0;i<l;i++) arr[i] = iter.next();
    return arr;
  }

  public static int toDim(ArrayList<Integer> list){
    int l = list.size();
    int dim = 1;
    Iterator<Integer> iter = list.iterator();
    for (int i=0;i<l;i++) dim = dim * iter.next();
    return dim;
  }

  private ImmutableList<ImmutableMap<String, Object>> processBarcodeRecognitionResult(List<FirebaseVisionBarcode> barcodes) {
    ImmutableList.Builder<ImmutableMap<String, Object>> dataBuilder =
            ImmutableList.<ImmutableMap<String, Object>>builder();

    for (FirebaseVisionBarcode barcode: barcodes) {
      ImmutableMap.Builder<String, Object> barcodeBuilder = ImmutableMap.<String, Object>builder();

      Rect bounds = barcode.getBoundingBox();
      barcodeBuilder.put("rect_bottom", (double)bounds.bottom);
      barcodeBuilder.put("rect_top", (double)bounds.top);
      barcodeBuilder.put("rect_right", (double)bounds.right);
      barcodeBuilder.put("rect_left", (double)bounds.left);

      ImmutableList.Builder<ImmutableMap<String, Integer>> pointsBuilder =
              ImmutableList.<ImmutableMap<String, Integer>>builder();
      for (Point corner : barcode.getCornerPoints()) {
        ImmutableMap.Builder<String, Integer> pointBuilder = ImmutableMap.<String, Integer>builder();
        pointBuilder.put("x", corner.x);
        pointBuilder.put("y", corner.y);
        pointsBuilder.add(pointBuilder.build());
      }
      barcodeBuilder.put("points", pointsBuilder.build());
      barcodeBuilder.put("raw_value", barcode.getRawValue());
      barcodeBuilder.put("display_value", barcode.getDisplayValue());
      barcodeBuilder.put("format", barcode.getFormat());

      int valueType = barcode.getValueType();
      barcodeBuilder.put("value_type", valueType);

      ImmutableMap.Builder<String, Object> typeValueBuilder = ImmutableMap.<String, Object>builder();
      switch (valueType) {
        case FirebaseVisionBarcode.TYPE_EMAIL:
          typeValueBuilder.put("type", barcode.getEmail().getType());
          typeValueBuilder.put("address", barcode.getEmail().getAddress());
          typeValueBuilder.put("body", barcode.getEmail().getBody());
          typeValueBuilder.put("subject", barcode.getEmail().getSubject());
          barcodeBuilder.put("email", typeValueBuilder.build());
          break;
        case FirebaseVisionBarcode.TYPE_PHONE:
          typeValueBuilder.put("number", barcode.getPhone().getNumber());
          typeValueBuilder.put("type", barcode.getPhone().getType());
          barcodeBuilder.put("phone", typeValueBuilder.build());
          break;
        case FirebaseVisionBarcode.TYPE_SMS:
          typeValueBuilder.put("message", barcode.getSms().getMessage());
          typeValueBuilder.put("phone_number", barcode.getSms().getPhoneNumber());
          barcodeBuilder.put("sms", typeValueBuilder.build());
          break;
        case FirebaseVisionBarcode.TYPE_URL:
          typeValueBuilder.put("title", barcode.getUrl().getTitle());
          typeValueBuilder.put("url", barcode.getUrl().getUrl());
          barcodeBuilder.put("url", typeValueBuilder.build());
          break;
        case FirebaseVisionBarcode.TYPE_WIFI:
          typeValueBuilder.put("ssid", barcode.getWifi().getSsid());
          typeValueBuilder.put("password", barcode.getWifi().getPassword());
          typeValueBuilder.put("encryption_type", barcode.getWifi().getEncryptionType());
          barcodeBuilder.put("wifi", typeValueBuilder.build());
          break;
        case FirebaseVisionBarcode.TYPE_GEO:
          typeValueBuilder.put("latitude", barcode.getGeoPoint().getLat());
          typeValueBuilder.put("longitude", barcode.getGeoPoint().getLng());
          barcodeBuilder.put("geo_point", typeValueBuilder.build());
          break;
        case FirebaseVisionBarcode.TYPE_CONTACT_INFO:
          ImmutableList.Builder<ImmutableMap<String, Object>> addressesBuilder =
                  ImmutableList.builder();
          for (FirebaseVisionBarcode.Address address : barcode.getContactInfo().getAddresses()) {
            ImmutableMap.Builder<String, Object> addressBuilder = ImmutableMap.builder();
            addressBuilder.put("address_lines", address.getAddressLines());
            addressBuilder.put("type", address.getType());
            addressesBuilder.add(addressBuilder.build());
          }
          typeValueBuilder.put("addresses", addressesBuilder.build());

          ImmutableList.Builder<ImmutableMap<String, Object>> emailsBuilder =
                  ImmutableList.builder();
          for (FirebaseVisionBarcode.Email email : barcode.getContactInfo().getEmails()) {
            ImmutableMap.Builder<String, Object> emailBuilder = ImmutableMap.builder();
            emailBuilder.put("address", email.getAddress());
            emailBuilder.put("type", email.getType());
            emailBuilder.put("body", email.getBody());
            emailBuilder.put("subject", email.getSubject());
            emailsBuilder.add(emailBuilder.build());
          }
          typeValueBuilder.put("emails", emailsBuilder.build());

          ImmutableMap.Builder<String, Object> nameBuilder = ImmutableMap.builder();
          nameBuilder.put("formatted_name",  barcode.getContactInfo().getName().getFormattedName());
          nameBuilder.put("first", barcode.getContactInfo().getName().getFirst());
          nameBuilder.put("last", barcode.getContactInfo().getName().getLast());
          nameBuilder.put("middle", barcode.getContactInfo().getName().getMiddle());
          nameBuilder.put("prefix", barcode.getContactInfo().getName().getPrefix());
          nameBuilder.put("pronounciation", barcode.getContactInfo().getName().getPronunciation());
          nameBuilder.put("suffix", barcode.getContactInfo().getName().getSuffix());
          typeValueBuilder.put("name", nameBuilder.build());


          ImmutableList.Builder<ImmutableMap<String, Object>> phonesBuilder =
                  ImmutableList.builder();
          for (FirebaseVisionBarcode.Phone phone : barcode.getContactInfo().getPhones()) {
            ImmutableMap.Builder<String, Object> phoneBuilder = ImmutableMap.builder();
            phoneBuilder.put("number", phone.getNumber());
            phoneBuilder.put("type", phone.getType());
            phonesBuilder.add(phoneBuilder.build());
          }
          typeValueBuilder.put("phones", phonesBuilder.build());

          typeValueBuilder.put("urls", barcode.getContactInfo().getUrls());
          typeValueBuilder.put("job_title", barcode.getContactInfo().getTitle());
          typeValueBuilder.put("organization", barcode.getContactInfo().getOrganization());

          barcodeBuilder.put("contact_info", typeValueBuilder.build());
          break;
        case FirebaseVisionBarcode.TYPE_CALENDAR_EVENT:
          typeValueBuilder.put("event_description", barcode.getCalendarEvent().getDescription());
          typeValueBuilder.put("location", barcode.getCalendarEvent().getLocation());
          typeValueBuilder.put("organizer", barcode.getCalendarEvent().getOrganizer());
          typeValueBuilder.put("status", barcode.getCalendarEvent().getStatus());
          typeValueBuilder.put("summary", barcode.getCalendarEvent().getSummary());
          typeValueBuilder.put("start", barcode.getCalendarEvent().getStart().getRawValue());
          typeValueBuilder.put("end", barcode.getCalendarEvent().getEnd().getRawValue());
          barcodeBuilder.put("calendar_event", typeValueBuilder.build());
          break;
        case FirebaseVisionBarcode.TYPE_DRIVER_LICENSE:
          typeValueBuilder.put("first_name", barcode.getDriverLicense().getFirstName());
          typeValueBuilder.put("middle_name", barcode.getDriverLicense().getMiddleName());
          typeValueBuilder.put("last_name", barcode.getDriverLicense().getLastName());
          typeValueBuilder.put("gender", barcode.getDriverLicense().getGender());
          typeValueBuilder.put("address_city", barcode.getDriverLicense().getAddressCity());
          typeValueBuilder.put("address_state", barcode.getDriverLicense().getAddressState());
          typeValueBuilder.put("address_zip", barcode.getDriverLicense().getAddressZip());
          typeValueBuilder.put("birth_date", barcode.getDriverLicense().getBirthDate());
          typeValueBuilder.put("document_type", barcode.getDriverLicense().getDocumentType());
          typeValueBuilder.put("license_number", barcode.getDriverLicense().getLicenseNumber());
          typeValueBuilder.put("expiry_date", barcode.getDriverLicense().getExpiryDate());
          typeValueBuilder.put("issuing_date", barcode.getDriverLicense().getIssueDate());
          typeValueBuilder.put("issuing_country", barcode.getDriverLicense().getIssuingCountry());
          barcodeBuilder.put("calendar_event", typeValueBuilder.build());
          break;
      }

      dataBuilder.add(barcodeBuilder.build());
    }

    return dataBuilder.build();
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

  private ImmutableList<ImmutableMap<String, Object>> processFaceDetectionResult(List<FirebaseVisionFace> faces) {
    ImmutableList.Builder<ImmutableMap<String, Object>> dataBuilder =
            ImmutableList.<ImmutableMap<String, Object>>builder();

    for (FirebaseVisionFace face: faces) {
      ImmutableMap.Builder<String, Object> faceBuilder = ImmutableMap.<String, Object>builder();
      faceBuilder.put("rect_bottom", (double)face.getBoundingBox().bottom);
      faceBuilder.put("rect_top", (double)face.getBoundingBox().top);
      faceBuilder.put("rect_right", (double)face.getBoundingBox().right);
      faceBuilder.put("rect_left", (double)face.getBoundingBox().left);
      faceBuilder.put("tracking_id", (int)face.getTrackingId());
      faceBuilder.put("head_euler_angle_y", face.getHeadEulerAngleY());
      faceBuilder.put("head_euler_angle_z", face.getHeadEulerAngleZ());
      faceBuilder.put("smiling_probability", face.getSmilingProbability());
      faceBuilder.put("right_eye_open_probability", face.getRightEyeOpenProbability());
      faceBuilder.put("left_eye_open_probability", face.getLeftEyeOpenProbability());
      ImmutableMap.Builder<Integer, Object> landmarksBuilder = ImmutableMap.<Integer, Object>builder();
      for (Integer landmarkType: LandmarkTypes) {
        ImmutableMap.Builder<String, Object> landmarkBuilder = ImmutableMap.<String, Object>builder();
        ImmutableMap.Builder<String, Object> positionkBuilder = ImmutableMap.<String, Object>builder();
        FirebaseVisionFaceLandmark landmark = face.getLandmark(landmarkType);
        if(landmark != null) {
          positionkBuilder.put("x", landmark.getPosition().getX());
          positionkBuilder.put("y", landmark.getPosition().getY());
          if(landmark.getPosition().getZ() != null) {
            positionkBuilder.put("z", landmark.getPosition().getZ());
          }
          landmarkBuilder.put("position", positionkBuilder.build());
          landmarkBuilder.put("type", landmarkType);
          landmarksBuilder.put(landmarkType, landmarkBuilder.build());
        }
      }
      faceBuilder.put("landmarks", landmarksBuilder.build());


      dataBuilder.add(faceBuilder.build());
    }

    return dataBuilder.build();
  }

  private ImmutableList<ImmutableMap<String, Object>> processImageLabelingResult(List<FirebaseVisionLabel> labels) {
    ImmutableList.Builder<ImmutableMap<String, Object>> dataBuilder =
            ImmutableList.<ImmutableMap<String, Object>>builder();

    for (FirebaseVisionLabel label: labels) {
      ImmutableMap.Builder<String, Object> labelBuilder = ImmutableMap.<String, Object>builder();

      labelBuilder.put("label", label.getLabel());
      labelBuilder.put("entityID", label.getEntityId());
      labelBuilder.put("confidence", label.getConfidence());

      dataBuilder.add(labelBuilder.build());
    }

    return dataBuilder.build();
  }
}
