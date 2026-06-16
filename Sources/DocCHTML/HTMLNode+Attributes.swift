/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2026 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 See https://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

extension HTMLNode {
    package enum Attribute {
        // MARK: Global attributes
        
        /// A hint for the browser to generate a keyboard shortcut for the current element.
        ///
        /// Browsers should use the first character that's found on the user's keyboard layout.
        case accessKey([UnicodeScalar])
        /// An hint for autocapitalization behavior of the element.
        case autoCapitalize(AutoCapitalize)
        /// The autocorrection behavior for the element.
        case autoCorrect(Bool)
        /// An indication that browser it to focus the element as soon as the page is loaded, allowing the user to just start typing without having to manually focus the element.
        case autoFocus
        /// A list of classes for the element.
        case `class`([String])
        /// A configuration that controls whether or not the element is editable.
        case contentEditable(ContentEditable)
        /// The text direction of the element.
        case dir(Dir)
        /// A configuration that controls whether or not the element is draggable.
        case draggable(Bool)
        /// A configuration of what action label (or icon) the browser should present for the "enter key" on virtual keyboards.
        case enterKeyHint(EnterKeyHint)
        /// An offset for the heading levels of descendants of the element.
        ///
        /// According to the HTML specification, the value must be a valid non-negative integer between 0 and 8, inclusive.
        case headingOffset(Int)
        /// Prevents a heading offset from traversing beyond this element.
        case headingReset
        /// An indication that the element is not yet, or is no longer, directly relevant to the page's current state,
        /// or that it is being used to declare content to be reused by other parts of the page as opposed to being directly accessed by the user.
        case hidden(Hidden)
        /// A configuration that controls whether or not the element is inert (cannot be interacted with).
        case inert
        /// A hint to browsers about the type of virtual keyboard to use when editing this element.
        case inputMode(InputMode)
        // We're excluding the `is` attribute for custom HTML elements.
        // We're excluding the various `item...` attributes for HTML "items".
        
        /// The language that a non-editable element is in, or the language that an editable element should be written in by the user.
        ///
        /// According to the HTML specification, the attribute should contain a valid BCP 47 language tag.
        case lang(String)
        /// A cryptographic nonce ("number used once") which can be used by Content Security Policy to determine whether or not a given fetch will be allowed to proceed.
        case nonce(String)
        /// Designates the element as a "popover" that is hidden until it opened via an invoking element.
        case popover
        /// Defines the semantic meaning of an element.
        case role(Role)
        // We're excluding the `slot` attribute for the shadow DOM.
        
        /// A configuration that controls whether or not the element is spellchecked.
        case spellcheck(Bool)
        // We're excluding the `style` attribute for inline CSS.
        
        /// A configuration that controls whether or not the element is sequentially focusable and determines its relative oder in the sequential navigation.
        ///
        /// A negative value means that the element is _click_ focusable but not _sequentially_ focusable.
        /// A positive value means that the element is both _click_ focusable and _sequentially_ focusable and creates a relative ordering so that higher values come later.
        case tabIndex(Int)
        /// Advisory information for the element, such as would be appropriate for a tooltip.
        case title(String)
        /// A configuration that controls whether the element's text is to be translated when the page is localized, or whether to leave them unchanged.
        case translate(Bool)
        /// A configuration that controls whether the browser should offer writing suggestions for this element.
        case writingSuggestions(Bool)
        
        /// A value for the ``HTMLNode/Attribute/autocapitalize(_:)`` attribute.
        package enum AutoCapitalize: String {
            /// No autocapitalization should be applied (all letters should default to lowercase).
            case none
            /// The first letter of each sentence should default to a capital letter; all other letters should default to lowercase.
            case sentences
            /// The first letter of each word should default to a capital letter; all other letters should default to lowercase.
            case words
            /// All letters should default to uppercase.
            case characters
        }
        
        /// A value for the ``HTMLNode/Attribute/contentEditable(_:)`` attribute.
        package enum ContentEditable: String {
            /// The element is editable.
            case `true`
            /// The element is not editable.
            case `false`
            /// Only the element's raw text content is editable; rich formatting is disabled.
            case plaintextOnly = "plaintext-only"
        }
        
        /// A value for the ``HTMLNode/Attribute/dir(_:)`` attribute.
        package enum Dir: String {
            /// The contents of the element are explicitly directionally isolated left-to-right text.
            case ltr
            /// The contents of the element are explicitly directionally isolated right-to-left text.
            case rtl
            /// The contents of the element are explicitly directionally isolated text, but the direction is to be determined programmatically using the contents of the element.
            case auto
        }
        
        /// A value for the ``HTMLNode/Attribute/enterKeyHint(_:)`` attribute.
        package enum EnterKeyHint: String {
            /// The browser should present a cue for the operation 'enter', typically inserting a new line.
            case enter
            /// The browser should present a cue for the operation 'done', typically meaning there is nothing more to input and the input method editor (IME) will be closed.
            case done
            /// The browser should present a cue for the operation 'go', typically meaning to take the user to the target of the text they typed.
            case go
            /// The browser should present a cue for the operation 'next', typically taking the user to the next field that will accept text.
            case next
            /// The browser should present a cue for the operation 'previous', typically taking the user to the previous field that will accept text.
            case previous
            /// The browser should present a cue for the operation 'search', typically taking the user to the results of searching for the text they have typed.
            case search
            /// The browser should present a cue for the operation 'send', typically delivering the text to its target.
            case send
        }
        
        /// A value for the ``HTMLNode/Attribute/hidden(_:)`` attribute.
        package enum Hidden: String {
            /// The element is will not be rendered
            ///
            /// Can either be represented as an explicit "hidden" value or as an empty value.
            case hidden     = ""
            /// The element is will not be rendered, but content inside will be accessible to find-in-page and fragment navigation.
            case untilFound = "until-found"
        }
        
        /// A value for the ``HTMLNode/Attribute/inputMode(_:)`` attribute.
        package enum InputMode: String {
            /// The browser should not display any virtual keyboard
            case none
            /// The browser should display a keyboard for text input.
            case text
            /// The browser should display a keyboard for telephone number input.
            case tel
            /// The browser should display a keyboard for text input with keys for aiding the input of URLs.
            case url
            /// The browser should display a keyboard for text input with keys for aiding the input of email addresses.
            case email
            /// The browser should display a keyboard for numeric input.
            case numeric
            /// The browser should display a keyboard for fractional numeric input.
            case decimal
            /// The browser should display a keyboard for search.
            case search
        }
        
        /// A value for the ``HTMLNode/Attribute/role(_:)`` attribute.
        package enum Role: String {
            // Document structure roles
            
            case toolbar
            case tooltip
            case feed
            case math
            case presentation
            case note
            case application
            @available(*, deprecated, message: "Use a <article> element instead.")
            case article
            @available(*, deprecated, message: "Use a <td> element instead.")
            case cell
            @available(*, deprecated, message: "Use a <th scope=col> element instead.")
            case columnHeader = "columnheader"
            @available(*, deprecated, message: "Use a <dfn> element instead.")
            case definition
            case directory
            case document
            @available(*, deprecated, message: "Use a <figure> element instead.")
            case figure
            case group
            @available(*, deprecated, message: "Use a <h1> - <h6> element instead.")
            case heading
            @available(*, deprecated, message: "Use a <img> element instead.")
            case img
            @available(*, deprecated, message: "Use a <ul> or <ol> element instead.")
            case list
            @available(*, deprecated, message: "Use a <li> element instead.")
            case listItem = "listitem"
            @available(*, deprecated, message: "Use a <meter> element instead.")
            case meter
            @available(*, deprecated, message: "Use a <tr> element instead.")
            case row
            @available(*, deprecated, message: "Use a <thead>, <hody>, or <tfoot> element instead.")
            case rowGroup  = "rowgroup"
            @available(*, deprecated, message: "Use a <th scope=row> element instead.")
            case rowHeader = "rowheader"
            @available(*, deprecated, message: "Use a <hr> element instead.")
            case separator
            @available(*, deprecated, message: "Use a <table> element instead.")
            case table
            @available(*, deprecated, message: "Use a <dfn> element instead.")
            case term
            
            // Widget roles
            
            case scrollbar
            case searchBox = "searchBox"
            case slider
            case spinButton = "spinbutton"
            case `switch`
            case tab
            case tabPanel = "tabpanel"
            case treeItem = "treeitem"
            
            // Landmark roles
            
            @available(*, deprecated, message: "Use a <header> element instead.")
            case banner
            @available(*, deprecated, message: "Use a <aside> element instead.")
            case complementary
            @available(*, deprecated, message: "Use a <footer> element instead.")
            case contentInfo = "contentinfo"
            @available(*, deprecated, message: "Use a <form> element instead.")
            case form
            @available(*, deprecated, message: "Use a <main> element instead.")
            case main
            @available(*, deprecated, message: "Use a <nav> element instead.")
            case navigation
            @available(*, deprecated, message: "Use a <section> element instead.")
            case region
            @available(*, deprecated, message: "Use a <search> element instead.")
            case search
            
            // Live region roles
            
            case alert
            case log
            case marquee
            case status
            case timer
            
            // Window roles
            
            case alertDialog = "alertDialog"
            case dialog
        }
        
        // MARK: Meta attributes
        
        /// Declares the document's character encoding to be UTF-8; which  is the only valid encoding for HTML5 documents.
        case utf8CharSet
        
        
        case name(String)
        case contents(String)
        
        // MARK: Element-specific attributes
        
        /// Configures the browser to tread `<a>` element's linked URL as a download.
        case download
        /// The URL that the `<a>` element links to.
        case href(String)
        /// A hint at the human language of the linked URL
        case hrefLang(String)
        /// How much information the browser should send in a referrer header when following the link.
        case referrerPolicy(ReferrerPolicy)
        /// A list of the types of that the linked URL ...
        case rel([LinkType])

        
        
        /// A value for the ``HTMLNode/Attribute/referrerPolicy(_:)`` attribute.
        package enum ReferrerPolicy: String {
            /// The browser should not send a referrer header.
            case noReferrer = "no-referrer"
            /// The browser should not send a referrer header. to origins without TLS (HTTPS).
            case noReferrerWhenDowngrade = "no-referrer-when-downgrade"
            /// The browser should limit the referrer information to the origin of the referring page: its scheme, host, and port.
            case origin
            /// The browser should limit the referrer information to the origin of the referring page: its scheme, host, and port. Navigations on the same origin should still include the path.
            case originWhenCrossOrigin = "origin-when-cross-origin"
            /// The browser should send referred information for the same origin, but cross-origin requests should contain no referrer information.
            case sameOrigin = "same-origin"
            // Only send the origin of the document as the referrer when the protocol security level stays the same (HTTPS→HTTPS), but don't send it to a less secure destination (HTTPS→HTTP).
            
            case strictOrigin = "strict-origin"
            // Send a full URL when performing a same-origin request, only send the origin when the protocol security level stays the same (HTTPS→HTTPS), and send no header to a less secure destination (HTTPS→HTTP).
            case strictOriginWhenCrossOrigin = "strict-origin-when-cross-origin"
            
            @available(*, deprecated, message: "This policy is unsafe because it leaks origins and paths from TLS-protected resources to insecure origins.")
            case unsafeURL = "unsafe-url"
        }
        
        package enum LinkType: String {
            case fixme
        }
    }
}

