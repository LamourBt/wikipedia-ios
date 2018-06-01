import XCTest
import WMF

let pressDuration = 0.1 // don't set this to too large a value or presses which happen to land on buttons will activate the button instead of letting the drag event bubble up

extension XCUIElement {
    func wmf_tap() -> Bool {
        guard exists else { return false }
        tap()
        return true
    }
    func wmf_typeText(text: String) -> Bool {
        guard exists else { return false }
        typeText(text)
        return true
    }
    func wmf_waitUntilExists(timeout: TimeInterval = 30) -> XCUIElement {
        if self.exists { return self }
        _ = XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == true"), object: self)], timeout: timeout)
        return self
    }
}

private enum ElementPropertyType: String {
    case label
    case placeholderValue

    private func predicate(for text: String) -> NSPredicate {
        return NSPredicate(format: "\(rawValue) == %@", text)
    }
    private func wildcardPredicate(for text: String) -> NSPredicate {
        var mutableText = text
        for i in 0...9 {
            mutableText = mutableText.replacingOccurrences(of: "%\(i)$@", with: "*")
        }
        mutableText = "*\(mutableText)*"
        return NSPredicate(format: "\(rawValue) like[cd] %@", mutableText)
    }
    
    func predicate(for texts: [String]) -> NSPredicate {
        return NSCompoundPredicate(orPredicateWithSubpredicates: texts.map{text in predicate(for: text)})
    }
    func wildcardPredicate(for texts: [String]) -> NSPredicate {
        return NSCompoundPredicate(orPredicateWithSubpredicates: texts.map{text in wildcardPredicate(for: text)})
    }
}

private extension XCUIElementQuery {
    func wmf_firstElement(with propertyType: ElementPropertyType, withTranslationIn keys: [String], convertTranslationSubstitutionStringsToWildcards shouldConvert: Bool = false, timeout: TimeInterval = 30) -> XCUIElement {
        let translations = keys.map{key in WMFLocalizedString(key, value: "", comment: "")} // localization strings are copied into this scheme during a build phase: https://stackoverflow.com/a/38133902/135557
        let predicate = shouldConvert ? propertyType.wildcardPredicate(for: translations) : propertyType.predicate(for: translations)
        // Used `element:boundBy:0` rather than `firstMatch` because the latter doesn't play nice with `exists` checking as of Xcode 9.3
        return matching(predicate).element(boundBy: 0).wmf_waitUntilExists(timeout: timeout)
    }
}

extension XCUIApplication {
    func wmf_firstButton(withTranslationIn keys: [String], convertTranslationSubstitutionStringsToWildcards shouldConvert: Bool = false) -> XCUIElement {
        return buttons.wmf_firstElement(with: .label, withTranslationIn: keys, convertTranslationSubstitutionStringsToWildcards: shouldConvert)
    }
    func wmf_tapFirstButton(withTranslationIn keys: [String], convertTranslationSubstitutionStringsToWildcards shouldConvert: Bool = false) -> Bool {
        return wmf_firstButton(withTranslationIn: keys, convertTranslationSubstitutionStringsToWildcards: shouldConvert).wmf_tap()
    }

    func wmf_firstStaticText(withTranslationIn keys: [String], convertTranslationSubstitutionStringsToWildcards shouldConvert: Bool = false) -> XCUIElement {
        return staticTexts.wmf_firstElement(with: .label, withTranslationIn: keys, convertTranslationSubstitutionStringsToWildcards: shouldConvert)
    }
    func wmf_tapFirstStaticText(withTranslationIn keys: [String], convertTranslationSubstitutionStringsToWildcards shouldConvert: Bool = false) -> Bool {
        return wmf_firstStaticText(withTranslationIn: keys, convertTranslationSubstitutionStringsToWildcards: shouldConvert).wmf_tap()
    }

    func wmf_firstSwitch(withTranslationIn keys: [String], convertTranslationSubstitutionStringsToWildcards shouldConvert: Bool = false) -> XCUIElement {
        return switches.wmf_firstElement(with: .label, withTranslationIn: keys, convertTranslationSubstitutionStringsToWildcards: shouldConvert)
    }
    func wmf_tapFirstSwitch(withTranslationIn keys: [String], convertTranslationSubstitutionStringsToWildcards shouldConvert: Bool = false) -> Bool {
        return wmf_firstSwitch(withTranslationIn: keys, convertTranslationSubstitutionStringsToWildcards: shouldConvert).wmf_tap()
    }
    
    func wmf_firstSearchField(withTranslationIn keys: [String], convertTranslationSubstitutionStringsToWildcards shouldConvert: Bool = false) -> XCUIElement {
        return searchFields.wmf_firstElement(with: .placeholderValue, withTranslationIn: keys, convertTranslationSubstitutionStringsToWildcards: shouldConvert)
    }

    func wmf_tapFirstCloseButton() -> Bool {
        return buttons.wmf_firstElement(with: .label, withTranslationIn: ["close-button-accessibility-label"]).wmf_tap()
    }
    
    func wmf_tapFirstNavigationBarBackButton() -> Bool {
        let backButtonTapped = wmf_tapFirstButton(withTranslationIn: ["back", "back-button-accessibility-label"])
        guard !backButtonTapped else {
            return backButtonTapped
        }
        // Needed because if the title is long, the back button sometimes won't have text, as seen on https://stackoverflow.com/q/38595242/135557
        return navigationBars.buttons.element(boundBy: 0).wmf_waitUntilExists().wmf_tap()
    }
    
    func wmf_tapFirstCollectionViewCell() -> Bool {
        return collectionViews.children(matching: .cell).element(boundBy: 0).wmf_waitUntilExists().wmf_tap()
    }
    
    func wmf_scrollToTop() -> Bool {
        let tapResult = statusBars.element(boundBy: 0).wmf_waitUntilExists().wmf_tap()
        sleep(2) // Give it time to scroll up.
        return tapResult
    }
    
    func wmf_scrollElementToTop(element: XCUIElement) {
        let elementTopCoord = element.coordinate(withNormalizedOffset:CGVector(dx: 0.5, dy: 0.0))
        elementTopCoord.press(forDuration: pressDuration, thenDragTo: coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0)))
        sleep(2) // Give it time to scroll down.
    }
    
    func wmf_scrollDown() {
        sleep(2)
        let iPadSafeBottomDragStartY: Double = 0.8 // If set to 1.0 it drags from very bottom of the screen which triggers an iPad task switcher and zooms out the app. So drag from a little above the very bottom.
        coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: iPadSafeBottomDragStartY)).press(forDuration: pressDuration, thenDragTo: coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: -1.0)))
        sleep(2) // Give it time to scroll down.
    }
    
    func wmf_scrollToOtherElement(key: String, success: (XCUIElement) -> ()){
        let maxScrollSeconds: Double = 240
        let start = Date()
        repeat {
            let element = otherElements.wmf_firstElement(with: .label, withTranslationIn: [key], convertTranslationSubstitutionStringsToWildcards: true, timeout: TimeInterval(1))
            if element.exists {
                wmf_scrollElementToTop(element: element)
                success(element)
                sleep(2)
                break
            }
            wmf_scrollDown()
        } while Date().timeIntervalSince(start) < maxScrollSeconds
    }
}