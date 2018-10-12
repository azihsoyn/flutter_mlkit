#import "MlkitPlugin.h"
#import "Firebase/Firebase.h"
#import "AVFoundation/AVFoundation.h"

@implementation MlkitPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterMethodChannel* channel = [FlutterMethodChannel
                                     methodChannelWithName:@"plugins.flutter.io/mlkit"
                                     binaryMessenger:[registrar messenger]];
    MlkitPlugin* instance = [[MlkitPlugin alloc] init];
    [registrar addMethodCallDelegate:instance channel:channel];
    landmarkTypeMap = @{
                        @0:FIRFaceLandmarkTypeMouthBottom,
                        @1:FIRFaceLandmarkTypeLeftCheek,
                        @3:FIRFaceLandmarkTypeLeftEar,
                        @4:FIRFaceLandmarkTypeLeftEye,
                        @5:FIRFaceLandmarkTypeMouthLeft,
                        @6:FIRFaceLandmarkTypeNoseBase,
                        @7:FIRFaceLandmarkTypeRightCheek,
                        @9:FIRFaceLandmarkTypeRightEar,
                        @10:FIRFaceLandmarkTypeRightEye,
                        @11:FIRFaceLandmarkTypeMouthRight,
                        };
}

FIRVisionTextRecognizer *textDetector;
FIRVisionBarcodeDetector *barcodeDetector;
FIRVisionFaceDetector *faceDetector;
FIRVisionLabelDetector *labelDetector;

// android
//   https://firebase.google.com/docs/reference/android/com/google/firebase/ml/vision/face/FirebaseVisionFaceLandmark#BOTTOM_MOUTH
NSDictionary *landmarkTypeMap;

- (instancetype)init {
    self = [super init];
    if (self) {
        if (![FIRApp defaultApp]) {
            [FIRApp configure];
        }
    }
    return self;
}

