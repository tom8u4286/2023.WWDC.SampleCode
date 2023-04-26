/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The view controller for displaying the detailed information on each product.
*/

import UIKit

class DetailParentViewController: UIViewController {
    
    // The storyboard identifier for this view controller.
    static let viewControllerIdentifier = "DetailParentViewController"
    
    // MARK: - Properties
    
    var product: Product! {
        didSet {
            title = product.name
            updateChildDetailViewControllers(product: product)
        }
    }
    
    var parentTabbarController: UITabBarController!
    
    // The restored selected tab index for UITabBarController.
    var restoredSelectedTab: Int = 0
    
    // The restored EditViewController (iOS 12.x).
    var restoredEditor: EditViewController!
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let editButton =
            UIBarButtonItem(barButtonSystemItem: .edit,
                            target: self,
                            action: #selector(editAction(sender:)))
        navigationItem.rightBarButtonItem = editButton
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if #available(iOS 13.0, *) {
            // For iOS 13 and later, restore the editor from the user activity state.
            
            // Restore and present the EditViewController?
            // 復原編輯卡片欄位內容 並 顯示卡片
            if let activityUserInfo = view.window?.windowScene?.userActivity?.userInfo {
                if activityUserInfo[SceneDelegate.presentedEditorKey] != nil {
                    
                    // Restore the edit view controller.
                    // 復原 EditViewController
                    // 載入Storyboard的EditViewController，
                    if let editNavViewController = EditViewController.loadEditViewController() {
                        if let editViewController = editNavViewController.topViewController as? EditViewController {
                            // 將editViewController的product Assign給本頁的product
                            editViewController.product = product
                            
                            // Restore the edit fields.
                            // 復原 編輯欄位
                            editViewController.restoredTitle = activityUserInfo[SceneDelegate.editorTitleKey] as? String
                            editViewController.restoredPrice = activityUserInfo[SceneDelegate.editorPriceKey] as? String
                            editViewController.restoredYear = activityUserInfo[SceneDelegate.editorYearKey] as? String
                            
                            // 顯示本彈出式編輯卡片
                            self.present(editNavViewController, animated: false, completion: nil)
                        }
                    }
                }
            }

            /** Set up the activation predicates to determine which scenes to activate.
                Restrictions:
                    Block-based predicates are not allowed.
                    Regular expression predicates are not allowed.
                    The only keyPath you can reference is "self".
            */
            let conditions = view.window!.windowScene!.activationConditions
            
            // The primary "can" predicate (the kind of content this scene can display -— specific targetContentIdenfiers).
            conditions.canActivateForTargetContentIdentifierPredicate = NSPredicate(value: false)

            // The secondary "prefers" predicate (this scene displays certain content -— the product's identifier).
            let preferPredicate = NSPredicate(format: "self == %@", product.identifier.uuidString)
            conditions.prefersToActivateForTargetContentIdentifierPredicate =
                NSCompoundPredicate(orPredicateWithSubpredicates: [preferPredicate])

            // Update the user activity with this product and tab selection for scene-based state restoration.
            updateUserActivity()
        } else {
            // For iOS 12.x, restore the editor from the encoded restoration store.
            if let editor = restoredEditor {
                let navController = UINavigationController(rootViewController: editor)
                self.present(navController, animated: false, completion: {
                    self.restoredEditor = nil
                })
            }
        }
        
        if parentTabbarController != nil {
            parentTabbarController.selectedIndex = restoredSelectedTab
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // This view controller is going away, no more user activity to track.
        if #available(iOS 13.0, *) {
            view.window?.windowScene?.userActivity = nil
        } else {
            userActivity = nil
        }
    }
    
    // MARK: - Actions
    
    @objc
    func editAction(sender: Any) {
        // Present the edit view controller to edit the product's data.
        guard let editNavViewController = EditViewController.loadEditViewController() else { return }
        
        if let editViewController = editNavViewController.topViewController as? EditViewController {
            editViewController.product = product
            self.present(editNavViewController, animated: true, completion: nil)
        }
    }
    
    func updateChildDetailViewControllers(product: Product) {
        guard let tabbarController = parentTabbarController else { return }
        guard let tabViewControllers = tabbarController.viewControllers else { return }
        
        if let infoViewController = tabViewControllers[0] as? InfoViewController {
            infoViewController.product = product
        }
        if let photoViewController = tabViewControllers[1] as? ImageViewController {
            photoViewController.product = product
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Preparation of the embed segue to hold the tab bar controller. Pass the product to the tab bar controller's children.
        if segue.identifier == "embedTabbar" {
            if let destinationTabbarController = segue.destination as? UITabBarController {
                parentTabbarController = destinationTabbarController
                                
                // Receive a notification when the tab selection changes (to restore later).
                parentTabbarController.delegate = self
                
                // Pass the product to both child view controllers inside the tab bar controller.
                if product != nil {
                    updateChildDetailViewControllers(product: product)
                }
            }
        }
    }

    @available(iOS 13.0, *)
    /** Update the user activity for this view controller's scene.
        viewDidAppear calls this upon initial presentation.  The tabBarController.didSlect delegate also calls it.
    */
    func updateUserActivity() {
        print("🍎 DetailPage: updateUserActivity()")
        var currentUserActivity = view.window?.windowScene?.userActivity
        if currentUserActivity == nil {
            /** Note: You must include the activityType string below in your Info.plist file under the `NSUserActivityTypes` array.
                More info: https://developer.apple.com/documentation/foundation/nsuseractivity
            */
            currentUserActivity = NSUserActivity(activityType: SceneDelegate.MainSceneActivityType())
        }

        /** The target content identifier is a structured way to represent data in your model.
            Set a string that identifies the content of this NSUserActivity.
            Here the userActivity's targetContentIdentifier is the product's title.
        */
        currentUserActivity?.title = product.name
        currentUserActivity?.targetContentIdentifier = product.identifier.uuidString
        
        // Add the tab bar selection to the user activity.
        let selectedTab = parentTabbarController!.selectedIndex
        currentUserActivity?.addUserInfoEntries(from: [SceneDelegate.selectedTabKey: selectedTab])
        
        // Add the product to the user activity (as a coded JSON object).
        currentUserActivity?.addUserInfoEntries(from: [SceneDelegate.productKey: product.identifier.uuidString])
        
        // Update the product to both child view controllers in the tab bar controller.
        updateChildDetailViewControllers(product: product)
        
        view.window?.windowScene?.userActivity = currentUserActivity
        
        // Mark this scene's session with this userActivity product identifier, so you can update the UI later.
        view.window?.windowScene?.session.userInfo = [SceneDelegate.productIdentifierKey: product.identifier.uuidString]
    }
}

