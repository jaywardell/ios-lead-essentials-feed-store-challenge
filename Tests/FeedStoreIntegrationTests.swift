//
//  Copyright © 2020 Essential Developer. All rights reserved.
//

import XCTest
import FeedStoreChallenge

class FeedStoreIntegrationTests: XCTestCase {
	
	//  ***********************
	//
	//  Uncomment and implement the following tests if your
	//  implementation persists data to disk (e.g., CoreData/Realm)
	//
	//  ***********************
	
	override func setUp() {
		super.setUp()
		
		setupEmptyStoreState()
	}
	
	override func tearDown() {
		super.tearDown()
		
		undoStoreSideEffects()
	}
	
	func test_retrieve_deliversEmptyOnEmptyCache() {
		let sut = makeSUT()
		
		expect(sut, toRetrieve: .empty)
	}
	
	func test_retrieve_deliversFeedInsertedOnAnotherInstance() {
		let storeToInsert = makeSUT()
		let storeToLoad = makeSUT()
		let feed = uniqueImageFeed()
		let timestamp = Date()
		
		insert((feed, timestamp), to: storeToInsert)
		
		expect(storeToLoad, toRetrieve: .found(feed: feed, timestamp: timestamp))
	}
	
	func test_insert_overridesFeedInsertedOnAnotherInstance() {
		let storeToInsert = makeSUT()
		let storeToOverride = makeSUT()
		let storeToLoad = makeSUT()
		
		insert((uniqueImageFeed(), Date()), to: storeToInsert)
		
		let latestFeed = uniqueImageFeed()
		let latestTimestamp = Date()
		insert((latestFeed, latestTimestamp), to: storeToOverride)
		
		expect(storeToLoad, toRetrieve: .found(feed: latestFeed, timestamp: latestTimestamp))
	}
	
	func test_delete_deletesFeedInsertedOnAnotherInstance() {
		//        let storeToInsert = makeSUT()
		//        let storeToDelete = makeSUT()
		//        let storeToLoad = makeSUT()
		//
		//        insert((uniqueImageFeed(), Date()), to: storeToInsert)
		//
		//        deleteCache(from: storeToDelete)
		//
		//        expect(storeToLoad, toRetrieve: .empty)
	}
	
	// - MARK: Helpers
	
	private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> FeedStore {
		let fileURL = testSpecificStoreURL()
		let sut = RealmFeedStore(fileURL)
		trackForMemoryLeaks(sut, file: file, line: line)
		return sut
	}
	
	func trackForMemoryLeaks(_ instance: AnyObject, file: StaticString = #filePath, line: UInt = #line) {
		addTeardownBlock { [weak instance] in
			XCTAssertNil(instance, "\(String(describing: instance)) was never deallocated.", file: file, line: line)
		}
	}

	private func testSpecificStoreURL() -> URL {
		let out = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!.appendingPathComponent("\(type(of: self)).realm")
		return out
	}

	private func setupEmptyStoreState() {
		clearRealmFiles(at: testSpecificStoreURL())
	}
	
	private func undoStoreSideEffects() {
		clearRealmFiles(at: testSpecificStoreURL())
	}
	
	private func clearRealmFiles(at realmURL: URL) {
		let realmURLs = [
			realmURL,
			realmURL.appendingPathExtension("lock"),
			realmURL.appendingPathExtension("note"),
			realmURL.appendingPathExtension("management")
		]
		for URL in realmURLs {
			do {
				try FileManager.default.removeItem(at: URL)
			} catch {
				// handle error
			}
		}
	}

}