UIImage* imageFromImageSourceWithData(NSData *data) {
    CGImageSourceRef imageSource = CGImageSourceCreateWithData((__bridge CFDataRef)data, NULL);
    CGImageRef imageRef = CGImageSourceCreateImageAtIndex(imageSource, 0, NULL);
    CFRelease(imageSource);
    UIImage *image = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    return image;
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    FIRVision *vision = [FIRVision vision];
    NSMutableArray *ret = [NSMutableArray array];
    UIImage* uiImage = NULL;
    FIRVisionImage *image = NULL;

    if ([call.method hasSuffix:@"#detectFromPath"]) {
        NSString *path = call.arguments[@"filepath"];
        uiImage = [UIImage imageWithContentsOfFile:path];
        image = [[FIRVisionImage alloc] initWithImage:uiImage];
    } else if ([call.method hasSuffix:@"#detectFromBinary"]) {
        FlutterStandardTypedData* typedData = call.arguments[@"binary"];
        uiImage = [UIImage imageWithData: typedData.data];
        image = [[FIRVisionImage alloc] initWithImage:uiImage];
    }

    if ([call.method hasPrefix:@"FirebaseVisionTextDetector#detectFrom"]) {
        textDetector = [vision onDeviceTextRecognizer];
        [textDetector processImage:image
                        completion:^(FIRVisionText *_Nullable resultText,
                                     NSError *_Nullable error) {
                            if (error != nil) {
                                [ret addObject:error.localizedDescription];
                                result(ret);
                                return;
                            } else if (resultText != nil) {
                                // Recognized text
                                for (FIRVisionTextBlock *block in resultText.blocks) {
                                    [ret addObject:visionTextBlockToDictionary(block)];
                                }
                            }
                            result(ret);
                            return;
                        }];
    } else if ([call.method hasPrefix:@"FirebaseVisionBarcodeDetector#detectFrom"]) {
        barcodeDetector = [vision barcodeDetector];
        [barcodeDetector detectInImage:image
                            completion:^(NSArray<FIRVisionBarcode *> *barcodes,
                                         NSError *error) {
                                if (error != nil) {
                                    [ret addObject:error.localizedDescription];
                                    result(ret);
                                    return;
                                } else if (barcodes != nil) {
                                    // Scaned barcode
                                    for (FIRVisionBarcode *barcode in barcodes) {
                                        [ret addObject:visionBarcodeToDictionary(barcode)];
                                    }
                                }
                                result(ret);
                                return;
                            }];
    } else if ([call.method hasPrefix:@"FirebaseVisionFaceDetector#detectFrom"]) {
        if(call.arguments[@"option"] != [NSNull null] ){
            FIRVisionFaceDetectorOptions *options = [[FIRVisionFaceDetectorOptions alloc] init];
            NSNumber *modeType = call.arguments[@"option"][@"modeType"];
            options.performanceMode = (FIRVisionFaceDetectorPerformanceMode)modeType;
            NSNumber *landmarkType = call.arguments[@"option"][@"landmarkType"];
            options.landmarkMode =  (FIRVisionFaceDetectorLandmarkMode)landmarkType.unsignedIntegerValue;
            NSNumber *classificationType = call.arguments[@"option"][@"classificationType"];
            options.classificationMode = (FIRVisionFaceDetectorClassificationMode)classificationType.unsignedIntegerValue;
            NSNumber *minFaceSize = call.arguments[@"option"][@"minFaceSize"];
#if CGFLOAT_IS_DOUBLE
            options.minFaceSize = [minFaceSize doubleValue];
#else
            options.minFaceSize = [minFaceSize floatValue];
#endif
            NSNumber *isTrackingEnabled = call.arguments[@"option"][@"isTrackingEnabled"];
            options.trackingEnabled = [isTrackingEnabled boolValue];
            faceDetector = [vision faceDetectorWithOptions:options];
        }else{
            faceDetector = [vision faceDetector];
        }

        /* TODO
        // Calculate the image orientation
        FIRVisionDetectorImageOrientation orientation;

        // Using front-facing camera
        AVCaptureDevicePosition devicePosition = AVCaptureDevicePositionFront;

        UIDeviceOrientation deviceOrientation = UIDevice.currentDevice.orientation;
        switch (deviceOrientation) {
            case UIDeviceOrientationPortrait:
                if (devicePosition == AVCaptureDevicePositionFront) {
                    orientation = FIRVisionDetectorImageOrientationLeftTop;
                } else {
                    orientation = FIRVisionDetectorImageOrientationRightTop;
                }
                break;
            case UIDeviceOrientationLandscapeLeft:
                if (devicePosition == AVCaptureDevicePositionFront) {
                    orientation = FIRVisionDetectorImageOrientationBottomLeft;
                } else {
                    orientation = FIRVisionDetectorImageOrientationTopLeft;
                }
                break;
            case UIDeviceOrientationPortraitUpsideDown:
                if (devicePosition == AVCaptureDevicePositionFront) {
                    orientation = FIRVisionDetectorImageOrientationRightBottom;
                } else {
                    orientation = FIRVisionDetectorImageOrientationLeftBottom;
                }
                break;
            case UIDeviceOrientationLandscapeRight:
                if (devicePosition == AVCaptureDevicePositionFront) {
                    orientation = FIRVisionDetectorImageOrientationTopRight;
                } else {
                    orientation = FIRVisionDetectorImageOrientationBottomRight;
                }
                break;
            default:
                orientation = FIRVisionDetectorImageOrientationTopLeft;
                break;
        }

        FIRVisionImageMetadata *metadata = [[FIRVisionImageMetadata alloc] init];
        metadata.orientation = orientation;

        image.metadata = metadata;
        */

        [faceDetector processImage:image
                        completion:^(NSArray<FIRVisionFace *> *faces,
                                     NSError *error) {
                            if (error != nil) {
                                [ret addObject:error.localizedDescription];
                                result(ret);
                                return;
                            } else if (faces != nil) {
                                // Scaned barcode
                                for (FIRVisionFace *face in faces) {
                                    [ret addObject:visionFaceToDictionary(face)];
                                }
                            }
                            result(ret);
                            return;
                        }];
    } else if ([call.method hasPrefix:@"FirebaseVisionLabelDetector#detectFrom"]) {
        labelDetector = [vision labelDetector];
        [labelDetector detectInImage:(FIRVisionImage *)image
                          completion:^(NSArray<FIRVisionLabel *> *labels,
                                       NSError *error){
                              if(error != nil){
                                  [ret addObject:error.localizedDescription];
                                  result(ret);
                                  return;
                              } else if(labels != nil){
                                  for (FIRVisionLabel *label in labels){
                                      [ret addObject:visionLabelToDictionary(label)];
                                  }
                              }
                              result(ret);
                              return;
                          }];
    } else if ([call.method hasPrefix:@"FirebaseModelManager#registerCloudModelSource"]) {
        if(call.arguments[@"source"] != [NSNull null] ){
            NSString *modeName = call.arguments[@"source"][@"modelName"];
            BOOL enableModelUpdates = call.arguments[@"source"][@"enableModelUpdates"];
            FIRModelDownloadConditions *initialDownloadConditions = [[FIRModelDownloadConditions alloc] initWithIsWiFiRequired:YES
                                                                                                       canDownloadInBackground:YES];
            FIRModelDownloadConditions *updatesDownloadConditions = [[FIRModelDownloadConditions alloc] initWithIsWiFiRequired:YES
                                                                                                       canDownloadInBackground:YES];
            if(call.arguments[@"source"][@"initialDownloadConditions"] != [NSNull null] ){
                BOOL requireWifi = call.arguments[@"source"][@"initialDownloadConditions"][@"requireWifi"];
                BOOL requireDeviceIdle = call.arguments[@"source"][@"initialDownloadConditions"][@"requireDeviceIdle"];
                initialDownloadConditions =
                [[FIRModelDownloadConditions alloc] initWithIsWiFiRequired:requireWifi
                                                   canDownloadInBackground:requireDeviceIdle];
            }
            if(call.arguments[@"source"][@"updatesDownloadConditions"] != [NSNull null] ){
                BOOL requireWifi = call.arguments[@"source"][@"initialDownloadConditions"][@"requireWifi"];
                BOOL requireDeviceIdle = call.arguments[@"source"][@"initialDownloadConditions"][@"requireDeviceIdle"];
                initialDownloadConditions =
                updatesDownloadConditions =
                [[FIRModelDownloadConditions alloc] initWithIsWiFiRequired:requireWifi
                                                canDownloadInBackground:requireDeviceIdle];
            }
            FIRCloudModelSource *cloudModelSource =
            [[FIRCloudModelSource alloc] initWithModelName:modeName
                                        enableModelUpdates:enableModelUpdates
                                         initialConditions:initialDownloadConditions
                                          updateConditions:updatesDownloadConditions];
            BOOL registrationSuccess =
            [[FIRModelManager modelManager] registerCloudModelSource:cloudModelSource];
        }
    } else if ([call.method hasPrefix:@"FirebaseModelInterpreter#run"]) {
        NSString *cloudModelName = call.arguments[@"cloudModelName"];
        // TODO local model
        FIRModelOptions *options = [[FIRModelOptions alloc] initWithCloudModelName:cloudModelName                                                                localModelName:nil];
        FIRModelInterpreter *interpreter = [FIRModelInterpreter modelInterpreterWithOptions:options];
        FIRModelInputOutputOptions *ioOptions = [[FIRModelInputOutputOptions alloc] init];
        NSError *error;
        NSNumber *inputIndex = call.arguments[@"inputOutputOptions"][@"inputIndex"];
        NSNumber *inputDataType = call.arguments[@"inputOutputOptions"][@"inputDataType"];
        FIRModelElementType inputType = (FIRModelElementType)[inputDataType intValue];
        NSArray<NSNumber *> *inputDims = call.arguments[@"inputOutputOptions"][@"inputDims"];
        [ioOptions setInputFormatForIndex:[inputIndex unsignedIntegerValue]
                                     type:inputType
                               dimensions:inputDims
                                    error:&error];
        if (error != nil) {
            NSLog(@"Failed setInputFormatForIndex with error: %@", error.localizedDescription);
            return;
        }

        NSNumber *outputIndex = call.arguments[@"inputOutputOptions"][@"outputIndex"];
        NSNumber *outputDataType = call.arguments[@"inputOutputOptions"][@"outputDataType"];
        FIRModelElementType outputType = (FIRModelElementType)[outputDataType intValue];
        NSArray<NSNumber *> *outputDims = call.arguments[@"inputOutputOptions"][@"outputDims"];
        [ioOptions setOutputFormatForIndex:[outputIndex unsignedIntegerValue]
                                      type:outputType
                                dimensions:outputDims
                                     error:&error];
        if (error != nil) {
            NSLog(@"Failed setOutputFormatForIndex with error: %@", error.localizedDescription);
            return;
        }
        FIRModelInputs *inputs = [[FIRModelInputs alloc] init];
        FlutterStandardTypedData* typedData = call.arguments[@"inputBytes"];
        // ...
        [inputs addInput:typedData.data error:&error];  // Repeat as necessary.
        if (error != nil) {
            NSLog(@"Failed addInput with error: %@", error);
            return;
        }
        [interpreter runWithInputs:inputs
                           options:ioOptions
                        completion:^(FIRModelOutputs * _Nullable outputs,
                                     NSError * _Nullable error) {
                            if (error != nil || outputs == nil) {
                                NSLog(@"Failed runWithInputs with error: %@", error.localizedDescription);
                                return;
                            }

                            NSArray <NSArray<NSNumber *> *>*outputArrayOfArrays = [outputs outputAtIndex:0 error:&error];
                            if (error) {
                                NSLog(@"Failed to process detection outputs with error: %@", error.localizedDescription);
                                return;
                            }

                            // Get the first output from the array of output arrays.
                            if(!outputArrayOfArrays || !outputArrayOfArrays.firstObject || ![outputArrayOfArrays.firstObject isKindOfClass:[NSArray class]] || !outputArrayOfArrays.firstObject.firstObject || ![outputArrayOfArrays.firstObject.firstObject isKindOfClass:[NSNumber class]]) {
                                NSLog(@"Failed to get the results array from output.");
                                return;
                            }

                            NSArray<NSNumber *> *ret = outputArrayOfArrays.firstObject;

                            result(ret);
                            return;
                        }];
    } else {
        result(FlutterMethodNotImplemented);
    }
}

