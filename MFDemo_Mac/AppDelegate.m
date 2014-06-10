//
//  AppDelegate.m
//  MFDemo_Mac
//
//  Created by Jymn_Chen on 14-5-21.
//  Copyright (c) 2014年 Jymn_Chen. All rights reserved.
//

/*
 * MusicFans Album Complement
 */

#define TEST_NUM 1

#import "AppDelegate.h"
#import "MFAlbum.h"
#import "Constants.h"

// 要使用GDataXML类库解析XML文件，首先要导入该头文件
#import <GDataXML-HTML/GDataXMLNode.h>

#pragma mark - Constants

NSString * const kWebAPIURL = @"https://c10239232.web.cddbp.net/webapi/xml/1.0/"; // 调用网络接口的URL
NSString * const kClientID  = @"4541440"; // 你申请的应用的Client ID
NSString * const kClientTag = @"79EFBF4E21724D084BA87FF9B242F0C9"; // 你申请的应用的Client Tag
//NSString * const kClientID  = @"10239232"; // 你申请的应用的Client ID
//NSString * const kClientTag = @"46B9ABAD30F0F5EB409C7BFAA13EB2EF"; // 你申请的应用的Client Tag

/* 将数据存储进UserDefaults时使用的Key值 */
NSString * const kUserID = @"UserID";

@interface AppDelegate () <NSTableViewDataSource, NSTableViewDelegate>
{
    NSUInteger p_currentPage;
    NSUInteger p_allPages;
}

/**
 * 在执行查询前必须注册一个User ID，注册完成后可将其存储在本地，下次使用时无需重新注册
 */
@property (copy, nonatomic) NSString *app_userID;

@property (strong, nonatomic) NSMutableArray *gn_IDs;

/**
 *  保存查询到的专辑的详细内容，成员为MFAlbum类
 */
@property (strong, nonatomic) NSMutableArray *searchAlbums;

@property (weak) IBOutlet NSTableView *resultsTableView;

@property (weak) IBOutlet NSTextField *resultsCount_label;

@property (weak) IBOutlet NSTextField *currentPage_label;
@property (weak) IBOutlet NSButton *previousPage_button;
@property (weak) IBOutlet NSButton *nextPage_button;

@end

@implementation AppDelegate

#pragma mark - NSApplicationDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    self.gn_IDs = [NSMutableArray array];
    self.searchAlbums = [NSMutableArray array];
    
    // 初始化搜索结果在界面的展示
    p_currentPage = 0;
    p_allPages = 0;
    [self updatePagingText];
    [self showSearchResultsCountText:0];
    [_previousPage_button setEnabled:NO];
    [_nextPage_button setEnabled:NO];
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *userID = [userDefaults objectForKey:kUserID];
    if (!userID) { // 启动应用后，首先要注册一个User ID，用于执行后面的查询请求
        [self gn_registerUserID];
    }
    else {
        self.app_userID = userID;
        NSLog(@"*** Get User ID from UserDefaults ***");
        NSLog(@"User ID = %@", userID);
        
#if TEST_NUM == 0
        [self gn_albumSearchWithArtist:@"Ludwig van Beethoven"
                            albumTitle:@""
                            trackTitle:@""
                                 start:1
                                   end:10];
#elif TEST_NUM == 1
        [self gn_albumSearchWithArtist:@"Ludwig van Beethoven"
                            albumTitle:@"Symphonie No. 9"
                            trackTitle:@"Symphony No. 9 in D minor, Op. 125: I. Allegro ma non troppo, un poco maestoso"
                                 start:1
                                   end:10];
#elif TEST_NUM == 2
        [self gn_albumSearchWithArtist:@"Mozart"
                            albumTitle:@""
                            trackTitle:@"Contredanse"
                                 start:1
                                   end:10];
#elif TEST_NUM == 3
        // 注意查询的字符串中不能带有非法字符，如&，斜杠，@等
        // &要转换为&amp;
        [self gn_albumSearchWithArtist:@"The Carpenters"
                            albumTitle:@"Now &amp; Then"
                            trackTitle:@"Yesterday Once More"
                                 start:1
                                   end:10];
#endif
    }
}

