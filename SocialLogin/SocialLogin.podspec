Pod::Spec.new do |spec|

  spec.name         = "SocialLogin"
  spec.version      = "1.0.0"
  spec.summary      = "This is a dynamic library for handling Social login"
  spec.description  = "This library is for handling the social login for multiple instances"
  spec.homepage     = "https://github.com/Rahul-iOS-ttn/SocialLogin"
  spec.license      = "MIT"
  spec.author       = { "Rahul-iOS-ttn" => "rahul.sharma1@tothenew.com" }
  spec.platform     = :ios, "11.0"
  spec.source       = { :git => "https://github.com/Rahul-iOS-ttn/SocialLogin.git", :tag => spec.version.to_s }

  spec.source_files  = "SocialLogin/**/*.{swift}"
  # spec.exclude_files = "Classes/Exclude"

  # ――― Resources ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  A list of resources included with the Pod. These are copied into the
  #  target bundle with a build phase script. Anything else will be cleaned.
  #  You can preserve files from being cleaned, please don't preserve
  #  non-essential files like tests, examples and documentation.
  #

  # spec.resource  = "icon.png"
  # spec.resources = "Resources/*.png"

  # spec.preserve_paths = "FilesToSave", "MoreFilesToSave"


  # ――― Project Linking ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  Link your library with frameworks, or libraries. Libraries do not include
  #  the lib prefix of their name.
  #

  # spec.framework  = "SomeFramework"
  # spec.frameworks = "SomeFramework", "AnotherFramework"

  # spec.library   = "iconv"
  # spec.libraries = "iconv", "xml2"


  # ――― Project Settings ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  If your library depends on compiler flags you can set them in the xcconfig hash
  #  where they will only apply to your library. If you depend on other Podspecs
  #  you can include multiple dependencies to ensure it works.

  # spec.requires_arc = true

  # spec.xcconfig = { "HEADER_SEARCH_PATHS" => "$(SDKROOT)/usr/include/libxml2" }
  # spec.dependency "JSONKit", "~> 1.4"
  
  # Swift Versions
  spec.swift_versions = "5.0"
end
