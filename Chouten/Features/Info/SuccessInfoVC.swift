//
//  SuccessInfoVC.swift
//  ChoutenRedesign
//
//  Created by Inumaki on 06.02.24.
//

import UIKit
import ComposableArchitecture

protocol SuccessInfoVCDelegate: AnyObject {
    func fetchMedia(url: String, newIndex: Int)
    func fetchCollections() -> [HomeSection]
    func fetchIsInCollections() -> [HomeSectionChecks]
    func fetchIsInAnyCollection() -> Bool
    func addItemToCollection(collection: HomeSection)
    func removeFromCollection(collection: HomeSection)
    func updateFlag(status: ItemStatus)
    func updateItemInCollection(collection: HomeSection)
}

class SuccessInfoVC: UIViewController {
    weak var delegate: SuccessInfoVCDelegate?
    var infoData: InfoData
    var currentModuleType: ModuleType = .video

    var doneLoading = false

    let topBar = InfoTopBar(title: InfoData.freeToUseData.titles.primary)

    let headerDisplay: InfoHeaderDisplay
    let extraInfoDisplay: ExtraInfoDisplay
    let seasonDisplay: SeasonDisplay
    let mediaListDisplay: MediaListDisplay
    let loadingSeasonDisplay: LoadingSeasonDisplay
    let loadingMediaListDisplay: LoadingMediaListDisplay
    let seasonSelector: SeasonSelectorView

    lazy var scrollView: UIScrollView = createScrollView()
    lazy var contentView: UIStackView = createContentView()

    var offsetY: Double = 0.0

