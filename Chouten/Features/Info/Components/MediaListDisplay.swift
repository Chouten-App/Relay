//
//  MediaListDisplay.swift
//  ChoutenRedesign
//
//  Created by Inumaki on 08.02.24.
//

import UIKit

class MediaListDisplay: UIView {

    var infoData: InfoData

    let contentView: UIStackView = {
        let contentView = UIStackView()
        contentView.axis = .vertical
        contentView.spacing = 12
        contentView.translatesAutoresizingMaskIntoConstraints = false
        return contentView
    }()

    var mediaListIndex: Int = 0
    var paginationIndex: Int = 0

    weak var delegate: MediaListDelegate?

    // MARK: Lifecycle

    init(infoData: InfoData) {
        self.infoData = infoData
        super.init(frame: .zero)
        configure()
        setupConstraints()
        updateData()
    }

    // MARK: View Lifecycle

    override init(frame: CGRect) {
        self.infoData = .sample
        super.init(frame: frame)
        configure()
        setupConstraints()
        updateData()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Setup

    private func configure() {
        addSubview(contentView)
    }

    func updateData(with index: Int? = nil) {
        if let index {
            mediaListIndex = index
        }

        contentView.arrangedSubviews
            .forEach { $0.removeFromSuperview() }

        let list = infoData.mediaList[mediaListIndex]
        let pagination = list.pagination[paginationIndex]
        let items = pagination.items

        // let watchedUrls = DatabaseManager.shared.fetchWatchedURLs()

        for index in 0..<items.count {
            let item: MediaItem = items[index]
            let mediaItemDisplay = MediaItemDisplay(item: item, index: index, watched: false)

            mediaItemDisplay.delegate = self

            contentView.addArrangedSubview(mediaItemDisplay)

            NSLayoutConstraint.activate([
                mediaItemDisplay.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                mediaItemDisplay.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
            ])
        }
    }

    // MARK: Layout

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentView.heightAnchor.constraint(equalTo: heightAnchor, constant: -20)
        ])
    }
}

extension MediaListDisplay: MediaItemDelegate {
    func tapped(_ data: MediaItem, index: Int) {
        self.delegate?.mediaItemTapped(data, index: index)
    }
}
