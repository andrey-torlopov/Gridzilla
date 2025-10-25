//
//  ImageListParserTests.swift
//  GridzillaTests
//
//  Created by Andrey Torlopov on 25.10.2025.
//

import Testing
@testable import Gridzilla
internal import Foundation

struct ImageListParserTests {
    let parser = ImageListParser()

    // MARK: - Single URL Tests

    @Test func parseSingleURLWithJpgExtension() {
        let input = "https://img1.akspic.ru/attachments/crops/5/6/4/3/7/173465/173465-nacionalnyj_park_glejsher-ekoregion-poslesvechenie-lyudi_v_prirode-prirodnyj_landshaft-1440x2960.jpg"
        let result = parser.parse(input)

        #expect(result.count == 1)

        if case .image(let thumbnail, let original, let caption) = result[0].content {
            #expect(thumbnail.absoluteString == input)
            #expect(original.absoluteString == input)
            #expect(caption == nil)
        } else {
            Issue.record("Expected image content")
        }
    }

    @Test func parseSingleURLWithoutExtension() {
        let input = "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQqNZNZvSkBzt5rPSmUNYKNG1MpuC6h1LppdQ"
        let result = parser.parse(input)

        #expect(result.count == 1)

        if case .image(let thumbnail, let original, let caption) = result[0].content {
            #expect(thumbnail.absoluteString == input)
            #expect(original.absoluteString == input)
            #expect(caption == nil)
        } else {
            Issue.record("Expected image content")
        }
    }

    @Test func parseSingleURLWithPngExtension() {
        let input = "https://example.com/image.png"
        let result = parser.parse(input)

        #expect(result.count == 1)

        if case .image(let thumbnail, let original, _) = result[0].content {
            #expect(thumbnail.absoluteString == input)
            #expect(original.absoluteString == input)
        } else {
            Issue.record("Expected image content")
        }
    }

    // MARK: - Multiple URLs on Same Line Tests

    @Test func parseTwoURLsOnSameLine() {
        let url1 = "https://example.com/thumb.jpg"
        let url2 = "https://example.com/original.jpg"
        let input = "\(url1) \(url2)"
        let result = parser.parse(input)

        #expect(result.count == 1)

        if case .image(let thumbnail, let original, let caption) = result[0].content {
            #expect(thumbnail.absoluteString == url1)
            #expect(original.absoluteString == url2)
            #expect(caption == nil)
        } else {
            Issue.record("Expected image content with two URLs")
        }
    }

    @Test func parseURLWithCaption() {
        let url = "https://example.com/image.jpg"
        let input = "\(url) Beautiful landscape"
        let result = parser.parse(input)

        #expect(result.count == 1)

        if case .image(_, _, let caption) = result[0].content {
            #expect(caption == "Beautiful landscape")
        } else {
            Issue.record("Expected image content with caption")
        }
    }

    @Test func parseTwoURLsWithCaption() {
        let url1 = "https://example.com/thumb.jpg"
        let url2 = "https://example.com/original.jpg"
        let input = "\(url1) \(url2) Amazing photo"
        let result = parser.parse(input)

        #expect(result.count == 1)

        if case .image(let thumbnail, let original, let caption) = result[0].content {
            #expect(thumbnail.absoluteString == url1)
            #expect(original.absoluteString == url2)
            #expect(caption == "Amazing photo")
        } else {
            Issue.record("Expected image content with two URLs and caption")
        }
    }

    // MARK: - Invalid URL Tests

    @Test func parseInvalidURL() {
        let input = "https://www.gstatic.com/404"
        let result = parser.parse(input)

        #expect(result.count == 1)

        // Valid URL structure but may return 404 - should still be treated as image
        if case .image(let thumbnail, _, _) = result[0].content {
            #expect(thumbnail.absoluteString == input)
        } else {
            Issue.record("Expected image content for valid URL")
        }
    }

    @Test func parseInvalidScheme() {
        let input = "ftp://example.com/image.jpg"
        let result = parser.parse(input)

        #expect(result.count == 1)

        if case .invalidLink(let link) = result[0].content {
            #expect(link == input)
        } else {
            Issue.record("Expected invalid link for non-http/https scheme")
        }
    }

    // MARK: - Multiple Lines Tests

    @Test func parseMultipleLines() {
        let input = """
        https://example.com/image1.jpg
        https://example.com/image2.png
        https://example.com/image3.gif
        """
        let result = parser.parse(input)

        #expect(result.count == 3)

        for descriptor in result {
            if case .image = descriptor.content {
                // Success
            } else {
                Issue.record("Expected all lines to be parsed as images")
            }
        }
    }