    var blurOverlay: UIImageView = {
        let view = UIImageView()
        view.contentMode = .top
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    // MARK: Lifecycle

    init(infoData: InfoData) {
        self.infoData = infoData
        self.headerDisplay = InfoHeaderDisplay(infoData: infoData, offsetY: offsetY)
        self.extraInfoDisplay = ExtraInfoDisplay(infoData: infoData)
        self.seasonDisplay = SeasonDisplay(infoData: infoData)
        self.mediaListDisplay = MediaListDisplay(infoData: infoData)
        self.loadingSeasonDisplay = LoadingSeasonDisplay()
        self.loadingMediaListDisplay = LoadingMediaListDisplay()
        self.seasonSelector = SeasonSelectorView(infoData.seasons)
        super.init(nibName: nil, bundle: nil)
    }

    // MARK: View Lifecycle

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateData() {
        if (delegate?.fetchIsInAnyCollection() == true) {
            topBar.bookmarkButton.iconName = "bookmark.fill"
        }
        
        topBar.titleLabel.text = infoData.titles.primary

        headerDisplay.infoData = infoData
        headerDisplay.updateData()

        seasonDisplay.infoData = infoData
        seasonDisplay.updateData()

        extraInfoDisplay.infoData = infoData
        extraInfoDisplay.updateData()

        if !infoData.mediaList.isEmpty {
            print("NOT EMPTY")
            self.loadingSeasonDisplay.alpha = 1.0
            self.loadingMediaListDisplay.alpha = 1.0
            UIView.animate(withDuration: 0.2, animations: {
                self.loadingSeasonDisplay.alpha = 0.0
                self.loadingMediaListDisplay.alpha = 0.0
            }, completion: { _ in
                self.loadingSeasonDisplay.removeFromSuperview()
                self.loadingMediaListDisplay.removeFromSuperview()

                self.seasonDisplay.infoData = self.infoData
                self.seasonDisplay.updateData()

                self.mediaListDisplay.infoData = self.infoData
                self.mediaListDisplay.updateData()

                self.seasonDisplay.alpha = 0.0
                self.mediaListDisplay.alpha = 0.0

                self.contentView.addArrangedSubview(self.seasonDisplay)
                self.contentView.addArrangedSubview(self.mediaListDisplay)

                self.seasonSelector.updateData(with: self.infoData.seasons)

                UIView.animate(withDuration: 0.2) {
                    self.seasonDisplay.alpha = 1.0
                    self.mediaListDisplay.alpha = 1.0
                }
            })
        } else {
            if doneLoading {
                UIView.animate(withDuration: 0.2) {
                    self.seasonDisplay.removeFromSuperview()
                    self.mediaListDisplay.removeFromSuperview()
                    self.loadingSeasonDisplay.removeFromSuperview()
                    self.loadingMediaListDisplay.removeFromSuperview()

                    // add error display
                    let titleCard = TitleCard("No Media Found.", description: "This title doesnt seem to have any media yet...")

                    self.contentView.addArrangedSubview(titleCard)

                    self.contentView.layoutIfNeeded()
                }
            } else {
                self.seasonDisplay.alpha = 1.0
                self.mediaListDisplay.alpha = 1.0

                // Animate the alpha values
                UIView.animate(withDuration: 0.2, animations: {
                    // Fade out the existing views
                    self.seasonDisplay.alpha = 0.0
                    self.mediaListDisplay.alpha = 0.0
                }, completion: { _ in
                    // Remove the existing views from superview after fade out animation completes
                    self.seasonDisplay.removeFromSuperview()
                    self.mediaListDisplay.removeFromSuperview()

                    // Add new views with alpha set to 0.0
                    self.loadingSeasonDisplay.alpha = 0.0
                    self.loadingMediaListDisplay.alpha = 0.0
                    self.contentView.addArrangedSubview(self.loadingSeasonDisplay)
                    self.contentView.addArrangedSubview(self.loadingMediaListDisplay)

                    // Fade in the new views
                    UIView.animate(withDuration: 0.2) {
                        self.loadingSeasonDisplay.alpha = 1.0
                        self.loadingMediaListDisplay.alpha = 1.0
                    }
                })
            }
        }

        viewWillLayoutSubviews()
    }

    override func viewDidLoad() {
        seasonSelector.alpha = 0.0

        super.viewDidLoad()

        view.backgroundColor = ThemeManager.shared.getColor(for: .bg)

        scrollView.delegate = self

        scrollView.addSubview(contentView)

        contentView.addArrangedSubview(headerDisplay)
        contentView.addArrangedSubview(extraInfoDisplay)
        if !infoData.mediaList.isEmpty {
            contentView.addArrangedSubview(seasonDisplay)
            contentView.addArrangedSubview(mediaListDisplay)
        } else {
            contentView.addArrangedSubview(loadingSeasonDisplay)
            contentView.addArrangedSubview(loadingMediaListDisplay)
        }

        view.addSubview(scrollView)
        view.addSubview(topBar)

        topBar.layer.zPosition = 10
        seasonSelector.layer.zPosition = 20
        seasonSelector.delegate = self
        
        topBar.bookmarkButton.addTarget(self, action: #selector(bookmarkButtonTapped), for: .touchUpInside)

        view.addSubview(seasonSelector)

        setupConstraints()

        mediaListDisplay.delegate = self

        seasonDisplay.delegate = self

        seasonDisplay.seasonButton.onTap = {
            UIView.animate(withDuration: 0.2) {
                self.seasonSelector.alpha = 1.0
            }
        }
    }
    
    @objc func bookmarkButtonTapped() {
        let collectionMenuVC = CollectionMenuVC()
        collectionMenuVC.delegate = self

        if let sheet = collectionMenuVC.sheetPresentationController {
            sheet.detents = [.medium()]
            sheet.prefersGrabberVisible = true
            sheet.prefersScrollingExpandsWhenScrolledToEdge = false
        }

        present(collectionMenuVC, animated: true, completion: nil)
    }

    // MARK: Layout
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

            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),

            seasonDisplay.heightAnchor.constraint(equalToConstant: 32 + 6 + 18 + 24),
            loadingSeasonDisplay.heightAnchor.constraint(equalToConstant: 32 + 6 + 14),

            seasonSelector.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            seasonSelector.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            seasonSelector.topAnchor.constraint(equalTo: view.topAnchor),
            seasonSelector.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // MARK: Helpers
    private func createScrollView() -> UIScrollView {
        let scrollView                              = UIScrollView()
        scrollView.alwaysBounceVertical             = true
        scrollView.showsVerticalScrollIndicator     = false
        scrollView.contentInsetAdjustmentBehavior   = .never
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }

    private func createContentView() -> UIStackView {
        let stack       = UIStackView()
        stack.axis      = .vertical
        stack.spacing   = 20
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }

    private func takeScreenshot() -> UIImage {
        // Find the currently active scene
        if let windowScene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
           let window = windowScene.windows.first {
            let layer = window.layer
            let scale = UIScreen.main.scale
            UIGraphicsBeginImageContextWithOptions(layer.frame.size, false, scale)

            if let context = UIGraphicsGetCurrentContext() {
                layer.render(in: context)
            }

            let screenshot = UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
            UIGraphicsEndImageContext()

            return screenshot
        }

        return UIImage()
    }

    func addBlur(to image: UIImage) -> UIImage? {
        if let ciImage = CIImage(image: image) {
            ciImage.applyingFilter("CIGaussianBlur")
            return UIImage(ciImage: ciImage)
        }
        return nil
    }
}

// MARK: UIScrollViewDelegate
extension SuccessInfoVC: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = -scrollView.contentOffset.y

