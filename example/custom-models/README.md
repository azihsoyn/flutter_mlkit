
# mlkit custom model example

example how to use custom remote models.

## Getting Started

Setup MLKit as described [here](../../)

Upload the following models to your MLKit custom model repository (Firebase Console -> ML Kit -> Custom):
  
| Model | Link | Hosted name |
|--|--|--|
| Classification with Mobilenet quantized | [download](https://storage.googleapis.com/download.tensorflow.org/models/tflite/mobilenet_v1_1.0_224_quant_and_labels.zip) | mobilenet_quant |
| Classification with Mobilenet float | [download](http://download.tensorflow.org/models/tflite_11_05_08/mobilenet_v2_1.0_224.tgz) | mobilenet_float |
| Object detection with Coco/mobilenet | [download](http://storage.googleapis.com/download.tensorflow.org/models/tflite/coco_ssd_mobilenet_v1_1.0_quant_2018_06_29.zip) | coco |