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

@end