        topBar.blurView.alpha = -offsetY / 120
        topBar.titleLabel.alpha = -offsetY / 120

        headerDisplay.view.clipsToBounds = offsetY <= 0

        let heightOffset = max((offsetY) - 40, -40)

        headerDisplay.bannerHeightConstraint.constant = heightOffset
    }
}

extension SuccessInfoVC: MediaListDelegate {
    func mediaItemTapped(_ data: MediaItem, index: Int) {
        let scenes = UIApplication.shared.connectedScenes
        guard let windowScene = scenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let navController = window.rootViewController as? UINavigationController else {
            return
        }

        switch currentModuleType {
        case .video:
            break
            /*
            let landscapeVC = PlayerVC(data: data, info: infoData, index: index)
            landscapeVC.modalPresentationStyle = .fullScreen
            navController.navigationBar.isHidden = true
            navController.present(landscapeVC, animated: true, completion: nil)
             */
        case .book:
            break
            /*
            // find media items list
            var mediaItems: [MediaItem] = []
            if let paginationWithItem = infoData.mediaList
                .flatMap({ $0.pagination })
                .first(where: { pagination in
                    pagination.items.contains(where: { $0 == data })
                }) {

                // Do something with the pagination
                mediaItems = paginationWithItem.items
            } else {
                print("Pagination containing the item not found.")
            }

            let readerVC = ReaderViewController(infoData: infoData, item: data, index: index, mediaItems: mediaItems)
            navController.navigationBar.isHidden = true
            navController.pushViewController(readerVC, animated: true)
             */
        default:
            break
        }
    }
}

extension SuccessInfoVC: SeasonSelectorDelegate {
    func didChangeSeason(to newIndex: Int) {
        if infoData.seasons.count > newIndex {
            delegate?.fetchMedia(url: infoData.seasons[newIndex].url, newIndex: newIndex)
        }
    }

    func closeSelector() {
        UIView.animate(withDuration: 0.2) {
            self.seasonSelector.alpha = 0.0
        }
    }
}

extension SuccessInfoVC: SeasonDisplayDelegate {
    func didChangePagination(to index: Int) {
        self.mediaListDisplay.updateData(with: index)
    }
}

extension SuccessInfoVC: CollectionMenuVCDelegate {
    func fetchCollections() -> [HomeSection] {
        return self.delegate!.fetchCollections()
    }
    
    func fetchIsInCollections() -> [HomeSectionChecks] {
        return self.delegate!.fetchIsInCollections()
    }
    
    func addItemToCollection(collection: HomeSection) {
        return self.delegate!.addItemToCollection(collection: collection)
    }
    
    func removeFromCollection(collection: HomeSection) {
        return self.delegate!.removeFromCollection(collection: collection)
    }
    
    func updateFlag(status: ItemStatus) {
        return self.delegate!.updateFlag(status: status)
    }
    
    func updateItemInCollection(collection: HomeSection) {
        return self.delegate!.updateItemInCollection(collection: collection)
    }
}

