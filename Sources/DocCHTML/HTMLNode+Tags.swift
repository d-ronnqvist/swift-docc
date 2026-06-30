/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2026 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 See https://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

@resultBuilder
package struct HTMLBuilder {
    
    package typealias Component = [HTMLNode]
    
    package static func buildExpression(_ expression: consuming HTMLNode) -> Component {
        [ expression ]
    }
    
    package static func buildExpression(_ expression: consuming HTMLNode?) -> Component {
        expression.map { [$0] } ?? []
    }

    // Support transforming strings into HTML text elements.
    package static func buildExpression(_ text: consuming String) -> Component {
        [ .text(text) ]
    }
    
    /// Support `if` statements without an `else` statement.
    package static func buildOptional(_ component: consuming Component?) -> Component { component ?? [] }

    /// Support `if-else` and `switch` statements.
    package static func buildEither(first  component: consuming Component) -> Component { component }
    package static func buildEither(second component: consuming Component) -> Component { component }
    
    /// Support `for-in` loops
    package static func buildArray(_ components: consuming [Component]) -> Component {
        components.flatMap { $0 }
    }
    
    package static func buildPartialBlock(first: HTMLNode) -> Component {
        [first]
    }
    package static func buildPartialBlock(first: Component) -> Component {
        first
    }
    package static func buildPartialBlock(first: Component?) -> Component {
        first ?? []
    }
    package static func buildPartialBlock(first: consuming [Component]) -> Component {
        guard !first.isEmpty else {
            return []
        }
        var copy = consume first
        let capacity = copy.reduce(0) { acc, element in acc + element.count }
        var result = copy.removeFirst()
        result.reserveCapacity(capacity)
        for chunk in copy {
            result.append(contentsOf: chunk)
        }
        return result
    }
    
    package static func buildPartialBlock(accumulated: consuming Component, next: HTMLNode) -> Component {
        var copy = consume accumulated
        copy.append(next)
        return copy
    }
    package static func buildPartialBlock(accumulated: consuming Component, next: consuming Component) -> Component {
        var copy = consume accumulated
        copy.append(contentsOf: next)
        return copy
    }
    package static func buildPartialBlock(accumulated: consuming Component, next: consuming Component?) -> Component {
        guard let next else {
            return accumulated
        }
        var copy = consume accumulated
        copy.append(contentsOf: next)
        return copy
    }
    static func buildPartialBlock(accumulated: consuming Component, next: consuming [ Component ]) -> Component {
        var copy = consume accumulated
        for n in next {
            copy.append(contentsOf: n)
        }
        return copy
    }
}

// MARK: Tags

// This only defined functions for the HTML elements that we've needed to create so far,
// with only the parameters that we've needed to pass so far.
// If you need another element you can add a new function here, following the style of the other functions.
// If you need to pass new information to an existing element you can add a new parameter with a default value to that element's corresponding function.

package func html(_ attributes: HTMLNode.Attribute..., @HTMLBuilder contents: () -> [HTMLNode]) -> HTMLNode {
    ._element(.html, attributes: consume attributes , contents: contents())
}

// MARK Metadata

package func head(@HTMLBuilder _ contents: () -> [HTMLNode]) -> HTMLNode {
    ._element(.head, contents: contents())
}

package func title(_ title: consuming String) -> HTMLNode {
    ._element(.title, contents: [.text(consume title)])
}

package func link(_ attributes: HTMLNode.Attribute...) -> HTMLNode {
    ._voidElement(.link, attributes: consume attributes)
}

package func meta(_ attributes: HTMLNode.Attribute...) -> HTMLNode {
    ._voidElement(.meta, attributes: consume attributes)
}

// Sections

package func body(@HTMLBuilder _ contents: () -> [HTMLNode]) -> HTMLNode {
    ._element(.body, contents: contents())
}

package func article(_ attributes: HTMLNode.Attribute..., @HTMLBuilder contents: () -> [HTMLNode]) -> HTMLNode {
    ._element(.article, attributes: attributes, contents: contents())
}
package func article(_ attributes: consuming [HTMLNode.Attribute] = [], contents: [HTMLNode]) -> HTMLNode {
    ._element(.article, attributes: attributes, contents: contents)
}

package func section(_ attributes: [HTMLNode.Attribute], @HTMLBuilder contents: () -> [HTMLNode]) -> HTMLNode {
    ._element(.section, attributes: attributes, contents: contents())
}
func section(_ attributes: consuming [HTMLNode.Attribute] = [], contents: [HTMLNode]) -> HTMLNode {
    ._element(.section, attributes: attributes, contents: contents)
}

package func nav(_ attributes: HTMLNode.Attribute..., @HTMLBuilder contents: () -> [HTMLNode]) -> HTMLNode {
    ._element(.nav, attributes: attributes, contents: contents())
}
func nav(_ attributes: consuming [HTMLNode.Attribute] = [], contents: [HTMLNode]) -> HTMLNode {
    ._element(.nav, attributes: attributes, contents: contents)
}

