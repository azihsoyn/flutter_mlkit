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
    } else {
        result(FlutterMethodNotImplemented);
    }
}

NSDictionary *visionTextToDictionary(id<FIRVisionText> visionText) {
    return @{
             @"text" : visionText.text,
             // https://stackoverflow.com/questions/7726924/saving-nsrect-to-nsuserdefaults/7727344
             //@"frame": [NSValue valueWithCGRect:visionText.frame],
             };
}

NSDictionary *visionTextBlockToDictionary(FIRVisionTextBlock * visionTextBlock) {
    NSMutableArray<NSDictionary *> *lines = [NSMutableArray array];
    for (FIRVisionTextLine *line in visionTextBlock.lines) {
        [lines addObject: visionTextLineToDictionary(line)];
    }
    return @{
             @"text" : visionTextBlock.text,
             //@"frame": [NSValue valueWithCGRect:visionTextBlock.frame],
             @"lines": lines,
             };
}

NSDictionary *visionTextLineToDictionary(FIRVisionTextLine * visionTextLine) {
    NSMutableArray<NSDictionary *> *elements = [NSMutableArray array];
    for (FIRVisionTextElement *element in visionTextLine.elements) {
        [elements addObject: visionTextElementToDictionary(element)];
    }
    return @{
             @"text" : visionTextLine.text,
             @"elements": elements,
             };
}

NSDictionary *visionTextElementToDictionary(FIRVisionTextElement * visionTextElement) {
    return @{
             @"text" : visionTextElement.text,
             };
}

@end
