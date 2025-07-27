//
//  KeywordHighlightingTextView.swift
//  tcPresaleDreamland
//
//  Created by Sedoykin Alexey on 26/07/2025.
//

import SwiftUI
import AppKit

#if os(macOS)
struct KeywordHighlightingTextView: NSViewRepresentable {
    @Binding var text: String
    var keywords: [String]
    var fontSize: CGFloat = 13

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeNSView(context: Context) -> NSScrollView {
        let scroll = NSScrollView()
        scroll.hasVerticalScroller = true
        scroll.drawsBackground = false

        // ⬇️ Give the text view an initial, non-zero frame
        let initialSize = scroll.contentSize
        let tv = NSTextView(frame: NSRect(origin: .zero, size: initialSize))
        tv.autoresizingMask = [.width]                 // track width changes

        // Basic config
        tv.isRichText = true
        tv.isEditable = true
        tv.isAutomaticQuoteSubstitutionEnabled = false
        tv.isAutomaticLinkDetectionEnabled = false
        tv.allowsUndo = true
        tv.textContainerInset = NSSize(width: 6, height: 6)

        // Colors & font (visible in light/dark)
        tv.drawsBackground = true
        tv.backgroundColor = .textBackgroundColor
        tv.textColor = .labelColor
        tv.font = NSFont.systemFont(ofSize: fontSize)

        // Layout: track width, big height so it can lay out
        tv.isVerticallyResizable = true
        tv.isHorizontallyResizable = false
        tv.textContainer?.widthTracksTextView = true
        tv.textContainer?.containerSize = NSSize(width: initialSize.width,
                                                 height: CGFloat.greatestFiniteMagnitude)

        tv.delegate = context.coordinator
        scroll.documentView = tv

        // initial content
        tv.string = text
        applyHighlight(in: tv, coordinator: context.coordinator)

        return scroll
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let tv = nsView.documentView as? NSTextView else { return }

        // Ensure container width matches the scroll view after layout
        DispatchQueue.main.async {
            let w = nsView.contentSize.width
            tv.textContainer?.widthTracksTextView = true
            tv.textContainer?.containerSize = NSSize(width: w,
                                                     height: CGFloat.greatestFiniteMagnitude)
            // keep the view’s frame in sync with the scroll width
            var f = tv.frame
            f.size.width = w
            tv.frame = f
        }

        if tv.string != text {
            let sel = tv.selectedRange()
            tv.string = text
            applyHighlight(in: tv, selection: sel, coordinator: context.coordinator)
        } else {
            applyHighlight(in: tv, coordinator: context.coordinator)
        }
    }

    // MARK: - Coordinator
    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: KeywordHighlightingTextView
        var isApplyingHighlight = false
        init(_ parent: KeywordHighlightingTextView) { self.parent = parent }

        func textDidChange(_ notification: Notification) {
            guard !isApplyingHighlight,
                  let tv = notification.object as? NSTextView else { return }
            // keep SwiftUI binding in sync
            parent.text = tv.string
            // re-highlight (selection will be preserved inside applyHighlight)
            parent.applyHighlight(in: tv, coordinator: self)
        }

    }

    // MARK: - Highlighting
    private func applyHighlight(in textView: NSTextView,
                                selection: NSRange? = nil,
                                coordinator: Coordinator? = nil) {
        // Don’t interfere with ongoing IME composition
        if textView.hasMarkedText() { return }

        let coord = coordinator ?? (textView.delegate as? Coordinator)
        coord?.isApplyingHighlight = true
        defer { coord?.isApplyingHighlight = false }

        // Preserve caret/selection no matter who called us
        let currentSelection = selection ?? textView.selectedRange()

        guard let storage = textView.textStorage else { return }
        let fullRange = NSRange(location: 0, length: storage.length)

        // Base attributes (don’t rebuild the string—just set attributes)
        let baseFont = NSFont.systemFont(ofSize: fontSize)
        let baseColor = NSColor.labelColor

        storage.beginEditing()
        storage.setAttributes([.font: baseFont, .foregroundColor: baseColor], range: fullRange)

        // Bold the keywords
        let boldFont = NSFont.boldSystemFont(ofSize: fontSize)
        let s = textView.string as NSString
        for key in keywords where !key.isEmpty {
            var searchRange = fullRange
            while true {
                let r = s.range(of: key, options: [], range: searchRange)
                if r.location == NSNotFound { break }
                storage.addAttribute(.font, value: boldFont, range: r)
                let nextLocation = r.location + r.length
                searchRange = NSRange(location: nextLocation, length: fullRange.length - nextLocation)
            }
        }
        storage.endEditing()

        // Keep typing consistent
        textView.typingAttributes = [.font: baseFont, .foregroundColor: baseColor]

        // Restore caret/selection
        textView.setSelectedRange(currentSelection)
    }


    private func ranges(of needle: String, in haystack: String) -> [NSRange] {
        var out: [NSRange] = []
        var search = haystack.startIndex..<haystack.endIndex
        while let r = haystack.range(of: needle, options: [], range: search) {
            out.append(NSRange(r, in: haystack))
            search = r.upperBound..<haystack.endIndex
        }
        return out
    }
}
#endif


