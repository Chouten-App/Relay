//
//  InfoViewRefactor.swift
//  ChoutenRedesign
//
//  Created by Inumaki on 06.02.24.
//

import Combine
import ComposableArchitecture
import UIKit

class InfoViewRefactor: LoadableViewControllerBase {
    var store: Store<InfoFeature.State, InfoFeature.Action>

    let loadingInfoVC = LoadingInfoVC()
    let errorInfoVC = UIViewController()
    let successInfoVC = SuccessInfoVC(infoData: .freeToUseData)

    let topBar = InfoTopBar(title: InfoData.freeToUseData.titles.primary)

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .portrait
    }

    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        .portrait
    }

    init(url: String) {
        store = .init(
            initialState: .init(),
            reducer: { InfoFeature() }
        )
        
        super.init(loadingViewController: loadingInfoVC, errorViewController: errorInfoVC, successViewController: successInfoVC)

        store.send(.view(.onAppear(url)))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    required init(loadingViewController: UIViewController, errorViewController: UIViewController, successViewController: UIViewController, waitingViewController: UIViewController? = nil) {
        fatalError("init(loadingViewController:errorViewController:successViewController:waitingViewController:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = ThemeManager.shared.getColor(for: .bg)

        successInfoVC.delegate = self

        observe { [weak self] in
            guard let self else { return }

            if let infoData = self.store.infoData, let success = self.successViewController as? SuccessInfoVC {
                success.doneLoading = self.store.doneLoading

                success.infoData = infoData
                success.currentModuleType = self.store.currentModuleType

                success.updateData()

                self.showSuccess()
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if #available(iOS 16.0, *) {
            if let windowScene = view.window?.windowScene {
                let geometryPreferences = UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: .portrait)
                windowScene.requestGeometryUpdate(geometryPreferences) { error in
                    print("Error requesting geometry update: \(error.localizedDescription)")
                }
            }
        } else {
            UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
            UINavigationController.attemptRotationToDeviceOrientation()
        }
    }

    private func setupConstraints() {
        let scenes = UIApplication.shared.connectedScenes
        let windowScene = scenes.first as? UIWindowScene
        let window = windowScene?.windows.first

        let topPadding = window?.safeAreaInsets.top ?? 0.0

        NSLayoutConstraint.activate([
            topBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topBar.topAnchor.constraint(equalTo: view.topAnchor),
            topBar.heightAnchor.constraint(equalToConstant: topPadding + 40),
            topBar.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.width)
        ])
    }
}

extension InfoViewRefactor: SuccessInfoVCDelegate {
    func fetchCollections() -> [HomeSection] {
        return store.collections
    }
    
    func fetchIsInCollections() -> [HomeSectionChecks] {
        return store.isInCollections
    }
    
    func fetchIsInAnyCollection() -> Bool {
        return store.isInAnyCollection
    }
    
    func addItemToCollection(collection: HomeSection) {
        store.send(.view(.addToCollection(collection)))
    }
    
    func fetchMedia(url: String, newIndex: Int) {
        store.send(.view(.fetchNewSeason(url, newIndex: newIndex)))
    }
    
    func removeFromCollection(collection: HomeSection) {
        store.send(.view(.removeFromCollection(collection)))
    }
    
    func updateFlag(status: ItemStatus) {
        store.send(.view(.updateFlag(status)))
    }
    
    func updateItemInCollection(collection: HomeSection) {
        store.send(.view(.updateItemInCollection(collection)))
    }
}
