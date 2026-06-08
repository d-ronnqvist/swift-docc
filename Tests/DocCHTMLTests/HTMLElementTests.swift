/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2026 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 See https://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

import Foundation
import Testing
@testable import DocCHTML
import DocCCommon

struct HTMLElementTests {
    
    @Test
    func encodingHTMLStructure() {
        #expect(htmlString(for: element) == """
        <section><nav id="breadcrumbs"><ul><li>Swift</li><li>Int</li><li>random(in:using:)</li></ul></nav><hgroup><p>Type Method</p><h1>random(<wbr>in:<wbr>using:)</h1></hgroup><p>Returns a random value within the specified range, using the given generator as a source for randomness.</p><ul id="availability"><li title="Available on iOS 8.0 and later">iOS 8.0+</li></ul><pre id="declaration"><code><span class="keyword">static</span> <span class="keyword">func</span> random&lt;T&gt;(
            in <span class="internalParameter">range</span>...</code></pre></section>
        """)
        
        #expect(htmlString(for: element, options: .omitQuotingSingleWordAttributeValues) == """
        <section><nav id=breadcrumbs><ul><li>Swift</li><li>Int</li><li>random(in:using:)</li></ul></nav><hgroup><p>Type Method</p><h1>random(<wbr>in:<wbr>using:)</h1></hgroup><p>Returns a random value within the specified range, using the given generator as a source for randomness.</p><ul id=availability><li title="Available on iOS 8.0 and later">iOS 8.0+</li></ul><pre id=declaration><code><span class=keyword>static</span> <span class=keyword>func</span> random&lt;T&gt;(
            in <span class=internalParameter>range</span>...</code></pre></section>
        """)
        
        #expect(htmlString(for: element, options: .omitAllowedEndTags) == """
        <section><nav id="breadcrumbs"><ul><li>Swift<li>Int<li>random(in:using:)</ul></nav><hgroup><p>Type Method<h1>random(<wbr>in:<wbr>using:)</h1></hgroup><p>Returns a random value within the specified range, using the given generator as a source for randomness.<ul id="availability"><li title="Available on iOS 8.0 and later">iOS 8.0+</ul><pre id="declaration"><code><span class="keyword">static</span> <span class="keyword">func</span> random&lt;T&gt;(
            in <span class="internalParameter">range</span>...</code></pre></section>
        """)
        
        #expect(htmlString(for: element, options: [.omitQuotingSingleWordAttributeValues, .omitAllowedEndTags]) == """
        <section><nav id=breadcrumbs><ul><li>Swift<li>Int<li>random(in:using:)</ul></nav><hgroup><p>Type Method<h1>random(<wbr>in:<wbr>using:)</h1></hgroup><p>Returns a random value within the specified range, using the given generator as a source for randomness.<ul id=availability><li title="Available on iOS 8.0 and later">iOS 8.0+</ul><pre id=declaration><code><span class=keyword>static</span> <span class=keyword>func</span> random&lt;T&gt;(
            in <span class=internalParameter>range</span>...</code></pre></section>
        """)
    }
    
    @Test
    func prettyEncodingHTMLStructure() {
        #expect(htmlString(for: element, options: .prettyPrint) == """
        <section>
          <nav id="breadcrumbs">
            <ul>
              <li>Swift</li>
              <li>Int</li>
              <li>random(in:using:)</li>
            </ul>
          </nav>
          <hgroup>
            <p>Type Method</p>
            <h1>random(<wbr>in:<wbr>using:)</h1>
          </hgroup>
          <p>Returns a random value within the specified range, using the given generator as a source for randomness.</p>
          <ul id="availability">
            <li title="Available on iOS 8.0 and later">
              iOS 8.0+
            </li>
          </ul>
          <pre id="declaration"><code><span class="keyword">static</span> <span class="keyword">func</span> random&lt;T&gt;(
            in <span class="internalParameter">range</span>...</code></pre>
        </section>
        """)
        
        #expect(htmlString(for: element, options: [.prettyPrint, .omitQuotingSingleWordAttributeValues]) == """
        <section>
          <nav id=breadcrumbs>
            <ul>
              <li>Swift</li>
              <li>Int</li>
              <li>random(in:using:)</li>
            </ul>
          </nav>
          <hgroup>
            <p>Type Method</p>
            <h1>random(<wbr>in:<wbr>using:)</h1>
          </hgroup>
          <p>Returns a random value within the specified range, using the given generator as a source for randomness.</p>
          <ul id=availability>
            <li title="Available on iOS 8.0 and later">
              iOS 8.0+
            </li>
          </ul>
          <pre id=declaration><code><span class=keyword>static</span> <span class=keyword>func</span> random&lt;T&gt;(
            in <span class=internalParameter>range</span>...</code></pre>
        </section>
        """)
        
        #expect(htmlString(for: element, options: [.prettyPrint, .omitAllowedEndTags]) == """
        <section>
          <nav id="breadcrumbs">
            <ul>
              <li>Swift
              <li>Int
              <li>random(in:using:)
            </ul>
          </nav>
          <hgroup>
            <p>Type Method
            <h1>random(<wbr>in:<wbr>using:)</h1>
          </hgroup>
          <p>Returns a random value within the specified range, using the given generator as a source for randomness.
          <ul id="availability">
            <li title="Available on iOS 8.0 and later">
              iOS 8.0+
          </ul>
          <pre id="declaration"><code><span class="keyword">static</span> <span class="keyword">func</span> random&lt;T&gt;(
            in <span class="internalParameter">range</span>...</code></pre>
        </section>
        """)
        
        #expect(htmlString(for: element, options: [.prettyPrint, .omitQuotingSingleWordAttributeValues, .omitAllowedEndTags]) == """
        <section>
          <nav id=breadcrumbs>
            <ul>
              <li>Swift
              <li>Int
              <li>random(in:using:)
            </ul>
          </nav>
          <hgroup>
            <p>Type Method
            <h1>random(<wbr>in:<wbr>using:)</h1>
          </hgroup>
          <p>Returns a random value within the specified range, using the given generator as a source for randomness.
          <ul id=availability>
            <li title="Available on iOS 8.0 and later">
              iOS 8.0+
          </ul>
          <pre id=declaration><code><span class=keyword>static</span> <span class=keyword>func</span> random&lt;T&gt;(
            in <span class=internalParameter>range</span>...</code></pre>
        </section>
        """)
    }
    
    private let element = HTMLElement.element(.section) {
        HTMLElement.element(.nav, attributes: ["id": "breadcrumbs"]) {
            HTMLElement.element(.ul) {
                HTMLElement.element(.li) { "Swift" }
                HTMLElement.element(.li) { "Int" }
                HTMLElement.element(.li) { "random(in:using:)" }
            }
        }
        HTMLElement.element(.hgroup) {
            HTMLElement.element(.p) { "Type Method" }
            HTMLElement.element(.h1) {
                "random("
                HTMLElement.voidElement(.wbr)
                "in:"
                HTMLElement.voidElement(.wbr)
                "using:)"
            }
        }
        HTMLElement.element(.p) {
            "Returns a random value within the specified range, using the given generator as a source for randomness."
        }
        HTMLElement.element(.ul, attributes: ["id": "availability"]) {
            HTMLElement.element(.li, attributes: ["title": "Available on iOS 8.0 and later"]) {
                "iOS 8.0+"
            }
        }
        HTMLElement.element(.pre, attributes: ["id": "declaration"]) {
            HTMLElement.element(.code) {
                HTMLElement.element(.span, attributes: ["class": "keyword"]) {
                    "static"
                }
                " "
                HTMLElement.element(.span, attributes: ["class": "keyword"]) {
                    "func"
                }
                " random<T>(\n    in "
                HTMLElement.element(.span, attributes: ["class": "internalParameter"]) {
                    "range"
                }
                "..." // The rest of the declaration
            }
        }
    }
}
    
private func htmlString(for element: HTMLElement, options: HTMLFormatter.Options = []) -> String {
    String(decoding: HTMLFormatter.format(inPageElement: element, options: options), as: UTF8.self)
}
