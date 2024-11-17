//
//  InfoTopBar.swift
//  ChoutenRedesign
//
//  Created by Inumaki on 06.02.24.
//

import UIKit
import GoogleCast

class VariableBlurUIView: UIVisualEffectView {

    init(gradientMask: UIImage, maxBlurRadius: CGFloat = 50) {
        super.init(effect: UIBlurEffect(style: .regular))

        // `CAFilter` is a private QuartzCore class that we dynamically declare in `CAFilter.h`.
        let variableBlur = CAFilter.filter(withType: "variableBlur") as! NSObject

        // The blur radius at each pixel depends on the alpha value of the corresponding pixel in the gradient mask.
        // An alpha of 1 results in the max blur radius, while an alpha of 0 is completely unblurred.
        guard let gradientImageRef = gradientMask.cgImage else {
            fatalError("Could not decode gradient image")
        }

        variableBlur.setValue(maxBlurRadius, forKey: "inputRadius")
        variableBlur.setValue(gradientImageRef, forKey: "inputMaskImage")
        variableBlur.setValue(true, forKey: "inputNormalizeEdges")

        // Get rid of the visual effect view's dimming/tint view, so we don't see a hard line.
        let tintOverlayView = subviews[1]
        tintOverlayView.alpha = 0

        // We use a `UIVisualEffectView` here purely to get access to its `CABackdropLayer`,
        // which is able to apply various, real-time CAFilters onto the views underneath.
        let backdropLayer = subviews.first?.layer

        // Replace the standard filters (i.e. `gaussianBlur`, `colorSaturate`, etc.) with only the variableBlur.
        backdropLayer?.filters = [variableBlur]
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class InfoTopBar: UIView {

    let title: String

    let wrapper: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    let blurView = VariableBlurUIView(gradientMask: UIImage(named: "alpha-gradient")!)

    let backButton = CircleButton(icon: "chevron.left")
    var bookmarkButton = CircleButton(icon: "bookmark")
    
    let castButton = GCKUICastButton()

    let titleLabel: UILabel = {
        let label           = UILabel()
        label.textColor     = ThemeManager.shared.getColor(for: .fg)
        label.font          = UIFont.systemFont(ofSize: 20, weight: .bold)
        label.numberOfLines = 1
        label.lineBreakStrategy = []
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    let horizontalStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.isUserInteractionEnabled = true
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    let titleHorizontalStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.isUserInteractionEnabled = true
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    let marqueeWrapper = UIView()

    init(title: String) {
        self.title = title
        super.init(frame: .zero)
        configure()
        setupConstraints()
    }

    override init(frame: CGRect) {
        self.title = "Title"
        super.init(frame: frame)
        configure()
        setupConstraints()
        // removeFilters()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configure() {
        titleHorizontalStack.addArrangedSubview(titleLabel)
        titleHorizontalStack.addArrangedSubview(bookmarkButton)
        
        marqueeWrapper.clipsToBounds = true
        marqueeWrapper.translatesAutoresizingMaskIntoConstraints = false
        marqueeWrapper.addSubview(titleHorizontalStack)

        translatesAutoresizingMaskIntoConstraints = false

        wrapper.addSubview(blurView)

        horizontalStack.addArrangedSubview(backButton)

        wrapper.addSubview(horizontalStack)
        wrapper.addSubview(marqueeWrapper)
        addSubview(wrapper)

        // update title
        titleLabel.text = title

        titleLabel.alpha = 0.0
        blurView.alpha = 0.0
        blurView.translatesAutoresizingMaskIntoConstraints = false
        
        castButton.translatesAutoresizingMaskIntoConstraints = false
        titleHorizontalStack.addArrangedSubview(castButton)

        backButton.onTap = {
            let scenes = UIApplication.shared.connectedScenes
            if let windowScene = scenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let navController = window.rootViewController as? UINavigationController {
                navController.popViewController(animated: true)
            }
        }
    }

    // MARK: Layout
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            wrapper.leadingAnchor.constraint(equalTo: leadingAnchor),
            wrapper.trailingAnchor.constraint(equalTo: trailingAnchor),
            wrapper.topAnchor.constraint(equalTo: topAnchor),
            wrapper.bottomAnchor.constraint(equalTo: bottomAnchor),

            blurView.leadingAnchor.constraint(equalTo: leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: trailingAnchor),
            blurView.topAnchor.constraint(equalTo: topAnchor),
            blurView.bottomAnchor.constraint(equalTo: bottomAnchor),

            horizontalStack.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor, constant: 20),
            horizontalStack.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor, constant: -12 - 60),

            marqueeWrapper.topAnchor.constraint(equalTo: backButton.topAnchor),
            marqueeWrapper.bottomAnchor.constraint(equalTo: backButton.bottomAnchor),
            marqueeWrapper.leadingAnchor.constraint(equalTo: backButton.trailingAnchor, constant: 12),
            marqueeWrapper.trailingAnchor.constraint(equalTo: blurView.trailingAnchor, constant: -20),

            titleHorizontalStack.centerYAnchor.constraint(equalTo: marqueeWrapper.centerYAnchor),
            titleHorizontalStack.leadingAnchor.constraint(equalTo: marqueeWrapper.leadingAnchor),
            titleHorizontalStack.trailingAnchor.constraint(equalTo: marqueeWrapper.trailingAnchor)
        ])
    }
    
    private func removeFilters() {
        let effectLayer = blurView.layer
                
        // Get all the filters applied to the layer
        var filters = effectLayer.filters
        
        // Filter the filters to keep only GaussianBlur (or any other type you want)
        filters = filters?.filter { filter in
            if let gaussianBlur = filter as? CIFilter {
                return gaussianBlur.name == "CIGaussianBlur"
            }
            return false
        }
        
        // Apply the filtered list of filters back to the layer
        effectLayer.filters = filters
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = blurView.bounds
        gradientLayer.colors = [
            UIColor.black.withAlphaComponent(1.0).cgColor,  // Full blur at the top
            UIColor.black.withAlphaComponent(0.0).cgColor   // No blur at the bottom
        ]
        gradientLayer.locations = [0.0, 1.0]
        
        // Add the gradient as a mask to the visualEffectView
        blurView.layer.mask = gradientLayer
    }
}
