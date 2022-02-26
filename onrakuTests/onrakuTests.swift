//
//  onrakuTests.swift
//  onrakuTests
//
//  Created by Satoru Abe on 2022/02/11.
//

import XCTest

@testable import onraku

class onrakuTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testSplit() throws {
        let cases: [(src: String, expected: [String])] = [
            (src: "hoge", expected: []),
            (src: "hoge _piyo Remix_", expected: []),
            (src: "hoge -ababa Remix-", expected: ["ababa"]),
            (src: "hoge - obobo Remix -", expected: ["obobo"]),
            (src: "hoge (fuga Remix)", expected: ["fuga"]),
            (src: "hoge (fuga2 remix)", expected: ["fuga2"]),
            (src: "hoge [foo Remix]", expected: ["foo"]),
            (src: "hoge (DJ Nantoka Remix)", expected: ["DJ Nantoka"]),
            (src: "hoge (DJ Untara Bootleg)", expected: ["DJ Untara"]),
            (src: "hoge (bar Flip)", expected: ["bar"]),
        ]
        cases.forEach { (src, expected) in
            XCTAssertEqual(src.intelligentlyExtractRemixersCredit(), expected)
        }

        let cases2: [(src: String, expected: [String])] = [
            (src: "hoge", expected: []),
            (src: "hoge feat. pi yo", expected: ["pi yo"]),
            (src: "hoge ft. bar", expected: ["bar"]),
            (src: "hoge featuring ababa", expected: ["ababa"]),
            (src: "hoge feat.  obobo", expected: ["obobo"]),
            (src: "hoge feat. fuga (piyo remix)", expected: ["fuga"]),
            (src: "hoge feat. fuga2 [piyo remix]", expected: ["fuga2"]),
            (src: "hoge Prod. foo [piyo remix]", expected: ["foo"]),
        ]
        cases2.forEach { (src, expected) in
            XCTAssertEqual(src.intelligentlyExtractFeaturedArtists(), expected)
        }

        XCTAssertEqual("".intelligentlySplitIntoSubArtists(), [])
        XCTAssertEqual("hoge (aa)".intelligentlySplitIntoSubArtists(), ["hoge", "aa"])
        XCTAssertEqual("a (b), c (d)".intelligentlySplitIntoSubArtists(), ["a", "b", "c", "d"])
        XCTAssertEqual("a & b".intelligentlySplitIntoSubArtists(), ["a", "b"])
        XCTAssertEqual(
            "a (b), c (d) from x".intelligentlySplitIntoSubArtists(), ["a", "b", "c", "d", "x"])
        XCTAssertEqual("a・b・c from x".intelligentlySplitIntoSubArtists(), ["a", "b", "c", "x"])
        XCTAssertEqual("foo (a, b, c)".intelligentlySplitIntoSubArtists(), ["foo", "a", "b", "c"])
        XCTAssertEqual("foo (a), bar (a)".intelligentlySplitIntoSubArtists(), ["foo", "a", "bar"])
        XCTAssertEqual("a x b".intelligentlySplitIntoSubArtists(), ["a", "b"])
        XCTAssertEqual("a × b".intelligentlySplitIntoSubArtists(), ["a", "b"])
        XCTAssertEqual("a feat. b, c".intelligentlySplitIntoSubArtists(), ["a", "b", "c"])
        XCTAssertEqual("a Feat. b, c".intelligentlySplitIntoSubArtists(), ["a", "b", "c"])
        XCTAssertEqual("afeat. b".intelligentlySplitIntoSubArtists(), ["afeat. b"])

        XCTAssertEqual("".intelligentlySplitIntoSubGenres(), [])
        XCTAssertEqual("a / b / c".intelligentlySplitIntoSubGenres(), ["a", "b", "c"])
        XCTAssertEqual("hoge (fuga)".intelligentlySplitIntoSubGenres(), ["hoge", "fuga"])
        XCTAssertEqual(
            "hoge (fuga / piyo)".intelligentlySplitIntoSubGenres(), ["hoge", "fuga", "piyo"])
    }

    //    func testPerformanceExample() throws {
    //        // This is an example of a performance test case.
    //        self.measure {
    //            // Put the code you want to measure the time of here.
    //        }
    //    }

}
