import Foundation
import UIKit

enum ShareService {
    static func share(text: String, from controller: UIViewController) {
        let activity = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        controller.present(activity, animated: true)
    }
}


