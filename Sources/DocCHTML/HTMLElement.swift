/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2026 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 See https://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

package import struct Foundation.Data // Used as a return value by the formatter

// MARK: Element

package struct HTMLElement: Sendable {
    /*fileprivate*/package enum Storage {
        case text(String)
        case element(Tag, attributes: [String: String], children: [HTMLElement])
        case voidElement(Tag, attributes: [String: String])
    }
    /*fileprivate*/package var storage: Storage
    
    /*fileprivate*/ package static func text(_ text: consuming String) -> HTMLElement {
        .init(storage: .text(text))
    }
//    /*fileprivate*/ static func element(_ tag: Tag, attributes: [String: String] = [:], @HTMLBuilder _ children: () -> [HTMLElement]) -> HTMLElement {
//        .init(storage: .element(tag, attributes: attributes, children: children()))
//    }
    /*fileprivate*/ package static func element(_ tag: Tag, attributes: [String: String] = [:], children: [HTMLElement]) -> HTMLElement {
        assert(!tag.isVoid, "Cannot create an element using void tag '\(tag.name)'. Use `.voidElement(...)` instead.")
        assert(attributes.keys.count == Set(attributes.keys.map { $0.lowercased() }).count, "All attribute names has to be case insensitively unique. This wasn't true for ...")
        assert(children.allSatisfy { $0.elementTag == nil || tag.canOmitEndTag(whenFollowedBy: $0.elementTag) == false }, "Element '\(tag.name)' cannot contain ...")
        assert(!attributes.isEmpty || !children.isEmpty, "Tag '\(tag.name)' is unexpectedly empty (no attributes and no members).")
        return .init(storage: .element(tag, attributes: attributes, children: children))
    }
    
    /*fileprivate*/ package static func element(_ tag: Tag, children: [HTMLElement], attributes: [String: String]) -> HTMLElement {
        .element(tag, attributes: attributes, children: children)
    }
    
    /*fileprivate*/ package static func voidElement(_ tag: Tag, attributes: [String: String] = [:]) -> HTMLElement {
        assert(tag.isVoid, "")
        return .init(storage: .voidElement(tag, attributes: attributes))
    }
    
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
    
    // FIXME: REMOVE THIS
    package mutating func addChild(_ child: HTMLElement) {
        if case .element(let tag, let attributes, var children) = storage {
            children.append(child)
            storage = .element(tag, attributes: attributes, children: children)
        }
    }
    
    // FIXME: REMOVE THIS
    package mutating func addAttributes(_ newAttributes: [String: String]) {
        switch storage {
            case .element(let tag, var attributes, let children):
                attributes.merge(newAttributes, uniquingKeysWith: { _, new in new })
                storage = .element(tag, attributes: attributes, children: children)
            case .voidElement(let voidTag, var attributes):
                attributes.merge(newAttributes, uniquingKeysWith: { _, new in new })
                storage = .voidElement(voidTag, attributes: attributes)
                
            default: break
        }
    }
}

// MARK: Formatting