// 向GraceNote网站注册User ID
- (void)gn_registerUserID {
    NSString *registerString = [NSString stringWithFormat:@"\
                                <QUERIES>\
                                    <QUERY CMD=\"REGISTER\">\
                                        <CLIENT>%@-%@</CLIENT>\
                                    </QUERY>\
                                </QUERIES>",
                                kClientID, kClientTag]; // 要POST的字符串，CMD=REGISTER表示注册动作
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:kWebAPIURL]];
    [request setHTTPMethod:@"POST"];
    NSData *data = [registerString dataUsingEncoding:NSUTF8StringEncoding];
    [request setHTTPBody:data];
    
    // 建立NSURLSessionDataTask
    NSURLSession *session = [NSURLSession sharedSession];
    __weak AppDelegate *weakSelf = self; // 防止self和block形成retain cycle
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSLog(@"*** Register ***");
        [self showResponseCode:response];
        
        if (data) {
            NSError *parseError = nil;
            // 这里使用第三方类库GDataXML解析XML数据，请确保已经安装GDataXML类库
            GDataXMLDocument *doc = [[GDataXMLDocument alloc] initWithData:data encoding:NSUTF8StringEncoding error:&parseError];
            if (parseError) {
                NSLog(@"Parse Error:%@", [parseError localizedDescription]);
                weakSelf.app_userID = nil;
            }
            else {
                /**
                 *  返回的XML数据示例：
                 <RESPONSES>
                    <RESPONSE STATUS="OK">
                        <USER>267493051066226693-31C70A189A61B89C0D45A782DCB7C072</USER>
                    </RESPONSE>
                 </RESPONSES>
                 */
                GDataXMLElement *rootElement = [doc rootElement];
                NSArray *responses = [rootElement elementsForName:kGNResponse];
                GDataXMLElement *resp = responses[0];
                if (![self gn_requestSucceed:resp]) {
                    return;
                }
                
                NSString *userID = [[resp elementsForName:kGNUser][0] stringValue];
                
                // 将获取到的user id保存起来
                weakSelf.app_userID = userID;
                
                // 将user id存储到User Defaults中
                NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
                [userDefaults setObject:userID forKey:kUserID];
                [userDefaults synchronize];
                
                NSLog(@"User ID = %@", userID);
            }
        }
        
        if (error) {
            NSLog(@"error : %@", [error localizedDescription]);
        }
        
        NSLog(@"--- Register Finished ---");
    }];
    
    // 最后一定要用resume方法启动任务
    [dataTask resume];
}

