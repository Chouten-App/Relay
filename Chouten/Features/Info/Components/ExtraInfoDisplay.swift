//
//  ExtraInfoDisplay.swift
//  ChoutenRedesign
//
//  Created by Inumaki on 08.02.24.
//

import UIKit
import GoogleCast

class ExtraInfoDisplay: UIView {

    var infoData: InfoData

    let stack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    let tagsDisplay: TagDisplay

    let descriptionLabel: UILabel = {
        let label           = UILabel()
        label.textColor     = ThemeManager.shared.getColor(for: .fg)
        label.font          = UIFont.systemFont(ofSize: 14)
        label.alpha         = 0.7
        label.numberOfLines = 9
        label.lineBreakMode = .byCharWrapping
        return label
    }()
    
    let chapterButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .accent
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .bold)
        button.setTitle("Continue Watching: Episode 1", for: .normal)
        button.layer.cornerRadius = 20
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()


    // MARK: Lifecycle

    init(infoData: InfoData) {
        self.infoData = infoData
        self.tagsDisplay = TagDisplay(infoData: infoData)
        super.init(frame: .zero)
        configure()
        setupConstraints()
        updateData()
    }

    // MARK: View Lifecycle

    override init(frame: CGRect) {
        self.infoData = .sample
        self.tagsDisplay = TagDisplay(infoData: infoData)
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
        if !infoData.tags.isEmpty {
            stack.addArrangedSubview(tagsDisplay)
        }
        stack.addArrangedSubview(descriptionLabel)

        addSubview(stack)
    }

    func updateData() {
        tagsDisplay.infoData = infoData
        tagsDisplay.updateData()

        stack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        stack.addArrangedSubview(chapterButton)
        
        stack.setCustomSpacing(16, after: chapterButton)

        if !infoData.tags.isEmpty {
            stack.addArrangedSubview(tagsDisplay)
        }
        stack.addArrangedSubview(descriptionLabel)

        let paragraphStyle = NSMutableParagraphStyle()
        let attstr = NSMutableAttributedString(string: infoData.sanitizedDescription)
        paragraphStyle.hyphenationFactor = 1.0
        attstr.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(0..<attstr.length))
        descriptionLabel.attributedText = attstr
        
        chapterButton.addTarget(self, action: #selector(castMedia), for: .touchUpInside)
    }
    
    @objc func castMedia() {
        let mediaMetadata = GCKMediaMetadata()
        
        // Set the title
        mediaMetadata.setString("Tower of God Season 2", forKey: kGCKMetadataKeyTitle)

        // Set the poster image
        let posterURL = URL(string: "https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx153406-dU2RLKgMUF2U.jpg")!
        let image = GCKImage(url: posterURL, width: 220, height: 360) // Use appropriate dimensions
        mediaMetadata.addImage(image)
        
        let mediaInfo = GCKMediaInformation(
            contentID: "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4",
            streamType: .buffered,
            contentType: "video/mp4",
            metadata: mediaMetadata,
            streamDuration: 0,
            mediaTracks: nil,
            textTrackStyle: nil,
            customData: nil
        )

        if let session = GCKCastContext.sharedInstance().sessionManager.currentSession {
            session.remoteMediaClient?.loadMedia(mediaInfo)
        } else {
            // Handle case where no session is active
        }
    }

    // MARK: Layout

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            
            chapterButton.heightAnchor.constraint(equalToConstant: 40),
            chapterButton.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.width * 0.7),
            
            descriptionLabel.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.width - 40)
        ])

        if !infoData.tags.isEmpty {
            NSLayoutConstraint.activate([
                tagsDisplay.heightAnchor.constraint(equalToConstant: 24)
            ])
        }
    }
}