NSDictionary *visionTextBlockToDictionary(FIRVisionTextBlock * visionTextBlock) {
    __block NSMutableArray<NSDictionary *> *points =[NSMutableArray array];
    [visionTextBlock.cornerPoints enumerateObjectsUsingBlock:^(NSValue * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [points addObject:@{
                            @"x": @(((__bridge CGPoint *)obj)->x),
                            @"y": @(((__bridge CGPoint *)obj)->y),
                            }];
    }];
    NSMutableArray<NSDictionary *> *lines = [NSMutableArray array];
    for (FIRVisionTextLine *line in visionTextBlock.lines) {
        [lines addObject: visionTextLineToDictionary(line)];
    }
    return @{
             @"text" : visionTextBlock.text,
             @"rect_left": @(visionTextBlock.frame.origin.x),
             @"rect_top": @(visionTextBlock.frame.origin.y),
             @"rect_right": @(visionTextBlock.frame.origin.x + visionTextBlock.frame.size.width),
             @"rect_bottom": @(visionTextBlock.frame.origin.y + visionTextBlock.frame.size.height),
             @"lines": lines,
             @"points": points,
             };
}

NSDictionary *visionTextLineToDictionary(FIRVisionTextLine * visionTextLine) {
    __block NSMutableArray<NSDictionary *> *points =[NSMutableArray array];
    [visionTextLine.cornerPoints enumerateObjectsUsingBlock:^(NSValue * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [points addObject:@{
                            @"x": @(((__bridge CGPoint *)obj)->x),
                            @"y": @(((__bridge CGPoint *)obj)->y),
                            }];
    }];
    
    NSMutableArray<NSDictionary *> *elements = [NSMutableArray array];
    for (FIRVisionTextElement *element in visionTextLine.elements) {
        [elements addObject: visionTextElementToDictionary(element)];
    }
    return @{
             @"text" : visionTextLine.text,
             @"rect_left": @(visionTextLine.frame.origin.x),
             @"rect_top": @(visionTextLine.frame.origin.y),
             @"rect_right": @(visionTextLine.frame.origin.x + visionTextLine.frame.size.width),
             @"rect_bottom": @(visionTextLine.frame.origin.y + visionTextLine.frame.size.height),
             @"elements": elements,
             @"points": points,
             };
}

