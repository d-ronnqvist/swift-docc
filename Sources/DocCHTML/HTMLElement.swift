/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2026 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 See https://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

import struct Foundation.Data // Used as a return value by the formatter

// MARK: Element


package struct HTMLElement {
    enum Tag: UInt8 {
        case html
        
        // Metadata
        
        case head
        case title
        case style
        // `base`, `link`, and `meta` are void-elements
        
        // Sections
        
        case body
        case article
        case section
        case nav
        case aside
        case h1, h2, h3, h4, h5, h6
        case hgroup
        case header
        case footer
        case address
        
        // Grouping
        
        case p
        case pre
        case blockquote
        case ol
        case ul
        case menu
        case li
        case dl
        case dt
        case dd
        case figure
        case figcaption
        case main
        case search
        case div
        // `hr` is a void-element
        
        // Text-level semantics
        
        case a
        case em
        case strong
        case small
        case s
        case cite
        case q
        case dfn
        case abbr
        case ruby
        case rt
        case rp
        case data
        case time
        case code
        case `var`
        case samp
        case kbd
        case sub, sup
        case i
        case b
        case u
        case mark
        case bdi
        case bdo
        case span
        // `br` and `wbr` are void-elements
        
        // Embedded
        
        case picture
        case iframe
        case object
        case video
        case audio
        case map
        // `source`, `img`, `embed`, `track`, and `area` are void-elements
        
        // Tables
        
        case table
        case caption
        case colgroup
        // `col` is a void-element
        case tbody
        case thead
        case tfoot
        case tr
        case td
        case th
        
        // Forms
        
        case form
        case label
        // `input` in a void-element
        case button
        case select
        case datalist
        case optgroup
        case option
        case textarea
        case output
        case progress
        case meter
        case fieldset
        case legend
        case selectedcontent
        
        // Interactive
        
        case details
        case summary
        case dialog
        
        // Scripting
        
        case script
        case noscript
        case template
        case slot
        case canvas
    }
    
    enum VoidTag: UInt8 {
        // Metadata
        case base, link, meta
        // Grouping
        case hr
        // Text-level semantics
        case br, wbr
        // Embedded
        case source, img, embed, track, area
        // Tables
        case col
        // Forms
        case input
    }
    
    fileprivate enum Storage {
        case text(String)
        case comment(String)
        case element(Tag, attributes: [String: String], children: [HTMLElement])
        case voidElement(VoidTag, attributes: [String: String])
    }
    fileprivate var storage: Storage
    
    fileprivate var elementTag: Tag? {
        if case .element(let tag, _, _) = storage {
            tag
        } else {
            nil
        }
    }
    
    fileprivate var isElement: Bool {
        if case .element = storage {
            true
        } else {
            false
        }
    }
    
    /*fileprivate*/ static func text(_ text: consuming String) -> HTMLElement {
        .init(storage: .text(text))
    }
    fileprivate static func comment(_ comment: consuming String) -> HTMLElement {
        .init(storage: .comment(comment))
    }
    /*fileprivate*/ static func element(_ tag: Tag, attributes: [String: String] = [:], @HTMLBuilder _ children: () -> [HTMLElement]) -> HTMLElement {
        .init(storage: .element(tag, attributes: attributes, children: children()))
    }
    /*fileprivate*/ static func element(_ tag: Tag, attributes: [String: String] = [:], children: [HTMLElement]) -> HTMLElement {
        .init(storage: .element(tag, attributes: attributes, children: children))
    }
    /*fileprivate*/ static func voidElement(_ tag: VoidTag, attributes: [String: String] = [:]) -> HTMLElement {
        .init(storage: .voidElement(tag, attributes: attributes))
    }
    
    func render(into result: inout String) {
        switch storage {
        case .text(let text):
            result.append(contentsOf: text)
            
        case .comment(let comment):
            result.append(contentsOf: "<!-- \(comment) -->")
            
        case .element(let name, let attributes, let children):
            result.append("<\(name)")
            
            for (name, value) in attributes.sorted(by: { $0.key < $1.key }) {
                result.append(contentsOf: " \(name)=\"\(value)\"")
            }
            guard !children.isEmpty else {
                result.append(contentsOf: "/>")
                return
            }
            
            result.append(">")
            for child in children {
                child.render(into: &result)
            }
            result.append(contentsOf: "</\(name)>")
            
        case .voidElement(let name, let attributes):
            result.append("<\(name)")
            
            for (name, value) in attributes.sorted(by: { $0.key < $1.key }) {
                result.append(contentsOf: " \(name)=\"\(value)\"")
            }
            result.append(">")
        }
    }
}