protocol CollectionMenuVCDelegate: AnyObject {
    func fetchCollections() -> [HomeSection]
    func fetchIsInCollections() -> [HomeSectionChecks]
    func addItemToCollection(collection: HomeSection)
    func removeFromCollection(collection: HomeSection)
    func updateFlag(status: ItemStatus)
    func updateItemInCollection(collection: HomeSection)
}

class CollectionMenuVC: UIViewController {
    weak var delegate: CollectionMenuVCDelegate?

    private var collections: [HomeSection] = []
    private var isInCollections: [HomeSectionChecks] = []
    private var itemStatuses: [ItemStatus] = []

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Collections"
        label.font = UIFont.boldSystemFont(ofSize: 20)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let tableView = UITableView()
    
    private let cancelButton: UIButton = {
        var configuration = UIButton.Configuration.plain()
        configuration.title = "Cancel"
        configuration.attributedTitle = AttributedString("Cancel", attributes: AttributeContainer([
            .font: UIFont.systemFont(ofSize: 14, weight: .bold),
            .foregroundColor: UIColor.fg
        ]))

        let button = UIButton(configuration: configuration)
        button.backgroundColor = ThemeManager.shared.getColor(for: .overlay)

        button.layer.cornerRadius = 8
        button.layer.borderColor = ThemeManager.shared.getColor(for: .border).cgColor
        button.layer.borderWidth = 0.5

        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let confirmButton: UIButton = {
        var configuration = UIButton.Configuration.plain()
        configuration.title = "Confirm"
        configuration.attributedTitle = AttributedString("Confirm", attributes: AttributeContainer([
            .font: UIFont.systemFont(ofSize: 14, weight: .bold),
            .foregroundColor: UIColor.fg
        ]))

        let button = UIButton(configuration: configuration)
        button.backgroundColor = ThemeManager.shared.getColor(for: .accent)

        button.layer.cornerRadius = 8

        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        return indicator
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.systemBackground
        setupUI()
        loadCollectionsData()
    }

    private func setupUI() {
        // Add title label
        view.addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])

        // Setup table view
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(CollectionCell.self, forCellReuseIdentifier: "CollectionCell")
        view.addSubview(tableView)
        
        // Buttons
        view.addSubview(cancelButton)
        view.addSubview(confirmButton)
        view.addSubview(loadingIndicator)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            cancelButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            cancelButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            cancelButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -16),
            cancelButton.heightAnchor.constraint(equalToConstant: 44),
            
            confirmButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            confirmButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            confirmButton.bottomAnchor.constraint(equalTo: cancelButton.topAnchor, constant: -8),
            confirmButton.heightAnchor.constraint(equalToConstant: 44),

            loadingIndicator.centerXAnchor.constraint(equalTo: confirmButton.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: confirmButton.centerYAnchor)
       ])

       // Add actions
       cancelButton.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
       confirmButton.addTarget(self, action: #selector(confirmButtonTapped), for: .touchUpInside)
    }

    private func loadCollectionsData() {
        guard let delegate = delegate else { return }
        collections = delegate.fetchCollections()
        isInCollections = delegate.fetchIsInCollections()
        itemStatuses = collections.flatMap { collection in
            // Find status for each collection or set to `.none` if not found
            return collection.list.map { item in
                if isInCollections.first(where: { $0.url == item.url }) != nil {
                    return item.status
                }
                return .none
            }
        }
        tableView.reloadData()
    }
    
    @objc private func cancelButtonTapped() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func confirmButtonTapped() {
        confirmButton.setTitle("", for: .normal)
        loadingIndicator.startAnimating()

        confirmButton.isEnabled = false

        // Simulate a custom function with a delay
        DispatchQueue.global().async {
            sleep(2)

            DispatchQueue.main.async {
                // Stop the loading indicator
                self.loadingIndicator.stopAnimating()

                // Re-enable the confirm button
                self.confirmButton.isEnabled = true

                // Dismiss the sheet after the task is complete
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
}

extension CollectionMenuVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return collections.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CollectionCell", for: indexPath) as! CollectionCell
        let collection = collections[indexPath.row]
        let isInCollection = isInCollections[indexPath.row].isInCollection
        let status = indexPath.row < itemStatuses.count ? itemStatuses[indexPath.row] : (collections[indexPath.row].list.first(where: { $0.url == isInCollections[indexPath.row].url })?.status ?? .none)

        cell.configure(with: collection.title, isInCollection: isInCollection, status: status, collection: collection, delegate: self)

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let collection = collections[indexPath.row]
        let isInCollection = isInCollections[indexPath.row].isInCollection

        if isInCollection {
            delegate?.removeFromCollection(collection: collection)
        } else {
            delegate?.addItemToCollection(collection: collection)
        }

        // Toggle the state
        isInCollections[indexPath.row].isInCollection.toggle()

        // Update the cell
        tableView.reloadRows(at: [indexPath], with: .automatic)
    }
}

