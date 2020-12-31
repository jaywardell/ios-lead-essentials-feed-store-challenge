//
//  BridgingHeader.h
//  FeedStoreChallenge
//
//  Created by Joseph Wardell on 12/31/20.
//  Copyright © 2020 Essential Developer. All rights reserved.
//

@import Foundation;

#ifndef BridgingHeader_h
#define BridgingHeader_h
NS_INLINE NSException * _Nullable ExecuteWithObjCExceptionHandling(void(NS_NOESCAPE^_Nonnull tryBlock)(void)) {
	@try {
		tryBlock();
	}
	@catch (NSException *exception) {
		return exception;
	}
	return nil;
}


#endif /* BridgingHeader_h */
