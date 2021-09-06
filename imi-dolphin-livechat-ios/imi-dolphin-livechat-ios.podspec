
Pod::Spec.new do |spec|


  spec.name         = "imi-dolphin-livechat-ios"
  spec.version      = "2.0.1"
  spec.summary      = "Description of livechat connector by 3dolphins"

  spec.description  = "dolphin livechat connector is a library which help user to build chat application easy using Stompclient library"

  spec.homepage     = "https://jupiter.3dolphinsocial.com/3dolphins/dolphin-sdk/imi-dolphin-livechat-ios"

  spec.license      = "MIT"

  spec.author       = { "3dolphin" => "dolphininmo@gmail.com" }
  
  
  spec.swift_version = "5.0"
  spec.platform     = :ios, "11.0"
  spec.ios.deployment_target  = '11.0'
 
  spec.source       = { :git => "https://jupiter.3dolphinsocial.com/3dolphins/dolphin-sdk/imi-dolphin-livechat-ios.git", :tag => spec.version.to_s }

  spec.source_files  = '**/Sources/*.swift'

  spec.dependency "StompClientLib"
  spec.dependency "CryptoSwift", '~> 1.3.8'


end
