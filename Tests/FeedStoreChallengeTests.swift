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
		
		// if there's already invalid data there, then the realm will return an error when it tries to read
		try! "not valid realm data".write(to: testSpecificStoreURL(), atomically: false, encoding: .utf8)
		let sut = makeSUT(at: testSpecificStoreURL())

		assertThatRetrieveDeliversFailureOnRetrievalError(on: sut)
	}

	func test_retrieve_hasNoSideEffectsOnFailure() {

		// if there's already invalid data there, then the realm will return an error when it tries to read
		try! "not valid realm data".write(to: testSpecificStoreURL(), atomically: false, encoding: .utf8)
		let sut = makeSUT(at: testSpecificStoreURL())

		assertThatRetrieveHasNoSideEffectsOnFailure(on: sut)
	}

	func test_retrieve_deliversFailureOnRetrievalError_forPermissionsError() {
		
		// if the current user doesn't have permission to read the store url passed in,
		// then the realm will return an error when it tries to read
		let sut = makeSUT(at: noPermissionsStoreURL())

		assertThatRetrieveDeliversFailureOnRetrievalError(on: sut)
	}

	func test_retrieve_hasNoSideEffectsOnFailure_forPermissionsError() {

		// if the current user doesn't have permission to read the store url passed in,
		// then the realm will return an error when it tries to read
		let sut = makeSUT(at: noPermissionsStoreURL())

		assertThatRetrieveHasNoSideEffectsOnFailure(on: sut)
	}

	func test_retrieve_deliversFailureOnRetrievalError_forInvalidURL() {

		// if the store url is invalid,
		// then the realm will return an error when it tries to read
		let sut = makeSUT(at: invalidStoreURL())

		assertThatRetrieveDeliversFailureOnRetrievalError(on: sut)
	}

	func test_retrieve_hasNoSideEffectsOnFailure_forInvalidURL() {

		// if the store url is invalid,
		// then the realm will return an error when it tries to read
		let sut = makeSUT(at: invalidStoreURL())

		assertThatRetrieveHasNoSideEffectsOnFailure(on: sut)
	}

}

extension FeedStoreChallengeTests: FailableInsertFeedStoreSpecs {

	func test_insert_deliversErrorOnInsertionError() {

		// trying to write into a realm that is readonly will cause an error
		let sut = RealmFeedStore(fileURL: testSpecificReadOnlyStoreURL(), readOnly: true)
		trackForMemoryLeaks(sut)

		assertThatInsertDeliversErrorOnInsertionError(on: sut)
		
		clearRealmFiles(at: testSpecificReadOnlyStoreURL())
	}

	func test_insert_hasNoSideEffectsOnInsertionError() {

		// In order to test retrieval after a failed insert
		// we need an existing realm file that the retrieve can read
		// but we need it to be empty when insert() is called
		writeEmptyRealmFile(at: testSpecificReadOnlyStoreURL())

		// trying to insert into a realm that is readonly will cause an error
		let sut = RealmFeedStore(fileURL: testSpecificReadOnlyStoreURL(), readOnly: true)
		trackForMemoryLeaks(sut)

		assertThatInsertHasNoSideEffectsOnInsertionError(on: sut)

		clearRealmFiles(at: testSpecificReadOnlyStoreURL())
	}

	private func writeEmptyRealmFile(at fileURL: URL) {
		
		// create an existing realm at the standard test location
		// and write to it, but leave it empty
		// so that a file exists at the expected path
		let existingRealm = RealmFeedStore(fileURL: fileURL)
		let exp1 = expectation(description: "Wait for dummy insertion")
		existingRealm.insert(uniqueImageFeed(), timestamp: Date()) {_ in
			exp1.fulfill()
		}

		let exp2 = expectation(description: "Wait for dummy deeltion")
		existingRealm.deleteCachedFeed {_ in
			exp2.fulfill()
		}
		wait(for: [exp1, exp2], timeout: 1.0)
	}
	
}

extension FeedStoreChallengeTests: FailableDeleteFeedStoreSpecs {

	func test_delete_deliversErrorOnDeletionError() {

		// trying to delete from a realm that is readonly will cause an error
		let sut = RealmFeedStore(fileURL: testSpecificReadOnlyStoreURL(), readOnly: true)
		trackForMemoryLeaks(sut)

		assertThatDeleteDeliversErrorOnDeletionError(on: sut)
		
		clearRealmFiles(at: testSpecificReadOnlyStoreURL())
	}

	func test_delete_hasNoSideEffectsOnDeletionError() {

		// In order to test retrieval after a failed deletion
		// we need an existing realm file that the retrieve can read
		// but we need it to be empty when insert() is called
		writeEmptyRealmFile(at: testSpecificReadOnlyStoreURL())
		
		// trying to delete from a realm that is readonly will cause an error
		let sut = RealmFeedStore(fileURL: testSpecificReadOnlyStoreURL(), readOnly: true)
		trackForMemoryLeaks(sut)

		print(testSpecificReadOnlyStoreURL())
		
		assertThatDeleteHasNoSideEffectsOnDeletionError(on: sut)
		
		clearRealmFiles(at: testSpecificReadOnlyStoreURL())
	}

}

// MARK:- Helpers

extension FeedStoreChallengeTests {
	
	private func makeSUT(at fileURL: URL? = nil, file: StaticString = #filePath, line: UInt = #line) -> FeedStore {
		let sut: RealmFeedStore
		if let fileURL = fileURL {
			sut = RealmFeedStore(fileURL: fileURL)
		}
		else {
			sut = RealmFeedStore(inMemoryIdentifier: UUID().uuidString)
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

	private func testSpecificReadOnlyStoreURL() -> URL {
		let out = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!.appendingPathComponent("\(type(of: self))_readonly.realm")
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

	private func invalidStoreURL() -> URL {
		URL(string: "invalid://store-url")!
	}

	private func noPermissionsStoreURL() -> URL {
		FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
	}

}