package struct HTMLFormatter {
    private var buffer: [UInt8]
    private let options: Options
    
    private init(initialCapacity: Int = 1024 * 2, options: Options) {
        self.buffer = [UInt8]()
        self.buffer.reserveCapacity(initialCapacity)
        self.options = options
    }
    
    package static func format(document: HTMLElement, options: Options = []) -> Data {
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
    
    package static func format(inPageElement: HTMLElement, options: Options = []) -> Data {
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
    
    package struct Options: OptionSet {
        package let rawValue: Int
        package init(rawValue: Int) {
            self.rawValue = rawValue
        }
        
        ///
        package static let prettyPrint = Self(rawValue: 1 << 0)
        
        ///
        package static let omitQuotingSingleWordAttributeValues = Self(rawValue: 1 << 1)
        
        ///
        package static let omitAllowedEndTags = Self(rawValue: 1 << 2)
    }
    
    // MARK: Compact formatting
    
    private mutating func _compactFormat(_ element: consuming HTMLElement, nextElementTag: HTMLElement.Tag?) {
        switch element.storage {
        case .text(let text):
            _format(text: consume text)
            
//        case .comment(_):
//            fatalError()
//            guard options.contains(.includeComments) else { return }
//            _format(comment: comment)
            
        case .element(let tag, let attributes, let children):
            buffer.append(.init(ascii: "<"))
            tag.name.withUTF8Buffer { buffer.append(contentsOf: $0) }
            
            // Start tag
            _format(attributes: consume attributes)
            guard !children.isEmpty else {
//                buffer.append(contentsOf: "/>".utf8)
                _add_s("/>")
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
//            buffer.append(contentsOf: "</".utf8)
            _add_s("</")
//            tag.name.withUTF8Buffer { buffer.append(contentsOf: $0) }
            _add_s(tag.name)
            buffer.append(.init(ascii: ">"))
            
            
        case .voidElement(let voidTag, let attributes):
            buffer.append(.init(ascii: "<"))
            voidTag.name.withUTF8Buffer { buffer.append(contentsOf: $0) }
            _format(attributes: consume attributes)
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
        func appendLineBreakAndIndentation(depth: UInt8 = state.depth) {
            Self._indentationData.withUnsafeBufferPointer {
                buffer.append(contentsOf: $0.prefix(1 /* the newline */ &+ Int(depth) &* 2 /* two spaces per indentation level */))
            }
        }
        
        switch element.storage {
            case .text(let text):
                if !state.presentOnSameLine {
                    appendLineBreakAndIndentation()
                }
                _format(text: consume text)
                
                //        case .comment(_):
                //            fatalError()
                //            guard options.contains(.includeComments) else { return }
                //            if !state.presentOnSameLine {
                //                addNewLineIndentation()
                //            }
                //            _format(comment: comment)
                
            case .element(let tag, let attributes, let children):
                if !state.presentOnSameLine {
                    appendLineBreakAndIndentation()
                }
                // Add the start tag
                buffer.append(.init(ascii: "<"))
                tag.name.withUTF8Buffer { buffer.append(contentsOf: $0) }
                
                let presentChildrenOnSameLine = attributes.isEmpty && !children.contains(where: \.isElement)
                _format(attributes: consume attributes)
                guard !children.isEmpty else {
                    // Self-close the element if it's empty.
                    //                buffer.append(contentsOf: "/>".utf8)
                    _add_s("/>")
                    return
                }
                buffer.append(.init(ascii: ">"))
                
                
                // It's a matter of opinion how to "pretty print" HTML.
                //            let presentChildrenOnSameLine = attributes.isEmpty && !children.contains(where: \.isElement)
                var childState = PrettyPrintingState(depth: state.depth &+ 1, presentOnSameLine: presentChildrenOnSameLine, nextElement: nil)
                
                for index in children.indices {
                    let child = children[index]
                    let nextIndex = index &+ 1
                    // It's necessary to know what element comes next in the container (if any) to determine when it's allowed to omit the end tag.
                    childState.nextElement = nextIndex < children.endIndex ? children[nextIndex].elementTag : nil
                    
                    // Whitespace is significant inside `<pre>` elements; so we switch to formatting that sub-hierarchy _without_ pretty printing.
                    if child.elementTag == .pre {
                        // However, first we add a new line and indentation so that the `<pre>` element starts appropriately indented on a new line.
                        appendLineBreakAndIndentation(depth: childState.depth)
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
                    appendLineBreakAndIndentation()
                }
                //            buffer.append(contentsOf: "</".utf8)
                _add_s("</")
                tag.name.withUTF8Buffer { buffer.append(contentsOf: $0) }
                buffer.append(.init(ascii: ">"))
                
                
            case .voidElement(let voidTag, let attributes):
                if !state.presentOnSameLine {
                    appendLineBreakAndIndentation()
                }
                buffer.append(.init(ascii: "<"))
                voidTag.name.withUTF8Buffer { buffer.append(contentsOf: $0) }
                _format(attributes: consume attributes)
                buffer.append(.init(ascii: ">"))
        }
    }
    
    private mutating func _add(_ string: consuming String) {
        var string = consume string
        string.withUTF8 {
            buffer.append(contentsOf: $0)
        }
    }
    
    private mutating func _add_s(_ string: StaticString) {
        string.withUTF8Buffer { buffer.append(contentsOf: $0) }
    }
    
    private mutating func _format(text: consuming String) {
        // This can be made nicer with UTF8Span when we can require anyAppleOS 26+
        var text = consume text
        text.withUTF8 {
            var remaining = $0[...]
            
//
            while let index = remaining.firstIndex(where: \.needsEscapingInHTMLText) {
                buffer.append(contentsOf: remaining[..<index])
                switch remaining[index] {
                case .init(ascii: "&"): _add_s("&amp;") //buffer.append(contentsOf: "&amp;".utf8)
                case .init(ascii: "<"): _add_s("&lt;") //buffer.append(contentsOf: "&lt;".utf8)
                case .init(ascii: ">"): _add_s("&gt;") //buffer.append(contentsOf: "&gt;".utf8)
                default: fatalError("Missing handling of escapable character '\(Character(UnicodeScalar(remaining[index])))'")
                }
                remaining = remaining[remaining.index(after: index)...]
            }
            
            buffer.append(contentsOf: remaining)
                
        }
        
//        var remaining = text.utf8[...]
//        
//        while let index = remaining.firstIndex(where: \.needsEscapingInHTMLText) {
//            buffer.append(contentsOf: remaining[..<index])
//            switch remaining[index] {
//                case .init(ascii: "&"): _add("&amp;") //buffer.append(contentsOf: "&amp;".utf8)
//                case .init(ascii: "<"): _add("&lt;") //buffer.append(contentsOf: "&lt;".utf8)
//                case .init(ascii: ">"): _add("&gt;") //buffer.append(contentsOf: "&gt;".utf8)
//                default: fatalError("Missing handling of escapable character '\(Character(UnicodeScalar(remaining[index])))'")
//            }
//            remaining = remaining[remaining.index(after: index)...]
//        }
//        
//        buffer.append(contentsOf: remaining)
    }
    
    private mutating func _format(attributes: [String: String]) {
        func _format(value: consuming String) {
            // This can be made nicer with UTF8Span when we can require anyAppleOS 26+
            var value = consume value
            value.withUTF8 {
                var remaining = $0[...]
                
                // If the formatter is configured to not quote attribute values unless necessary; check the value _needs_ quoting.
                guard !options.contains(.omitQuotingSingleWordAttributeValues) || remaining.contains(where: \.needsQuotingInHTMLAttribute) else {
                    buffer.append(.init(ascii: "="))
                    // If the value doesn't need quoting, the only escapable character is `&`.
                    while let index = remaining.firstIndex(of: .init(ascii: "&")) {
                        buffer.append(contentsOf: remaining[..<index])
                        //                    buffer.append(contentsOf: "&amp;".utf8)
                        _add_s("&amp;")
                        remaining = remaining[remaining.index(after: index)...]
                    }
                    buffer.append(contentsOf: remaining)
                    return
                }
                
//                buffer.append(contentsOf: "=\"".utf8)
                _add_s("=\"")
                
                while let index = remaining.firstIndex(where: \.needsEscapingInHTMLAttribute) {
                    buffer.append(contentsOf: remaining[..<index])
                    // Because the formatter uses `"` to quote the attribute values; we only need to escape `&` and `"`.
                    //                buffer.append(contentsOf: remaining[index] == .init(ascii: "&") ? "&amp;".utf8 : "&quot;".utf8)
                    if remaining[index] == .init(ascii: "&") {
                        _add_s("&amp;")
                    } else {
                        _add_s("&quot;")
                    }
                    remaining = remaining[remaining.index(after: index)...]
                }
                buffer.append(contentsOf: remaining)
                buffer.append(.init(ascii: "\""))
            }
        }
        
        // Regardless of pretty printing or not, sort the attributes by their key so that the output is stable across different program executions.
        for (name, value) in attributes.sorted(by: { $0.key < $1.key }) {
            buffer.append(.init(ascii: " "))
//            buffer.append(contentsOf: name.utf8)
            _add(consume name)
            guard !value.isEmpty else { continue }
            _format(value: consume value)
        }
    }
}

private extension UTF8.CodeUnit {
    var needsEscapingInHTMLText: Bool {
        return self == .init(ascii: "&")
            || self == .init(ascii: "<")
            || self == .init(ascii: ">") // Not strictly necessary according to the spec.
    }
    var needsEscapingInHTMLAttribute: Bool {
        return self == .init(ascii: "&")
            || self == .init(ascii: "\"") // Because the formatter uses `"` to quote the attribute value, we don't need to escape `'`.
    }
    /// A Boolean value that determines whether this UTF-8 code unit
    ///
    /// An attribute value can remain unquoted if it doesn't contain ASCII whitespace or any of " ' ` = < >
    var needsQuotingInHTMLAttribute: Bool {
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

// MARK: Result Builder

@resultBuilder
struct HTMLBuilder {
    
//    static func buildBlock(_ components: [HTMLElement]...) -> Something {
//        components.flatMap { $0 }
//    }
    
//    static func buildExpression(_ expression: consuming HTMLElement) -> Something {
//        [expression]
//    }
    
//    static func buildExpression(_ text: consuming String) -> Something {
//        [.text(text)]
//    }
    
    /// Support `if` statements without an `else` statement.
//    static func buildOptional(_ component: consuming Something?) -> Something { component ?? [] }
//    
//    /// Support `if-else` and `switch` statements.
//    static func buildEither(first  component: consuming Something) -> Something { component }
//    static func buildEither(second component: consuming Something) -> Something { component }
//    
//    /// Support `for-in` loops
//    static func buildArray(_ components: consuming [Something]) -> Something {
//        components.flatMap { $0 }
//    }
    
//    static func buildArray(_ components: [ [HTMLElement] ]) -> [HTMLElement] {
//        components.flatMap { $0 }
//    }
    
    static func buildPartialBlock(first: HTMLElement) -> [HTMLElement] {
        [first]
    }
    
//    static func buildPartialBlock(first: [HTMLElement]) -> [HTMLElement] {
//        first
//    }
    
    static func buildPartialBlock(accumulated: consuming [HTMLElement], next: HTMLElement) -> [HTMLElement] {
        var copy = consume accumulated
        copy.append(next)
        return copy
    }
    
//    static func buildPartialBlock(accumulated: consuming [HTMLElement], next: consuming [HTMLElement]) -> [HTMLElement] {
//        var copy = consume accumulated
//        copy.append(contentsOf: next)
//        return copy
//    }
//    
//    static func buildPartialBlock(accumulated: consuming [HTMLElement], next: consuming [ [HTMLElement] ]) -> [HTMLElement] {
//        var copy = consume accumulated
//        for n in next {
//            copy.append(contentsOf: n)
//        }
//        return copy
//    }
    
    static func buildFinalResult(_ component: [HTMLElement]) -> [HTMLElement] {
        component
    }
}


// MARK: Tags

// This only defined functions for the HTML elements that we've needed to create so far,
// with only the parameters that we've needed to pass so far.
// If you need another element you can add a new function here, following the style of the other functions.
// If you need to pass new information to an existing element you can add a new parameter with a default value to that element's corresponding function.

package func html(lang: consuming String? = nil, @HTMLBuilder _ children: () -> [HTMLElement]) -> HTMLElement {
    .element(.html, attributes: lang.map { ["lang": $0] } ?? [:] , children: children())
}

// MARK Metadata

package func head(@HTMLBuilder _ children: () -> [HTMLElement]) -> HTMLElement {
    .element(.head, children: children())
}

package func link(rel: consuming String, href: consuming String) -> HTMLElement {
    .voidElement(.link, attributes: ["rel": rel, "href": href])
}

package func meta(attributes: consuming [String: String]) -> HTMLElement {
    .voidElement(.meta, attributes: consume attributes)
}

// Sections

package func body(@HTMLBuilder _ children: () -> [HTMLElement]) -> HTMLElement {
    .element(.body, children: children())
}

package func article(@HTMLBuilder _ children: () -> [HTMLElement]) -> HTMLElement {
    .element(.article, children: children())
}

package func section(id: consuming String? = nil, @HTMLBuilder _ children: () -> [HTMLElement]) -> HTMLElement {
    .element(.section, attributes: id.map { ["id": $0] } ?? [:], children: children())
}

package func nav(id: consuming String? = nil, @HTMLBuilder _ children: () -> [HTMLElement]) -> HTMLElement {
    .element(.nav, attributes: id.map { ["id": $0] } ?? [:], children: children())
}

package func aside(class classNames: consuming String? = nil, @HTMLBuilder _ children: () -> [HTMLElement]) -> HTMLElement {
    .element(.aside, attributes: classNames.map { ["class": $0] } ?? [:], children: children())
}

package func h1(class classNames: consuming String? = nil, @HTMLBuilder _ children: () -> [HTMLElement]) -> HTMLElement {
    .element(.h1, attributes: classNames.map { ["class": $0] } ?? [:], children: children())
}

package func h2(_ text: String) -> HTMLElement {
    .element(.h2, children: [.text(text)])
}

func h1(children: [HTMLElement]) -> HTMLElement {
    .element(.h2, children: children)
}

func h2(children: [HTMLElement]) -> HTMLElement {
    .element(.h2, children: children)
}

func h3(children: [HTMLElement]) -> HTMLElement {
    .element(.h3, children: children)
}

func h4(children: [HTMLElement]) -> HTMLElement {
    .element(.h4, children: children)
}

func h5(children: [HTMLElement]) -> HTMLElement {
    .element(.h5, children: children)
}

func h6(children: [HTMLElement]) -> HTMLElement {
    .element(.h6, children: children)
}

package func hgroup(@HTMLBuilder _ children: () -> [HTMLElement]) -> HTMLElement {
    .element(.hgroup, children: children())
}

package func header(@HTMLBuilder _ children: () -> [HTMLElement]) -> HTMLElement {
    .element(.header, children: children())
}

package func footer(@HTMLBuilder _ children: () -> [HTMLElement]) -> HTMLElement {
    .element(.footer, children: children())
}

// Grouping

package func p(class classNames: consuming String? = nil, @HTMLBuilder _ children: () -> [HTMLElement]) -> HTMLElement {
    .element(.p, attributes: classNames.map { ["class": $0] } ?? [:], children: children())
}

package func pre(id: consuming String? = nil, @HTMLBuilder _ children: () -> [HTMLElement]) -> HTMLElement {
    .element(.pre, attributes: id.map { ["id": $0] } ?? [:], children: children())
}

package func ol(class classNames: consuming String? = nil, @HTMLBuilder _ children: () -> [HTMLElement]) -> HTMLElement {
    let listItems = children()
    assert(listItems.allSatisfy { $0.elementTag == .li }, "<ol> tags can only contain <li> tags")
    return .element(.ol, attributes: classNames.map { ["class": $0] } ?? [:], children: listItems)
}

package func ul(id: consuming String? = nil, @HTMLBuilder _ children: () -> [HTMLElement]) -> HTMLElement {
    let listItems = children()
    assert(listItems.allSatisfy { $0.elementTag == .li }, "<ul> tags can only contain <li> tags")
    return .element(.ul, attributes: id.map { ["id": $0] } ?? [:], children: listItems)
}

package func li(attributes: consuming [String: String] = [:], @HTMLBuilder _ children: () -> [HTMLElement]) -> HTMLElement {
    .element(.li, attributes: consume attributes, children: children())
}

package func dl(@HTMLBuilder _ children: () -> [HTMLElement]) -> HTMLElement {
    let listItems = children()
    assert(listItems.allSatisfy { $0.elementTag == .dt || $0.elementTag == .dd }, "<dl> tags can only contain <dt> and <dt> tags")
    return .element(.dl, children: listItems)
}

package func dt(@HTMLBuilder _ children: () -> [HTMLElement]) -> HTMLElement {
    let content = children()
    assert(content.allSatisfy { $0.elementTag != .footer && $0.elementTag == .header }, "<dd> tags cannot contain <header> or <footer> tags")
    return .element(.dt, children: content)
}

package func dd(@HTMLBuilder _ children: () -> [HTMLElement]) -> HTMLElement {
    return .element(.dd, children: children())
}

package let hr = HTMLElement.voidElement(.hr)

// Text-level semantics

package func a(href: consuming String, @HTMLBuilder _ children: () -> [HTMLElement]) -> HTMLElement {
    .element(.a, attributes: ["href": href], children: children())
}

func s(children: [HTMLElement]) -> HTMLElement {
    .element(.s, children: children)
}

package func code(class classNames: consuming String? = nil, @HTMLBuilder _ children: () -> [HTMLElement]) -> HTMLElement {
    .element(.code, attributes: classNames.map { ["class": $0] } ?? [:], children: children())
}

func i(children: [HTMLElement]) -> HTMLElement {
    .element(.i, children: children)
}

func b(children: [HTMLElement]) -> HTMLElement {
    .element(.b, children: children)
}

package func span(class classNames: consuming String? = nil, @HTMLBuilder _ children: () -> [HTMLElement]) -> HTMLElement {
    .element(.span, attributes: classNames.map { ["class": $0] } ?? [:], children: children())
}

package let br = HTMLElement.voidElement(.br)

package let wbr = HTMLElement.voidElement(.wbr)

// Embedded

package func picture(@HTMLBuilder _ children: () -> [HTMLElement]) -> HTMLElement {
    .element(.picture, children: children())
}

func img(attributes: consuming [String: String]) -> HTMLElement {
    .voidElement(.img, attributes: consume attributes)
}

func source(attributes: consuming [String: String]) -> HTMLElement {
    .voidElement(.source, attributes: consume attributes)
}

// Tables

func table(children: [HTMLElement]) -> HTMLElement {
    .element(.table, children: children)
}

func thead(children: [HTMLElement]) -> HTMLElement {
    assert(children.allSatisfy { $0.elementTag == .tr }, "<thead> tags can only contain <tr> tags")
    return .element(.thead, children: children)
}

func tbody(children: [HTMLElement]) -> HTMLElement {
    assert(children.allSatisfy { $0.elementTag == .tr }, "<thead> tags can only contain <tr> tags")
    return .element(.tbody, children: children)
}

func tr(colspan: UInt = 0, rowspan: UInt = 0, class className: consuming String? = nil, children: [HTMLElement]) -> HTMLElement {
    assert(children.allSatisfy { $0.elementTag == .td || $0.elementTag == .th }, "<tr> tags can only contain <td> and <th> tags")
    var attributes = [String: String]()
    if colspan > 0 {
        attributes["colspan"] = colspan.description
    }
    if rowspan > 0 {
        attributes["rowspan"] = rowspan.description
    }
    if let className {
        attributes["class"] = consume className
    }
    return .element(.tr, attributes: attributes, children: children)
}

func td(colspan: UInt = 0, rowspan: UInt = 0, class className: consuming String? = nil, children: [HTMLElement]) -> HTMLElement {
    var attributes = [String: String]()
    if colspan > 0 {
        attributes["colspan"] = colspan.description
    }
    if rowspan > 0 {
        attributes["rowspan"] = rowspan.description
    }
    if let className {
        attributes["class"] = consume className
    }
    return .element(.tr, attributes: attributes, children: children)
}

// Forms

package func label(@HTMLBuilder _ children: () -> [HTMLElement]) -> HTMLElement {
    .element(.label, children: children())
}

package func input(attributes: consuming [String: String]) -> HTMLElement {
    .voidElement(.input, attributes: consume attributes)
}

package func fieldset(@HTMLBuilder _ children: () -> [HTMLElement]) -> HTMLElement {
    .element(.fieldset, children: children())
}

// FIXME: This should be private
package extension HTMLElement {
    enum Tag: UInt8 {
        case html
        
        // Metadata
        
        case head
        case title
        case style
        case base // a void element
        case link // a void element
        case meta // a void element
        
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
        case hr // a void-element
        
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
        case br  // a void-element
        case wbr // a void-element
        
        // Embedded
        
        case picture
        case iframe
        case object
        case video
        case audio
        case map
        case source // a void-element
        case img    // a void-element
        case embed  // a void-element
        case track  // a void-element
        case area   // a void-element
        
        // Tables
        
        case table
        case caption
        case colgroup
        case col // a void-element
        case tbody
        case thead
        case tfoot
        case tr
        case td
        case th
        
        // Forms
        
        case form
        case label
        case input // a void-element
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
}

private extension HTMLElement.Tag {
    var isVoid: Bool {
        switch self {
            case .base, .link, .meta,                  // Metadata
                 .hr,                                  // Grouping
                 .br, .wbr,                            // Text-level semantics
                 .source, .img, .embed, .track, .area, // Embedded
                 .col,                                 // Tables
                 .input:                               // Forms
                     true
            default: false
        }
    }
    
    // FIXME: USE THIS!
    var canPrettyPrintInline: Bool {
        // Our pretty printer can include any "text-level semantic" tag inline
        Self.a.rawValue <= self.rawValue && self.rawValue <= Self.wbr.rawValue
    }
    
    var name: StaticString {
        switch self {
            case .html:       "html"
            case .head:       "head"
            case .title:      "title"
            case .style:      "style"
            case .base:       "base"
            case .link:       "link"
            case .meta:       "meta"
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
            case .hr:         "hr"
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
            case .br:         "br"
            case .wbr:        "wbr"
            case .picture:    "picture"
            case .iframe:     "iframe"
            case .object:     "object"
            case .video:      "video"
            case .audio:      "audio"
            case .map:        "map"
            case .source:     "source"
            case .img:        "img"
            case .embed:      "embed"
            case .track:      "track"
            case .area:       "area"
            case .table:      "table"
            case .caption:    "caption"
            case .colgroup:   "colgroup"
            case .col:        "col"
            case .tbody:      "tbody"
            case .thead:      "thead"
            case .tfoot:      "tfoot"
            case .tr:         "tr"
            case .td:         "td"
            case .th:         "th"
            case .form:       "form"
            case .label:      "label"
            case .input:      "input"
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
            case .address, .article, .aside, .blockquote, .details, .dialog, .div, .dl, .fieldset, .figcaption, .figure, .footer, .form, .h1, .h2, .h3, .h4, .h5, .h6, .hgroup, .hr, .main, .menu, .nav, .ol, .p, .pre, .search, .section, .table, .ul, nil:
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
            next == .optgroup || next == .hr || next == nil
            
        case .option:
            next == .option || next == .optgroup || next == .hr || next == nil
            
        default:
            false
        }
    }
}
