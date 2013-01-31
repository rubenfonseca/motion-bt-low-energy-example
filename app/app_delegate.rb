class AppDelegate
  def application(application, didFinishLaunchingWithOptions:launchOptions)
    @window = UIWindow.alloc.initWithFrame(UIScreen.mainScreen.bounds).tap do |win|
      vc  = MainViewController.alloc.init
      nav = UINavigationController.alloc.initWithRootViewController vc

      win.rootViewController = nav
      win.rootViewController.wantsFullScreenLayout = true

      win.makeKeyAndVisible
    end

    true
  end
end
