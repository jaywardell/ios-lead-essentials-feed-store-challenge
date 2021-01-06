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
	@objc fileprivate dynamic var id: String = ""
	@objc fileprivate dynamic var desc: String?
	@objc fileprivate dynamic var location: String?
	@objc fileprivate dynamic var url: String = ""

	convenience init(localFeedImage: LocalFeedImage) {
		self.init()
		self.id = localFeedImage.id.uuidString
		self.desc = localFeedImage.description
		self.location = localFeedImage.location
		self.url = localFeedImage.url.absoluteString
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
	
	@objc fileprivate dynamic var timestamp: Date = .distantPast
	fileprivate dynamic var images = List<RealmFeedStoreCachedFeedImage>()
		
	convenience init(timestamp: Date, feed: [LocalFeedImage]) {
		self.init()
		self.timestamp = timestamp
		self.images.append(objectsIn: feed.map(RealmFeedStoreCachedFeedImage.init(localFeedImage:)))
	}
}

// MARK:-
public final class RealmFeedStore: FeedStore {
	
	private let configuration: Realm.Configuration
	private let queue: DispatchQueue
	
	enum WriteError: Error { case readonlyStore }

	public enum Configuration {
		case fileURL(URL)
		case inMemoryIdentifier(String)
	}
	
	internal init(_ configuration:Configuration, readOnly: Bool) {
		switch configuration {
		case .fileURL(let URL):
		self.configuration = Realm.Configuration(fileURL: URL, readOnly: readOnly)
		case .inMemoryIdentifier(let identifier):
		self.configuration = Realm.Configuration(inMemoryIdentifier: identifier, readOnly: readOnly)
		}
		self.queue = DispatchQueue(label: "\(type(of: Self.self))", qos: .userInitiated, autoreleaseFrequency: .workItem)
	}
	
	public convenience init(fileURL: URL) {
		self.init(.fileURL(fileURL), readOnly: false)
	}
	
	public convenience init(inMemoryIdentifier identifier: String = UUID().uuidString) {
		self.init(.inMemoryIdentifier(identifier), readOnly: false)
	}
	
	private var _realm: Realm?
	private func getRealm() throws -> Realm {
		if let existing = _realm { return existing }
		_realm = try Realm(configuration: self.configuration, queue: queue)
		return _realm!
	}
	
	private var canWrite: Bool { !configuration.readOnly }
	private func ensureSafeConfiguration() -> Error? {
		// calling write on a readonly Realm store causes an Objective-C exception to be thrown
		// so let's just throw our own error before it happens
		if !canWrite {
			return WriteError.readonlyStore
		}
		return nil
	}
	
	public func deleteCachedFeed(completion: @escaping DeletionCompletion) {
		if let error = ensureSafeConfiguration() { return completion(error) }
		
		queue.async { [self] in
			do {
				let realm = try self.getRealm()
				try realm.write {
					
					realm.deleteAll()
				}
				completion(nil)
			}
			catch {
				completion(error)
			}
		}
		
	}
	
	public func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
		if let error = ensureSafeConfiguration() { return completion(error) }

		queue.async { [self] in
			do {
				let realm = try self.getRealm()
				try realm.write {
					
					realm.deleteAll()

					let cache = RealmFeedCache(timestamp: timestamp, feed: feed)
					realm.add(cache)
				}
				completion(nil)
			}
			catch {
				completion(error)
			}
		}
	}
	
	public func retrieve(completion: @escaping RetrievalCompletion) {
		
		queue.async { [self] in
			do {
				let realm = try getRealm()
				
				guard let cache = realm.objects(RealmFeedCache.self).last else {
					return completion(.empty)
				}
				
				completion(.found(feed: cache.images.compactMap(\.localFeedImage), timestamp: cache.timestamp))
			}
			catch {
				completion(.failure(error))
			}
		}
	}
}
