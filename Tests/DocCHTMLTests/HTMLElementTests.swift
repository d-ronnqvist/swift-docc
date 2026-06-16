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
        <section><nav id="breadcrumbs"><ul><li>Swift</li><li>Int</li><li>random(in:using:)</li></ul></nav><hgroup><p>Type Method</p><h1>random(<wbr>in:<wbr>using:)</h1></hgroup><p>Returns a random value within the specified range, using the given generator as a source for randomness.</p><ul id="availability"><li title="Available on iOS 8.0 and later">iOS 8.0+</li></ul><pre id="declaration"><code><span class="keyword">static</span> <span class="keyword">func</span> random&lt;T>(
            in <span class="internalParameter">range</span>...</code></pre></section>
        """)
        
        #expect(htmlString(for: element, options: .omitOptionalQuotesAroundAttributeValues) == """
        <section><nav id=breadcrumbs><ul><li>Swift</li><li>Int</li><li>random(in:using:)</li></ul></nav><hgroup><p>Type Method</p><h1>random(<wbr>in:<wbr>using:)</h1></hgroup><p>Returns a random value within the specified range, using the given generator as a source for randomness.</p><ul id=availability><li title="Available on iOS 8.0 and later">iOS 8.0+</li></ul><pre id=declaration><code><span class=keyword>static</span> <span class=keyword>func</span> random&lt;T>(
            in <span class=internalParameter>range</span>...</code></pre></section>
        """)
        
        #expect(htmlString(for: element, options: .omitOptionalEndTags) == """
        <section><nav id="breadcrumbs"><ul><li>Swift<li>Int<li>random(in:using:)</ul></nav><hgroup><p>Type Method<h1>random(<wbr>in:<wbr>using:)</h1></hgroup><p>Returns a random value within the specified range, using the given generator as a source for randomness.<ul id="availability"><li title="Available on iOS 8.0 and later">iOS 8.0+</ul><pre id="declaration"><code><span class="keyword">static</span> <span class="keyword">func</span> random&lt;T>(
            in <span class="internalParameter">range</span>...</code></pre></section>
        """)
        
        #expect(htmlString(for: element, options: [.omitOptionalQuotesAroundAttributeValues, .omitOptionalEndTags]) == """
        <section><nav id=breadcrumbs><ul><li>Swift<li>Int<li>random(in:using:)</ul></nav><hgroup><p>Type Method<h1>random(<wbr>in:<wbr>using:)</h1></hgroup><p>Returns a random value within the specified range, using the given generator as a source for randomness.<ul id=availability><li title="Available on iOS 8.0 and later">iOS 8.0+</ul><pre id=declaration><code><span class=keyword>static</span> <span class=keyword>func</span> random&lt;T>(
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
            <li title="Available on iOS 8.0 and later">iOS 8.0+</li>
          </ul>
          <pre id="declaration"><code><span class="keyword">static</span> <span class="keyword">func</span> random&lt;T>(
            in <span class="internalParameter">range</span>...</code></pre>
        </section>
        """)
        
        #expect(htmlString(for: element, options: [.prettyPrint, .omitOptionalQuotesAroundAttributeValues]) == """
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
            <li title="Available on iOS 8.0 and later">iOS 8.0+</li>
          </ul>
          <pre id=declaration><code><span class=keyword>static</span> <span class=keyword>func</span> random&lt;T>(
            in <span class=internalParameter>range</span>...</code></pre>
        </section>
        """)
        
        #expect(htmlString(for: element, options: [.prettyPrint, .omitOptionalEndTags]) == """
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
            <li title="Available on iOS 8.0 and later">iOS 8.0+
          </ul>
          <pre id="declaration"><code><span class="keyword">static</span> <span class="keyword">func</span> random&lt;T>(
            in <span class="internalParameter">range</span>...</code></pre>
        </section>
        """)
        
        #expect(htmlString(for: element, options: [.prettyPrint, .omitOptionalQuotesAroundAttributeValues, .omitOptionalEndTags]) == """
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
            <li title="Available on iOS 8.0 and later">iOS 8.0+
          </ul>
          <pre id=declaration><code><span class=keyword>static</span> <span class=keyword>func</span> random&lt;T>(
            in <span class=internalParameter>range</span>...</code></pre>
        </section>
        """)
    }
    
    private let element = DocCHTML.section {
        nav(id: "breadcrumbs") {
            ul {
                li { "Swift" }
                li { "Int" }
                li { "random(in:using:)" }
            }
        }
        hgroup {
            p { "Type Method" }
            h1 {
                "random("
                wbr
                "in:"
                wbr
                "using:)"
            }
        }
        p {
            "Returns a random value within the specified range, using the given generator as a source for randomness."
        }
        ul(id: "availability") {
            li(attributes: ["title": "Available on iOS 8.0 and later"]) {
                "iOS 8.0+"
            }
        }
        pre(id: "declaration") {
            code {
                span(class: "keyword") { "static" }
                " "
                span(class: "keyword") { "func" }
                " random<T>(\n    in "
                span(class: "internalParameter") { "range" }
                "..." // The rest of the declaration
            }
        }
    }
}
    
private func htmlString(for element: HTMLNode, options: HTMLFormatter.Options = []) -> String {
    String(decoding: HTMLFormatter.format(inPageElement: element, options: options), as: UTF8.self)
}