    @Test func parseRealWorldExample() {
        let input = """
        https://img1.akspic.ru/attachments/crops/5/6/4/3/7/173465/173465-nacionalnyj_park_glejsher-ekoregion-poslesvechenie-lyudi_v_prirode-prirodnyj_landshaft-1440x2960.jpg
        https://www.gstatic.com/404
        https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQqNZNZvSkBzt5rPSmUNYKNG1MpuC6h1LppdQ
        https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQcikPF2V9GSmCy98NUw0u9lehuYk_V0tTTPQ
        https://upload.wikimedia.org/wikipedia/commons/4/43/ESO-VLT-Laser-phot-33a-07.jpg
        https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSR6FeU1LpnDc51eJEbJY6fn_rg6md8SfAbQw
        https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQyoGWuJ1GFcGfQ2EWMcCA7piB5AtvdN-USSw
        https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSLYPN9b5PVwzB50Nrebay37z79Xr18rH9rdQ
        https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQzhSXSznpKjRjkVSDai0I22GlBHMcVXHPjZg
        lalala
        https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQKMBWXDkh39EwFfxTgsvf-f-IuC_cMHDX1Sg
        https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSWmWDG5z0KEBbc-My7aGzu7vNdzyyVjsu4Vw
        """
        let result = parser.parse(input)

        #expect(result.count == 12)

        // Count images vs text
        var imageCount = 0
        var textCount = 0

        for descriptor in result {
            switch descriptor.content {
            case .image:
                imageCount += 1
            case .text:
                textCount += 1
            case .invalidLink:
                break
            }
        }

        // All valid URLs should be parsed as images (11), only "lalala" as text (1)
        #expect(imageCount == 11)
    }

    // MARK: - Edge Cases

    @Test func parseEmptyString() {
        let input = ""
        let result = parser.parse(input)

        #expect(result.isEmpty)
    }

    @Test func parseWhitespaceOnly() {
        let input = "   \n  \n   "
        let result = parser.parse(input)

        #expect(result.isEmpty)
    }

    @Test func parseURLWithWhitespace() {
        let input = "  https://example.com/image.jpg  "
        let result = parser.parse(input)

        #expect(result.count == 1)

        if case .image(let thumbnail, _, _) = result[0].content {
            #expect(thumbnail.absoluteString == "https://example.com/image.jpg")
        } else {
            Issue.record("Expected image content")
        }
    }

    @Test func parseURLWithQueryParameters() {
        let input = "https://example.com/image?size=large&quality=high"
        let result = parser.parse(input)

        #expect(result.count == 1)

        if case .image(let thumbnail, _, _) = result[0].content {
            #expect(thumbnail.absoluteString == input)
        } else {
            Issue.record("Expected image content")
        }
    }

    @Test func parseURLWithFragment() {
        let input = "https://example.com/image.jpg#section"
        let result = parser.parse(input)

        #expect(result.count == 1)

        if case .image(let thumbnail, _, _) = result[0].content {
            #expect(thumbnail.absoluteString == input)
        } else {
            Issue.record("Expected image content")
        }
    }

    @Test func parseHTTPandHTTPS() {
        let input = """
        https://example.com/secure.jpg
        http://example.com/insecure.jpg
        """
        let result = parser.parse(input)

        #expect(result.count == 2)

        // Both should be valid
        for descriptor in result {
            if case .image = descriptor.content {
                // Success
            } else {
                Issue.record("Expected both http and https to be valid")
            }
        }
    }

    @Test func parseURLWithDifferentSeparators() {
        let url1 = "https://example.com/thumb.jpg"
        let url2 = "https://example.com/original.jpg"

        // Test different separators
        let inputs = [
            "\(url1) \(url2)",           // space
            "\(url1)\t\(url2)",          // tab
            "\(url1),\(url2)",           // comma
            "\(url1);\(url2)",           // semicolon
            "\(url1)|\(url2)",           // pipe
        ]

        for input in inputs {
            let result = parser.parse(input)
            #expect(result.count == 1)

            if case .image(let thumbnail, let original, _) = result[0].content {
                #expect(thumbnail.absoluteString == url1)
                #expect(original.absoluteString == url2)
            } else {
                Issue.record("Expected two URLs to be parsed correctly")
            }
        }
    }
}
