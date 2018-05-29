#import "MlkitPlugin.h"
#import "Firebase/Firebase.h"

@implementation MlkitPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  FlutterMethodChannel* channel = [FlutterMethodChannel
      methodChannelWithName:@"plugins.flutter.io/firebase_mlkit/vision_text"
            binaryMessenger:[registrar messenger]];
  MlkitPlugin* instance = [[MlkitPlugin alloc] init];
  [registrar addMethodCallDelegate:instance channel:channel];
}

FIRVisionTextDetector *textDetector;

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

  textDetector = [vision textDetector];
  NSString *path = call.arguments[@"filepath"];

  UIImage* uiImage = [UIImage imageWithContentsOfFile:path];
  FIRVisionImage *image = [[FIRVisionImage alloc] initWithImage:uiImage];
  if ([@"detectFromPath" isEqualToString:call.method]) {
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
          NSString *value = feature.text;
          //NSArray<NSValue *> *corners = feature.cornerPoints;
          [ret addObject:value];
        }
      }
      result(ret);
      return;
    }];
  } else {
    result(FlutterMethodNotImplemented);
  }
}

@end
