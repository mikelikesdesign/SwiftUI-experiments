//
//  KeyboardPrototypeViewController.swift
//  drag delete
//
//  Created by Codex on 5/9/26.
//

import UIKit

final class KeyboardPrototypeViewController: UIViewController {
    private final class PrototypeTextView: UITextView {
        var overrideCaretRect: CGRect? {
            didSet {
                setNeedsDisplay()
            }
        }

        override func caretRect(for position: UITextPosition) -> CGRect {
            overrideCaretRect ?? super.caretRect(for: position)
        }
    }

    private enum ScrubAxis {
        case inline
        case line
    }

    private struct LineDeletePreview {
        let range: NSRange
        let caretLocation: Int
        let caretOverrideRect: CGRect?
    }

    private struct LineStartAdjustment {
        let rangeStart: Int
        let caretLocation: Int
        let caretOverrideRect: CGRect?
    }

    private let textBackgroundColor = UIColor.white
    private let textForegroundColor = UIColor(red: 0.10, green: 0.10, blue: 0.12, alpha: 1)
    private let normalCaretColor = UIColor.black
    private let scrubCaretColor = UIColor(red: 1.00, green: 0.27, blue: 0.27, alpha: 1)
    private let textFont = UIFont.systemFont(ofSize: 19, weight: .regular)
    private let keyboardBackgroundColor = UIColor.white
    private let keyBackgroundColor = UIColor(red: 0.91, green: 0.92, blue: 0.94, alpha: 1)
    private let functionKeyBackgroundColor = UIColor(red: 0.91, green: 0.92, blue: 0.94, alpha: 1)
    private let keyTextColor = UIColor(red: 0.05, green: 0.06, blue: 0.08, alpha: 1)

    private let textView = PrototypeTextView()
    private let keyboardContainer = UIView()
    private let deletePill = UIControl()
    private let deleteButton = UIButton(type: .system)
    private let scrubCaretView = UIView()

    private var firstRowButtons: [UIButton] = []
    private var secondRowButtons: [UIButton] = []
    private var thirdRowLetterButtons: [UIButton] = []
    private var allKeyButtons: [UIButton] = []
    private var keyGlyphViews: [UIView] = []
    private var textValueByButton: [UIButton: String] = [:]

    private var shiftButton: UIButton?
    private var numbersButton: UIButton?
    private var emojiButton: UIButton?
    private var spaceButton: UIButton?
    private var returnButton: UIButton?

    private var normalizedScrub: CGFloat = 0
    private var deleteCenter = CGPoint.zero
    private var scrubDistance: CGFloat = 270
    private var scrubStartLocation = CGPoint.zero
    private var smoothedScrubLocation = CGPoint.zero
    private var scrubAxis: ScrubAxis = .inline
    private var lineScrubAnchorX: CGFloat?
    private var isScrubbing = false
    private var isShifted = false
    private var collapsedDeleteFrame = CGRect.zero
    private var scrubStartSelectedRange: NSRange?
    private var scrubInlineDeleteRange: NSRange?
    private var scrubLineDeleteRange: NSRange?
    private var scrubLineStartLocations: [Int] = []
    private var pendingDeleteRange: NSRange?
    private var isScrubCaretPositionLocked = false

    private let keyboardHeight: CGFloat = 276
    private let keyHeight: CGFloat = 45
    private let keyGap: CGFloat = 6
    private let keySideInset: CGFloat = 8
    private let deleteButtonWidth: CGFloat = 56
    private let previewTextAlpha: CGFloat = 0.30
    private let fullDeleteThreshold: CGFloat = 1
    private let legacyFullDeleteTargetOffset: CGFloat = 29
    private let axisSwitchThreshold: CGFloat = 16
    private let lineScrubActivationDistance: CGFloat = 14
    private let lineHorizontalAdjustmentThreshold: CGFloat = 10
    private let lineScrubEasingExponent: Double = 1.45
    private let scrubLocationSmoothing: CGFloat = 0.34
    private let scrubCaretTransitionDuration: TimeInterval = 0.16
    private let scrubCaretWidth: CGFloat = 2.5
    private let scrubCaretShadowOpacity: Float = 0.18
    private let scrubCaretShadowRadius: CGFloat = 2.5
    private let scrubCaretShadowOffset = CGSize(width: 0, height: 1.4)
    private let textInset = UIEdgeInsets(top: 92, left: 24, bottom: 150, right: 24)

    private var pointsPerLineScrub: CGFloat {
        max(28, textFont.lineHeight * 1.2)
    }

    private var defaultTypingAttributes: [NSAttributedString.Key: Any] {
        [
            .font: textFont,
            .foregroundColor: textForegroundColor
        ]
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = textBackgroundColor

        configureKeyboardContainer()
        configureTextView()
        configureScrubCaretView()
        configureKeyboardKeys()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        textView.becomeFirstResponder()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        endScrubDeleting(animated: false)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        layoutKeyboard()
        updateScrubGeometry()
        updateScrubCaretView()
    }

    private func configureKeyboardContainer() {
        keyboardContainer.backgroundColor = keyboardBackgroundColor
        keyboardContainer.layer.cornerRadius = 28
        keyboardContainer.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        keyboardContainer.layer.borderWidth = 1
        keyboardContainer.layer.borderColor = UIColor(red: 0.80, green: 0.81, blue: 0.84, alpha: 1).cgColor
        keyboardContainer.clipsToBounds = true
        keyboardContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(keyboardContainer)

        NSLayoutConstraint.activate([
            keyboardContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            keyboardContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            keyboardContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            keyboardContainer.heightAnchor.constraint(equalToConstant: keyboardHeight)
        ])
    }

