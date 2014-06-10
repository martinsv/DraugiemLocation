//
//  UserCacheController.h
//  Photo Bombers
//
//  Created by Armands Lazdiņš on 10/06/14.
//  Copyright (c) 2014 Armands Lazdiņš. All rights reserved.
//

/* SVARIGI
 
 Oriģināli biju paredzējis katru lejuplādēto lietotāja bildi saglabāt gan NSCache, gan ierīcē, izmantojot NSFileManager.
 Diemžēl, šķiet, ka Xcode 6 ir bugs ar metožu return type un input parameters, nav iespējams ievietot UI objektus.
 Pastāv iespēja, ka šis bugs ir tikai uz manas sistēmas, tāpēc Models - > cahceControllet mapītē Jūs atradīsiet cacheController failus.
 Faili nav pievienoti projektam.
 
 Sīkāk: http://stackoverflow.com/questions/24147741/xcode-6-cant-return-uiimage-from-method
 
 */

#import <Foundation/Foundation.h>

@interface UserCacheController : NSObject

@property (nonatomic) NSCache *cache;

+ (UserCacheController *)sharedCache;

- (void)setImage:(UIImage *)image forKey:(NSString *)key;
- (UIImage *)getImageForKey:(NSString *)key;
- (void)clearCache;


@end
