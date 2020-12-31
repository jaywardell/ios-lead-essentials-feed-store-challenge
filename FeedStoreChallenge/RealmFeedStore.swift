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
final class CachedFeedImage: Object {
	@objc fileprivate dynamic var id: String?
	@objc fileprivate dynamic var desc: String?
	@objc fileprivate dynamic var location: String?
	@objc fileprivate dynamic var url: String?
	@objc fileprivate dynamic var timestamp: Date?

	fileprivate class func createFeedImage(from localFeedImage: LocalFeedImage, at timestamp: Date) -> CachedFeedImage {
		
		let out = CachedFeedImage()
		out.id = localFeedImage.id.uuidString
		out.desc = localFeedImage.description
		out.location = localFeedImage.location
		out.url = localFeedImage.url.absoluteString
		
		out.timestamp = timestamp
		
		return out
	}
		
	fileprivate var localFeedImage: LocalFeedImage {
		LocalFeedImage(id: UUID(uuidString: id!)!, description: desc, location: location, url: URL(string: url!)!)
	}
}

// MARK:-
public final class RealmFeedStore: FeedStore {
	
	let realm: Realm
	public init() {
		self.realm = try! Realm()
	}
	

	public func deleteCachedFeed(completion: @escaping DeletionCompletion) {
		fatalError()
	}
	
	public func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
		try! realm.write {
			for image in feed {
				realm.add(CachedFeedImage.createFeedImage(from: image, at: timestamp))
			}
		}
		completion(nil)
	}
	
	public func retrieve(completion: @escaping RetrievalCompletion) {
		let cached = realm.objects(CachedFeedImage.self)
		if cached.count > 0 {
			let feedImages = cached.map {
				$0.localFeedImage
			}
			
			let timestamp = cached.first!.timestamp!
			
			completion(.found(feed: Array(feedImages), timestamp: timestamp))
		}
		else {
			completion(.empty)
		}
	}
	
	
}