// MARK: - DoneEditDelegate

extension DetailParentViewController: DoneEditDelegate {
    
    // The EditViewController is done editing the product.
    func doneEdit(_ editViewController: EditViewController, product: Product) {
        title = product.name
    }
    
}

// MARK: - UITabBarControllerDelegate

extension DetailParentViewController: UITabBarControllerDelegate {
    
    // The user selected a tab bar controller tab.
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        if #available(iOS 13.0, *) {
            // Remember this tab selection as part of the user activity for scene-based state restoration.
            updateUserActivity()
        }
        restoredSelectedTab = tabBarController.selectedIndex
    }
    
}

// MARK: - UIStateRestoring (iOS 12.x)

// The system calls these overrides for nonscene-based versions of this app in iOS 12.x.

extension DetailParentViewController {

    // Keys for restoring this view controller.
    static let tabbarController = "tabbar" // The embedded child tab bar controller.
    static let restoreProductKey = "product" // The encoded product identifier.
    static let restoreSelectedTabKey = "selectedTab" // The tab bar controller's selected tab.
    
    static let restorePresentedEditorKey = "presentedEditor" // Indicates whether the system presented the editor view controller.
    static let restoreEditorKey = "editor" // The stored editor view controller.

    /// 將ViewController的狀態Encode起來。
    ///
    /// -Authors: Tomtom Chu
    /// -Date: 2023.4.26
    override func encodeRestorableState(with coder: NSCoder) {
        super.encodeRestorableState(with: coder)

        // 以DetailParentViewController.restoreProductKey，儲存當前的product的identifier。
        coder.encode(product.identifier.uuidString, forKey: DetailParentViewController.restoreProductKey)
        
        /** Because you’re using a custom container view controller (to hold the UITabBarController),
            you must encode it to restore its child view controllers.
            This allows the system to call encodeRestorableState/decodeRestorableState functions for each child.
            Note: Each child you encode must have a unique restoration identifier.
        */
        // 以DetailParentViewController.tabbarControllery作為Key，儲存當前的parentTabbarController。
        coder.encode(parentTabbarController, forKey: DetailParentViewController.tabbarController)
        
        // Save the tab bar's selected index page.
        // 以DetailParentViewController.restoreSelectedTabKey作為Key，儲存目前的Tab SelectedIndex(Tab頁面index)。
        coder.encode(parentTabbarController.selectedIndex, forKey: DetailParentViewController.restoreSelectedTabKey)
        
        /// presentedViewController是ViewController的屬性，
        ///
        /// -Authors: Tomtom Chu
        /// -Date: 2023.4.26
        if let presentedNavController = presentedViewController as? UINavigationController {
            let presentedViewController = presentedNavController.topViewController
            
            // Note: You don't need to encode the navigation controller.
            // 儲存當前的ViewController是否是EditViewController。
            coder.encode(presentedViewController is EditViewController, forKey: DetailParentViewController.restorePresentedEditorKey)
            
            /** EditViewController is a presented or child view controller so you must encode it to restore it.
                This allows the system to call encodeRestorableState/decodeRestorableState functions for the EditViewController.
            */
            ///
            ///
            /// 看不懂？？
            ///
            /// -Authors: Tomtom Chu
            /// -Date: 2023.4.26
            coder.encode(presentedViewController, forKey: DetailParentViewController.restoreEditorKey)
        }
    }

    override func decodeRestorableState(with coder: NSCoder) {
        super.decodeRestorableState(with: coder)
        print("🐞 decodeRestorableState")

        guard let decodedProductIdentifier = coder.decodeObject(forKey: DetailParentViewController.restoreProductKey) as? String else {
            fatalError("A product did not exist in the restore. In your app, handle this gracefully.")
        }
        product = DataModelManager.sharedInstance.product(fromIdentifier: decodedProductIdentifier)
        
        restoredSelectedTab = coder.decodeInteger(forKey: DetailParentViewController.restoreSelectedTabKey)
        
        if let editor = coder.decodeObject(forKey: DetailParentViewController.restoreEditorKey) as? EditViewController {
            restoredEditor = editor
            restoredEditor.product = product
        }

        // Note: The child view controllers inside the tab bar and the EditViewController each restore themselves.
    }

}
