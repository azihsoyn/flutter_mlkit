#import "MlkitPlugin.h"
#import "Firebase/Firebase.h"

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

FIRVisionTextDetector *textDetector;
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

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    FIRVision *vision = [FIRVision vision];
    NSMutableArray *ret = [NSMutableArray array];
    NSString *path = call.arguments[@"filepath"];
    UIImage* uiImage = [UIImage imageWithContentsOfFile:path];
    FIRVisionImage *image = [[FIRVisionImage alloc] initWithImage:uiImage];
    
    if ([@"FirebaseVisionTextDetector#detectFromPath" isEqualToString:call.method]) {
        textDetector = [vision textDetector];
        [textDetector detectInImage:image
                         completion:^(NSArray<FIRVisionText *> *features,
                                      NSError *error) {
                             if (error != nil) {
                                 [ret addObject:error.localizedDescription];
                                 result(ret);
                                 return;
                             } else if (features != nil) {
                                 // Recognized text
                                 for (id <FIRVisionText> feature in features) {
                                     // Blocks contain lines of text
                                     if ([feature isKindOfClass:[FIRVisionTextBlock class]]) {
                                         FIRVisionTextBlock *block = (FIRVisionTextBlock *)feature;
                                         [ret addObject:visionTextBlockToDictionary(block)];
                                     }
                                     
                                     // Lines contain text elements
                                     else if ([feature isKindOfClass:[FIRVisionTextLine class]]) {
                                         FIRVisionTextLine *line = (FIRVisionTextLine *)feature;
                                         [ret addObject:visionTextLineToDictionary(line)];
                                     }
                                     
                                     // Text elements are typically words
                                     else if ([feature isKindOfClass:[FIRVisionTextElement class]]) {
                                         FIRVisionTextElement *element = (FIRVisionTextElement *)feature;
                                         [ret addObject:visionTextElementToDictionary(element)];
                                     }
                                     else {
                                         [ret addObject:visionTextToDictionary(feature)];
                                     }
                                 }
                             }
                             result(ret);
                             return;
                         }];
    } else if ([@"FirebaseVisionBarcodeDetector#detectFromPath" isEqualToString:call.method]) {
        /*
         FIRVisionBarcodeDetectorOptions *options = [[FIRVisionBarcodeDetectorOptions alloc]
         initWithFormats: FIRVisionBarcodeFormatAll];
         barcodeDetector = [vision barcodeDetectorWithOptions:options];
         */
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
    } else if ([@"FirebaseVisionFaceDetector#detectFromPath" isEqualToString:call.method]) {
        if(call.arguments[@"option"] != [NSNull null] ){
            FIRVisionFaceDetectorOptions *options = [[FIRVisionFaceDetectorOptions alloc] init];
            NSNumber *modeType = call.arguments[@"option"][@"modeType"];
            options.modeType = (FIRVisionFaceDetectorMode)modeType;
            NSNumber *landmarkType = call.arguments[@"option"][@"landmarkType"];
            options.landmarkType =  (FIRVisionFaceDetectorLandmark)landmarkType.unsignedIntegerValue;
            NSNumber *classificationType = call.arguments[@"option"][@"classificationType"];
            options.classificationType = (FIRVisionFaceDetectorClassification)classificationType.unsignedIntegerValue;
            NSNumber *minFaceSize = call.arguments[@"option"][@"minFaceSize"];
#if CGFLOAT_IS_DOUBLE
            options.minFaceSize = [minFaceSize doubleValue];
#else
            options.minFaceSize = [minFaceSize floatValue];
#endif
            NSNumber *isTrackingEnabled = call.arguments[@"option"][@"isTrackingEnabled"];
            options.isTrackingEnabled = [isTrackingEnabled boolValue];
            faceDetector = [vision faceDetectorWithOptions:options];
        }else{
            faceDetector = [vision faceDetector];
        }

        [faceDetector detectInImage:image
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
    } else if ([@"FirebaseVisionLabelDetector#detectFromPath" isEqualToString:call.method]){
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
    }else {
        result(FlutterMethodNotImplemented);
    }
}

NSDictionary *visionTextToDictionary(id<FIRVisionText> visionText) {
    __block NSMutableArray<NSDictionary *> *points =[NSMutableArray array];
    [visionText.cornerPoints enumerateObjectsUsingBlock:^(NSValue * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [points addObject:@{
                            @"x": @(((__bridge CGPoint *)obj)->x),
                            @"y": @(((__bridge CGPoint *)obj)->y),
                            }];
    }];
    return @{
             @"text" : visionText.text,
             @"rect_left": @(visionText.frame.origin.x),
             @"rect_top": @(visionText.frame.origin.y),
             @"rect_right": @(visionText.frame.origin.x + visionText.frame.size.width),
             @"rect_bottom": @(visionText.frame.origin.y + visionText.frame.size.height),
             @"points": points,
             };
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
    return @{@"event_description": calendar.eventDescription,
             @"location": calendar.location,
             @"organizer": calendar.organizer,
             @"status": calendar.status,
             @"summary": calendar.summary,
             @"start": calendar.start,
             @"end": calendar.end,
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
