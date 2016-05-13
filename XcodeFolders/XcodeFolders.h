//
//  XcodeFolders.h
//  XcodeFolders
//
//  Created by Jacobo Rodriguez on 13/5/16.
//  Copyright © 2016 tBear Software. All rights reserved.
//

#import <AppKit/AppKit.h>

@interface XcodeFolders : NSObject

@property (nonatomic, strong, readonly) NSBundle *bundle;

+ (instancetype)sharedPlugin;

@end