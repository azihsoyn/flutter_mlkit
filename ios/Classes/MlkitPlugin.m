#import "MlkitPlugin.h"
#import "Firebase/Firebase.h"
#import "AVFoundation/AVFoundation.h"
@import FirebaseMLCommon;

@implementation MlkitPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterMethodChannel* channel = [FlutterMethodChannel
                                     methodChannelWithName:@"plugins.flutter.io/mlkit"
                                     binaryMessenger:[registrar messenger]];
    MlkitPlugin* instance = [[MlkitPlugin alloc] init];
    [registrar addMethodCallDelegate:instance channel:channel];
    localCustomModelMap = [NSMutableDictionary dictionary];
    remoteCustomModelMap = [NSMutableDictionary dictionary];
}

// android
//   https://firebase.google.com/docs/reference/android/com/google/firebase/ml/vision/face/FirebaseVisionFaceLandmark#BOTTOM_MOUTH
NSDictionary *landmarkTypeMap;
NSMutableDictionary *localCustomModelMap;
NSMutableDictionary *remoteCustomModelMap;

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
    NSMutableArray *ret = [NSMutableArray array];



    if ([call.method hasPrefix:@"FirebaseModelManager#registerRemoteModelSource"]) {
        if(call.arguments[@"source"] != [NSNull null] ){
            NSString *modeName = call.arguments[@"source"][@"modelName"];
            BOOL enableModelUpdates = call.arguments[@"source"][@"enableModelUpdates"];
            FIRModelDownloadConditions *initialDownloadConditions = [[FIRModelDownloadConditions alloc] initWithAllowsCellularAccess:YES
                                                                                                       allowsBackgroundDownloading:YES];
            FIRModelDownloadConditions *updatesDownloadConditions = [[FIRModelDownloadConditions alloc] initWithAllowsCellularAccess:YES
                                                                                                       allowsBackgroundDownloading:YES];
            if(call.arguments[@"source"][@"initialDownloadConditions"] != [NSNull null] ){
                BOOL requireWifi = call.arguments[@"source"][@"initialDownloadConditions"][@"requireWifi"];
                BOOL requireDeviceIdle = call.arguments[@"source"][@"initialDownloadConditions"][@"requireDeviceIdle"];
                initialDownloadConditions =
                [[FIRModelDownloadConditions alloc] initWithAllowsCellularAccess:requireWifi
                                                   allowsBackgroundDownloading:requireDeviceIdle];
            }
            if(call.arguments[@"source"][@"updatesDownloadConditions"] != [NSNull null] ){
                BOOL requireWifi = call.arguments[@"source"][@"initialDownloadConditions"][@"requireWifi"];
                BOOL requireDeviceIdle = call.arguments[@"source"][@"initialDownloadConditions"][@"requireDeviceIdle"];
                initialDownloadConditions =
                updatesDownloadConditions =
                [[FIRModelDownloadConditions alloc] initWithAllowsCellularAccess:requireWifi
                                                allowsBackgroundDownloading:requireDeviceIdle];
            }
            FIRCustomRemoteModel *remoteModelSource =
            [[FIRCustomRemoteModel alloc] initWithName:modeName];
            NSProgress *downloadProgress =
            [[FIRModelManager modelManager] downloadModel:remoteModelSource
                                                    conditions:initialDownloadConditions];
            [remoteCustomModelMap setObject:remoteModelSource forKey:modeName];
        }
    } else if ([call.method hasPrefix:@"FirebaseModelManager#registerLocalModelSource"]) {
        if(call.arguments[@"source"] != [NSNull null] ){
            NSString *modeName = call.arguments[@"source"][@"modelName"];
            NSString *assetFilePath = call.arguments[@"source"][@"assetFilePath"];
            NSString *fullpath = [@"Frameworks/App.framework/flutter_assets/" stringByAppendingString:assetFilePath];
            NSString *path = [[NSBundle mainBundle] pathForResource:fullpath ofType:nil];
            FIRCustomLocalModel *localModel = [[FIRCustomLocalModel alloc] initWithModelPath:path];
            [remoteCustomModelMap setObject:localModel forKey:modeName];
        }
    } else if ([call.method hasPrefix:@"FirebaseModelInterpreter#run"]) {
        NSString *remoteModelName = nil;
        FIRCustomRemoteModel *remoteModel = nil;
        if (call.arguments[@"remoteModelName"] != [NSNull null]) {
            remoteModelName = call.arguments[@"remoteModelName"];
            remoteModel = [remoteCustomModelMap objectForKey:remoteModelName];
        }
        NSString *localModelName = nil;
        FIRCustomLocalModel *localModel = nil;
        if (call.arguments[@"localModelName"] != [NSNull null]) {
            localModelName = call.arguments[@"localModelName"];
            localModel = [localCustomModelMap objectForKey:localModelName];
        }

        FIRModelInterpreter *interpreter;
        if(remoteModel != nil && localModel != nil){
            if ([[FIRModelManager modelManager] isModelDownloaded:remoteModel]) {
              interpreter = [FIRModelInterpreter modelInterpreterForRemoteModel:remoteModel];
            } else {
              interpreter = [FIRModelInterpreter modelInterpreterForLocalModel:localModel];
            }
        }else if (remoteModel != nil && localModel == nil) {
            // remote only
            interpreter = [FIRModelInterpreter modelInterpreterForRemoteModel:remoteModel];
        }else if (remoteModel == nil && localModel != nil) {
            // local only
            interpreter = [FIRModelInterpreter modelInterpreterForLocalModel:localModel];
            
        }
        FIRModelInputOutputOptions *ioOptions = [[FIRModelInputOutputOptions alloc] init];
        NSLog(@"Building input options");
        NSError *error;
        NSArray<NSDictionary *> *inputOptions = call.arguments[@"inputOutputOptions"][@"inputOptions"];
        for (int i = 0; i < [inputOptions count]; i++)
        {
            NSNumber *inputDataType = [inputOptions objectAtIndex:i][@"dataType"];
            FIRModelElementType inputType = (FIRModelElementType)[inputDataType intValue];
            NSArray<NSNumber *> *inputDims = [inputOptions objectAtIndex:i][@"dims"];
            [ioOptions setInputFormatForIndex:i
                                        type:inputType
                                dimensions:inputDims
                                        error:&error];
            if (error != nil) {
                NSLog(@"Failed setInputFormatForIndex with error: %@", error.localizedDescription);
                return;
            }
        }
        
        NSLog(@"Building output options");
        NSArray<NSDictionary *> *outputOptions = call.arguments[@"inputOutputOptions"][@"outputOptions"];
        for (int i = 0; i < [outputOptions count]; i++)
        {
            NSNumber *outputDataType = [outputOptions objectAtIndex:i][@"dataType"];
            FIRModelElementType outputType = (FIRModelElementType)[outputDataType intValue];
            NSArray<NSNumber *> *outputDims = [outputOptions objectAtIndex:i][@"dims"];
            [ioOptions setOutputFormatForIndex:i
                                         type:outputType
                                   dimensions:outputDims
                                        error:&error];
            if (error != nil) {
                NSLog(@"Failed setOutputFormatForIndex with error: %@", error.localizedDescription);
                return;
            }
        }
        
        FIRModelInputs *inputs = [[FIRModelInputs alloc] init];
        FlutterStandardTypedData* typedData = call.arguments[@"inputBytes"];
        // ...
        [inputs addInput:typedData.data error:&error];  // Repeat as necessary.
        if (error != nil) {
            NSLog(@"Failed addInput with error: %@", error);
            return;
        }
        NSLog(@"Running detection");
        [interpreter runWithInputs:inputs
                           options:ioOptions
                        completion:^(FIRModelOutputs * _Nullable outputs,
                                     NSError * _Nullable error) {
                            NSLog(@"Detection run");
                            if (error != nil || outputs == nil) {
                                NSLog(@"Failed runWithInputs with error: %@", error.localizedDescription);
                                return;
                            }
                            __block NSMutableArray<NSObject *> *ret =[NSMutableArray array];
                            for (int i = 0; i < [outputOptions count]; i++)
                            {
                                NSObject *outputArray = [outputs outputAtIndex:i error:&error];
                                if (error) {
                                    NSLog(@"Failed to process detection outputs with error: %@", error.localizedDescription);
                                    return;
                                }

                                // Get the first output from the array of output arrays.
                                if(!outputArray) {
                                    NSLog(@"Failed to get the results array from output.");
                                    return;
                                }
                                
                                [ret addObject:processList(outputArray)];
                            }
                            result(ret);
                            return;
                        }];
    } else {
        result(FlutterMethodNotImplemented);
    }
}

NSMutableArray *processList(NSObject * o) {
    __block NSMutableArray<NSObject *> *list =[NSMutableArray array];
    if ([o isKindOfClass:[NSArray class]]) {
        int length = [((NSArray *)o) count];
        for (int i = 0; i < length; i++) {
            NSObject *o2 = [((NSArray *)o) objectAtIndex:i];
            if ([o2 isKindOfClass:[NSArray class]]) {
                [list addObject:processList(o2)];
            } else {
                [list addObject:o2];
            }
        }
    } else {
        [list addObject:o];
    }
    return list;
}

@end
