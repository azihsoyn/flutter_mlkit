#import "MlkitPlugin.h"
@import Firebase;

@implementation MlkitPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  FlutterMethodChannel* channel = [FlutterMethodChannel
      methodChannelWithName:@"plugins.flutter.io/firebase_mlkit/vision_text"
            binaryMessenger:[registrar messenger]];
  MlkitPlugin* instance = [[MlkitPlugin alloc] init];
  [registrar addMethodCallDelegate:instance channel:channel];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
  FIRVisionTextDetector *textDetector;
  FIRVision *vision = [FIRVision vision];
  textDetector = [vision textDetector];
  FIRVisionImage *image = [[FIRVisionImage alloc] initWithImage:uiImage];
  if ([@"detectFromPath" isEqualToString:call.method]) {
    [textDetector detectInImage:image
                     completion:^(NSArray<FIRVisionText *> *features,
                                  NSError *error) {
      if (error != nil) {
        return;
      } else if (features != nil) {
        // Recognized text
        for (id <FIRVisionText> feature in features) {
          NSString *value = feature.text;
          NSArray<NSValue *> *corners = feature.cornerPoints;
        }
      }
    }];
    result([@"iOS " stringByAppendingString:[[UIDevice currentDevice] systemVersion]]);
  } else {
    result(FlutterMethodNotImplemented);
  }
}

@end