// MARK: Formatting

struct HTMLFormatter {
    private var buffer: [UInt8]
    private let options: Options
    
    private init(initialCapacity: Int = 512, options: Options) {
        self.buffer = [UInt8]()
        self.buffer.reserveCapacity(initialCapacity)
        self.options = options
    }
    
    static func format(document: HTMLElement, options: Options = []) -> Data {
        var encoder = Self(options: options)
        
        // When encoding an entire document,
        encoder.buffer.append(contentsOf: "<!DOCTYPE html>\n".utf8)
        if options.contains(.prettyPrint) {
            encoder._prettyFormat(document, state: .init(presentOnSameLine: true))
        } else {
            encoder._compactFormat(document, nextElementTag: nil)
        }
        
        return Data(encoder.buffer)
    }
    
    static func format(inPageElement: HTMLElement, options: Options = []) -> Data {
        var encoder = Self(options: options)
        
        if case .element(.pre, _, _) = inPageElement.storage {
            encoder._compactFormat(inPageElement, nextElementTag: nil)
        } else if options.contains(.prettyPrint) {
            encoder._prettyFormat(inPageElement, state: .init(presentOnSameLine: true))
        } else {
            encoder._compactFormat(inPageElement, nextElementTag: nil)
        }
        
        return Data(encoder.buffer)
    }
    
    struct Options: OptionSet {
        let rawValue: Int
        
        ///
        static let prettyPrint = Self(rawValue: 1 << 0)
        
        ///
        static let includeComments = Self(rawValue: 1 << 1)
        
        ///
        static let omitQuotingSingleWordAttributeValues = Self(rawValue: 1 << 2)
        
        ///
        static let omitAllowedEndTags = Self(rawValue: 1 << 3)
    }
    
    // MARK: Compact formatting
    
    private mutating func _compactFormat(_ element: HTMLElement, nextElementTag: HTMLElement.Tag?) {
        switch element.storage {
        case .text(let text):
            _format(text: text)
            
        case .comment(let comment):
            guard options.contains(.includeComments) else { return }
            _format(comment: comment)
            
        case .element(let tag, let attributes, let children):
            buffer.append(.init(ascii: "<"))
            tag.name.withUTF8Buffer { buffer.append(contentsOf: $0) }
            
            // Start tag
            _format(attributes: attributes)
            guard !children.isEmpty else {
                buffer.append(contentsOf: "/>".utf8)
                return
            }
            buffer.append(.init(ascii: ">"))
            
            for index in children.indices {
                let child = children[index]
                
                let nextIndex = index &+ 1
                _compactFormat(child, nextElementTag: nextIndex < children.endIndex ? children[nextIndex].elementTag : nil)
            }
                
            // End tag
            if options.contains(.omitAllowedEndTags), tag.canOmitEndTag(whenFollowedBy: nextElementTag) {
                return
            }
            buffer.append(contentsOf: "</".utf8)
            tag.name.withUTF8Buffer { buffer.append(contentsOf: $0) }
            buffer.append(.init(ascii: ">"))
            
            
        case .voidElement(let voidTag, let attributes):
            buffer.append(.init(ascii: "<"))
            voidTag.name.withUTF8Buffer { buffer.append(contentsOf: $0) }
            _format(attributes: attributes)
            buffer.append(.init(ascii: ">"))
        }
    }
    
    // MARK: Pretty print formatting
    
    private static let _indentationData: [UInt8] = {
        // Stop indenting further after 64 levels of indentation
        var data = [UInt8](repeating: .init(ascii: " "), count: 128)
        data[0] = .init(ascii: "\n")
        return data
    }()
    
    private struct PrettyPrintingState {
        var depth: UInt8 = 0
        var presentOnSameLine: Bool
        var nextElement: HTMLElement.Tag? = nil
    }
    