// 以Artist，Album Title，Track Title为搜索关键字，发起搜索请求
// 返回的搜索结果有多个，用start和end返回的起始和终止索引，例如start = 11, end = 20，那么返回搜索结果中的第11到20条
- (void)gn_albumSearchWithArtist:(NSString *)anArtist
                      albumTitle:(NSString *)anAlbumTitle
                      trackTitle:(NSString *)aTrackTitle
                           start:(NSUInteger)startIndex
                             end:(NSUInteger)endIndex
{
    // 首先移除上次残留的查询结果
    [_gn_IDs removeAllObjects];
    
    // 首先做错误判断
    if (startIndex <= 0 || endIndex <= 0 || startIndex > endIndex) {
        [_previousPage_button setEnabled:YES];
        [_nextPage_button setEnabled:YES];
        return;
    }
    
    // 设置查询字符串，本次请求属于ALBUM_SEARCH操作
    NSString *searchString = [NSString stringWithFormat:@"\
                              <QUERIES>\
                                <AUTH>\
                                    <CLIENT>%@-%@</CLIENT>\
                                    <USER>%@</USER>\
                                </AUTH>\
                                <QUERY CMD=\"ALBUM_SEARCH\">\
                                    <TEXT TYPE=\"ARTIST\">%@</TEXT>\
                                    <TEXT TYPE=\"ALBUM_TITLE\">%@</TEXT>\
                                    <TEXT TYPE=\"TRACK_TITLE\">%@</TEXT>\
                                    <RANGE>\
                                        <START>%ld</START>\
                                        <END>%ld</END>\
                                    </RANGE>\
                                </QUERY>\
                              </QUERIES>",
                              kClientID, kClientTag, _app_userID, anArtist, anAlbumTitle, aTrackTitle, startIndex, endIndex];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:kWebAPIURL]];
    [request setHTTPMethod:@"POST"];
    NSData *data = [searchString dataUsingEncoding:NSUTF8StringEncoding];
    [request setHTTPBody:data];
    
    // 建立NSURLSessionDataTask并用resume方法启动任务
    NSURLSession *session = [NSURLSession sharedSession];
    __weak AppDelegate *weakSelf = self;
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSLog(@"*** Album Search ***");
        [self showResponseCode:response];
        
        if (data) {
            NSError *parseError = nil;
            GDataXMLDocument *doc = [[GDataXMLDocument alloc] initWithData:data encoding:NSUTF8StringEncoding error:&parseError];
            if (parseError) {
                NSLog(@"Parse Error:%@", [parseError localizedDescription]);
            }
            else {
                /**
                 *  请求成功，返回XML结果示例：
                 <RESPONSES>
                    <RESPONSE STATUS="OK">
                        <RANGE>
                            <COUNT>2</COUNT>
                            <START>1</START>
                            <END>2</END>
                        </RANGE>
                        <ALBUM ORD="1">
                            <GN_ID>7552265-4E82AF73CE400EDC94DCDA49547C585F</GN_ID>
                            <ARTIST>The Carpenters</ARTIST>
                            <TITLE>Now &amp; Then</TITLE>
                            <PKG_LANG>ENG</PKG_LANG>
                            <DATE>1973</DATE>
                            <GENRE NUM="61365" ID="25333">70&apos;s Rock</GENRE>
                            <MATCHED_TRACK_NUM>6</MATCHED_TRACK_NUM>
                            <TRACK_COUNT>15</TRACK_COUNT>
                            <TRACK>
                                <TRACK_NUM>6</TRACK_NUM>
                                <GN_ID>7552271-366ED2D1FEB61E8D720D4941009C91A9</GN_ID>
                                <TITLE>Yesterday Once More</TITLE>
                            </TRACK>
                        </ALBUM>
                        <ALBUM ORD="2">
                            <GN_ID>19546461-AA0668FE5972459884664A7C3FE9D9C2</GN_ID>
                            <ARTIST>The Carpenters</ARTIST>
                            <TITLE>Now And Then</TITLE>
                            <PKG_LANG>ENG</PKG_LANG>
                            <GENRE NUM="61365" ID="25333">70&apos;s Rock</GENRE>
                            <MATCHED_TRACK_NUM>6</MATCHED_TRACK_NUM>
                            <TRACK_COUNT>8</TRACK_COUNT>
                            <TRACK>
                                <TRACK_NUM>6</TRACK_NUM>
                                <GN_ID>19546467-560982E049BFF85016AB89C37513F474</GN_ID>
                                <TITLE>Yesterday Once More</TITLE>
                            </TRACK>
                        </ALBUM>
                    </RESPONSE>
                 </RESPONSES>
                 */
                GDataXMLElement *rootElement = [doc rootElement];
                NSArray *responses = [rootElement elementsForName:kGNResponse];
                if ([responses count]) {
                    GDataXMLElement *resp = [responses firstObject];
                    if (![self gn_requestSucceed:resp]) {
                        return;
                    }
                    
                    GDataXMLElement *range = [resp elementsForName:kGNRange][0];
                    if (!range) { // 如果没有返回range元素，那么抓取数据失败
                        NSLog(@"Fail to search album");
                        return;
                    }
                    NSUInteger count = (NSUInteger)[[[range elementsForName:kGNCount][0] stringValue] integerValue];
                    NSUInteger start = (NSUInteger)[[[range elementsForName:kGNStart][0] stringValue] integerValue];
                    
                    if (count <= 0) { // 没有搜索到结果，直接返回
                        [self showSearchResultsCountText:0];
                        return;
                    }
                    
                    // 计算当前页数和总页数，并更新界面
                    p_currentPage = start / 10 + 1;
                    p_allPages = count / 10;
                    NSUInteger i = (count - count / 10 * 10) ? 1 : 0;
                    p_allPages += i;
                    [self updatePagingText];
                    [self showSearchResultsCountText:count];
                    
                    // searchCount表示本次返回的搜索结果总数
                    NSUInteger searchCount = 0;
                    if (endIndex >= count) {
                        searchCount = count - startIndex;
                    }
                    else {
                        searchCount = endIndex - startIndex;
                    }
                    
                    NSArray *albums = [resp elementsForName:kGNAlbum];
                    for (NSUInteger i = 0; i <= searchCount; i++) {
                        GDataXMLElement *album = albums[i];
                        NSString *gn_id = [[album elementsForName:kGNID][0] stringValue];
                        
                        // 将每一条搜索结果的GN_ID添加到数组gn_IDs中
                        [weakSelf.gn_IDs addObject:gn_id];
                    }
                    
                    // 恢复翻页按钮的响应
                    [_previousPage_button setEnabled:YES];
                    [_nextPage_button setEnabled:YES];
                    
                    // 逐个抓取专辑的具体信息
                    [weakSelf albumFetch];
                }
            }
        }
        
        if (error) {
            NSLog(@"error : %@", [error localizedDescription]);
        }
        
        NSLog(@"--- Album Search Finished ---");
    }];
    
    [dataTask resume];
}

