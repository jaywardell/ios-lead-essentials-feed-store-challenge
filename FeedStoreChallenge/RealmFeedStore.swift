//
//  RealmFeedStore.swift
//  FeedStoreChallenge
//
//  Created by Joseph Wardell on 12/31/20.
//  Copyright © 2020 Essential Developer. All rights reserved.
//

import Foundation
import RealmSwift

/// This is an internal type to RealmFeedStore
/// It should not be used by any code outside this file
// we would make it fileprivate, but Realm complains with an error
final class RealmFeedStoreCachedFeedImage: Object {
	@objc fileprivate dynamic var id: String
	@objc fileprivate dynamic var desc: String?
	@objc fileprivate dynamic var location: String?
	@objc fileprivate dynamic var url: String

	private override init() {
		self.id = ""
		self.url = ""
	}
	
	fileprivate class func create(from localFeedImage: LocalFeedImage) -> RealmFeedStoreCachedFeedImage {
		
		let out = RealmFeedStoreCachedFeedImage()
		out.id = localFeedImage.id.uuidString
		out.desc = localFeedImage.description
		out.location = localFeedImage.location
		out.url = localFeedImage.url.absoluteString
				
		return out
	}
		
	fileprivate var localFeedImage: LocalFeedImage? {
		guard let uuid = UUID(uuidString: id),
			  let url = URL(string: url) else {
			 return nil
		}
		return LocalFeedImage(id: uuid, description: desc, location: location, url: url)
	}
}

/// This is an internal type to RealmFeedStore
/// It should not be used by any code outside this file
// we would make it fileprivate, but Realm complains with an error
final class RealmFeedStoreTimestamp: Object {
	@objc fileprivate dynamic var timestamp: Date?
	
	fileprivate class func create(from timestamp: Date) -> RealmFeedStoreTimestamp {
		
		let out = RealmFeedStoreTimestamp()
		out.timestamp = timestamp
		
		return out
	}
}

// MARK:-
public final class RealmFeedStore: FeedStore {
	
	private let configuration: Realm.Configuration
	private let queue: DispatchQueue
	public init(_ fileURL: URL, readOnly: Bool = false) {
		self.configuration = Realm.Configuration(fileURL: fileURL, readOnly: readOnly)
		self.queue = DispatchQueue(label: "\(type(of: Self.self))", qos: .userInitiated, autoreleaseFrequency: .workItem)
	}
	
	private func accessRealm(_ callback: @escaping (Result<Realm, Error>)->()) {
		queue.async {
			do {
				let realm = try Realm(configuration: self.configuration)
				callback(.success(realm))
			}
			catch {
				callback(.failure(error))
			}
		}
	}
	
	private func writeToRealm(_ callback: @escaping (Result<Realm, Error>)->()) {
		queue.async { [unowned self] in
			do {
				let realm = try Realm(configuration: self.configuration, queue: self.queue)
				try ObjectiveCExceptions.performTry {
					realm.beginWrite()
				}
				callback(.success(realm))
				try realm.commitWrite()
			}
			catch {
				callback(.failure(error))
			}
		}
	}
	
	public func deleteCachedFeed(completion: @escaping DeletionCompletion) {

		writeToRealm {
			switch $0 {
			case .failure(let error):
				completion(error)
			
			case .success(let realm):
				realm.deleteAll()
				completion(nil)
			}
		}
	}
	
	public func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
		
		writeToRealm {
			switch $0 {
			case .failure(let error):
				completion(error)
				
			case .success(let realm):
				realm.deleteAll()
				
				for image in feed {
					realm.add(RealmFeedStoreCachedFeedImage.create(from: image))
				}
				realm.add(RealmFeedStoreTimestamp.create(from: timestamp))
				
				completion(nil)
			}
		}
	}
	
	public func retrieve(completion: @escaping RetrievalCompletion) {
		
		accessRealm { result in
			switch result {
			case .failure(let error):
				return completion(.failure(error))
			
			case .success(let realm):
				guard let timestamp = realm.objects(RealmFeedStoreTimestamp.self).last?.timestamp else { return completion(.empty) }
				
				let cached = realm.objects(RealmFeedStoreCachedFeedImage.self)
				let feedImages = Array(cached.map(\.localFeedImage)).compactMap { $0 }
				completion(.found(feed: feedImages, timestamp: timestamp))
			}
		}
	}
}
