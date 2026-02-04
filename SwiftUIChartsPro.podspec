Pod::Spec.new do |s|
  s.name             = 'SwiftUIChartsPro'
  s.version          = '1.0.0'
  s.summary          = 'Professional charting library for SwiftUI with animations.'
  s.description      = 'SwiftUIChartsPro provides professional charts for SwiftUI with line, bar, pie charts and smooth animations.'
  s.homepage         = 'https://github.com/muhittincamdali/SwiftUI-Charts-Pro'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Muhittin Camdali' => 'contact@muhittincamdali.com' }
  s.source           = { :git => 'https://github.com/muhittincamdali/SwiftUI-Charts-Pro.git', :tag => s.version.to_s }
  s.ios.deployment_target = '15.0'
  s.swift_versions = ['5.9', '5.10', '6.0']
  s.source_files = 'Sources/**/*.swift'
  s.frameworks = 'Foundation', 'SwiftUI'
end