// 逐个抓取专辑的具体信息
- (void)albumFetch {
    // 首先移除上次搜索的残留数据
    [_searchAlbums removeAllObjects];
    
    // 以gn_IDs中的每一个gnID为搜索关键字，执行album fetch请求，抓取专辑的完整信息
    for (NSString *gnID in _gn_IDs) {
        [self gn_albumFetchWithGNID:gnID];
    }
}

// 以GN_ID为搜索关键字，执行album fetch请求，抓取专辑的完整信息
- (void)gn_albumFetchWithGNID:(NSString *)aID {
    // 设置要查询的字符串，本次操作为ALBUM_FETCH操作
    NSString *searchString = [NSString stringWithFormat:@"\
                              <QUERIES>\
                                <AUTH>\
                                    <CLIENT>%@-%@</CLIENT>\
                                    <USER>%@</USER>\
                                </AUTH>\
                                <QUERY CMD=\"ALBUM_FETCH\">\
                                    <MODE>SINGLE_BEST_COVER</MODE>\
                                    <GN_ID>%@</GN_ID>\
                                    <OPTION>\
                                        <PARAMETER>SELECT_EXTENDED</PARAMETER>\
                                        <VALUE>COVER,ARTIST_IMAGE</VALUE>\
                                    </OPTION>\
                                    <OPTION>\
                                        <PARAMETER>COVER_SIZE</PARAMETER>\
                                        <VALUE>THUMBNAIL</VALUE>\
                                    </OPTION>\
                                </QUERY>\
                              </QUERIES>",
                              kClientID, kClientTag, _app_userID, aID];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:kWebAPIURL]];
    [request setHTTPMethod:@"POST"];
    NSData *data = [searchString dataUsingEncoding:NSUTF8StringEncoding];
    [request setHTTPBody:data];
    
    // 建立NSURLSessionDataTask并用resume方法启动任务
    NSURLSession *session = [NSURLSession sharedSession];
    __weak AppDelegate *weakSelf = self;
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSLog(@"*** Album Fetch ***");
        [self showResponseCode:response];

        if (data) {
            /*
             * 返回的XML结果示例：
             <RESPONSES>
                <RESPONSE STATUS="OK">
                    <ALBUM>
                        <GN_ID>84560577-7A6534AF0D13986003DEE32E8A0AA344</GN_ID>
                        <ARTIST>Leslie Howard</ARTIST>
                        <TITLE>Liszt: The Complete Music For Solo Piano, Vol. 22 – The Beethoven Symphonies [Disc 5]</TITLE>
                        <PKG_LANG>ENG</PKG_LANG>
                        <DATE>1993</DATE>
                        <GENRE NUM="125246" ID="43686">Other Classical</GENRE>
                        <TRACK_COUNT>4</TRACK_COUNT>
                        <TRACK>
                            <TRACK_NUM>1</TRACK_NUM>
                            <GN_ID>84560578-480E4C88EFFAB3A71B0931C879C3C465</GN_ID>
                            <TITLE>Beethoven/Liszt: Symphony #9 In D Minor, S 464/9, &quot;Choral&quot; - 1. Allegro Ma Non Troppo, Un Poco Maestoso</TITLE>
                        </TRACK>
                        <TRACK>
                            <TRACK_NUM>2</TRACK_NUM>
                            <GN_ID>84560579-76D91DC5953DC6A831AC39C90982E00F</GN_ID>
                            <TITLE>Beethoven/Liszt: Symphony #9 In D Minor, S 464/9, &quot;Choral&quot; - 2. Molto Vivace, Presto, Da Capo Tutto, Coda, Presto</TITLE>
                        </TRACK>
                        <TRACK>
                            <TRACK_NUM>3</TRACK_NUM>
                            <GN_ID>84560580-58C40AA62685745452BC0EAA68050453</GN_ID>
                            <TITLE>Beethoven/Liszt: Symphony #9 In D Minor, S 464/9, &quot;Choral&quot; - 3. Adagio Molto E Cantabile, Andante Moderato</TITLE>
                        </TRACK>
                        <TRACK>
                            <TRACK_NUM>4</TRACK_NUM>
                            <GN_ID>84560581-3EBD17DB4984905749986AC8034C76BC</GN_ID>
                            <TITLE>Beethoven/Liszt: Symphony #9 In D Minor, S 464/9, &quot;Choral&quot; - 4. Presto, Allegro Assai &apos;Ode To Joy&apos;</TITLE>
                        </TRACK>
                        <URL TYPE="COVERART" SIZE="THUMBNAIL" WIDTH="75" HEIGHT="75">http://akamai-b.cdn.cddbp.net/cds/2.0/cover/726E/E6DD/B718/6BC9_thumbnail_front.jpg</URL>
                        <URL TYPE="ARTIST_IMAGE" SIZE="THUMBNAIL" WIDTH="57" HEIGHT="75">http://akamai-b.cdn.cddbp.net/cds/2.0/image-artist/E551/CE4E/35E0/00C5_thumbnail_front.jpg</URL>
                    </ALBUM>
                </RESPONSE>
             </RESPONSES>
             */
            
//            // 输出返回的xml内容
//            [self logoutXMLData:data];
            
            // 通过返回的xml二进制数据初始化MFAlbum对象
            MFAlbum *album = [[MFAlbum alloc] initWithXMLData:data];
            if (album) {
                // 将查询结果添加到searchAlbums数组中
                [weakSelf.searchAlbums addObject:album];
            }
            
            [weakSelf showResults];
        }
        
        if (error) {
            NSLog(@"error : %@", [error localizedDescription]);
        }
        
        NSLog(@"--- Album Fetch Finished ---");
    }];
    
    [dataTask resume];
}