package func aside(_ attributes: HTMLNode.Attribute..., @HTMLBuilder contents: () -> [HTMLNode]) -> HTMLNode {
    ._element(.aside, attributes: attributes, contents: contents())
}
package func aside(_ attributes: consuming [HTMLNode.Attribute] = [], contents: [HTMLNode]) -> HTMLNode {
    ._element(.aside, attributes: attributes, contents: contents)
}

package func h1(_ attributes: HTMLNode.Attribute..., @HTMLBuilder contents: () -> [HTMLNode]) -> HTMLNode {
    ._element(.h1, attributes: attributes, contents: contents())
}
package func h1(_ attributes: consuming [HTMLNode.Attribute] = [], contents: [HTMLNode]) -> HTMLNode {
    ._element(.h1, attributes: attributes, contents: contents)
}

package func h2(_ text: String) -> HTMLNode {
    ._element(.h2, contents: [.text(text)])
}
package func h2(_ attributes: HTMLNode.Attribute..., @HTMLBuilder contents: () -> [HTMLNode]) -> HTMLNode {
    ._element(.h2, attributes: attributes, contents: contents())
}
package func h2(_ attributes: consuming [HTMLNode.Attribute] = [], contents: [HTMLNode]) -> HTMLNode {
    ._element(.h2, attributes: attributes, contents: contents)
}

func heading(level: Int, _ attributes: HTMLNode.Attribute..., contents: [HTMLNode]) -> HTMLNode {
    let tag: HTMLNode._Tag = switch level {
        case 1:  .h1
        case 2:  .h2
        case 3:  .h3
        case 4:  .h4
        case 5:  .h5
        default: .h6
    }
    return ._element(tag, attributes: attributes, contents: contents)
}


package func hgroup(_ attributes: HTMLNode.Attribute..., @HTMLBuilder contents: () -> [HTMLNode]) -> HTMLNode {
    ._element(.hgroup, attributes: attributes, contents: contents())
}

package func header(_ attributes: HTMLNode.Attribute..., @HTMLBuilder contents: () -> [HTMLNode]) -> HTMLNode {
    ._element(.header, attributes: attributes, contents: contents())
}

package func footer(_ attributes: HTMLNode.Attribute..., @HTMLBuilder contents: () -> [HTMLNode]) -> HTMLNode {
    ._element(.footer, attributes: attributes, contents: contents())
}

// Grouping

package func p(_ attributes: HTMLNode.Attribute..., @HTMLBuilder contents: () -> [HTMLNode]) -> HTMLNode {
    ._element(.p, attributes: attributes, contents: contents())
}
func p(_ attributes: consuming [HTMLNode.Attribute] = [], contents: [HTMLNode]) -> HTMLNode {
    ._element(.p, attributes: attributes, contents: contents)
}

package func pre(_ attributes: HTMLNode.Attribute..., @HTMLBuilder contents: () -> [HTMLNode]) -> HTMLNode {
    ._element(.pre, attributes: attributes, contents: contents())
}
func pre(_ attributes: [HTMLNode.Attribute] = [], contents: [HTMLNode]) -> HTMLNode {
    ._element(.pre, attributes: attributes, contents: contents)
}

package func ol(_ attributes: HTMLNode.Attribute..., @HTMLBuilder contents: () -> [HTMLNode]) -> HTMLNode {
    ol(attributes, contents: contents())
}
func ol(_ attributes: consuming [HTMLNode.Attribute] = [], contents: [HTMLNode]) -> HTMLNode {
    assert(contents.allSatisfy { $0._tag == .li }, "<ol> tags can only contain <li> tags")
    return ._element(.ol, attributes: attributes, contents: contents)
}

package func ul(_ attributes: HTMLNode.Attribute..., @HTMLBuilder contents: () -> [HTMLNode]) -> HTMLNode {
    ul(attributes, contents: contents())
}
func ul(_ attributes: consuming [HTMLNode.Attribute] = [], contents: [HTMLNode]) -> HTMLNode {
    assert(contents.allSatisfy { $0._tag == .li }, "<ul> tags can only contain <li> tags")
    return ._element(.ul, attributes: attributes, contents: contents)
}

package func li(_ attributes: HTMLNode.Attribute..., @HTMLBuilder contents: () -> [HTMLNode]) -> HTMLNode {
    ._element(.li, attributes: attributes, contents: contents())
}
func li(attributes: consuming [HTMLNode.Attribute] = [], contents: [HTMLNode]) -> HTMLNode {
    ._element(.li, attributes: attributes, contents: contents)
}

package func dl(_ attributes: HTMLNode.Attribute..., @HTMLBuilder contents: () -> [HTMLNode]) -> HTMLNode {
    dl(attributes, contents: contents())
}
func dl(_ attributes: consuming [HTMLNode.Attribute] = [], contents: [HTMLNode]) -> HTMLNode {
    assert(contents.allSatisfy { $0._tag == .dt || $0._tag == .dd }, "<dl> tags can only contain <dt> and <dt> tags")
    return ._element(.dl, contents: contents)
}

func dt(_ attributes: HTMLNode.Attribute..., contents text: consuming String) -> HTMLNode {
    ._element(.dt, attributes: attributes, contents: [.text(consume text)])
}

