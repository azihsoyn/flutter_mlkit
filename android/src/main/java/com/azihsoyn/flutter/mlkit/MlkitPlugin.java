package com.azihsoyn.flutter.mlkit;

import android.app.Activity;
import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Matrix;
import android.graphics.Point;
import android.graphics.Rect;
import android.media.ExifInterface;
import android.net.Uri;
import android.content.res.AssetManager;
import android.content.res.AssetFileDescriptor;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import android.util.Log;

import com.google.android.gms.tasks.Continuation;
import com.google.android.gms.tasks.OnFailureListener;
import com.google.android.gms.tasks.OnSuccessListener;
import com.google.android.gms.tasks.Task;
import com.google.common.collect.ImmutableList;
import com.google.common.collect.ImmutableMap;
import com.google.firebase.ml.common.FirebaseMLException;
import com.google.firebase.ml.common.modeldownload.FirebaseModelDownloadConditions;
import com.google.firebase.ml.common.modeldownload.FirebaseModelManager;
import com.google.firebase.ml.common.modeldownload.FirebaseRemoteModel;
import com.google.firebase.ml.common.modeldownload.FirebaseLocalModel;
import com.google.firebase.ml.custom.FirebaseModelDataType;
import com.google.firebase.ml.custom.FirebaseModelInputOutputOptions;
import com.google.firebase.ml.custom.FirebaseModelInputs;
import com.google.firebase.ml.custom.FirebaseModelInterpreter;
import com.google.firebase.ml.custom.FirebaseModelOptions;
import com.google.firebase.ml.custom.FirebaseModelOutputs;

import com.google.firebase.ml.naturallanguage.FirebaseNaturalLanguage;
import com.google.firebase.ml.naturallanguage.languageid.FirebaseLanguageIdentification;
import com.google.firebase.ml.vision.FirebaseVision;
import com.google.firebase.ml.vision.barcode.FirebaseVisionBarcode;
import com.google.firebase.ml.vision.barcode.FirebaseVisionBarcodeDetector;
import com.google.firebase.ml.vision.common.FirebaseVisionImage;
import com.google.firebase.ml.vision.face.FirebaseVisionFace;
import com.google.firebase.ml.vision.face.FirebaseVisionFaceDetector;
import com.google.firebase.ml.vision.face.FirebaseVisionFaceDetectorOptions;
import com.google.firebase.ml.vision.face.FirebaseVisionFaceLandmark;
import com.google.firebase.ml.vision.label.FirebaseVisionImageLabel;
import com.google.firebase.ml.vision.label.FirebaseVisionImageLabeler;
import com.google.firebase.ml.vision.text.FirebaseVisionText;
import com.google.firebase.ml.vision.text.FirebaseVisionTextRecognizer;

import java.io.ByteArrayInputStream;
import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.lang.reflect.Array;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.FloatBuffer;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Objects;

import java.io.ByteArrayInputStream;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;

/**
 * MlkitPlugin
 */
public class MlkitPlugin implements MethodCallHandler {
    private static final List<Integer> LandmarkTypes = Collections.unmodifiableList(new ArrayList<Integer>() {
        {
            add(FirebaseVisionFaceLandmark.MOUTH_BOTTOM);
            add(FirebaseVisionFaceLandmark.MOUTH_RIGHT);
            add(FirebaseVisionFaceLandmark.MOUTH_LEFT);
            add(FirebaseVisionFaceLandmark.RIGHT_EYE);
            add(FirebaseVisionFaceLandmark.LEFT_EYE);
            add(FirebaseVisionFaceLandmark.RIGHT_EAR);
            add(FirebaseVisionFaceLandmark.LEFT_EAR);
            add(FirebaseVisionFaceLandmark.RIGHT_CHEEK);
            add(FirebaseVisionFaceLandmark.LEFT_CHEEK);
            add(FirebaseVisionFaceLandmark.NOSE_BASE);
        }
    });
    private static Context context;
    private static Activity activity;

    /**
     * Plugin registration.
     */
    public static void registerWith(Registrar registrar) {
        final MethodChannel channel = new MethodChannel(registrar.messenger(), "plugins.flutter.io/mlkit");
        channel.setMethodCallHandler(new MlkitPlugin());
        context = registrar.context();
        activity = registrar.activity();
    }

