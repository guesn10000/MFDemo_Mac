//
//  MFAlbum.h
//  MFDemo_Mac
//
//  Created by Jymn_Chen on 14-5-21.
//  Copyright (c) 2014年 Jymn_Chen. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MFAlbum : NSObject

/**
 *  通过xml二进制数据初始化本类对象，其中要使用GDataXML类库解析这些xml数据
 */
- (instancetype)initWithXMLData:(NSData *)xmlData;

// 专辑封面图片所在的URL字符串
@property (copy, readonly, nonatomic) NSString *coverArtURLString;

// 艺术家照片所在的URL字符串
@property (copy, readonly, nonatomic) NSString *artistImageURLString;

// 专辑中的歌曲数
@property (assign, readonly, nonatomic) NSUInteger trackCount;

/**
 *  在控制台输出该对象的完整信息，仅用于调试
 */
- (void)logoutDetails;

@end
