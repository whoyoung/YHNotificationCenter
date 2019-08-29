
Pod::Spec.new do |s|
  s.name         = "YHNotificationCenter"
  s.version      = "1.0.0"
  s.summary      = "自己实现通知中心，无需在 dealloc 方法中移除观察者"
  s.description  = <<-DESC
***
## Features:
1. 自己实现通知中心，无需在 dealloc 方法中移除观察者.  
***
                   DESC

  s.homepage     = "https://github.com/whoyoung/YHNotificationCenter"
  s.license      = "MIT"

  s.author             = { "杨虎" => "huyang@mail.bistu.edu.cn" }
  s.platform     = :ios
  s.source       = { :git => "https://github.com/whoyoung/YHNotificationCenter", :tag => "#{s.version}" }

  s.source_files         = "YHNotificationCenter/NotificationCenter/*.{h,m}"
  s.requires_arc = true

end