// 第四步：当抓取专辑信息成功后，显示所有搜索到的专辑的完整信息
- (void)showResults {
    NSLog(@"*** Search Results ***");
    for (MFAlbum *album in _searchAlbums) {
        [album logoutDetails];
    }
    
    [_resultsTableView reloadData];
    
    NSLog(@"--- Search Results Finished ---");
}

// 在控制台打印请求返回的HTTP状态码
- (void)showResponseCode:(NSURLResponse *)response {
    NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
    NSInteger responseStatusCode = [httpResponse statusCode];
    NSLog(@"%ld", responseStatusCode);
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

// 输出请求返回的xml数据
- (void)logoutXMLData:(NSData *)xmlData {
    NSString *xmlString = [[NSString alloc] initWithData:xmlData encoding:NSUTF8StringEncoding];
    NSLog(@"xml string = %@", xmlString);
}

#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [_searchAlbums count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    NSString *unknown = @"未知";
    MFAlbum *album = _searchAlbums[row];
    NSString *identifier = tableColumn.identifier;
    if ([identifier isEqualToString:@"coverArt"]) {
        NSURL *coverArtURL = [NSURL URLWithString:album.coverArtURLString];
        NSImage *image;
        if (coverArtURL) {
            image = [[NSImage alloc] initWithContentsOfURL:coverArtURL];
        }
        else {
            image = [NSImage imageNamed:@"NotFound"];
        }
        return image;
    }
    else if ([identifier isEqualToString:@"artistImage"]) {
        NSURL *artistImageURL = [NSURL URLWithString:album.artistImageURLString];
        NSImage *image;
        if (artistImageURL) {
            image = [[NSImage alloc] initWithContentsOfURL:artistImageURL];
        }
        else {
            image = [NSImage imageNamed:@"NotFound"];
        }
        
        return image;
    }
    else if ([identifier isEqualToString:@"trackCount"]) {
        return [NSString stringWithFormat:@"%ld", album.trackCount] ? [NSString stringWithFormat:@"%ld", album.trackCount] : unknown;
    }
    else {
        NSString *info = [album valueForKey:identifier];
        return info ? info : unknown;
    }
}

