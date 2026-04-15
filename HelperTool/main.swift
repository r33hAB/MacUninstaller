import Foundation

let delegate = HelperToolDelegate()
let listener = NSXPCListener(machServiceName: AppConstants.helperBundleID)
listener.delegate = delegate
listener.resume()
RunLoop.main.run()
