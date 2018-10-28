#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'mlkit'
  s.version          = '0.8.3'
  s.summary          = 'A Flutter plugin to use the Firebase ML Kit.'
  s.description      = <<-DESC
A new flutter plugin project.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'
  s.dependency 'Firebase/Core', '~> 5.11.0'
  s.dependency 'Firebase/MLVision', '~> 5.11.0'
  s.dependency 'Firebase/MLVisionTextModel', '~> 5.11.0'
  s.dependency 'Firebase/MLVisionBarcodeModel', '~> 5.11.0'
  s.dependency 'Firebase/MLVisionFaceModel', '~> 5.11.0'
  s.dependency 'Firebase/MLVisionLabelModel', '~> 5.11.0'
  s.dependency 'Firebase/MLModelInterpreter', '~> 5.11.0'
  s.static_framework = true 
  s.ios.deployment_target = '9.0'
end