#pragma mark - Paging

// 点击上一页按钮
- (IBAction)previousPage:(id)sender {
    if (p_currentPage == 1) {
        NSLog(@"第一页，不能再向前翻了");
        return;
    }
    
    p_currentPage--;
    [self pagingSearchRequest];
}

// 点击下一页按钮
- (IBAction)nextPage:(id)sender {
    if (p_currentPage == p_allPages) {
        NSLog(@"最后一页，不能再向后翻了");
        return;
    }
    
    p_currentPage++;
    [self pagingSearchRequest];
}

// 翻页时执行的网络请求
- (void)pagingSearchRequest {
    [_previousPage_button setEnabled:NO];
    [_nextPage_button setEnabled:NO];
    
    // 例如上一次返回的结果是11 - 20条，那么翻向下一页返回的结果是21 - 30条(start = 21, end = 30)，
    // 翻向上一页返回的结果是1 - 10条(start = 1, end = 10)
    NSUInteger start = (p_currentPage - 1) * 10 + 1;
    NSUInteger end = start + 9;
    
    // 根据start和end发起新的请求，返回前面10个或后面10个搜索结果
#if TEST_NUM == 0
    [self gn_albumSearchWithArtist:@"Ludwig van Beethoven"
                        albumTitle:@""
                        trackTitle:@""
                             start:start
                               end:end];
#elif TEST_NUM == 1
    [self gn_albumSearchWithArtist:@"Ludwig van Beethoven"
                        albumTitle:@"Symphonie No. 9"
                        trackTitle:@"Symphony No. 9 in D minor, Op. 125: I. Allegro ma non troppo, un poco maestoso"
                             start:start
                               end:end];
#elif TEST_NUM == 2
    [self gn_albumSearchWithArtist:@"Mozart"
                        albumTitle:@""
                        trackTitle:@"Contredanse"
                             start:start
                               end:end];
#elif TEST_NUM == 3
    // 注意查询的字符串中不能带有非法字符，如&，斜杠，@等
    // &要转换为&amp;
    [self gn_albumSearchWithArtist:@"The Carpenters"
                        albumTitle:@"Now &amp; Then"
                        trackTitle:@"Yesterday Once More"
                             start:start
                               end:end];
#endif
    
}

// 更新当前页面进度，如 2 / 12，2是当前页，12是总页数。
- (void)updatePagingText {
    NSString *progress = [NSString stringWithFormat:@"%ld / %ld", p_currentPage, p_allPages];
    NSTextFieldCell *cell = _currentPage_label.cell;
    [cell setTitle:progress];
}

// 显示一共有多少个搜索结果
- (void)showSearchResultsCountText:(NSUInteger)count {
    NSString *pageCountString = [NSString stringWithFormat:@"%ld个搜索结果", count];
    NSTextFieldCell *cell = _resultsCount_label.cell;
    [cell setTitle:pageCountString];
}

@end