    public static int[] toArray(ArrayList<Integer> list) {
        // List<Integer> -> int[]
        int l = list.size();
        int[] arr = new int[l];
        Iterator<Integer> iter = list.iterator();
        for (int i = 0; i < l; i++)
            arr[i] = iter.next();
        return arr;
    }

    public static int toDim(ArrayList<Integer> list) {
        int l = list.size();
        int dim = 1;
        Iterator<Integer> iter = list.iterator();
        for (int i = 0; i < l; i++)
            dim = dim * iter.next();
        return dim;
    }

    @Override
    public void onMethodCall(MethodCall call, final Result result) {

        FirebaseVisionImage image = null;

        if (call.method.endsWith("#detectFromPath")) {
            String path = call.argument("filepath");
            File file = new File(path);
            BitmapFactory.Options bounds = new BitmapFactory.Options();
            bounds.inJustDecodeBounds = true;
            BitmapFactory.decodeFile(file.getAbsolutePath(), bounds);
            BitmapFactory.Options opts = new BitmapFactory.Options();
            Bitmap bm = BitmapFactory.decodeFile(file.getAbsolutePath(), opts);

            try {
                InputStream in = activity.getContentResolver().openInputStream(Uri.fromFile(file));
                int rotationAngle = getRotationAngle(in);

                Bitmap rotatedBitmap = createRotatedBitmap(bm, bounds, rotationAngle);

                image = FirebaseVisionImage.fromBitmap(rotatedBitmap);
            } catch (IOException e) {
                Log.e("error", e.getMessage());
                return;
            }
        } else if (call.method.endsWith("#detectFromBinary")) {
            byte[] bytes = call.argument("binary");
            BitmapFactory.Options bounds = new BitmapFactory.Options();
            bounds.inJustDecodeBounds = true;
            BitmapFactory.decodeByteArray(bytes, 0, bytes.length, bounds);
            BitmapFactory.Options opts = new BitmapFactory.Options();
            Bitmap bm = BitmapFactory.decodeByteArray(bytes, 0, bytes.length, opts);

            try {
                InputStream in = new ByteArrayInputStream(bytes);
                int rotationAngle = getRotationAngle(in);

                Bitmap rotatedBitmap = createRotatedBitmap(bm, bounds, rotationAngle);

                image = FirebaseVisionImage.fromBitmap(rotatedBitmap);
            } catch (IOException e) {
                Log.e("error", e.getMessage());
                return;
            }
        }

        if (call.method.startsWith("FirebaseVisionTextDetector#detectFrom")) {
            FirebaseVisionTextRecognizer detector = FirebaseVision.getInstance().getOnDeviceTextRecognizer();
            detector.processImage(image).addOnSuccessListener(new OnSuccessListener<FirebaseVisionText>() {
                @Override
                public void onSuccess(FirebaseVisionText texts) {
                    result.success(processTextRecognitionResult(texts));
                }
            }).addOnFailureListener(new OnFailureListener() {
                @Override
                public void onFailure(@NonNull Exception e) {
                    // Task failed with an exception
                    e.printStackTrace();
                }
            });
        } else if (call.method.startsWith("FirebaseVisionBarcodeDetector#detectFrom")) {
            FirebaseVisionBarcodeDetector detector = FirebaseVision.getInstance().getVisionBarcodeDetector();
            detector.detectInImage(image).addOnSuccessListener(new OnSuccessListener<List<FirebaseVisionBarcode>>() {
                @Override
                public void onSuccess(List<FirebaseVisionBarcode> barcodes) {
                    result.success(processBarcodeRecognitionResult(barcodes));
                }
            }).addOnFailureListener(new OnFailureListener() {
                @Override
                public void onFailure(@NonNull Exception e) {
                    // Task failed with an exception
                    e.printStackTrace();
                }
            });
        } else if (call.method.startsWith("FirebaseVisionLabelDetector#detectFrom")) {
            FirebaseVisionImageLabeler detector = FirebaseVision.getInstance()
                    .getOnDeviceImageLabeler();
            detector.processImage(image)
                    .addOnSuccessListener(
                            new OnSuccessListener<List<FirebaseVisionImageLabel>>() {
                                @Override
                                public void onSuccess(List<FirebaseVisionImageLabel> labels) {
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
        } else if (call.method.startsWith("FirebaseVisionFaceDetector#detectFrom")) {
            FirebaseVisionFaceDetector detector;
            if (call.argument("option") != null) {
                Map<String, Object> optionsMap = call.argument("option");
                FirebaseVisionFaceDetectorOptions.Builder builder = new FirebaseVisionFaceDetectorOptions.Builder()
                        .setPerformanceMode((int) optionsMap.get("modeType"))
                        .setLandmarkMode((int) optionsMap.get("landmarkType"))
                        .setClassificationMode((int) optionsMap.get("classificationType"))
                        .setMinFaceSize((float) (double) optionsMap.get("minFaceSize"));
                if ((boolean) optionsMap.get("isTrackingEnabled")) {
                    builder.enableTracking();
                }
                FirebaseVisionFaceDetectorOptions options = builder.build();
                detector = FirebaseVision.getInstance().getVisionFaceDetector(options);
            } else {
                detector = FirebaseVision.getInstance().getVisionFaceDetector();
            }
            detector.detectInImage(image).addOnSuccessListener(new OnSuccessListener<List<FirebaseVisionFace>>() {
                @Override
                public void onSuccess(List<FirebaseVisionFace> faces) {
                    result.success(processFaceDetectionResult(faces));
                }
            }).addOnFailureListener(new OnFailureListener() {
                @Override
                public void onFailure(@NonNull Exception e) {
                    // Task failed with an exception
                    e.printStackTrace();
                }
            });
        } else if (call.method.equals("FirebaseModelManager#registerRemoteModelSource")) {
            FirebaseModelManager manager = FirebaseModelManager.getInstance();

            if (call.argument("source") != null) {
                Map<String, Object> sourceMap = call.argument("source");
                String modelName = (String) sourceMap.get("modelName");
                Boolean enableModelUpdates = (Boolean) sourceMap.get("enableModelUpdates");
                FirebaseRemoteModel.Builder cloudSourceBuilder = new FirebaseRemoteModel.Builder(modelName);
                cloudSourceBuilder.enableModelUpdates(enableModelUpdates);

                if (sourceMap.get("initialDownloadConditions") != null) {
                    Map<String, Boolean> conditionMap = (Map<String, Boolean>) sourceMap
                            .get("initialDownloadConditions");
                    FirebaseModelDownloadConditions.Builder conditionsBuilder = new FirebaseModelDownloadConditions.Builder();
                    if (conditionMap.get("requireWifi")) {
                        conditionsBuilder.requireWifi();
                    }
                    if (conditionMap.get("requireDeviceIdle")) {
                        conditionsBuilder.requireDeviceIdle();
                    }
                    if (conditionMap.get("requireCharging")) {
                        conditionsBuilder.requireCharging();
                    }
                    cloudSourceBuilder.setInitialDownloadConditions(conditionsBuilder.build());
                }

                if (sourceMap.get("updatesDownloadConditions") != null) {
                    Map<String, Boolean> conditionMap = (Map<String, Boolean>) sourceMap
                            .get("updatesDownloadConditions");
                    FirebaseModelDownloadConditions.Builder conditionsBuilder = new FirebaseModelDownloadConditions.Builder();
                    if (conditionMap.get("requireWifi")) {
                        conditionsBuilder.requireWifi();
                    }
                    if (conditionMap.get("requireDeviceIdle")) {
                        conditionsBuilder.requireDeviceIdle();
                    }
                    if (conditionMap.get("requireCharging")) {
                        conditionsBuilder.requireCharging();
                    }
                    cloudSourceBuilder.setUpdatesDownloadConditions(conditionsBuilder.build());
                }
                FirebaseRemoteModel model = cloudSourceBuilder.build();
                manager.registerRemoteModel(model);
                manager.downloadRemoteModelIfNeeded(model);

            }
        } else if (call.method.equals("FirebaseModelManager#registerLocalModelSource")) {
            FirebaseModelManager manager = FirebaseModelManager.getInstance();

            if (call.argument("source") != null) {
                Map<String, Object> sourceMap = call.argument("source");
                String modelName = (String) sourceMap.get("modelName");
                String assetFilePath = (String) sourceMap.get("assetFilePath");
                FirebaseLocalModel localSource =
                        new FirebaseLocalModel.Builder(modelName)
                                .setAssetFilePath("flutter_assets/"+assetFilePath)
                                .build();
                FirebaseModelManager.getInstance().registerLocalModel(localSource);
            }

        } else if (call.method.equals("FirebaseModelInterpreter#run")) {
            FirebaseModelInterpreter mInterpreter;
            String remoteModelName = call.argument("remoteModelName");
            String localModelName = call.argument("localModelName");
            try {

                FirebaseModelOptions.Builder builder = new FirebaseModelOptions.Builder();

                if (remoteModelName != null) {
                    builder.setRemoteModelName(remoteModelName);
                }
                if (localModelName != null) {
                    builder.setLocalModelName(localModelName);
                }
                FirebaseModelOptions modelOptions = builder.build();
                FirebaseModelInputOutputOptions.Builder ioBuilder = new FirebaseModelInputOutputOptions.Builder();
                FirebaseModelInputs.Builder inputsBuilder = new FirebaseModelInputs.Builder();

                final byte[] data = (byte[]) call.argument("inputBytes");

                Map<String, List<Map<String, Object>>> inputOutputOptionsMap = call.argument("inputOutputOptions");

                List<Map<String, Object>> inputOptions = inputOutputOptionsMap.get("inputOptions");
                int offset = 0;
                for (int i = 0; i < inputOptions.size(); i++) {
                    int inputDataType = (int) inputOptions.get(i).get("dataType");
                    ArrayList<Integer> _inputDims = (ArrayList<Integer>) inputOptions.get(i).get("dims");
                    ioBuilder.setInputFormat(i, inputDataType, toArray(_inputDims));

                    int bytesPerChannel = 1;
                    if (inputDataType == FirebaseModelDataType.FLOAT32
                            || inputDataType == FirebaseModelDataType.INT32) {
                        bytesPerChannel = 4;
                    } else if (inputDataType == FirebaseModelDataType.LONG) {
                        bytesPerChannel = 8;
                    }
                    int length = toDim(_inputDims) * bytesPerChannel;
                    ByteBuffer buffer = ByteBuffer.allocateDirect(length);
                    buffer.order(ByteOrder.nativeOrder());
                    buffer.rewind();
                    buffer.put(data, offset, length);
                    offset += length;
                    inputsBuilder.add(buffer);
                }

                final List<Map<String, Object>> outputOptions = inputOutputOptionsMap.get("outputOptions");
                for (int i = 0; i < outputOptions.size(); i++) {
                    int outputDataType = (int) outputOptions.get(i).get("dataType");
                    ArrayList<Integer> _outputDims = (ArrayList<Integer>) outputOptions.get(i).get("dims");
                    ioBuilder.setOutputFormat(i, outputDataType, toArray(_outputDims));
                }

                FirebaseModelInputOutputOptions inputOutputOptions = ioBuilder.build();
                mInterpreter = FirebaseModelInterpreter.getInstance(modelOptions);
                FirebaseModelInputs inputs = inputsBuilder.build();

                mInterpreter.run(inputs, inputOutputOptions).addOnFailureListener(new OnFailureListener() {
                    @Override
                    public void onFailure(@NonNull Exception e) {
                        e.printStackTrace();
                        Log.e("FirebaseModelInterpreter", e.getMessage());
                        return;
                    }
                }).continueWith(new Continuation<FirebaseModelOutputs, List<String>>() {
                    @Override
                    public List<String> then(Task<FirebaseModelOutputs> task) {
                        try {
                            ImmutableList.Builder<Object> dataBuilder = ImmutableList.<Object>builder();
                            for (int i = 0; i < outputOptions.size(); i++) {
                                int outputDataType = (int) outputOptions.get(i).get("dataType");
                                int[] outputDims = toArray((ArrayList<Integer>) outputOptions.get(i).get("dims"));
                                Object res = task.getResult().getOutput(i);
                                switch (outputDataType) {
                                case FirebaseModelDataType.BYTE:
                                    dataBuilder.add(processList(byte.class, res));
                                    break;
                                case FirebaseModelDataType.INT32:
                                    dataBuilder.add(processList(int.class, res));
                                    break;
                                case FirebaseModelDataType.LONG:
                                    dataBuilder.add(processList(long.class, res));
                                    break;

                                case FirebaseModelDataType.FLOAT32:
                                    Log.d("Infer",res.toString());

                                    dataBuilder.add(processList(double.class, res));
                                    break;
                                default:
                                    break;
                                }
                            }
                            result.success(dataBuilder.build());
                        } catch (Exception e) {
                            e.printStackTrace();
                            Log.e("FirebaseModelInterpreter", e.getMessage());
                        }
                        return null;

                    }
                });
            } catch (FirebaseMLException e) {
                e.printStackTrace();
                Log.e("error", e.getMessage());
                return;
            }
        } else if (call.method.equals("getLanguage")) {
            FirebaseLanguageIdentification languageIdentifier = FirebaseNaturalLanguage.getInstance()
                    .getLanguageIdentification();
            languageIdentifier.identifyLanguage((String) call.argument("text"))
                    .addOnSuccessListener(new OnSuccessListener<String>() {
                        @Override
                        public void onSuccess(@Nullable String languageCode) {
                            if (!Objects.equals(languageCode, "und")) {
                                result.success(languageCode);
                            } else {
                                result.error("0", "Language not found", "Unknown Language");
                            }
                        }
                    }).addOnFailureListener(new OnFailureListener() {
                        @Override
                        public void onFailure(@NonNull Exception e) {
                            result.error("0", "Language not found", e);
                        }
                    });

        } else {
            result.notImplemented();
        }
    }

    private ImmutableList<ImmutableMap<String, Object>> processBarcodeRecognitionResult(
            List<FirebaseVisionBarcode> barcodes) {
        ImmutableList.Builder<ImmutableMap<String, Object>> dataBuilder = ImmutableList
                .<ImmutableMap<String, Object>>builder();

        for (FirebaseVisionBarcode barcode : barcodes) {
            ImmutableMap.Builder<String, Object> barcodeBuilder = ImmutableMap.<String, Object>builder();

            Rect bounds = barcode.getBoundingBox();
            barcodeBuilder.put("rect_bottom", (double) bounds.bottom);
            barcodeBuilder.put("rect_top", (double) bounds.top);
            barcodeBuilder.put("rect_right", (double) bounds.right);
            barcodeBuilder.put("rect_left", (double) bounds.left);

            ImmutableList.Builder<ImmutableMap<String, Integer>> pointsBuilder = ImmutableList
                    .<ImmutableMap<String, Integer>>builder();
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
                ImmutableList.Builder<ImmutableMap<String, Object>> addressesBuilder = ImmutableList.builder();
                for (FirebaseVisionBarcode.Address address : barcode.getContactInfo().getAddresses()) {
                    ImmutableMap.Builder<String, Object> addressBuilder = ImmutableMap.builder();
                    addressBuilder.put("address_lines", address.getAddressLines());
                    addressBuilder.put("type", address.getType());
                    addressesBuilder.add(addressBuilder.build());
                }
                typeValueBuilder.put("addresses", addressesBuilder.build());

                ImmutableList.Builder<ImmutableMap<String, Object>> emailsBuilder = ImmutableList.builder();
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
                nameBuilder.put("formatted_name", barcode.getContactInfo().getName().getFormattedName());
                nameBuilder.put("first", barcode.getContactInfo().getName().getFirst());
                nameBuilder.put("last", barcode.getContactInfo().getName().getLast());
                nameBuilder.put("middle", barcode.getContactInfo().getName().getMiddle());
                nameBuilder.put("prefix", barcode.getContactInfo().getName().getPrefix());
                nameBuilder.put("pronounciation", barcode.getContactInfo().getName().getPronunciation());
                nameBuilder.put("suffix", barcode.getContactInfo().getName().getSuffix());
                typeValueBuilder.put("name", nameBuilder.build());

                ImmutableList.Builder<ImmutableMap<String, Object>> phonesBuilder = ImmutableList.builder();
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
        ImmutableList.Builder<ImmutableMap<String, Object>> dataBuilder = ImmutableList
                .<ImmutableMap<String, Object>>builder();

        List<FirebaseVisionText.TextBlock> blocks = texts.getTextBlocks();
        if (blocks.size() == 0) {
            return null;
        }
        for (int i = 0; i < blocks.size(); i++) {
            ImmutableMap.Builder<String, Object> blockBuilder = ImmutableMap.<String, Object>builder();
            blockBuilder.put("text", blocks.get(i).getText());
            blockBuilder.put("rect_bottom", (double) blocks.get(i).getBoundingBox().bottom);
            blockBuilder.put("rect_top", (double) blocks.get(i).getBoundingBox().top);
            blockBuilder.put("rect_right", (double) blocks.get(i).getBoundingBox().right);
            blockBuilder.put("rect_left", (double) blocks.get(i).getBoundingBox().left);
            ImmutableList.Builder<ImmutableMap<String, Integer>> blockPointsBuilder = ImmutableList
                    .<ImmutableMap<String, Integer>>builder();
            for (int p = 0; p < blocks.get(i).getCornerPoints().length; p++) {
                ImmutableMap.Builder<String, Integer> pointBuilder = ImmutableMap.<String, Integer>builder();
                pointBuilder.put("x", blocks.get(i).getCornerPoints()[p].x);
                pointBuilder.put("y", blocks.get(i).getCornerPoints()[p].y);
                blockPointsBuilder.add(pointBuilder.build());
            }
            blockBuilder.put("points", blockPointsBuilder.build());

            List<FirebaseVisionText.Line> lines = blocks.get(i).getLines();
            ImmutableList.Builder<ImmutableMap<String, Object>> linesBuilder = ImmutableList
                    .<ImmutableMap<String, Object>>builder();
            for (int j = 0; j < lines.size(); j++) {
                ImmutableMap.Builder<String, Object> lineBuilder = ImmutableMap.<String, Object>builder();
                lineBuilder.put("text", lines.get(j).getText());
                lineBuilder.put("rect_bottom", (double) lines.get(j).getBoundingBox().bottom);
                lineBuilder.put("rect_top", (double) lines.get(j).getBoundingBox().top);
                lineBuilder.put("rect_right", (double) lines.get(j).getBoundingBox().right);
                lineBuilder.put("rect_left", (double) lines.get(j).getBoundingBox().left);
                ImmutableList.Builder<ImmutableMap<String, Integer>> linePointsBuilder = ImmutableList
                        .<ImmutableMap<String, Integer>>builder();
                for (int p = 0; p < lines.get(j).getCornerPoints().length; p++) {
                    ImmutableMap.Builder<String, Integer> pointBuilder = ImmutableMap.<String, Integer>builder();
                    pointBuilder.put("x", lines.get(j).getCornerPoints()[p].x);
                    pointBuilder.put("y", lines.get(j).getCornerPoints()[p].y);
                    linePointsBuilder.add(pointBuilder.build());
                }
                lineBuilder.put("points", linePointsBuilder.build());

                List<FirebaseVisionText.Element> elements = lines.get(j).getElements();

                ImmutableList.Builder<ImmutableMap<String, Object>> elementsBuilder = ImmutableList
                        .<ImmutableMap<String, Object>>builder();
                for (int k = 0; k < elements.size(); k++) {
                    ImmutableMap.Builder<String, Object> elementBuilder = ImmutableMap.<String, Object>builder();
                    elementBuilder.put("text", elements.get(k).getText());
                    elementBuilder.put("rect_bottom", (double) elements.get(k).getBoundingBox().bottom);
                    elementBuilder.put("rect_top", (double) elements.get(k).getBoundingBox().top);
                    elementBuilder.put("rect_right", (double) elements.get(k).getBoundingBox().right);
                    elementBuilder.put("rect_left", (double) elements.get(k).getBoundingBox().left);
                    ImmutableList.Builder<ImmutableMap<String, Integer>> elementPointsBuilder = ImmutableList
                            .<ImmutableMap<String, Integer>>builder();
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
        ImmutableList.Builder<ImmutableMap<String, Object>> dataBuilder = ImmutableList
                .<ImmutableMap<String, Object>>builder();

        for (FirebaseVisionFace face : faces) {
            ImmutableMap.Builder<String, Object> faceBuilder = ImmutableMap.<String, Object>builder();
            faceBuilder.put("rect_bottom", (double) face.getBoundingBox().bottom);
            faceBuilder.put("rect_top", (double) face.getBoundingBox().top);
            faceBuilder.put("rect_right", (double) face.getBoundingBox().right);
            faceBuilder.put("rect_left", (double) face.getBoundingBox().left);
            faceBuilder.put("tracking_id", (int) face.getTrackingId());
            faceBuilder.put("head_euler_angle_y", face.getHeadEulerAngleY());
            faceBuilder.put("head_euler_angle_z", face.getHeadEulerAngleZ());
            faceBuilder.put("smiling_probability", face.getSmilingProbability());
            faceBuilder.put("right_eye_open_probability", face.getRightEyeOpenProbability());
            faceBuilder.put("left_eye_open_probability", face.getLeftEyeOpenProbability());
            ImmutableMap.Builder<Integer, Object> landmarksBuilder = ImmutableMap.<Integer, Object>builder();
            for (Integer landmarkType : LandmarkTypes) {
                ImmutableMap.Builder<String, Object> landmarkBuilder = ImmutableMap.<String, Object>builder();
                ImmutableMap.Builder<String, Object> positionkBuilder = ImmutableMap.<String, Object>builder();
                FirebaseVisionFaceLandmark landmark = face.getLandmark(landmarkType);
                if (landmark != null) {
                    positionkBuilder.put("x", landmark.getPosition().getX());
                    positionkBuilder.put("y", landmark.getPosition().getY());
                    if (landmark.getPosition().getZ() != null) {
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

    private ImmutableList<ImmutableMap<String, Object>> processImageLabelingResult(List<FirebaseVisionImageLabel> labels) {
        ImmutableList.Builder<ImmutableMap<String, Object>> dataBuilder =
                ImmutableList.<ImmutableMap<String, Object>>builder();

        for (FirebaseVisionImageLabel label : labels) {
            ImmutableMap.Builder<String, Object> labelBuilder = ImmutableMap.<String, Object>builder();

            labelBuilder.put("label", label.getText());
            labelBuilder.put("entityID", label.getEntityId());
            labelBuilder.put("confidence", label.getConfidence());

            dataBuilder.add(labelBuilder.build());
        }

        return dataBuilder.build();
    }

    private <T> ImmutableList<Object> processList(Class<T> clazz, Object o) {
        ImmutableList.Builder<Object> builder = ImmutableList.<Object>builder();
        if (o.getClass().isArray()) {
            int length = Array.getLength(o);
            for (int i = 0; i < length; i++) {
                Object o2 = Array.get(o, i);
                if (o2.getClass().isArray()) {
                    builder.add(processList(clazz, o2));
                } else {
                    builder.add((T) o2);
                }
            }
        } else {
            builder.add((T) o);
        }
        return builder.build();
    }

    private int getRotationAngle(InputStream in) throws IOException {
        try {
            ExifInterface exifInterface = new ExifInterface(in);
            String orientString = exifInterface.getAttribute(ExifInterface.TAG_ORIENTATION);
            int orientation = orientString != null ? Integer.parseInt(orientString) : ExifInterface.ORIENTATION_NORMAL;
            int rotationAngle = 0;
            if (orientation == ExifInterface.ORIENTATION_ROTATE_90)
                rotationAngle = 90;
            if (orientation == ExifInterface.ORIENTATION_ROTATE_180)
                rotationAngle = 180;
            if (orientation == ExifInterface.ORIENTATION_ROTATE_270)
                rotationAngle = 270;
            return rotationAngle;
        } catch (IOException e) {
            throw e;
        }
    }

    private Bitmap createRotatedBitmap(Bitmap bm, BitmapFactory.Options bounds, int rotationAngle) {
        Matrix matrix = new Matrix();
        matrix.setRotate(rotationAngle, (float) bm.getWidth() / 2, (float) bm.getHeight() / 2);
        return Bitmap.createBitmap(bm, 0, 0, bounds.outWidth, bounds.outHeight, matrix, true);
    }
}
