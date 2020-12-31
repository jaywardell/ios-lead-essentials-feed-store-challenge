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
	@objc fileprivate dynamic var id: String?
	@objc fileprivate dynamic var desc: String?
	@objc fileprivate dynamic var location: String?
	@objc fileprivate dynamic var url: String?

	fileprivate class func create(from localFeedImage: LocalFeedImage, at timestamp: Date) -> RealmFeedStoreCachedFeedImage {
		
		let out = RealmFeedStoreCachedFeedImage()
		out.id = localFeedImage.id.uuidString
		out.desc = localFeedImage.description
		out.location = localFeedImage.location
		out.url = localFeedImage.url.absoluteString
				
		return out
	}
		
	fileprivate var localFeedImage: LocalFeedImage {
		LocalFeedImage(id: UUID(uuidString: id!)!, description: desc, location: location, url: URL(string: url!)!)
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
				realm.add(RealmFeedStoreCachedFeedImage.create(from: image, at: timestamp))
			}
			
			realm.add(RealmFeedStoreTimestamp.create(from: timestamp))
		}
		completion(nil)
	}
	
	public func retrieve(completion: @escaping RetrievalCompletion) {
		let cached = realm.objects(RealmFeedStoreCachedFeedImage.self)
		if cached.count > 0 {
			let feedImages = cached.map {
				$0.localFeedImage
			}
			
			let timestamp = realm.objects(RealmFeedStoreTimestamp.self).first!.timestamp!			
			
			completion(.found(feed: Array(feedImages), timestamp: timestamp))
		}
		else {
			completion(.empty)
		}
	}
	
	
}