    private func configureTextView() {
        textView.text = """
        This prototype explores a more controlled way to delete text. Press the delete button once to remove a single character, or long press it to scrub through text. Drag left and right to preview deletion within the current line, or swipe up and down to preview line deletion.

        In line mode, vertical movement changes the line count and horizontal movement trims the active line. Text that would be deleted has opacity applied, giving you a live preview without removing anything yet. Nothing is deleted until you stop dragging.
        """
        textView.font = textFont
        textView.textColor = textForegroundColor
        textView.backgroundColor = textBackgroundColor
        textView.textContainerInset = textInset
        textView.textContainer.lineFragmentPadding = 0
        textView.contentInsetAdjustmentBehavior = .never
        textView.contentInset = .zero
        textView.scrollIndicatorInsets = .zero
        textView.isEditable = true
        textView.isSelectable = true
        textView.inputView = UIView(frame: .zero)
        textView.tintColor = normalCaretColor
        textView.typingAttributes = defaultTypingAttributes
        textView.selectedRange = NSRange(location: textView.text.count, length: 0)
        textView.autocorrectionType = .no
        textView.autocapitalizationType = .none
        textView.keyboardDismissMode = .none
        textView.showsVerticalScrollIndicator = false
        textView.alwaysBounceVertical = true
        textView.accessibilityIdentifier = "prototypeTextView"
        textView.translatesAutoresizingMaskIntoConstraints = false
        view.insertSubview(textView, belowSubview: keyboardContainer)

        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.topAnchor),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: keyboardContainer.topAnchor)
        ])
    }

    private func configureScrubCaretView() {
        scrubCaretView.backgroundColor = normalCaretColor
        scrubCaretView.alpha = 0
        scrubCaretView.clipsToBounds = false
        scrubCaretView.isHidden = true
        scrubCaretView.isUserInteractionEnabled = false
        scrubCaretView.layer.shadowColor = UIColor.black.cgColor
        scrubCaretView.layer.shadowOpacity = 0
        scrubCaretView.layer.shadowRadius = 0
        scrubCaretView.layer.shadowOffset = .zero
        view.insertSubview(scrubCaretView, belowSubview: keyboardContainer)
    }

    private func prepareScrubCaretTransitionFromTypingCaret() {
        scrubCaretView.layer.removeAllAnimations()
        applyScrubCaretStyle(active: false)
        if let frame = currentCaretFrame() {
            applyScrubCaretFrame(frame)
            scrubCaretView.alpha = 1
            scrubCaretView.isHidden = false
        }

        textView.tintColor = .clear
    }

    private func animateScrubCaretIn(animated: Bool) {
        let finalFrame = currentCaretFrame()

        if let finalFrame {
            scrubCaretView.alpha = 1
            scrubCaretView.isHidden = false
            if scrubCaretView.bounds.isEmpty {
                applyScrubCaretFrame(finalFrame)
            }
        }

        guard animated else {
            if let finalFrame {
                applyScrubCaretFrame(finalFrame)
            }
            applyScrubCaretStyle(active: true)
            return
        }

        UIView.animate(
            withDuration: scrubCaretTransitionDuration,
            delay: 0,
            options: [.beginFromCurrentState, .curveEaseOut],
            animations: {
                if let finalFrame {
                    self.applyScrubCaretFrame(finalFrame, disableActions: false)
                }
                self.applyScrubCaretStyle(active: true)
            }
        )
    }

    private func animateScrubCaretOut(animated: Bool, completion: @escaping () -> Void) {
        scrubCaretView.layer.removeAllAnimations()
        let finalFrame = currentCaretFrame()
        scrubCaretView.alpha = 1
        scrubCaretView.isHidden = false

        let finish = { [weak self] in
            guard let self else { return }
            self.textView.tintColor = self.normalCaretColor
            self.scrubCaretView.alpha = 0
            self.scrubCaretView.isHidden = true
            completion()
        }

        guard animated else {
            if let finalFrame {
                applyScrubCaretFrame(finalFrame)
            }
            applyScrubCaretStyle(active: false)
            finish()
            return
        }

        UIView.animate(
            withDuration: scrubCaretTransitionDuration,
            delay: 0,
            options: [.beginFromCurrentState, .curveEaseOut],
            animations: {
                if let finalFrame {
                    self.applyScrubCaretFrame(finalFrame, disableActions: false)
                }
                self.applyScrubCaretStyle(active: false)
            },
            completion: { _ in
                finish()
            }
        )
    }

    private func updateScrubCaretView() {
        guard isScrubbing, !isScrubCaretPositionLocked, let frame = currentCaretFrame() else { return }

        applyScrubCaretFrame(frame)
    }

    private func currentCaretFrame() -> CGRect? {
        guard let selectedTextRange = textView.selectedTextRange else { return nil }
        textView.layoutIfNeeded()

        let caretRect = textView.caretRect(for: selectedTextRange.start)
        guard caretRect.isNull == false, caretRect.isEmpty == false else {
            scrubCaretView.isHidden = true
            return nil
        }

        let convertedRect = textView.convert(caretRect, to: view)
        let caretWidth = max(scrubCaretWidth, convertedRect.width)
        let frame = CGRect(
            x: convertedRect.midX - (caretWidth / 2),
            y: convertedRect.minY,
            width: caretWidth,
            height: convertedRect.height
        ).integral

        return frame
    }

    private func applyScrubCaretFrame(_ frame: CGRect, disableActions: Bool = true) {
        let cornerRadius = min(frame.width, frame.height) / 2
        let updates = {
            self.scrubCaretView.isHidden = false
            self.scrubCaretView.frame = frame
            self.scrubCaretView.layer.cornerRadius = cornerRadius
            self.scrubCaretView.layer.shadowPath = UIBezierPath(
                roundedRect: self.scrubCaretView.bounds,
                cornerRadius: cornerRadius
            ).cgPath
        }

        guard disableActions else {
            updates()
            return
        }

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        updates()
        CATransaction.commit()
    }

    private func applyScrubCaretStyle(active: Bool) {
        scrubCaretView.backgroundColor = active ? scrubCaretColor : normalCaretColor
        scrubCaretView.layer.shadowOpacity = active ? scrubCaretShadowOpacity : 0
        scrubCaretView.layer.shadowRadius = active ? scrubCaretShadowRadius : 0
        scrubCaretView.layer.shadowOffset = active ? scrubCaretShadowOffset : .zero
    }

    private func configureKeyboardKeys() {
        firstRowButtons = "qwertyuiop".map { makeTextKey(String($0)) }
        secondRowButtons = "asdfghjkl".map { makeTextKey(String($0)) }
        thirdRowLetterButtons = "zxcvbnm".map { makeTextKey(String($0)) }

        let shift = makeFunctionKey(title: nil, imageName: "shift", accessibilityIdentifier: "shiftKey")
        shift.addTarget(self, action: #selector(shiftTapped(_:)), for: .touchUpInside)
        shiftButton = shift

        let numbers = makeFunctionKey(title: "123", imageName: nil, accessibilityIdentifier: "numbersKey")
        numbers.addTarget(self, action: #selector(functionKeyTapped(_:)), for: .touchUpInside)
        numbersButton = numbers

        let emoji = makeFunctionKey(title: "🙂", imageName: nil, accessibilityIdentifier: "emojiKey")
        emoji.titleLabel?.font = .systemFont(ofSize: 25, weight: .regular)
        emoji.backgroundColor = keyBackgroundColor
        emoji.addTarget(self, action: #selector(functionKeyTapped(_:)), for: .touchUpInside)
        emojiButton = emoji

        let space = makeFunctionKey(title: "Space", imageName: nil, accessibilityIdentifier: "spaceKey")
        space.addTarget(self, action: #selector(spaceTapped(_:)), for: .touchUpInside)
        spaceButton = space

        let returnKey = makeFunctionKey(title: nil, imageName: "return.left", accessibilityIdentifier: "returnKey")
        returnKey.addTarget(self, action: #selector(returnTapped(_:)), for: .touchUpInside)
        returnButton = returnKey

        configureDeleteKey()
        updateShiftAppearance()
    }

    private func configureDeleteKey() {
        deletePill.backgroundColor = functionKeyBackgroundColor
        deletePill.layer.cornerRadius = 10
        deletePill.clipsToBounds = false
        applyKeyShadow(to: deletePill)
        deletePill.addTarget(self, action: #selector(deleteTapped), for: .touchUpInside)
        keyboardContainer.addSubview(deletePill)

        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(deleteLongPressed(_:)))
        longPress.minimumPressDuration = 0.24
        longPress.allowableMovement = 420
        longPress.cancelsTouchesInView = true
        deletePill.addGestureRecognizer(longPress)

        deleteButton.setImage(UIImage(systemName: "delete.left"), for: .normal)
        deleteButton.setPreferredSymbolConfiguration(.init(pointSize: 22, weight: .regular), forImageIn: .normal)
        deleteButton.tintColor = keyTextColor
        deleteButton.backgroundColor = .clear
        deleteButton.isUserInteractionEnabled = false
        deleteButton.accessibilityLabel = "Delete"
        deleteButton.accessibilityIdentifier = "deleteKey"
        deletePill.addSubview(deleteButton)
        if let imageView = deleteButton.imageView {
            keyGlyphViews.append(imageView)
        }
    }

    private func makeTextKey(_ value: String) -> UIButton {
        let button = makeBaseKey(backgroundColor: keyBackgroundColor)
        button.setTitle(value, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 25, weight: .regular)
        button.accessibilityIdentifier = "key_\(value)"
        button.addTarget(self, action: #selector(textKeyTapped(_:)), for: .touchUpInside)
        textValueByButton[button] = value
        registerKeyButton(button)
        return button
    }

    private func makeFunctionKey(title: String?, imageName: String?, accessibilityIdentifier: String) -> UIButton {
        let button = makeBaseKey(backgroundColor: functionKeyBackgroundColor)
        button.accessibilityIdentifier = accessibilityIdentifier
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .regular)
        if let title {
            button.setTitle(title, for: .normal)
        }
        if let imageName {
            button.setImage(UIImage(systemName: imageName), for: .normal)
            button.setPreferredSymbolConfiguration(.init(pointSize: 23, weight: .regular), forImageIn: .normal)
        }
        registerKeyButton(button)
        return button
    }

    private func makeBaseKey(backgroundColor: UIColor) -> UIButton {
        let button = UIButton(type: .system)
        button.backgroundColor = backgroundColor
        button.tintColor = keyTextColor
        button.setTitleColor(keyTextColor, for: .normal)
        button.layer.cornerRadius = 10
        button.clipsToBounds = false
        applyKeyShadow(to: button)
        keyboardContainer.addSubview(button)
        return button
    }

    private func registerKeyButton(_ button: UIButton) {
        allKeyButtons.append(button)
        if let titleLabel = button.titleLabel {
            keyGlyphViews.append(titleLabel)
        }
        if let imageView = button.imageView {
            keyGlyphViews.append(imageView)
        }
    }

    private func applyKeyShadow(to view: UIView) {
        view.layer.shadowColor = UIColor(red: 0.51, green: 0.55, blue: 0.61, alpha: 1).cgColor
        view.layer.shadowOpacity = 0.24
        view.layer.shadowRadius = 0
        view.layer.shadowOffset = CGSize(width: 0, height: 1.2)
    }

    private func layoutKeyboard() {
        let width = keyboardContainer.bounds.width
        guard width > 0 else { return }

        let top: CGFloat = 13
        let rowGap: CGFloat = 11
        let fourthRowTop = top + ((keyHeight + rowGap) * 3) + 6

        layoutEvenRow(firstRowButtons, y: top, sideInset: keySideInset)
        layoutEvenRow(secondRowButtons, y: top + keyHeight + rowGap, sideInset: centeredInset(forKeyCount: secondRowButtons.count))

        let shiftWidth: CGFloat = 58
        let rowThreeY = top + ((keyHeight + rowGap) * 2)
        let thirdLetterWidth = (width - (keySideInset * 2) - (keyGap * 8) - (shiftWidth * 2)) / 7

        var x = keySideInset
        shiftButton?.frame = CGRect(x: x, y: rowThreeY, width: shiftWidth, height: keyHeight)
        x += shiftWidth + keyGap

        for button in thirdRowLetterButtons {
            button.frame = CGRect(x: x, y: rowThreeY, width: thirdLetterWidth, height: keyHeight)
            x += thirdLetterWidth + keyGap
        }

        let deleteFrame = CGRect(x: x, y: rowThreeY, width: shiftWidth, height: keyHeight)
        collapsedDeleteFrame = deleteFrame
        if !isScrubbing {
            deletePill.frame = deleteFrame
            deletePill.layer.cornerRadius = 10
            deletePill.backgroundColor = functionKeyBackgroundColor
        }

        let sideControlWidth: CGFloat = 49
        let emojiWidth: CGFloat = 49
        let returnWidth: CGFloat = 95
        let spaceWidth = width - (keySideInset * 2) - (keyGap * 3) - sideControlWidth - emojiWidth - returnWidth
        numbersButton?.frame = CGRect(x: keySideInset, y: fourthRowTop, width: sideControlWidth, height: keyHeight)
        emojiButton?.frame = CGRect(x: keySideInset + sideControlWidth + keyGap, y: fourthRowTop, width: emojiWidth, height: keyHeight)
        spaceButton?.frame = CGRect(x: keySideInset + sideControlWidth + emojiWidth + (keyGap * 2), y: fourthRowTop, width: spaceWidth, height: keyHeight)
        returnButton?.frame = CGRect(x: width - keySideInset - returnWidth, y: fourthRowTop, width: returnWidth, height: keyHeight)

        updateKeyShadowPaths()
        deleteButton.frame = deletePill.bounds
    }

    private func layoutEvenRow(_ buttons: [UIButton], y: CGFloat, sideInset: CGFloat) {
        guard !buttons.isEmpty else { return }
        let availableWidth = keyboardContainer.bounds.width - (sideInset * 2) - (keyGap * CGFloat(buttons.count - 1))
        let keyWidth = availableWidth / CGFloat(buttons.count)
        var x = sideInset

        for button in buttons {
            button.frame = CGRect(x: x, y: y, width: keyWidth, height: keyHeight)
            x += keyWidth + keyGap
        }
    }

    private func centeredInset(forKeyCount keyCount: Int) -> CGFloat {
        let rowOneKeyWidth = (keyboardContainer.bounds.width - (keySideInset * 2) - (keyGap * 9)) / 10
        let rowWidth = (rowOneKeyWidth * CGFloat(keyCount)) + (keyGap * CGFloat(keyCount - 1))
        return max(keySideInset, (keyboardContainer.bounds.width - rowWidth) / 2)
    }

    private func updateKeyShadowPaths() {
        for button in allKeyButtons {
            button.layer.shadowPath = UIBezierPath(roundedRect: button.bounds, cornerRadius: button.layer.cornerRadius).cgPath
        }
        deletePill.layer.shadowPath = UIBezierPath(roundedRect: deletePill.bounds, cornerRadius: deletePill.layer.cornerRadius).cgPath
    }

    @objc private func textKeyTapped(_ sender: UIButton) {
        guard let value = textValueByButton[sender] else { return }
        insertText(isShifted ? value.uppercased() : value)
        pulse(sender)
        if isShifted {
            isShifted = false
            updateShiftAppearance()
        }
    }

    @objc private func shiftTapped(_ sender: UIButton) {
        isShifted.toggle()
        updateShiftAppearance()
        pulse(sender)
    }

    @objc private func functionKeyTapped(_ sender: UIButton) {
        pulse(sender)
    }

    @objc private func spaceTapped(_ sender: UIButton) {
        insertText(" ")
        pulse(sender)
    }

    @objc private func returnTapped(_ sender: UIButton) {
        insertText("\n")
        pulse(sender)
    }

    private func updateShiftAppearance() {
        shiftButton?.backgroundColor = isShifted ? keyBackgroundColor : functionKeyBackgroundColor
        shiftButton?.tintColor = keyTextColor
    }

    private func insertText(_ string: String) {
        if let selectedRange = textView.selectedTextRange {
            textView.replace(selectedRange, withText: string)
            return
        }

        textView.text.append(string)
        textView.selectedRange = NSRange(location: textView.text.count, length: 0)
    }

    @objc private func deleteTapped() {
        guard !isScrubbing else { return }
        deleteCharacters(count: 1)
        pulse(deletePill)
    }

    @objc private func deleteLongPressed(_ recognizer: UILongPressGestureRecognizer) {
        let location = recognizer.location(in: view)

        switch recognizer.state {
        case .began:
            beginScrubDeleting(at: location)
        case .changed:
            updateScrubDeleting(at: location)
        case .ended:
            updateScrubDeleting(at: location, immediate: true)
            endScrubDeleting(commit: true)
        case .cancelled, .failed:
            endScrubDeleting(commit: false)
        default:
            break
        }
    }

    private func beginScrubDeleting(at location: CGPoint) {
        view.layer.removeAllAnimations()
        keyboardContainer.layer.removeAllAnimations()
        deletePill.layer.removeAllAnimations()
        deleteButton.layer.removeAllAnimations()
        scrubCaretView.layer.removeAllAnimations()

        layoutKeyboard()
        collapsedDeleteFrame = deletePill.frame
        isScrubbing = true
        normalizedScrub = 0
        scrubAxis = .inline
        scrubStartLocation = location
        smoothedScrubLocation = location
        prepareScrubCaretTransitionFromTypingCaret()
        isScrubCaretPositionLocked = true
        captureScrubPreviewState()
        isScrubCaretPositionLocked = false
        animateScrubCaretIn(animated: true)
        deletePill.backgroundColor = keyBackgroundColor
        deletePill.clipsToBounds = true
        deleteButton.transform = .identity
        setKeyboardGlyphsHidden(true, animated: true)
        updateScrubGeometry()
        updateKeyShadowPaths()
    }

    private func updateScrubDeleting(at location: CGPoint, immediate: Bool = false) {
        guard isScrubbing else { return }

        let scrubLocation = scrubPreviewLocation(for: location, immediate: immediate)
        let leftDistance = max(0, deleteCenter.x - scrubLocation.x)
        normalizedScrub = min(1, leftDistance / scrubDistance)
        let nextAxis = axisForScrubLocation(scrubLocation)
        if nextAxis != scrubAxis {
            lineScrubAnchorX = nextAxis == .line ? scrubLocation.x : nil
        }
        scrubAxis = nextAxis

        updatePendingDeletePreview(at: scrubLocation)
        updateScrubGeometry()
    }

    private func scrubPreviewLocation(for location: CGPoint, immediate: Bool) -> CGPoint {
        guard immediate == false else {
            smoothedScrubLocation = location
            return location
        }

        let previous = smoothedScrubLocation
        let smoothed = CGPoint(
            x: previous.x + ((location.x - previous.x) * scrubLocationSmoothing),
            y: previous.y + ((location.y - previous.y) * scrubLocationSmoothing)
        )
        smoothedScrubLocation = smoothed
        return smoothed
    }

    private func updateScrubGeometry() {
        let pillWidth = max(deletePill.bounds.width, deleteButtonWidth)
        let pillHeight = max(deletePill.bounds.height, keyHeight)
        deleteButton.frame = deletePill.bounds

        let deleteCenterInPill = CGPoint(
            x: pillWidth - (deleteButtonWidth / 2),
            y: pillHeight / 2
        )
        deleteCenter = deletePill.convert(deleteCenterInPill, to: view)
        let legacyFullDeleteTargetX = keyboardContainer.convert(
            CGPoint(x: keySideInset + legacyFullDeleteTargetOffset, y: 0),
            to: view
        ).x
        scrubDistance = max(80, deleteCenter.x - legacyFullDeleteTargetX)
    }

    private func captureScrubPreviewState() {
        let selectedRange = clampedTextRange(textView.selectedRange)
        scrubStartSelectedRange = selectedRange
        scrubInlineDeleteRange = inlineDeleteRange(from: selectedRange)
        scrubLineDeleteRange = availableDeleteRange(from: selectedRange)
        scrubLineStartLocations = visualLineStartLocations(in: scrubLineDeleteRange ?? selectedRange)
        pendingDeleteRange = NSRange(location: NSMaxRange(scrubLineDeleteRange ?? selectedRange), length: 0)

        if selectedRange.length > 0 {
            textView.selectedRange = NSRange(location: NSMaxRange(selectedRange), length: 0)
        }

        clearDeletePreview()
    }

    private func availableDeleteRange(from selectedRange: NSRange) -> NSRange {
        if selectedRange.length > 0 {
            return selectedRange
        }

        return NSRange(location: 0, length: selectedRange.location)
    }

    private func inlineDeleteRange(from selectedRange: NSRange) -> NSRange {
        if selectedRange.length > 0 {
            return selectedRange
        }

        let caretLocation = selectedRange.location
        let lineStart = visualLineStartLocation(containing: caretLocation)
        return NSRange(location: lineStart, length: max(0, caretLocation - lineStart))
    }

    private func axisForScrubLocation(_ location: CGPoint) -> ScrubAxis {
        let horizontalDistance = abs(location.x - scrubStartLocation.x)
        let verticalDistance = abs(location.y - scrubStartLocation.y)

        if scrubAxis == .line {
            return verticalDistance < (axisSwitchThreshold / 2) ? .inline : .line
        }

        if verticalDistance > axisSwitchThreshold && verticalDistance > horizontalDistance {
            return .line
        }

        return .inline
    }

    private func updatePendingDeletePreview(at location: CGPoint) {
        switch scrubAxis {
        case .inline:
            updateInlineDeletePreview()
        case .line:
            updateLineDeletePreview(at: location)
        }
    }

    private func updateInlineDeletePreview() {
        guard let availableRange = scrubInlineDeleteRange else { return }

        let pendingCount = pendingInlineDeleteCount(in: availableRange)
        let pendingLocation = NSMaxRange(availableRange) - pendingCount
        let pendingRange = NSRange(location: pendingLocation, length: pendingCount)
        let caretLocation = pendingCount > 0 ? pendingLocation : NSMaxRange(availableRange)
        pendingDeleteRange = pendingRange
        applyDeletePreview(range: pendingRange, caretLocation: caretLocation)
    }

    private func pendingInlineDeleteCount(in availableRange: NSRange) -> Int {
        guard availableRange.length > 0 else { return 0 }

        guard normalizedScrub > 0 else { return 0 }
        if normalizedScrub >= fullDeleteThreshold {
            return availableRange.length
        }

        let previewCount = Int((CGFloat(availableRange.length) * normalizedScrub).rounded(.toNearestOrAwayFromZero))
        return min(availableRange.length, max(0, previewCount))
    }

    private func updateLineDeletePreview(at location: CGPoint) {
        guard let availableRange = scrubLineDeleteRange else { return }

        let preview = pendingLineDeletePreview(at: location, in: availableRange)
        pendingDeleteRange = preview.range
        applyDeletePreview(
            range: preview.range,
            caretLocation: preview.caretLocation,
            caretOverrideRect: preview.caretOverrideRect
        )
    }

    private func pendingLineDeletePreview(at location: CGPoint, in availableRange: NSRange) -> LineDeletePreview {
        guard availableRange.length > 0 else {
            let caretLocation = NSMaxRange(availableRange)
            return LineDeletePreview(
                range: NSRange(location: caretLocation, length: 0),
                caretLocation: caretLocation,
                caretOverrideRect: nil
            )
        }

        let verticalDistance = abs(location.y - scrubStartLocation.y)
        guard verticalDistance > lineScrubActivationDistance else {
            let caretLocation = NSMaxRange(availableRange)
            return LineDeletePreview(
                range: NSRange(location: caretLocation, length: 0),
                caretLocation: caretLocation,
                caretOverrideRect: nil
            )
        }

        let lineStarts = scrubLineStartLocations.isEmpty ? [availableRange.location] : scrubLineStartLocations
        let lineCount = pendingLineDeleteLineCount(at: location, availableLineCount: lineStarts.count)
        let startIndex = max(0, lineStarts.count - lineCount)
        let topLineStart = min(max(availableRange.location, lineStarts[startIndex]), NSMaxRange(availableRange))
        let topLineEnd = startIndex + 1 < lineStarts.count
            ? min(max(topLineStart, lineStarts[startIndex + 1]), NSMaxRange(availableRange))
            : NSMaxRange(availableRange)
        let adjustment = adjustedLineStart(
            from: topLineStart,
            to: topLineEnd,
            at: location
        )
        let rangeStart = min(adjustment.rangeStart, NSMaxRange(availableRange))

        return LineDeletePreview(
            range: NSRange(location: rangeStart, length: NSMaxRange(availableRange) - rangeStart),
            caretLocation: min(adjustment.caretLocation, NSMaxRange(availableRange)),
            caretOverrideRect: adjustment.caretOverrideRect
        )
    }

    private func pendingLineDeleteLineCount(at location: CGPoint, availableLineCount: Int) -> Int {
        guard availableLineCount > 0 else { return 0 }

        let verticalDistance = abs(location.y - scrubStartLocation.y)
        guard verticalDistance > lineScrubActivationDistance else { return 0 }

        let activeDistance = verticalDistance - lineScrubActivationDistance
        let travelDistance = max(pointsPerLineScrub, keyboardLineScrubTravelDistance() - lineScrubActivationDistance)
        let progress = min(1, max(0, activeDistance / travelDistance))
        let easedProgress = CGFloat(pow(Double(progress), lineScrubEasingExponent))
        let scaledLineCount = Int(ceil(CGFloat(availableLineCount) * easedProgress))
        return min(availableLineCount, max(1, scaledLineCount))
    }

    private func keyboardLineScrubTravelDistance() -> CGFloat {
        let topDistance = max(0, scrubStartLocation.y - keyboardContainer.frame.minY)
        let bottomDistance = max(0, keyboardContainer.frame.maxY - scrubStartLocation.y)
        return max(pointsPerLineScrub, topDistance, bottomDistance)
    }

    private func adjustedLineStart(from lineStart: Int, to lineEnd: Int, at location: CGPoint) -> LineStartAdjustment {
        let lineLength = max(0, lineEnd - lineStart)
        guard lineLength > 0 else {
            return LineStartAdjustment(rangeStart: lineStart, caretLocation: lineEnd, caretOverrideRect: nil)
        }

        let lineEndCaretLocation = caretLocationForLineEnd(lineEnd, lineStart: lineStart)
        let lineEndCaretRect = caretOverrideRectAtVisualLineEnd(from: lineStart, to: lineEnd)
        let anchorX = lineScrubAnchorX ?? scrubStartLocation.x
        let horizontalDistance = abs(location.x - anchorX)
        guard horizontalDistance >= lineHorizontalAdjustmentThreshold else {
            return LineStartAdjustment(
                rangeStart: lineStart,
                caretLocation: lineEndCaretLocation,
                caretOverrideRect: lineEndCaretRect
            )
        }

        let leftTargetX = deleteCenter.x - scrubDistance
        let horizontalProgress = min(1, max(0, (location.x - leftTargetX) / scrubDistance))
        let adjustedOffset = Int((CGFloat(lineLength) * horizontalProgress).rounded(.toNearestOrAwayFromZero))
        let adjustedLocation = min(lineEnd, lineStart + adjustedOffset)
        let adjustedCaretRect = adjustedLocation >= lineEnd ? lineEndCaretRect : nil

        return LineStartAdjustment(
            rangeStart: adjustedLocation,
            caretLocation: adjustedLocation,
            caretOverrideRect: adjustedCaretRect
        )
    }

    private func caretLocationForLineEnd(_ lineEnd: Int, lineStart: Int) -> Int {
        visualLineEndLocation(from: lineStart, to: lineEnd)
    }

    private func visualLineEndLocation(from lineStart: Int, to lineEnd: Int) -> Int {
        let textLength = textView.textStorage.length
        guard textLength > 0 else { return 0 }

        let clampedStart = min(max(0, lineStart), textLength)
        let clampedEnd = min(max(clampedStart, lineEnd), textLength)
        guard clampedEnd > clampedStart else { return clampedEnd }

        let text = textView.textStorage.string as NSString
        var characterIndex = clampedEnd - 1
        while characterIndex >= clampedStart {
            if !isTrailingLineWhitespace(text.character(at: characterIndex)) {
                return characterIndex + 1
            }

            if characterIndex == clampedStart {
                break
            }
            characterIndex -= 1
        }

        return clampedStart
    }

    private func isTrailingLineWhitespace(_ character: unichar) -> Bool {
        switch character {
        case 9, 10, 13, 32, 160:
            return true
        default:
            return false
        }
    }

    private func caretOverrideRectAtVisualLineEnd(from lineStart: Int, to lineEnd: Int) -> CGRect? {
        let textLength = textView.textStorage.length
        guard textLength > 0 else { return nil }

        let clampedStart = min(max(0, lineStart), textLength)
        let visibleEnd = visualLineEndLocation(from: lineStart, to: lineEnd)
        guard visibleEnd > clampedStart else { return nil }

        let characterIndex = visibleEnd - 1
        textView.layoutIfNeeded()
        textView.layoutManager.ensureLayout(for: textView.textContainer)

        let characterRange = NSRange(location: characterIndex, length: 1)
        let glyphRange = textView.layoutManager.glyphRange(
            forCharacterRange: characterRange,
            actualCharacterRange: nil
        )
        guard glyphRange.length > 0 else { return nil }

        let glyphRect = textView.layoutManager.boundingRect(
            forGlyphRange: glyphRange,
            in: textView.textContainer
        )
        let lineRect = textView.layoutManager.lineFragmentUsedRect(
            forGlyphAt: NSMaxRange(glyphRange) - 1,
            effectiveRange: nil
        )
        guard glyphRect.isNull == false,
              glyphRect.isEmpty == false,
              lineRect.isNull == false,
              lineRect.isEmpty == false else {
            return nil
        }

        let caretWidth: CGFloat = 2
        let rawX = textView.textContainerInset.left + glyphRect.maxX
        let minX = textView.textContainerInset.left
        let maxX = max(minX, textView.bounds.width - textView.textContainerInset.right - caretWidth)

        return CGRect(
            x: min(max(rawX, minX), maxX),
            y: textView.textContainerInset.top + lineRect.minY,
            width: caretWidth,
            height: max(textFont.lineHeight, lineRect.height)
        )
    }

    private func visualLineStartLocation(containing caretLocation: Int) -> Int {
        let textLength = textView.textStorage.length
        guard caretLocation > 0, textLength > 0 else { return 0 }

        let clampedCaret = min(caretLocation, textLength)
        let nsText = textView.textStorage.string as NSString
        if clampedCaret > 0, nsText.character(at: clampedCaret - 1) == 10 {
            return clampedCaret
        }

        textView.layoutIfNeeded()
        textView.layoutManager.ensureLayout(for: textView.textContainer)

        let characterIndex = max(0, min(clampedCaret - 1, textLength - 1))
        let glyphIndex = textView.layoutManager.glyphIndexForCharacter(at: characterIndex)
        var lineGlyphRange = NSRange(location: 0, length: 0)
        _ = textView.layoutManager.lineFragmentRect(forGlyphAt: glyphIndex, effectiveRange: &lineGlyphRange)
        let lineCharacterRange = textView.layoutManager.characterRange(
            forGlyphRange: lineGlyphRange,
            actualGlyphRange: nil
        )

        return min(clampedCaret, max(0, lineCharacterRange.location))
    }

    private func visualLineStartLocations(in range: NSRange) -> [Int] {
        let availableRange = clampedTextRange(range)
        guard availableRange.length > 0 else { return [] }

        textView.layoutIfNeeded()
        textView.layoutManager.ensureLayout(for: textView.textContainer)

        let glyphRange = textView.layoutManager.glyphRange(
            forCharacterRange: availableRange,
            actualCharacterRange: nil
        )
        guard glyphRange.length > 0 else { return [availableRange.location] }

        var starts = Set<Int>()
        starts.insert(availableRange.location)

        textView.layoutManager.enumerateLineFragments(forGlyphRange: glyphRange) { [weak self] _, _, _, lineGlyphRange, _ in
            guard let self else { return }
            let characterRange = self.textView.layoutManager.characterRange(
                forGlyphRange: lineGlyphRange,
                actualGlyphRange: nil
            )
            guard let visibleRange = self.intersection(characterRange, availableRange),
                  visibleRange.length > 0 else {
                return
            }

            starts.insert(visibleRange.location)
        }

        return starts
            .filter { $0 >= availableRange.location && $0 < NSMaxRange(availableRange) }
            .sorted()
    }

    private func intersection(_ firstRange: NSRange, _ secondRange: NSRange) -> NSRange? {
        let lowerBound = max(firstRange.location, secondRange.location)
        let upperBound = min(NSMaxRange(firstRange), NSMaxRange(secondRange))
        guard upperBound > lowerBound else { return nil }

        return NSRange(location: lowerBound, length: upperBound - lowerBound)
    }

    private func applyDeletePreview(
        range: NSRange,
        caretLocation: Int? = nil,
        caretOverrideRect: CGRect? = nil
    ) {
        let selectedRange = textView.selectedRange
        let textLength = textView.textStorage.length
        let fullRange = NSRange(location: 0, length: textLength)
        let previewRange = clampedTextRange(range, textLength: textLength)

        textView.textStorage.beginEditing()
        if fullRange.length > 0 {
            textView.textStorage.addAttribute(.foregroundColor, value: textForegroundColor, range: fullRange)
            if previewRange.length > 0 {
                textView.textStorage.addAttribute(
                    .foregroundColor,
                    value: textForegroundColor.withAlphaComponent(previewTextAlpha),
                    range: previewRange
                )
            }
        }
        textView.textStorage.endEditing()

        textView.typingAttributes = defaultTypingAttributes
        if let caretLocation {
            let caretRange = clampedTextRange(NSRange(location: caretLocation, length: 0))
            textView.overrideCaretRect = caretOverrideRect
            textView.selectedRange = caretRange
            textView.scrollRangeToVisible(caretRange)
        } else {
            textView.overrideCaretRect = nil
            textView.selectedRange = clampedTextRange(selectedRange)
        }
        updateScrubCaretView()
    }

    private func clearDeletePreview() {
        applyDeletePreview(range: NSRange(location: 0, length: 0))
    }

    private func commitPendingDeleteRange() {
        guard let pendingDeleteRange else {
            clearDeletePreview()
            return
        }

        let deleteRange = clampedTextRange(pendingDeleteRange)
        clearDeletePreview()
        guard deleteRange.length > 0 else {
            restoreStartingSelectionIfPossible()
            return
        }

        guard let deleteTextRange = textViewRange(for: deleteRange) else {
            restoreStartingSelectionIfPossible()
            return
        }

        textView.replace(deleteTextRange, withText: "")
        textView.typingAttributes = defaultTypingAttributes
        textView.selectedRange = NSRange(location: min(deleteRange.location, textView.textStorage.length), length: 0)
        resetCaretForEmptyText()
    }

    private func restoreStartingSelectionIfPossible() {
        guard let scrubStartSelectedRange else { return }
        textView.selectedRange = clampedTextRange(scrubStartSelectedRange)
    }

    private func clearScrubPreviewState() {
        scrubStartSelectedRange = nil
        scrubInlineDeleteRange = nil
        scrubLineDeleteRange = nil
        scrubLineStartLocations = []
        scrubAxis = .inline
        scrubStartLocation = .zero
        smoothedScrubLocation = .zero
        lineScrubAnchorX = nil
        pendingDeleteRange = nil
        isScrubCaretPositionLocked = false
    }

    private func clampedTextRange(_ range: NSRange, textLength: Int? = nil) -> NSRange {
        guard range.location != NSNotFound else { return NSRange(location: 0, length: 0) }

        let length = textLength ?? textView.textStorage.length
        let location = min(max(0, range.location), length)
        let upperBound = min(max(location, NSMaxRange(range)), length)
        return NSRange(location: location, length: upperBound - location)
    }

    private func textViewRange(for range: NSRange) -> UITextRange? {
        let clampedRange = clampedTextRange(range)
        guard let start = textView.position(from: textView.beginningOfDocument, offset: clampedRange.location),
              let end = textView.position(from: start, offset: clampedRange.length) else {
            return nil
        }

        return textView.textRange(from: start, to: end)
    }

    private func endScrubDeleting(commit: Bool = false, animated: Bool = true) {
        let hadActiveScrub = isScrubbing
        let shouldCommit = commit && hadActiveScrub && (pendingDeleteRange?.length ?? 0) > 0

        if shouldCommit {
            commitPendingDeleteRange()
        } else if hadActiveScrub {
            clearDeletePreview()
            restoreStartingSelectionIfPossible()
        }

        isScrubbing = false
        normalizedScrub = 0
        textView.overrideCaretRect = nil
        clearScrubPreviewState()
        animateScrubCaretOut(animated: animated && view.window != nil) {}

        let resetViews = {
            self.deletePill.frame = self.collapsedDeleteFrame
            self.deletePill.layer.cornerRadius = 10
            self.deletePill.backgroundColor = self.functionKeyBackgroundColor
            self.deleteButton.frame = self.deletePill.bounds
            self.updateScrubGeometry()
            self.deleteButton.transform = .identity
            self.deletePill.transform = .identity
            self.updateKeyShadowPaths()
            self.setKeyboardGlyphsHidden(false, animated: false)
        }

        guard animated, view.window != nil else {
            resetViews()
            deletePill.clipsToBounds = false
            return
        }

        UIView.animate(
            withDuration: 0.18,
            delay: 0,
            options: [.beginFromCurrentState, .curveEaseOut],
            animations: resetViews,
            completion: { [weak self] _ in
                self?.deletePill.clipsToBounds = false
            }
        )
    }

    private func setKeyboardGlyphsHidden(_ hidden: Bool, animated: Bool) {
        let changes = {
            for glyphView in self.keyGlyphViews {
                glyphView.alpha = hidden ? 0 : 1
            }
        }

        guard animated else {
            changes()
            return
        }

        UIView.animate(withDuration: 0.14, delay: 0, options: [.beginFromCurrentState, .curveEaseOut], animations: changes)
    }

    private func deleteCharacters(count: Int) {
        guard count > 0, let selectedRange = textView.selectedTextRange else {
            return
        }

        if !selectedRange.isEmpty {
            textView.replace(selectedRange, withText: "")
            resetCaretForEmptyText()
            return
        }

        var remainingCount = count
        while remainingCount > 0 {
            guard let selectedRange = textView.selectedTextRange,
                  let start = textView.position(from: selectedRange.start, offset: -1),
                  let deleteRange = textView.textRange(from: start, to: selectedRange.start) else {
                resetCaretForEmptyText()
                return
            }

            textView.replace(deleteRange, withText: "")
            remainingCount -= 1
        }

        resetCaretForEmptyText()
    }

    private func resetCaretForEmptyText() {
        guard textView.text.isEmpty else { return }

        forceEmptyTextViewToTop()
        DispatchQueue.main.async { [weak self] in
            self?.forceEmptyTextViewToTop()
        }
    }

    private func forceEmptyTextViewToTop() {
        guard textView.text.isEmpty else { return }

        textView.selectedRange = NSRange(location: 0, length: 0)
        if let start = textView.position(from: textView.beginningOfDocument, offset: 0),
           let startRange = textView.textRange(from: start, to: start) {
            textView.selectedTextRange = startRange
        }

        textView.layoutIfNeeded()
        textView.setContentOffset(.zero, animated: false)
    }

    private func pulse(_ view: UIView) {
        UIView.animate(withDuration: 0.06, animations: {
            view.transform = CGAffineTransform(scaleX: 0.94, y: 0.94)
        }, completion: { [weak view] _ in
            UIView.animate(withDuration: 0.10) {
                view?.transform = .identity
            }
        })
    }
}
