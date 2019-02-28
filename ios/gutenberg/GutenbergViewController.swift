
import UIKit
import RNReactNativeGutenbergBridge
import Aztec

class GutenbergViewController: UIViewController {

    fileprivate lazy var gutenberg = Gutenberg(dataSource: self)
    fileprivate var htmlMode = false
    fileprivate var mediaPickCoordinator: MediaPickCoordinator?
    fileprivate lazy var mediaUploadCoordinator: MediaUploadCoordinator = {
        let mediaUploadCoordinator = MediaUploadCoordinator(gutenberg: self.gutenberg)
        return mediaUploadCoordinator
    }()
    
    override func loadView() {
        view = gutenberg.rootView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigationBar()
        gutenberg.delegate = self
        navigationController?.navigationBar.isTranslucent = false
    }

    @objc func moreButtonPressed(sender: UIBarButtonItem) {
        showMoreSheet()
    }

    @objc func saveButtonPressed(sender: UIBarButtonItem) {
        gutenberg.requestHTML()
    }
}

extension GutenbergViewController: GutenbergBridgeDelegate {

    func gutenbergDidLoad() {
        gutenberg.setFocusOnTitle()
    }

    func gutenbergDidMount(hasUnsupportedBlocks: Bool) {
        print("gutenbergDidMount(hasUnsupportedBlocks: \(hasUnsupportedBlocks))")
    }

    func gutenbergDidProvideHTML(title: String, html: String, changed: Bool) {
        print("didProvideHTML:")
        print("↳ Content changed: \(changed)")
        print("↳ Title: \(title)")
        print("↳ HTML: \(html)")
    }

    func gutenbergDidRequestMedia(from source: MediaPickerSource, with callback: @escaping MediaPickerDidPickMediaCallback) {
        switch source {
        case .mediaLibrary:
            print("Gutenberg did request media picker, passing a sample url in callback")
            callback(1, "https://cldup.com/cXyG__fTLN.jpg")
        case .deviceLibrary:
            print("Gutenberg did request a device media picker, opening the device picker")
            pickAndUpload(from: .savedPhotosAlbum, callback: callback)
        case .deviceCamera:
            print("Gutenberg did request a device media picker, opening the camera picker")
            pickAndUpload(from: .camera, callback: callback)
        }
    }

    func pickAndUpload(from source: UIImagePickerController.SourceType, callback: @escaping MediaPickerDidPickMediaCallback) {
        mediaPickCoordinator = MediaPickCoordinator(presenter: self, callback: { (url) in
            guard let url = url, let mediaID = self.mediaUploadCoordinator.upload(url: url) else {
                callback(nil, nil)
                return
            }
            callback(mediaID, url.absoluteString)
            self.mediaPickCoordinator = nil
        } )
        mediaPickCoordinator?.pick(from: source)
    }

    func gutenbergDidRequestMediaUploadSync() {
        print("Gutenberg request for media uploads to be resync")
    }

    func gutenbergDidRequestMediaUploadActionDialog(for mediaID: Int32) {
        guard let progress = mediaUploadCoordinator.progressForUpload(mediaID: mediaID) else {
            return
        }

        let title: String = "Media Options"
        var message: String? = ""
        let alertController = UIAlertController(title: title, message: nil, preferredStyle: .actionSheet)
        let dismissAction = UIAlertAction(title: "Dismiss", style: .cancel) { (action) in

        }
        alertController.addAction(dismissAction)

        if progress.fractionCompleted < 1 {
            let cancelUploadAction = UIAlertAction(title: "Cancel upload", style: .destructive) { (action) in
                self.mediaUploadCoordinator.cancelUpload(with: mediaID)
            }
            alertController.addAction(cancelUploadAction)
        } else if let error = progress.userInfo[.mediaError] as? String {
            message = error
            let retryUploadAction = UIAlertAction(title: "Retry upload", style: .default) { (action) in
                self.mediaUploadCoordinator.retryUpload(with: mediaID)
            }
            alertController.addAction(retryUploadAction)
        }

        alertController.title = title
        alertController.message = message
        alertController.popoverPresentationController?.sourceView = view
        alertController.popoverPresentationController?.sourceRect = view.frame
        alertController.popoverPresentationController?.permittedArrowDirections = .any
        present(alertController, animated: true, completion: nil)
    }
}

extension GutenbergViewController: GutenbergBridgeDataSource {
    
    func gutenbergLocale() -> String? {
        return Locale.preferredLanguages.first ?? "en"
    }
    
    func gutenbergTranslations() -> [String : [String]]? {
        return nil
    }
    
    func gutenbergInitialContent() -> String? {
        return nil
    }
    
    func gutenbergInitialTitle() -> String? {
        return nil
    }

    func aztecAttachmentDelegate() -> TextViewAttachmentDelegate {
        return ExampleAttachmentDelegate()
    }
}

//MARK: - Navigation bar

extension GutenbergViewController {

    func configureNavigationBar() {
        addSaveButton()
        addMoreButton()
    }

    func addSaveButton() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save,
                                                           target: self,
                                                           action: #selector(saveButtonPressed(sender:)))
    }

    func addMoreButton() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "...",
                                                            style: .plain,
                                                            target: self,
                                                            action: #selector(moreButtonPressed(sender:)))
    }
}

//MARK: - More actions

extension GutenbergViewController {

    func showMoreSheet() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let cancelAction = UIAlertAction(title: "Keep Editing", style: .cancel)
        alert.addAction(toggleHTMLModeAction)
        alert.addAction(updateHtmlAction)
        alert.addAction(cancelAction)

        present(alert, animated: true)
    }
    
    var toggleHTMLModeAction: UIAlertAction {
        return UIAlertAction(
            title: htmlMode ? "Switch To Visual" : "Switch to HTML",
            style: .default,
            handler: { [unowned self] action in
                self.toggleHTMLMode(action)
        })
    }
    
    var updateHtmlAction: UIAlertAction {
        return UIAlertAction(
            title: "Update HTML",
            style: .default,
            handler: { [unowned self] action in
                let alert = self.alertWithTextInput(using: { [unowned self] (htmlInput) in
                    if let input = htmlInput {
                        self.gutenberg.updateHtml(input)
                    }
                })
                self.present(alert, animated: true, completion: nil)
        })
    }
    
    func alertWithTextInput(using handler: ((String?) -> Void)?) -> UIAlertController {
        let alert = UIAlertController(title: "Enter HTML", message: nil, preferredStyle: .alert)
        alert.addTextField()
        let submitAction = UIAlertAction(title: "Submit", style: .default) { [unowned alert] (action) in
            handler?(alert.textFields?.first?.text)
        }
        alert.addAction(submitAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        return alert
    }
    
    func toggleHTMLMode(_ action: UIAlertAction) {
        htmlMode = !htmlMode
        gutenberg.toggleHTMLMode()
    }
}