NSDictionary *visionTextElementToDictionary(FIRVisionTextElement * visionTextElement) {
    __block NSMutableArray<NSDictionary *> *points =[NSMutableArray array];
    [visionTextElement.cornerPoints enumerateObjectsUsingBlock:^(NSValue * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [points addObject:@{
                            @"x": @(((__bridge CGPoint *)obj)->x),
                            @"y": @(((__bridge CGPoint *)obj)->y),
                            }];
    }];
    return @{
             @"text" : visionTextElement.text,
             @"rect_left": @(visionTextElement.frame.origin.x),
             @"rect_top": @(visionTextElement.frame.origin.y),
             @"rect_right": @(visionTextElement.frame.origin.x + visionTextElement.frame.size.width),
             @"rect_bottom": @(visionTextElement.frame.origin.y + visionTextElement.frame.size.height),
             @"points": points,
             };
}

NSDictionary *visionBarcodeToDictionary(FIRVisionBarcode * barcode) {
    __block NSMutableArray<NSDictionary *> *points =[NSMutableArray array];
    [barcode.cornerPoints enumerateObjectsUsingBlock:^(NSValue * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [points addObject:@{
                            @"x": @(((__bridge CGPoint *)obj)->x),
                            @"y": @(((__bridge CGPoint *)obj)->y),
                            }];
    }];
    return @{
             @"raw_value" : barcode.rawValue,
             @"display_value": barcode.displayValue ? barcode.displayValue : [NSNull null],
             @"rect_left": @(barcode.frame.origin.x),
             @"rect_top": @(barcode.frame.origin.y),
             @"rect_top": @(barcode.frame.origin.y),
             @"rect_right": @(barcode.frame.origin.x + barcode.frame.size.width),
             @"rect_bottom": @(barcode.frame.origin.y + barcode.frame.size.height),
             @"format": @(barcode.format),
             @"value_type": @(barcode.valueType),
             @"points": points,
             @"wifi": barcode.wifi ? visionBarcodeWiFiToDictionary(barcode.wifi) : [NSNull null],
             @"email": barcode.email ? visionBarcodeEmailToDictionary(barcode.email) : [NSNull null],
             @"phone": barcode.phone ? visionBarcodePhoneToDictionary(barcode.phone) : [NSNull null],
             @"sms": barcode.sms ? visionBarcodeSMSToDictionary(barcode.sms) : [NSNull null],
             @"url": barcode.URL ? visionBarcodeURLToDictionary(barcode.URL) : [NSNull null],
             @"geo_point": barcode.geoPoint ? visionBarcodeGeoPointToDictionary(barcode.geoPoint) : [NSNull null],
             @"contact_info": barcode.contactInfo ? visionBarcodeContactInfoToDictionary(barcode.contactInfo) : [NSNull null],
             @"calendar_event": barcode.calendarEvent ? visionBarcodeCalendarEventToDictionary(barcode.calendarEvent) : [NSNull null],
             @"driver_license": barcode.driverLicense ? visionBarcodeDriverLicenseToDictionary(barcode.driverLicense) : [NSNull null],
             };
}