extension HTMLNode.Attribute {
    var name: StaticString {
        switch self {
            case .accessKey:          "accesskey"
            case .autoCapitalize:     "autocapitalize"
            case .autoCorrect:        "autocorrect"
            case .autoFocus:          "autofocus"
            case .class:              "class"
            case .contentEditable:    "contenteditable"
            case .dir:                "dir"
            case .draggable:          "draggable"
            case .enterKeyHint:       "enterkeyhint"
            case .headingOffset:      "headingoffset"
            case .headingReset:       "headingreset"
            case .hidden:             "hidden"
            case .inert:              "inert"
            case .inputMode:          "inputmode"
            case .lang:               "lang"
            case .nonce:              "nonce"
            case .popover:            "popover"
            case .role:               "role"
            case .spellcheck:         "spellcheck"
            case .tabIndex:           "tabindex"
            case .title:              "title"
            case .translate:          "translate"
            case .writingSuggestions: "writingsuggestions"
            case .utf8CharSet:        "charset"
            case .name:               "name"
            case .contents:           "contents"
            case .download:           "download"
            case .href:               "href"
            case .hrefLang:           "hreflang"
            case .referrerPolicy:     "referrerpolicy"
            case .rel:                "rel"
        }
    }
    
    var value: String {
        switch self {
            // Global attributes
            case .accessKey(let keys):             keys.map { String(Character($0)) }.joined(separator: " ")
            case .autoCapitalize(let value):       value.rawValue
            case .autoCorrect(let enabled):        enabled ? "on" : "off"
            case .autoFocus:                       "" // A "boolean" attribute
            case .class(let classNames):           classNames.joined(separator: " ")
            case .contentEditable(let value):      value.rawValue
            case .dir(let value):                  value.rawValue
            case .draggable(let enabled):          enabled ? "true" : "false"
            case .enterKeyHint(let value):         value.rawValue
            case .headingOffset(let number):       min(0, max(8, number)).description
            case .headingReset:                    "" // A "boolean" attribute
            case .hidden(let value):               value.rawValue
            case .inert:                           "" // A "boolean" attribute
            case .inputMode(let value):            value.rawValue
            case .lang(let string):                string
            case .nonce(let string):               string
            case .popover:                         "" // A "boolean" attribute
            case .role(let value):                 value.rawValue
            case .spellcheck(let enabled):         enabled ? "true" : "false"
            case .tabIndex(let number):            number.description
            case .title(let string):               string
            case .translate(let enabled):          enabled ? "yes" : "no"
            case .writingSuggestions(let enabled): enabled ? "true" : "false"
                
            // Meta attributes
            case .utf8CharSet:                     "utf-8" // There's only one valid HTML 5 character encoding.
            case .name(let string):                string
            case .contents(let string):            string
            
            // Element-specific attributes
            case .download:                        "" // A "boolean" attribute
            case .href(let string):                string
            case .hrefLang(let string):            string
            case .referrerPolicy(let value):       value.rawValue
            case .rel(let values):                 values.map(\.rawValue).joined(separator: " ")
            
            
        }
    }
}
