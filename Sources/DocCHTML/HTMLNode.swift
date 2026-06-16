/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2026 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 See https://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

package struct HTMLNode: Sendable {
    // This type should be though of as opaque with a file-private implementation.
    // However, to avoid needing to define the formatting and parsing of HTML all in this file,
    // it's implementation is accessible within this module.
    
    typealias _Attributes = [String: String]
    
    enum _Storage {
        case text(String)
        // We intentionally don't model comments because we don't want them to appear in the output.
        case element(    _Tag, attributes: _Attributes, contents: [HTMLNode])
        case voidElement(_Tag, attributes: _Attributes)
    }
    var _storage: _Storage
    
    /// Creates a new HTML text node.
    package static func text(_ text: consuming String) -> HTMLNode {
        .init(_storage: .text(text))
    }

    static func _element(_ tag: _Tag, attributes: _Attributes = [:], contents: [HTMLNode]) -> HTMLNode {
        assert(!tag.isVoid, "Cannot create an element using void tag '\(tag)'. Use `.voidElement(...)` instead.")
        assert(attributes.keys.count == Set(attributes.keys.map { $0.lowercased() }).count, "All attribute names has to be case insensitively unique. This wasn't true for ...")
//        assert(tag == .body || contents.allSatisfy { $0.elementTag == nil || tag.canOmitEndTag(whenFollowedBy: $0.elementTag) == false }, "Element '\(tag.name)' cannot contain ...")
//        assert(tag.isVoid || !attributes.isEmpty || !contents.isEmpty, "Tag '\(tag.name)' is unexpectedly empty (no attributes and no members).")
        return .init(_storage: .element(tag, attributes: attributes, contents: contents))
    }
    
    static func _voidElement(_ tag: _Tag, attributes: _Attributes = [:]) -> HTMLNode {
        assert(tag.isVoid, "")
        return .init(_storage: .voidElement(tag, attributes: attributes))
    }
    
    mutating func addClass(_ className: consuming String) {
        switch _storage {
            case .element(let tag, var attributes, let contents):
                attributes.appendClassName(consume className)
                _storage = .element(tag, attributes: attributes, contents: contents)
                
            case .voidElement(let tag, var attributes):
                attributes.appendClassName(consume className)
                _storage = .voidElement(tag, attributes: attributes)
                
            case .text:
                break
        }
    }
    
    mutating func addClassOrWrapInParagraphWithClass(_ className: String) {
        switch _storage {
            case .element(let tag, var attributes, let contents):
                attributes.appendClassName(className)
                _storage = .element(tag, attributes: attributes, contents: contents)
                
            case .voidElement(let tag, var attributes):
                attributes.appendClassName(className)
                _storage = .voidElement(tag, attributes: attributes)
                
            case .text(let text):
                _storage = .element(.p, attributes: ["class": className], contents: [.text(text)])
        }
    }
    
    mutating func wrapInParagraphIfTextElement() {
        if case .text(let text) = _storage {
            _storage = .element(.p, attributes: [:], contents: [.text(text)])
        }
    }
    
    package var idAttribute: String? {
        get {
            switch _storage {
            case .element(_, let attributes, _), .voidElement(_, let attributes):
                attributes["id"]
            case .text:
                nil
            }
        }
        set {
            switch _storage {
            case .element(let tag, var attributes, let contents):
                attributes["id"] = newValue
                _storage = .element(tag, attributes: attributes, contents: contents)
            case .voidElement(let tag, var attributes):
                attributes["id"] = newValue
                _storage = .voidElement(tag, attributes: attributes)
            case .text:
                break
            }
        }
    }
    
    var _tag: _Tag? {
        if case .element(let tag, _, _) = _storage {
            tag
        } else {
            nil
        }
    }
    
    package var isSection: Bool {
        _tag == .section
    }
    
    var _isElement: Bool {
        if case .element = _storage {
            true
        } else {
            false
        }
    }
}

private extension HTMLNode._Attributes {
    mutating func appendClassName(_ className: consuming String) {
        if var existing = removeValue(forKey: "class") {
            existing.append(" ")
            existing.append(contentsOf: className)
            self["class"] = existing
        } else {
            self["class"] = className
        }
    }
}

private extension HTMLNode._Tag {
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
}
