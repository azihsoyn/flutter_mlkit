#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'mlkit'
  s.version          = '0.15.0'
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
  s.dependency 'Firebase/Core', '~> 6.11'
  s.dependency 'Firebase/MLVision', '~> 6.11'
  s.dependency 'Firebase/MLVisionTextModel', '~> 6.11'
  s.dependency 'Firebase/MLVisionBarcodeModel', '~> 6.11'
  s.dependency 'Firebase/MLVisionFaceModel', '~> 6.11'
  s.dependency 'Firebase/MLVisionLabelModel', '~> 6.11'
  s.dependency 'Firebase/MLModelInterpreter', '~> 6.11'
  s.dependency 'Firebase/MLNaturalLanguage', '~> 6.11'
  s.dependency 'Firebase/MLNLLanguageID', '~> 6.11'
  s.static_framework = true 
  s.ios.deployment_target = '9.0'
end

