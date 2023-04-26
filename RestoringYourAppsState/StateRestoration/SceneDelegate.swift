/*
See LICENSE folder for this sample’s licensing information.

Abstract:
This sample's main window scene delegate.
*/

import UIKit

@available(iOS 13.0, *)
class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    static let storyboardName = "Main"
    
    var window: UIWindow?
    
    /** Apps configure their UIWindow and attach it to the provided UIWindowScene scene.
        The system calls willConnectTo shortly after the app delegate's "configurationForConnecting" function.
        Use this function to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
     
        When using a storyboard file, as specified by the Info.plist key, UISceneStoryboardFile, the system automatically configures
        the window property and attaches it to the windowScene.
 
        Remember to retain(保留、留住) the SceneDelegate's UIWindow.
        The recommended approach is for the SceneDelegate to retain the scene's window.
    */
    /// 每一個Scene都會有一個自己的、獨一的UISceneSession，
    /// 這個session包含了一個獨一的identifier以及Scene的相關設定值。
    /// 我們不需要自己創建者個session，在我們創建一個Scene時，系統會自動幫Scene創建一個session。
    ///
    /// -Authors: Tomtom Chu
    /// -Date: 2023.
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        
        /// Determine the user activity from a new connection or from a session's state restoration.
        ///
        /// userActivity可以用來記錄使用者的狀態，例如「檢視App中的內容」、「正在編輯文件」、「正在瀏覽網頁」、「正在觀看影片」等等。
        /// iOS系統會使用userActivity來回復(restore)上次的使用者狀態。
        ///
        /// 根據官方文件，在重新連接Scene(reconnecting)時，UISceneSession的stateRestorationActivity會提供UserActivity。
        ///
        /// -Authors: Tomtom Chu
        /// -Date: 2023.4.25
        guard let userActivity = connectionOptions.userActivities.first ?? session.stateRestorationActivity else { return }
        
        if configure(window: window, session: session, with: userActivity) {
            // Remember this activity for later when this app quits or suspends.
            scene.userActivity = userActivity
            
            /** Set the title for this scene to allow the system to differentiate multiple scenes for the user.
                If set to nil or an empty string, the system doesn't display a title.
            */
            scene.title = userActivity.title
            
            // Mark this scene's session with this userActivity product identifier so you can update the UI later.
            if let sessionProduct = SceneDelegate.product(for: userActivity) {
                /// userInfo是一個以Key-Value的儲存資料的變數。
                ///
                /// NSUserActivity與UISceneSession都有userInfo，可以儲存資訊。
                /// 在SceneDelegate+StateRestoration.swift檔案中，有宣告幾種key值。SceneDelegate.productIdentifierKey是其中一種。
                ///
                /// -Authors: Tomtom Chu
                /// -Date: 2023.4.25
                session.userInfo =
                    [SceneDelegate.productIdentifierKey: sessionProduct.identifier]
            }
        } else {
            Swift.debugPrint("Failed to restore scene from \(userActivity)")
        }
        
        /** Set up the activation predicates(術語) to determine which scenes to activate.
            Restrictions:
                Block-based predicates are not allowed.
                Regular expression predicates are not allowed.
                The only keyPath you can reference is "self".
        */
        /// 定義系統啟動(activate)一個Scene的條件。
        ///
        /// -Authors: Tomtom Chu
        /// -Date: 2023.4.26
        let conditions = scene.activationConditions
        
        // The primary "can" predicate (the kind of content this scene can display — specific targetContentIdenfiers).
        conditions.canActivateForTargetContentIdentifierPredicate = NSPredicate(value: false)

        // The secondary "prefers" predicate (this scene displays certain content -— the product's identifier).
        if let activityProductIdentifier = session.userInfo![SceneDelegate.productIdentifierKey] as? String {
            let preferPredicate = NSPredicate(format: "self == %@", activityProductIdentifier)
            conditions.prefersToActivateForTargetContentIdentifierPredicate =
                NSCompoundPredicate(orPredicateWithSubpredicates: [preferPredicate])
        }
    }

    func configure(window: UIWindow?, session: UISceneSession, with activity: NSUserActivity) -> Bool {
        var succeeded = false
        
        /// Check the user activity type to know which part of the app to restore.
        ///
        /// activityType是一個類似bundleId的字串。
        ///
        /// -Authors: Tomtom Chu
        /// -Date: 2023.4.25
        if activity.activityType == SceneDelegate.MainSceneActivityType() {
            // The activity type is for restoring DetailParentViewController.

            // Present a parent detail view controller with the specified product and selected tab.
            let storyboard = UIStoryboard(name: SceneDelegate.storyboardName, bundle: .main)
            
            // 載入detailParentViewController的Storyboard檔。
            guard let detailParentViewController =
                storyboard.instantiateViewController(withIdentifier: DetailParentViewController.viewControllerIdentifier)
                    as? DetailParentViewController else { return false }

            // 開始從UserActivity中的userInfo取出資料。
            if let userInfo = activity.userInfo {
                
                /// Decode the user activity product identifier from the userInfo.
                /// 利用userInfo所記錄的ProductKey，
                /// 去Decode(解碼)DataModel先前儲存的Product資料，
                /// 並且assign給detailParentViewController的product變數。
                ///
                /// 注意：當User在上次離開App前，頁面停留在某Product的Detail頁面時，
                /// userInfo[SceneDelegate.productKey]才會有值。
                ///
                /// -Authors: Tomtom Chu
                /// -Date: 2023.4.25
                if let productIdentifier = userInfo[SceneDelegate.productKey] as? String {
                    print("🐷 productIdentifier")
                    let product = DataModelManager.sharedInstance.product(fromIdentifier: productIdentifier)
                    detailParentViewController.product = product
                }
                
                /// Decode the selected tab bar controller tab from the userInfo.
                /// 利用userInfo所記錄的selectedTabKey，
                /// assign給detailParentViewController，讓它知道上次停留在哪一個Tab。
                ///
                /// -Authors: Tomtom Chu
                /// -Date: 2023.4.25
                if let selectedTab = userInfo[SceneDelegate.selectedTabKey] as? Int {
                    print("🐶 selectedTab有值。")
                    detailParentViewController.restoredSelectedTab = selectedTab
                }
                
                // Push the detail view controller for the user activity product.
                if let navigationController = window?.rootViewController as? UINavigationController {
                    print("🍎 navigationController有值")
                    navigationController.pushViewController(detailParentViewController, animated: false)
                }
                
                succeeded = true
            }
        } else {
            // The incoming userActivity is not recognizable here.
        }
        
        return succeeded
    }
    
    /** Use this delegate as the system is releasing the scene or on window close.
        This occurs shortly after the scene enters the background, or when the system discards its session.
        Release any scene-related resources that the system can recreate the next time the scene connects.
        The scene may reconnect later because the system didn't necessarily discard its session (see`application:didDiscardSceneSessions` instead),
        so don't delete any user data or state permanently.
    */
    func sceneDidDisconnect(_ scene: UIScene) {
        //..
    }
    
    
    /// Use this delegate when the scene moves from an active state to an inactive state, on window close, or in iOS enter background.
    /// This may occur due to temporary interruptions (for example, an incoming phone call).
    /// 當Scene要進入inactive state時，會觸發DataModelManager儲存資料。
    ///
    /// -Authors: Tomtom Chu
    /// -Date: 2023.4.25
    func sceneWillResignActive(_ scene: UIScene) {
        // Save any pending changes to the product list.
        DataModelManager.sharedInstance.saveDataModel()
        
        if let userActivity = window?.windowScene?.userActivity {
            userActivity.resignCurrent()
        }
    }
    
    /** Use this delegate as the scene transitions from the background to the foreground, on window open, or in iOS resume.
        Use it to undo the changes made on entering the background.
    */
    func sceneWillEnterForeground(_ scene: UIScene) {
        //..
    }
    
    /** Use this delegate when the scene "has moved" from an inactive state to an active state.
        Also use it to restart any tasks that the system paused (or didn't start) when the scene was inactive.
        The system calls this delegate every time a scene becomes active so set up your scene UI here.
    */
    func sceneDidBecomeActive(_ scene: UIScene) {
        if let userActivity = window?.windowScene?.userActivity {
            userActivity.becomeCurrent()
        }
    }

    /// Use this delegate as the scene transitions from the foreground to the background.
    /// Also use it to save data, release shared resources, and store enough scene-specific state information
    /// to restore the scene to its current state.
    /// App進入背景時，儲存資料。
    ///
    /// -Authors: Tomtom Chu
    /// -Date: 2023.4.26
    func sceneDidEnterBackground(_ scene: UIScene) {
        // Save any pending changes to the product list.
        // 儲存資料
        DataModelManager.sharedInstance.saveDataModel()
    }

    // MARK: - Window Scene

    // Listen for size change.
    func windowScene(_ windowScene: UIWindowScene,
                     didUpdate previousCoordinateSpace: UICoordinateSpace,
                     interfaceOrientation previousInterfaceOrientation: UIInterfaceOrientation,
                     traitCollection previousTraitCollection: UITraitCollection) {
        // The scene size has changed. (User moved the slider horizontally in either direction.)
    }
    
    /// 更新collectionView與detailView。
    ///
    /// -Authors: Tomtom Chu
    /// -Date: 2023.4.26
    func updateScene(with product: Product) {
        if let navController = window!.rootViewController as? UINavigationController {
            if let collectionView = navController.viewControllers[0] as? CollectionViewController {
                // Update the collection view.
                collectionView.collectionView.reloadData()
            }
            
            // Update the detail view controller.
            if let detailParentViewController = navController.topViewController as? DetailParentViewController {
                // Check that the view controller product identifier matches the incoming product identifier.
                if product.identifier.uuidString == detailParentViewController.product.identifier.uuidString {
                    detailParentViewController.product = product
                    window?.windowScene!.title = product.name
                }
            }
        }
    }
    
    // MARK: - Handoff support
    
    func scene(_ scene: UIScene, willContinueUserActivityWithType userActivityType: String) {
        //..
    }

    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        guard userActivity.activityType == SceneDelegate.MainSceneActivityType() else { return }
 
        if let rootViewController = window?.rootViewController as? UINavigationController {
            // Update the detail view controller.
            if let detailParentViewController = rootViewController.topViewController as? DetailParentViewController {
                detailParentViewController.product = SceneDelegate.product(for: userActivity)
            }
        }
    }

    func scene(_ scene: UIScene, didFailToContinueUserActivityWithType userActivityType: String, error: Error) {
        let alert = UIAlertController(title: NSLocalizedString("UnableToContinueTitle", comment: ""),
                                      message: error.localizedDescription,
                                      preferredStyle: .alert)
        let okAction = UIAlertAction(title: NSLocalizedString("OKTitle", comment: ""), style: .default) { (action) in
            alert.dismiss(animated: true, completion: nil)
        }
        alert.addAction(okAction)
        window?.rootViewController?.present(alert, animated: true, completion: nil)
    }

}
