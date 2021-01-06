//
//  Copyright © 2019 Essential Developer. All rights reserved.
//

import XCTest
import FeedStoreChallenge
import RealmSwift

class FeedStoreChallengeTests: XCTestCase, FeedStoreSpecs {
	
	override func setUp() {
		setupEmptyStoreState()
	}
	
	override func tearDown() {
		undoStoreSideEffects()
	}
	
	//  ***********************
	//
	//  Follow the TDD process:
	//
	//  1. Uncomment and run one test at a time (run tests with CMD+U).
	//  2. Do the minimum to make the test pass and commit.
	//  3. Refactor if needed and commit again.
	//
	//  Repeat this process until all tests are passing.
	//
	//  ***********************
	
	func test_retrieve_deliversEmptyOnEmptyCache() {
		let sut = makeSUT()
		
		assertThatRetrieveDeliversEmptyOnEmptyCache(on: sut)
	}
	
	func test_retrieve_hasNoSideEffectsOnEmptyCache() {
		let sut = makeSUT()
		
		assertThatRetrieveHasNoSideEffectsOnEmptyCache(on: sut)
	}
	
	func test_retrieve_deliversFoundValuesOnNonEmptyCache() {
		let sut = makeSUT()
		
		assertThatRetrieveDeliversFoundValuesOnNonEmptyCache(on: sut)
	}
	
	func test_retrieve_hasNoSideEffectsOnNonEmptyCache() {
		let sut = makeSUT()
		
		assertThatRetrieveHasNoSideEffectsOnNonEmptyCache(on: sut)
	}
	
	func test_insert_deliversNoErrorOnEmptyCache() {
		let sut = makeSUT()
		
		assertThatInsertDeliversNoErrorOnEmptyCache(on: sut)
	}
	
	func test_insert_deliversNoErrorOnNonEmptyCache() {
		let sut = makeSUT()
		
		assertThatInsertDeliversNoErrorOnNonEmptyCache(on: sut)
	}
	
	func test_insert_overridesPreviouslyInsertedCacheValues() {
		let sut = makeSUT()
		
		assertThatInsertOverridesPreviouslyInsertedCacheValues(on: sut)
	}
	
	func test_delete_deliversNoErrorOnEmptyCache() {
		let sut = makeSUT()
		
		assertThatDeleteDeliversNoErrorOnEmptyCache(on: sut)
	}
	
	func test_delete_hasNoSideEffectsOnEmptyCache() {
		let sut = makeSUT()
		
		assertThatDeleteHasNoSideEffectsOnEmptyCache(on: sut)
	}
	
	func test_delete_deliversNoErrorOnNonEmptyCache() {
		let sut = makeSUT()
		
		assertThatDeleteDeliversNoErrorOnNonEmptyCache(on: sut)
	}
	
	func test_delete_emptiesPreviouslyInsertedCache() {
		let sut = makeSUT()
		
		assertThatDeleteEmptiesPreviouslyInsertedCache(on: sut)
	}
	
	func test_storeSideEffects_runSerially() {
		let sut = makeSUT()
		
		assertThatSideEffectsRunSerially(on: sut)
	}
	

}

//  ***********************
//
//  Uncomment the following tests if your implementation has failable operations.
//
//  Otherwise, delete the commented out code!
//
//  ***********************

extension FeedStoreChallengeTests: FailableRetrieveFeedStoreSpecs {

	func test_retrieve_deliversFailureOnRetrievalError() {
		
		try! "not valid realm data".write(to: testSpecificStoreURL(), atomically: false, encoding: .utf8)
		let sut = makeSUT(at: testSpecificStoreURL())

		assertThatRetrieveDeliversFailureOnRetrievalError(on: sut)
	}

	func test_retrieve_hasNoSideEffectsOnFailure() {

		try! "not valid realm data".write(to: testSpecificStoreURL(), atomically: false, encoding: .utf8)
		let sut = makeSUT(at: testSpecificStoreURL())

		assertThatRetrieveHasNoSideEffectsOnFailure(on: sut)
	}

