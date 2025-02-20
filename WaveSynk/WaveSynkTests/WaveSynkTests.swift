//
//  WaveSynkTests.swift
//  WaveSynkTests
//
//  Created by Carson Cruz on 1/16/25.
//

import XCTest
@testable import WaveSynk

class BaseWaveSynkTests: XCTestCase {
    override func setUp() async throws {
        try await super.setUp()
        TestConfiguration.setupTestEnvironment()
    }
    
    override func tearDown() async throws {
        TestConfiguration.cleanupTestEnvironment()
        try await super.tearDown()
    }
}