NSDictionary *visionBarcodeWiFiToDictionary(FIRVisionBarcodeWiFi* wifi){
    return @{@"ssid": wifi.ssid,
             @"password": wifi.password,
             @"encryption_type": @(wifi.type),
             };
}

NSDictionary *visionBarcodeEmailToDictionary(FIRVisionBarcodeEmail* email){
    return @{@"address": email.address,
             @"body": email.body,
             @"subject": email.subject,
             @"type": @(email.type),
             };
}

NSDictionary *visionBarcodePhoneToDictionary(FIRVisionBarcodePhone* phone){
    return @{@"number": phone.number,
             @"type": @(phone.type),
             };
}

NSDictionary *visionBarcodeSMSToDictionary(FIRVisionBarcodeSMS* sms){
    return @{@"phone_number": sms.phoneNumber,
             @"message": sms.message,
             };
}

NSDictionary *visionBarcodeURLToDictionary(FIRVisionBarcodeURLBookmark* url){
    return @{@"title": url.title,
             @"url": url.url,
             };
}

NSDictionary *visionBarcodeGeoPointToDictionary(FIRVisionBarcodeGeoPoint* geo){
    return @{@"longitude": @(geo.longitude),
             @"latitude": @(geo.latitude),
             };
}

NSDictionary *visionBarcodeContactInfoToDictionary(FIRVisionBarcodeContactInfo* contact){
    __block NSMutableArray<NSDictionary *> *addresses =[NSMutableArray array];
    [contact.addresses enumerateObjectsUsingBlock:^(FIRVisionBarcodeAddress * _Nonnull address, NSUInteger idx, BOOL * _Nonnull stop) {
        __block NSMutableArray<NSString *> *addressLines =[NSMutableArray array];
        [address.addressLines enumerateObjectsUsingBlock:^(NSString * _Nonnull addressLine, NSUInteger idx, BOOL * _Nonnull stop) {
            [addressLines addObject:addressLine];
        }];
        [addresses addObject:@{
                               @"address_lines": addressLines,
                               @"type": @(address.type),
                               }];
    }];
    
    __block NSMutableArray<NSDictionary *> *emails =[NSMutableArray array];
    [contact.emails enumerateObjectsUsingBlock:^(FIRVisionBarcodeEmail * _Nonnull email, NSUInteger idx, BOOL * _Nonnull stop) {
        [emails addObject:@{
                            @"address": email.address,
                            @"body": email.body,
                            @"subjec": email.subject,
                            @"type": @(email.type),
                            }];
    }];
    
    __block NSMutableArray<NSDictionary *> *phones =[NSMutableArray array];
    [contact.phones enumerateObjectsUsingBlock:^(FIRVisionBarcodePhone * _Nonnull phone, NSUInteger idx, BOOL * _Nonnull stop) {
        [phones addObject:@{
                            @"number": phone.number,
                            @"type": @(phone.type),
                            }];
    }];
    
    __block NSMutableArray<NSString *> *urls =[NSMutableArray array];
    [contact.urls enumerateObjectsUsingBlock:^(NSString * _Nonnull url, NSUInteger idx, BOOL * _Nonnull stop) {
        [urls addObject:url];
    }];
    return @{@"addresses": addresses,
             @"emails": emails,
             @"name": @{
                     @"formatted_name": contact.name.formattedName,
                     @"first": contact.name.first,
                     @"last": contact.name.last,
                     @"middle": contact.name.middle,
                     @"prefix": contact.name.prefix,
                     @"pronounciation" : contact.name.pronounciation,
                     @"suffix": contact.name.suffix,
                     },
             @"phones": phones,
             @"urls": urls,
             @"job_title": contact.jobTitle,
             @"organization": contact.organization,
             };
}

