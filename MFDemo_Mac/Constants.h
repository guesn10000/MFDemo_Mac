//
//  Constants.h
//  MFDemo_Mac
//
//  Created by Jymn_Chen on 14-5-22.
//  Copyright (c) 2014年 Jymn_Chen. All rights reserved.
//

#ifndef MFDemo_Mac_Constants_h
#define MFDemo_Mac_Constants_h

extern NSString * const kWebAPIURL; // 要发起请求的URL
extern NSString * const kClientID;  // 你申请的应用的Client ID
extern NSString * const kClientTag; // 你申请的应用的Client Tag

extern NSString * const kUserID; // 从NSUserDefaults中取出User ID时对应的Key值

// 在解析返回结果的XML数据时，遇到的一些XML结点值
#define kGNResponse    @"RESPONSE"
#define kGNRange       @"RANGE"
#define kGNCount       @"COUNT"
#define kGNStart       @"START"
#define kGNAlbum       @"ALBUM"
#define kGNID          @"GN_ID"
#define kGNArtist      @"ARTIST"
#define kGNUser        @"USER"
#define kGNTitle       @"TITLE"
#define kGNLanguage    @"PKG_LANG"
#define kGNDate        @"DATE"
#define kGNGenre       @"GENRE"
#define kGNTrackCount  @"TRACK_COUNT"
#define kGNTrack       @"TRACK"
#define kGNURL         @"URL"
#define kGNType        @"TYPE"
#define kGNCoverArt    @"COVERART"
#define kGNArtistImage @"ARTIST_IMAGE"
#define kGNStatus      @"STATUS"
#define kGNStatusOK    @"OK"
#define kGNStatusNoMatch @"NO_MATCH"
#define kGNStatusError @"ERROR"

#endif