extension CollectionMenuVC: CollectionCellDelegate {
    func updateFlag(status: ItemStatus) {
        return self.delegate!.updateFlag(status: status)
    }
    
    func updateItemInCollection(collection: HomeSection) {
        return self.delegate!.updateItemInCollection(collection: collection)
    }
}

protocol CollectionCellDelegate: AnyObject {
    func updateFlag(status: ItemStatus)
    func updateItemInCollection(collection: HomeSection)
}

// Custom UITableViewCell with circular radio button
class CollectionCell: UITableViewCell {
    private let titleLabel = UILabel()
    private let radioButton: UIButton = {
        let button = UIButton(type: .system)
        button.layer.cornerRadius = 12
        button.layer.borderWidth = 2
        button.layer.borderColor = UIColor.label.cgColor
        button.clipsToBounds = true
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let statusButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Select Status", for: .normal)
        button.setTitleColor(.systemBlue, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private var collection: HomeSection? = nil
    private let statusOptions: [ItemStatus] = [.completed, .dropped, .inprogress, .none, .planned]
    private weak var delegate: CollectionCellDelegate? = nil
    
    // Closure to handle the status selection
    var statusSelectionHandler: (() -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)
        contentView.addSubview(radioButton)
        contentView.addSubview(statusButton)

        NSLayoutConstraint.activate([
            radioButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            radioButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            radioButton.widthAnchor.constraint(equalToConstant: 24),
            radioButton.heightAnchor.constraint(equalToConstant: 24),

            titleLabel.leadingAnchor.constraint(equalTo: radioButton.trailingAnchor, constant: 12),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            statusButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            statusButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
        
        statusButton.addTarget(self, action: #selector(statusButtonTapped), for: .touchUpInside)
    }
    
    @objc private func statusButtonTapped() {
        guard let viewController = findViewController() else { return }
        
        let alertController = UIAlertController(title: "Select Status", message: nil, preferredStyle: .actionSheet)
                
        for status in statusOptions {
            let action = UIAlertAction(title: status.rawValue, style: .default) { _ in
                self.updateStatus(to: status)
            }
            alertController.addAction(action)
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)

        viewController.present(alertController, animated: true, completion: nil)
    }

    private func findViewController() -> UIViewController? {
        var responder: UIResponder? = self
        while responder != nil {
            responder = responder?.next
            if let viewController = responder as? UIViewController {
                return viewController
            }
        }
        return nil
    }

    func configure(with title: String, isInCollection: Bool, status: ItemStatus, collection: HomeSection, delegate: CollectionCellDelegate) {
        self.collection = collection
        self.delegate = delegate
        titleLabel.text = title
        updateRadioButton(isInCollection: isInCollection)
        statusButton.setTitle(status.rawValue, for: .normal)
    }

    private func updateRadioButton(isInCollection: Bool) {
        if isInCollection {
            radioButton.setTitle("✓", for: .normal)
            radioButton.backgroundColor = UIColor.label
            radioButton.setTitleColor(UIColor.systemBackground, for: .normal)
        } else {
            radioButton.setTitle("", for: .normal)
            radioButton.backgroundColor = UIColor.clear
        }
    }
    
    private func updateStatus(to status: ItemStatus) {
        if collection != nil {
            delegate!.updateFlag(status: status)
            delegate!.updateItemInCollection(collection: collection!)
        }
        
        statusButton.setTitle(status.rawValue, for: .normal)
    }
}