//
//  MFAlbum.m
//  MFDemo_Mac
//
//  Created by Jymn_Chen on 14-5-21.
//  Copyright (c) 2014年 Jymn_Chen. All rights reserved.
//

#import "MFAlbum.h"
#import <GDataXML-HTML/GDataXMLNode.h>
#import "Constants.h"

@interface MFAlbum ()

// GN_ID，在数据库中唯一标识该专辑
@property (copy, nonatomic) NSString *gn_id;

// 艺术家名
@property (copy, nonatomic) NSString *artistName;

// 专辑标题
@property (copy, nonatomic) NSString *albumTitle;

// 语言
@property (copy, nonatomic) NSString *language;

// 发行时间
@property (copy, nonatomic) NSString *releaseDate;

// 歌曲风格
@property (copy, nonatomic) NSString *genre;

// 专辑中的歌曲数
@property (assign, nonatomic) NSUInteger trackCount;

// 专辑中所有歌曲的标题
@property (copy, nonatomic) NSMutableArray *allTracks;

// 专辑封面图片所在的URL字符串
@property (copy, nonatomic) NSString *coverArtURLString;

// 艺术家照片所在的URL字符串
@property (copy, nonatomic) NSString *artistImageURLString;

@end

@implementation MFAlbum

- (instancetype)initWithXMLData:(NSData *)xmlData {
    self = [super init];
    if (self) {
        NSError *parseError = nil;
        GDataXMLDocument *doc = [[GDataXMLDocument alloc] initWithData:xmlData encoding:NSUTF8StringEncoding error:&parseError];
        if (parseError) {
            NSLog(@"Parse Error:%@", [parseError localizedDescription]);
            return nil; // 转换出错，直接返回nil
        }
        
        // 逐个解析xml结点，获取专辑对象所需要的所有信息
        GDataXMLElement *rootElement = [doc rootElement];
        GDataXMLElement *response = [rootElement elementsForName:kGNResponse][0];
        if (![self gn_requestSucceed:response]) {
            return nil;
        }
        
        GDataXMLElement *album = [response elementsForName:kGNAlbum][0];
        _gn_id = [[album elementsForName:kGNID][0] stringValue];
        _artistName = [[album elementsForName:kGNArtist][0] stringValue];
        _albumTitle = [[album elementsForName:kGNTitle][0] stringValue];
        _language = [[album elementsForName:kGNLanguage][0] stringValue];
        _releaseDate = [[album elementsForName:kGNDate][0] stringValue];
        _genre = [[album elementsForName:kGNGenre][0] stringValue];
        _trackCount = (NSUInteger)[[[album elementsForName:kGNTrackCount][0] stringValue] integerValue];
        
        _allTracks = [NSMutableArray array];
        NSArray *tracks = [album elementsForName:kGNTrack];
        for (GDataXMLElement *trackElement in tracks) {
            NSString *title = [[trackElement elementsForName:kGNTitle][0] stringValue];
            [_allTracks addObject:title];
        }
        
        NSArray *urlElements = [album elementsForName:kGNURL];
        if (!urlElements) {
            return self;
        }
        for (GDataXMLElement *element in urlElements) {
            GDataXMLNode *node = [element attributeForName:kGNType];
            NSString *type = [node stringValue];
            if ([type isEqualToString:kGNCoverArt]) {
                _coverArtURLString = [element stringValue];
            }
            else if ([type isEqualToString:kGNArtistImage]) {
                _artistImageURLString = [element stringValue];
            }
        }
    }
    return self;
}

// 通过返回的XML数据判断请求是否成功，如果请求成功，返回的状态为OK，如果出错，状态为ERROR
- (BOOL)gn_requestSucceed:(GDataXMLElement *)element {
    GDataXMLNode *statusNode = [element attributeForName:kGNStatus];
    NSString *status = [statusNode stringValue];
    if ([status isEqualToString:kGNStatusOK]) {
        return YES;
    }
    else if ([status isEqualToString:kGNStatusError]) {
        NSLog(@"请求出错");
    }
    else if ([status isEqualToString:kGNStatusNoMatch]) {
        NSLog(@"没有找到匹配的结果");
    }
    
    return NO;
}

- (void)logoutDetails {
    NSLog(@"*** Album Detail ***");
    NSLog(@"gn_id = %@", _gn_id);
    NSLog(@"artist name = %@", _artistName);
    NSLog(@"album title = %@", _albumTitle);
    NSLog(@"language = %@", _language);
    NSLog(@"release date = %@", _releaseDate);
    NSLog(@"genre = %@", _genre);
    NSLog(@"trackCount = %ld", _trackCount);
    NSLog(@"coverart url = %@", _coverArtURLString);
    NSLog(@"artist image url = %@", _artistImageURLString);
    NSLog(@"All tracks = %@", _allTracks);
    NSLog(@"---------------------------");
}

@end
