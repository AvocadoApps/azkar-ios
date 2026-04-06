import UIKit
import MessageUI

final class FeedbackMailPresenter {

    private let delegate = MailComposeDelegate()

    func present(from viewController: UIViewController) {
        guard MFMailComposeViewController.canSendMail() else {
            guard let url = URL(string: "https://t.me/jawziyya_feedback") else { return }
            UIApplication.shared.open(url)
            return
        }

        let mailComposerViewController = MFMailComposeViewController()
        mailComposerViewController.setToRecipients(["azkar.app@pm.me"])
        mailComposerViewController.mailComposeDelegate = delegate
        viewController.present(mailComposerViewController, animated: true)
    }
}

private final class MailComposeDelegate: NSObject, MFMailComposeViewControllerDelegate {

    func mailComposeController(
        _ controller: MFMailComposeViewController,
        didFinishWith result: MFMailComposeResult,
        error: Error?
    ) {
        controller.dismiss(animated: true)
    }
}