	func test_retrieve_deliversFailureOnRetrievalError_forPermissionsError() {
		let sut = makeSUT(at: noPermissionsStoreURL())

		assertThatRetrieveDeliversFailureOnRetrievalError(on: sut)
	}

	func test_retrieve_hasNoSideEffectsOnFailure_forPermissionsError() {
		let sut = makeSUT(at: noPermissionsStoreURL())

		assertThatRetrieveHasNoSideEffectsOnFailure(on: sut)
	}

	func test_retrieve_deliversFailureOnRetrievalError_forInvalidURL() {
		let sut = makeSUT(at: invalidStoreURL())

		assertThatRetrieveDeliversFailureOnRetrievalError(on: sut)
	}

	func test_retrieve_hasNoSideEffectsOnFailure_forInvalidURL() {
		let sut = makeSUT(at: invalidStoreURL())

		assertThatRetrieveHasNoSideEffectsOnFailure(on: sut)
	}

}

extension FeedStoreChallengeTests: FailableInsertFeedStoreSpecs {

	func test_insert_deliversErrorOnInsertionError() {

		// trying to write into a realm that is readonly will cause an error
		let sut = makeSUT(readonly: true)

		assertThatInsertDeliversErrorOnInsertionError(on: sut)
	}

	func test_insert_hasNoSideEffectsOnInsertionError() {

		// In order to test retrieval after a failed insert
		// we need an existing realm file that the retrieve can read
		// but we need it to be empty when insert() is called
		//
		// (we can't use an in-Memory Realm store for this
		// because Realm calls an error when you try to retreive from an empty readonly In-Memory realm store)
		writeEmptyRealmFile(at: testSpecificStoreURL())

		// trying to insert into a realm that is readonly will cause an error
		let sut = makeSUT(at: testSpecificStoreURL(), readonly: true)

		assertThatInsertHasNoSideEffectsOnInsertionError(on: sut)
	}

	private func writeEmptyRealmFile(at fileURL: URL) {
		
		// create an existing realm at the standard test location
		// and write to it, but leave it empty
		// so that a file exists at the expected path
		let existingRealm = RealmFeedStore(fileURL: fileURL)
		insert((feed: [], timestamp: Date()), to: existingRealm)
		deleteCache(from: existingRealm)
	}
	
}

extension FeedStoreChallengeTests: FailableDeleteFeedStoreSpecs {

	func test_delete_deliversErrorOnDeletionError() {

		// trying to delete from a realm that is readonly will cause an error
		let sut = makeSUT(readonly: true)

		assertThatDeleteDeliversErrorOnDeletionError(on: sut)
	}

	func test_delete_hasNoSideEffectsOnDeletionError() {

		// In order to test retrieval after a failed deletion
		// we need an existing realm file that the retrieve can read
		// but we need it to be empty when insert() is called
		//
		// (we can't use an in-Memory Realm store for this
		// because Realm calls an error when you try to retreive from an empty readonly In-Memory realm store.
		// of course, who would ever do that)
		writeEmptyRealmFile(at: testSpecificStoreURL())
		
		// trying to delete from a realm that is readonly will cause an error
		let sut = makeSUT(at: testSpecificStoreURL(), readonly: true)
		
		assertThatDeleteHasNoSideEffectsOnDeletionError(on: sut)
	}

}

// MARK:- Helpers

extension FeedStoreChallengeTests {
	
	private func makeSUT(at fileURL: URL? = nil, readonly: Bool = false, file: StaticString = #filePath, line: UInt = #line) -> FeedStore {
		let sut: RealmFeedStore
		if let fileURL = fileURL {
			sut = RealmFeedStore(.fileURL(fileURL), readOnly: readonly)
		}
		else {
			sut = RealmFeedStore(.inMemoryIdentifier(UUID().uuidString), readOnly: readonly)
		}
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
	
	private func clearRealmFiles(at realmURL: URL, file: StaticString = #filePath, line: UInt = #line) {

		XCTAssertNoThrow(try Realm.deleteFiles(for: Realm.Configuration(fileURL: realmURL)))
	}

	private func invalidStoreURL() -> URL {
		URL(string: "invalid://store-url")!
	}

	private func noPermissionsStoreURL() -> URL {
		FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
	}

}