func dd(_ attributes: HTMLNode.Attribute..., contents: [HTMLNode]) -> HTMLNode {
    ._element(.dd, attributes: attributes, contents: contents)
}

package let hr = HTMLNode._voidElement(.hr)

// Text-level semantics

package func a(_ attributes: HTMLNode.Attribute..., @HTMLBuilder contents: () -> [HTMLNode]) -> HTMLNode {
    a(attributes, contents: contents())
}
func a(_ attributes: consuming [HTMLNode.Attribute] = [], contents: [HTMLNode]) -> HTMLNode {
    return ._element(.a, attributes: attributes, contents: contents)
}

func s(contents: [HTMLNode]) -> HTMLNode {
    ._element(.s, contents: contents)
}

package func code(_ attributes: HTMLNode.Attribute..., @HTMLBuilder contents: () -> [HTMLNode]) -> HTMLNode {
    code(attributes, contents: contents())
}
func code(_ attributes: [HTMLNode.Attribute] = [], contents: [HTMLNode]) -> HTMLNode {
    ._element(.code, attributes: attributes, contents: contents)
}

func i(contents: [HTMLNode]) -> HTMLNode {
    ._element(.i, contents: contents)
}

func b(contents: [HTMLNode]) -> HTMLNode {
    ._element(.b, contents: contents)
}

package func span(_ attributes: HTMLNode.Attribute..., @HTMLBuilder contents: () -> [HTMLNode]) -> HTMLNode {
    span(attributes, contents: contents())
}
func span(_ attributes: consuming [HTMLNode.Attribute], contents: [HTMLNode]) -> HTMLNode {
    ._element(.span, attributes: attributes, contents: contents)
}

package let br = HTMLNode._voidElement(.br)

package let wbr = HTMLNode._voidElement(.wbr)

// Embedded

package func picture(@HTMLBuilder contents: () -> [HTMLNode]) -> HTMLNode {
    picture(contents: contents())
}
func picture(contents: [HTMLNode]) -> HTMLNode {
    ._element(.picture, contents: contents)
}

func img(attributes: consuming [HTMLNode.Attribute]) -> HTMLNode {
    ._voidElement(.img, attributes: consume attributes)
}

func source(attributes: consuming [HTMLNode.Attribute]) -> HTMLNode {
    ._voidElement(.source, attributes: consume attributes)
}

// Tables

func table(contents: [HTMLNode]) -> HTMLNode {
    ._element(.table, contents: contents)
}

func thead(contents: [HTMLNode]) -> HTMLNode {
    assert(contents.allSatisfy { $0._tag == .tr }, "<thead> tags can only contain <tr> tags")
    return ._element(.thead, contents: contents)
}

func tbody(contents: [HTMLNode]) -> HTMLNode {
    assert(contents.allSatisfy { $0._tag == .tr }, "<thead> tags can only contain <tr> tags")
    return ._element(.tbody, contents: contents)
}

func tr(contents: [HTMLNode]) -> HTMLNode {
    assert(contents.allSatisfy { $0._tag == .td || $0._tag == .th }, "<tr> tags can only contain <td> and <th> tags")
    return ._element(.tr, contents: contents)
}

func th(colspan: UInt = 0, rowspan: UInt = 0, class className: consuming String? = nil, contents: [HTMLNode]) -> HTMLNode {
    var attributes = [HTMLNode.Attribute]()
    if colspan > 1 {
        attributes.append(.colSpan(colspan))
    }
    if rowspan > 1 {
        attributes.append(.rowSpan(rowspan))
    }
    if let className {
        attributes.append(.class(consume className))
    }
    return ._element(.th, attributes: attributes, contents: contents)
}

func td(colspan: UInt = 0, rowspan: UInt = 0, class className: consuming String? = nil, contents: [HTMLNode]) -> HTMLNode {
    var attributes = [HTMLNode.Attribute]()
    if colspan > 1 {
        attributes.append(.colSpan(colspan))
    }
    if rowspan > 1 {
        attributes.append(.rowSpan(rowspan))
    }
    if let className {
        attributes.append(.class(consume className))
    }
    return ._element(.td, attributes: attributes, contents: contents)
}

// Forms

package func label(@HTMLBuilder _ contents: () -> [HTMLNode]) -> HTMLNode {
    ._element(.label, contents: contents())
}

package func input(_ attributes: HTMLNode.Attribute...) -> HTMLNode {
    ._voidElement(.input, attributes: attributes)
}

package func fieldset(role: consuming HTMLNode.Attribute.Role, @HTMLBuilder _ contents: () -> [HTMLNode]) -> HTMLNode {
    ._element(.fieldset, attributes: [.role(role)], contents: contents())
}

package func legend(_ text: consuming String) -> HTMLNode {
    ._element(.legend, contents: [.text(text)])
}


private func makeAttributes(id: consuming String? = nil, class classNames: consuming String? = nil) -> [String: String] {
    var attributes = [String: String]()
    if let id {
        attributes["id"] = id
    }
    if let classNames {
        attributes["class"] = classNames
    }
    return attributes
}

extension HTMLNode {
    enum _Tag: UInt8 {
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

extension HTMLNode._Tag {
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
}
