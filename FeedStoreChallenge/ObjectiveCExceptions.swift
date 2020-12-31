//
//  ObjectiveCExceptions.swift
//  FeedStoreChallenge
//
//  Created by Joseph Wardell on 12/31/20.
//  Copyright © 2020 Essential Developer. All rights reserved.
//

import Foundation

public struct NSExceptionError: Swift.Error {
   public let exception: NSException
   public init(exception: NSException) {
	  self.exception = exception
   }
}

public struct ObjectiveCExceptions {
   public static func performTry(workItem: () -> Void) throws {
	  let exception = ExecuteWithObjCExceptionHandling {
		 workItem()
	  }
	  if let exception = exception {
		 throw NSExceptionError(exception: exception)
	  }
   }
}