NSDictionary  * visionBarcodeCalendarEventToDictionary(FIRVisionBarcodeCalendarEvent* calendar){
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    dateFormatter.dateFormat = @"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'";
    dateFormatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    return @{@"event_description": calendar.eventDescription,
             @"location": calendar.location,
             @"organizer": calendar.organizer,
             @"status": calendar.status,
             @"summary": calendar.summary,
             @"start": [dateFormatter stringFromDate:calendar.start],
             @"end": [dateFormatter stringFromDate:calendar.end],
             };
}

NSDictionary *visionBarcodeDriverLicenseToDictionary(FIRVisionBarcodeDriverLicense* license){
    return @{@"first_name": license.firstName,
             @"middle_name": license.middleName,
             @"last_name": license.lastName,
             @"gender": license.gender,
             @"address_city": license.addressCity,
             @"address_state": license.addressState,
             @"address_zip": license.addressZip,
             @"birth_date": license.birthDate,
             @"document_type": license.documentType,
             @"license_number": license.licenseNumber,
             @"expiry_date": license.expiryDate,
             @"issuing_date": license.issuingDate,
             @"issuing_country": license.issuingCountry,
             };
}

NSDictionary *visionFaceToDictionary(FIRVisionFace* face){
    __block NSMutableDictionary *landmarks = [NSMutableDictionary dictionary];
    for (id key in landmarkTypeMap){
        FIRVisionFaceLandmark *landmark = [face landmarkOfType:landmarkTypeMap[key]];
        if(landmark != nil){
            NSDictionary *_landmark =@{
                                       @"position": @{
                                               @"x": landmark.position.x,
                                               @"y": landmark.position.y,
                                               @"z": landmark.position.z ? landmark.position.z : [NSNull null],
                                               },
                                       @"type": key,
                                       };
            [landmarks setObject:_landmark forKey:key];
        }
    }
    return @{
             @"rect_left": @(face.frame.origin.x),
             @"rect_top": @(face.frame.origin.y),
             @"rect_right": @(face.frame.origin.x + face.frame.size.width),
             @"rect_bottom": @(face.frame.origin.y + face.frame.size.height),
             @"has_tracking_id": @(face.hasTrackingID),
             @"tracking_id": @(face.trackingID),
             @"has_head_euler_angle_y": @(face.hasHeadEulerAngleY),
             @"head_euler_angle_y": @(face.headEulerAngleY),
             @"has_head_euler_angle_z": @(face.hasHeadEulerAngleZ),
             @"head_euler_angle_z": @(face.headEulerAngleZ),
             @"has_smiling_probability": @(face.hasSmilingProbability),
             @"smiling_probability": @(face.smilingProbability),
             @"has_right_eye_open_probability": @(face.hasRightEyeOpenProbability),
             @"right_eye_open_probability": @(face.rightEyeOpenProbability),
             @"has_left_eye_open_probability": @(face.hasLeftEyeOpenProbability),
             @"left_eye_open_probability": @(face.leftEyeOpenProbability),
             @"landmarks": landmarks,
             };
}

NSDictionary *visionLabelToDictionary(FIRVisionLabel *label){
    return @{@"label" : label.label,
             @"entityID" : label.entityID,
             @"confidence" : [NSNumber numberWithFloat:label.confidence],
             @"rect_left": @(label.frame.origin.x),
             @"rect_top": @(label.frame.origin.y),
             @"rect_right": @(label.frame.origin.x + label.frame.size.width),
             @"rect_bottom": @(label.frame.origin.y + label.frame.size.height),
             };
}

@end