    private mutating func _prettyFormat(_ element: HTMLElement, state: PrettyPrintingState) {
        func addNewLineIndentation(depth: UInt8 = state.depth) {
            Self._indentationData.withUnsafeBufferPointer {
                buffer.append(contentsOf: $0.prefix(1 /* the newline */ &+ Int(depth) &* 2 /* two spaces per indentation level */))
            }
        }
        
        switch element.storage {
        case .text(let text):
            if !state.presentOnSameLine {
                addNewLineIndentation()
            }
            _format(text: text)
            
        case .comment(let comment):
            guard options.contains(.includeComments) else { return }
            if !state.presentOnSameLine {
                addNewLineIndentation()
            }
            _format(comment: comment)
            
        case .element(let tag, let attributes, let children):
            if !state.presentOnSameLine {
                addNewLineIndentation()
            }
            // Add the start tag
            buffer.append(.init(ascii: "<"))
            tag.name.withUTF8Buffer { buffer.append(contentsOf: $0) }
            
            _format(attributes: attributes)
            guard !children.isEmpty else {
                // Self-close the element if it's empty.
                buffer.append(contentsOf: "/>".utf8)
                return
            }
            buffer.append(.init(ascii: ">"))
            
            
            // It's a matter of opinion how to "pretty print" HTML.
            let presentChildrenOnSameLine = attributes.isEmpty && !children.contains(where: \.isElement)
            var childState = PrettyPrintingState(depth: state.depth &+ 1, presentOnSameLine: presentChildrenOnSameLine, nextElement: nil)
            
            for index in children.indices {
                let child = children[index]
                let nextIndex = index &+ 1
                // It's necessary to know what element comes next in the container (if any) to determine when it's allowed to omit the end tag.
                childState.nextElement = nextIndex < children.endIndex ? children[nextIndex].elementTag : nil
               
                // Whitespace is significant inside `<pre>` elements; so we switch to formatting that sub-hierarchy _without_ pretty printing.
                if child.elementTag == .pre {
                    // However, first we add a new line and indentation so that the `<pre>` element starts appropriately indented on a new line.
                    addNewLineIndentation(depth: childState.depth)
                    _compactFormat(child, nextElementTag: childState.nextElement)
                } else {
                    _prettyFormat(child, state: childState)
                }
            }
            
            // End tag
            if options.contains(.omitAllowedEndTags), tag.canOmitEndTag(whenFollowedBy: state.nextElement) {
                return
            }
            if !presentChildrenOnSameLine {
                addNewLineIndentation()
            }
            buffer.append(contentsOf: "</".utf8)
            tag.name.withUTF8Buffer { buffer.append(contentsOf: $0) }
            buffer.append(.init(ascii: ">"))
            
            
        case .voidElement(let voidTag, let attributes):
            if !state.presentOnSameLine {
                addNewLineIndentation()
            }
            buffer.append(.init(ascii: "<"))
            voidTag.name.withUTF8Buffer { buffer.append(contentsOf: $0) }
            _format(attributes: attributes)
            buffer.append(.init(ascii: ">"))
        }
    }
    
    private mutating func _format(text: String) {
        var remaining = text.utf8[...]
        
        while let index = remaining.firstIndex(where: \.needsEscapingInHTMLText) {
            buffer.append(contentsOf: remaining[..<index])
            switch remaining[index] {
                case .init(ascii: "&"): buffer.append(contentsOf: "&amp;".utf8)
                case .init(ascii: "<"): buffer.append(contentsOf: "&lt;".utf8)
                case .init(ascii: ">"): buffer.append(contentsOf: "&gt;".utf8)
                default: fatalError("Missing handling of escapable character '\(Character(UnicodeScalar(remaining[index])))'")
            }
            remaining = remaining[remaining.index(after: index)...]
        }
        
        buffer.append(contentsOf: remaining)
    }
    
