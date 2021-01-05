//
//  RealmFeedStore.swift
//  FeedStoreChallenge
//
//  Created by Joseph Wardell on 12/31/20.
//  Copyright © 2020 Essential Developer. All rights reserved.
//

import Foundation
import RealmSwift

final class RealmFeedStoreCachedFeedImage: Object {
	@objc fileprivate dynamic var id: String
	@objc fileprivate dynamic var desc: String?
	@objc fileprivate dynamic var location: String?
	@objc fileprivate dynamic var url: String

	private override init() {
		self.id = ""
		self.url = ""
		super.init()
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

final class RealmFeedCache: Object {
	
	@objc fileprivate dynamic var timestamp: Date
	fileprivate dynamic var images = List<RealmFeedStoreCachedFeedImage>()
	
	fileprivate override init() {
		timestamp = Date.distantPast
		super.init()
	}
	
	static func create(at timestamp: Date, for feedImages: [LocalFeedImage]) -> RealmFeedCache {
		let out = RealmFeedCache()
		out.timestamp = timestamp
		out.images.append(objectsIn: feedImages.map(RealmFeedStoreCachedFeedImage.create(from:)))
		return out
	}
}

// MARK:-
public final class RealmFeedStore: FeedStore {
	
	private let configuration: Realm.Configuration
	private let queue: DispatchQueue
	public init(fileURL: URL, readOnly: Bool = false) {
		self.configuration = Realm.Configuration(fileURL: fileURL, readOnly: readOnly)
		self.queue = DispatchQueue(label: "\(type(of: Self.self))", qos: .userInitiated, autoreleaseFrequency: .workItem)
	}
	
	public init(inMemoryIdentifier: String, readOnly: Bool = false) {
		self.configuration = Realm.Configuration(inMemoryIdentifier: inMemoryIdentifier, readOnly: readOnly)
		self.queue = DispatchQueue(label: "\(type(of: Self.self))", qos: .userInitiated, autoreleaseFrequency: .workItem)
	}

	private var _realm: Realm?
	private func getRealm() throws -> Realm {
		if let existing = _realm { return existing }
		_realm = try Realm(configuration: self.configuration, queue: queue)
		return _realm!
	}
	
	private func accessRealm(_ callback: @escaping (Result<Realm, Error>)->()) {
		queue.async { [self] in
			do {
				let realm = try getRealm()
				callback(.success(realm))
			}
			catch {
				callback(.failure(error))
			}
		}
	}

	var canWrite: Bool { !configuration.readOnly }
	enum WriteError: Error { case readonlyStore }
	private func writeToRealm(_ callback: @escaping (Result<Realm, Error>)->()) {
		// calling write on a readonly Realm store causes an Objective-C exception to be thrown
		// so let's just throw our own error before it happens
		guard canWrite else { return callback(.failure(WriteError.readonlyStore)) }

		queue.async { [weak self] in
			do {
				if let realm = try self?.getRealm() {
					try realm.write {
						callback(.success(realm))
					}
				}
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

				let cache = RealmFeedCache.create(at: timestamp, for: feed)
				realm.add(cache)
				
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
				
				guard let cache = realm.objects(RealmFeedCache.self).last else {
					return completion(.empty)
				}
				
				completion(.found(feed: cache.images.compactMap(\.localFeedImage), timestamp: cache.timestamp))
			}
		}
	}
}
