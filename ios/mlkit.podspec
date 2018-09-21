#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'mlkit'
  s.version          = '0.0.1'
  s.summary          = 'A new flutter plugin project.'
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
  s.dependency 'Firebase/Core', '~> 5.8.0'
  s.dependency 'Firebase/MLVision', '~> 5.8.0'
  s.dependency 'Firebase/MLVisionTextModel', '~> 5.8.0'
  s.dependency 'Firebase/MLVisionBarcodeModel', '~> 5.8.0'
  s.dependency 'Firebase/MLVisionFaceModel', '~> 5.8.0'
  s.dependency 'Firebase/MLVisionLabelModel', '~> 5.8.0'
  s.dependency 'Firebase/MLModelInterpreter', '~> 5.8.0'
  
  s.ios.deployment_target = '9.0'
end