    private mutating func _format(attributes: [String: String]) {
        func _format(value: String) {
            var remaining = value.utf8[...]
            
            // If the formatter is configured to not quote attribute values unless necessary; check the value _needs_ quoting.
            guard !options.contains(.omitQuotingSingleWordAttributeValues) || remaining.contains(where: \.needsQuotingInHTMLAttribute) else {
                buffer.append(.init(ascii: "="))
                // If the value doesn't need quoting, the only escapable character is `&`.
                while let index = remaining.firstIndex(of: .init(ascii: "&")) {
                    buffer.append(contentsOf: remaining[..<index])
                    buffer.append(contentsOf: "&amp;".utf8)
                    remaining = remaining[remaining.index(after: index)...]
                }
                buffer.append(contentsOf: remaining)
                return
            }
            
            buffer.append(contentsOf: "=\"".utf8)
            
            while let index = remaining.firstIndex(where: \.needsEscapingInHTMLAttribute) {
                buffer.append(contentsOf: remaining[..<index])
                // Because the formatter uses `"` to quote the attribute values; we only need to escape `&` and `"`.
                buffer.append(contentsOf: remaining[index] == .init(ascii: "&") ? "&amp;".utf8 : "&quot;".utf8)
                remaining = remaining[remaining.index(after: index)...]
            }
            buffer.append(contentsOf: remaining)
            buffer.append(.init(ascii: "\""))
        }
        
        // Regardless of pretty printing or not, sort the attributes by their key so that the output is stable across different program executions.
        for (name, value) in attributes.sorted(by: { $0.key < $1.key }) {
            buffer.append(.init(ascii: " "))
            buffer.append(contentsOf: name.utf8)
            guard !value.isEmpty else { continue }
            _format(value: value)
        }
    }
    
    private mutating func _format(comment: String) {
        buffer.append(contentsOf: "<!--".utf8)
        buffer.append(contentsOf: comment.utf8)
        buffer.append(contentsOf: "-->".utf8)
    }
}

private extension UInt8 {
    var needsEscapingInHTMLText: Bool {
        return self == .init(ascii: "&")
            || self == .init(ascii: "<")
            || self == .init(ascii: ">") // Not strictly necessary according to the spec.
    }
    var needsEscapingInHTMLAttribute: Bool {
        return self == .init(ascii: "&")
            || self == .init(ascii: "\"") // Because the formatter uses `"` to quote the attribute value, we don't need to escape `'`.
    }
    var needsQuotingInHTMLAttribute: Bool {
        // The attribute value can remain unquoted if it doesn't contain ASCII whitespace or any of " ' ` = < >
        return self == .init(ascii: " " )
            || self == .init(ascii: "\t") // Tab
            || self == .init(ascii: "\n") // New line / Line feed
            || self == .init(ascii: "\r") // Carriage return
            || self == .init(ascii: "\"")
            || self == .init(ascii: "'" )
            || self == .init(ascii: "`" )
            || self == .init(ascii: "=" )
            || self == .init(ascii: "<" )
            || self == .init(ascii: ">" )
    }
}

// MARK: DSL

@resultBuilder
struct HTMLBuilder {
    
    typealias Something = [HTMLElement]
    
    static func buildBlock(_ components: [HTMLElement]...) -> Something {
        components.flatMap { $0 }
    }
    
    static func buildExpression(_ expression: consuming HTMLElement) -> Something {
        [expression]
    }
    
    static func buildExpression(_ text: consuming String) -> Something {
        [.text(text)]
    }
    
    /// Support `if` statements without an `else` statement.
    static func buildOptional(_ component: consuming Something?) -> Something { component ?? [] }
    
    /// Support `if-else` and `switch` statements.
    static func buildEither(first  component: consuming Something) -> Something { component }
    static func buildEither(second component: consuming Something) -> Something { component }
    
    /// Support `for-in` loops
    static func buildArray(_ components: consuming [Something]) -> Something {
        components.flatMap { $0 }
    }
}


//    
//func p(
//    id: String? = nil,
//    classes: [String]? = nil,
//    @HTMLBuilder _ children: () -> [HTMLElement]
//) -> HTMLElement {
//    var attributes = [String: String]()
//    return .element(.p, children)
//}

//
//struct MarkdownRendererTests {
//    
//    
//    func dsl() {
////        
////        let node = p {
////            "Before "
////            
////            b {
////                "bold"
////            }
////            
////           
////            " after."
////        }
////        
////        var res = ""
////        node.render(into: &res)
//        
//    }
//}


private extension HTMLElement.Tag {
    var name: StaticString {
        switch self {
            case .html:       "html"
            case .head:       "head"
            case .title:      "title"
            case .style:      "style"
            case .body:       "body"
            case .article:    "article"
            case .section:    "section"
            case .nav:        "nav"
            case .aside:      "aside"
            case .h1:         "h1"
            case .h2:         "h2"
            case .h3:         "h3"
            case .h4:         "h4"
            case .h5:         "h5"
            case .h6:         "h6"
            case .hgroup:     "hgroup"
            case .header:     "header"
            case .footer:     "footer"
            case .address:    "address"
            case .p:          "p"
            case .pre:        "pre"
            case .blockquote: "blockquote"
            case .ol:         "ol"
            case .ul:         "ul"
            case .menu:       "menu"
            case .li:         "li"
            case .dl:         "dl"
            case .dt:         "dt"
            case .dd:         "dd"
            case .figure:     "figure"
            case .figcaption: "figcaption"
            case .main:       "main"
            case .search:     "search"
            case .div:        "div"
            case .a:          "a"
            case .em:         "em"
            case .strong:     "strong"
            case .small:      "small"
            case .s:          "s"
            case .cite:       "cite"
            case .q:          "q"
            case .dfn:        "dfn"
            case .abbr:       "abbr"
            case .ruby:       "ruby"
            case .rt:         "rt"
            case .rp:         "rp"
            case .data:       "data"
            case .time:       "time"
            case .code:       "code"
            case .var:        "var"
            case .samp:       "samp"
            case .kbd:        "kbd"
            case .sub:        "sub"
            case .sup:        "sup"
            case .i:          "i"
            case .b:          "b"
            case .u:          "u"
            case .mark:       "mark"
            case .bdi:        "bdi"
            case .bdo:        "bdo"
            case .span:       "span"
            case .picture:    "picture"
            case .iframe:     "iframe"
            case .object:     "object"
            case .video:      "video"
            case .audio:      "audio"
            case .map:        "map"
            case .table:      "table"
            case .caption:    "caption"
            case .colgroup:   "colgroup"
            case .tbody:      "tbody"
            case .thead:      "thead"
            case .tfoot:      "tfoot"
            case .tr:         "tr"
            case .td:         "td"
            case .th:         "th"
            case .form:       "form"
            case .label:      "label"
            case .button:     "button"
            case .select:     "select"
            case .datalist:   "datalist"
            case .optgroup:   "optgroup"
            case .option:     "option"
            case .textarea:   "textarea"
            case .output:     "output"
            case .progress:   "progress"
            case .meter:      "meter"
            case .fieldset:   "fieldset"
            case .legend:     "legend"
            case .selectedcontent: "selectedcontent"
            case .details:    "details"
            case .summary:    "summary"
            case .dialog:     "dialog"
            case .script:     "script"
            case .noscript:   "noscript"
            case .template:   "template"
            case .slot:       "slot"
            case .canvas:     "canvas"
        }
    }
    
    /// Determines whether or not an element of this tag can omit its end tag when followed by the given `next` element in the same container.
    ///
    /// The HTML specific
    func canOmitEndTag(whenFollowedBy next: Self?) -> Bool {
        switch self {
        case .p:
            switch next {
            case .address, .article, .aside, .blockquote, .details, .dialog, .div, .dl, .fieldset, .figcaption, .figure, .footer, .form, .h1, .h2, .h3, .h4, .h5, .h6, .hgroup, /*.hr,*/ .main, .menu, .nav, .ol, .p, .pre, .search, .section, .table, .ul, nil:
                true
            default:
                false
            }
            
        case .body:
            true
            
        case .li:
            next == .li || next == nil
            
        case .dt:
            next == .dt || next == .dd
            
        case .dd:
            next == .dt || next == .dd || next == nil
            
        case .rt, .rp:
            next == .rt || next == .rp || next == nil
            
        case .caption:
            true

        case .thead:
            next == .tbody || next == .tfoot
            
        case .tfoot:
            next == nil
            
        case .tr:
            next == .td || next == nil
            
        case .td, .th:
            next == .td || next == .th || next == nil
            
        case .optgroup:
            next == .optgroup || /*next == .hr ||*/ next == nil
            
        case .option:
            next == .option || next == .optgroup || /*next == .hr ||*/ next == nil
            
        default:
            false
        }
    }
}


private extension HTMLElement.VoidTag {
    var name: StaticString {
        switch self {
            case .base:   "base"
            case .link:   "link"
            case .meta:   "meta"
            case .hr:     "hr"
            case .br:     "br"
            case .wbr:    "wbr"
            case .source: "source"
            case .img:    "img"
            case .embed:  "embed"
            case .track:  "track"
            case .area:   "area"
            case .col:    "col"
            case .input:  "input"
        }
    }
}
