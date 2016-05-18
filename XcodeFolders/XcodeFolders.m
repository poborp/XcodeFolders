//
//  XcodeFolders.m
//  XcodeFolders
//
//  Created by Jacobo Rodriguez on 13/5/16.
//  Copyright © 2016 tBear Software. All rights reserved.
//

#define kUserLibraryPath [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0]
#define kCodeSnippetsPath [kUserLibraryPath stringByAppendingPathComponent:@"/Developer/Xcode/UserData/CodeSnippets"]
#define kFileTemplatesPath [kUserLibraryPath stringByAppendingPathComponent:@"/Developer/Xcode/Templates/File Templates"]
#define kPluginsPath [kUserLibraryPath stringByAppendingPathComponent:@"/Application Support/Developer/Shared/Xcode/Plug-ins"]
#define kDevicesPath [kUserLibraryPath stringByAppendingPathComponent:@"/Developer/CoreSimulator/Devices/"]

#import "XcodeFolders.h"

static XcodeFolders *sharedPlugin;

@implementation XcodeFolders

#pragma mark - Initialization

+ (void)pluginDidLoad:(NSBundle *)plugin {
    
    NSArray *allowedLoaders = [plugin objectForInfoDictionaryKey:@"me.delisa.XcodePluginBase.AllowedLoaders"];
    if ([allowedLoaders containsObject:[[NSBundle mainBundle] bundleIdentifier]]) {
        sharedPlugin = [[self alloc] initWithBundle:plugin];
    }
}

+ (instancetype)sharedPlugin {
    
    return sharedPlugin;
}

- (instancetype)initWithBundle:(NSBundle *)bundle {
    
    self = [super init];
    if (self) {
        _bundle = bundle;
        
        if (NSApp && !NSApp.mainMenu) {
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidFinishLaunching:) name:NSApplicationDidFinishLaunchingNotification object:nil];
        } else {
            [self initializeAndLog];
        }
    }
    return self;
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSApplicationDidFinishLaunchingNotification object:nil];
    [self initializeAndLog];
}

- (void)initializeAndLog {
    
    NSString *name = [self.bundle objectForInfoDictionaryKey:@"CFBundleName"];
    NSString *version = [self.bundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    NSString *status = [self initialize] ? @"loaded successfully" : @"failed to load";
    NSLog(@"Plugin %@ %@ %@", name, version, status);
}

#pragma mark - Implementation

- (BOOL)initialize {
    
    NSMenuItem *menuItem = [[NSApp mainMenu] itemWithTitle:@"View"];
    if (menuItem) {

        [menuItem.submenu addItem:[NSMenuItem separatorItem]];

        NSMenuItem *menuBarItem = [[NSMenuItem alloc] initWithTitle:@"Xcode Folders" action:NULL keyEquivalent:@""];

        NSMenu *newMenu = [[NSMenu alloc] initWithTitle:@"Folders"];
        menuBarItem.submenu = newMenu;
        [menuItem.submenu addItem:menuBarItem];
        
        return [self initializeWithMainMenuItem:menuBarItem];
        
    } else {

        NSMenuItem *foldersBarItem = [[NSMenuItem alloc] initWithTitle:@"Folders" action:nil keyEquivalent:@""];
        foldersBarItem.submenu = [[NSMenu alloc] initWithTitle:@"Folders"];
        [[NSApp mainMenu] insertItem:foldersBarItem atIndex:3];
        
        return [self initializeWithMainMenuItem:foldersBarItem];
    }
}

- (BOOL)initializeWithMainMenuItem:(NSMenuItem *)mainMenuItem {
    
    NSMenuItem *codeSnippetsMenuItem = [[NSMenuItem alloc] initWithTitle:@"CodeSnippets" action:@selector(didPressFolderMenuItem:) keyEquivalent:@""];
    codeSnippetsMenuItem.target = self;
    codeSnippetsMenuItem.representedObject = kCodeSnippetsPath;
    [mainMenuItem.submenu addItem:codeSnippetsMenuItem];
    
    NSMenuItem *fileTemplatesMenuItem = [[NSMenuItem alloc] initWithTitle:@"File Templates" action:@selector(didPressFolderMenuItem:) keyEquivalent:@""];
    fileTemplatesMenuItem.target = self;
    fileTemplatesMenuItem.representedObject = kFileTemplatesPath;
    [mainMenuItem.submenu addItem:fileTemplatesMenuItem];
    
    NSMenuItem *pluginsMenuItem = [[NSMenuItem alloc] initWithTitle:@"Plug-ins" action:@selector(didPressFolderMenuItem:) keyEquivalent:@""];
    pluginsMenuItem.target = self;
    pluginsMenuItem.representedObject = kPluginsPath;
    [mainMenuItem.submenu addItem:pluginsMenuItem];
    
    [mainMenuItem.submenu addItem:[NSMenuItem separatorItem]];

    NSMenuItem *currentProjectMenuItem = [[NSMenuItem alloc] initWithTitle:@"Current Project" action:@selector(didPressProyectFolderMenuItem:) keyEquivalent:@""];
    currentProjectMenuItem.target = self;
    [mainMenuItem.submenu addItem:currentProjectMenuItem];
    
    NSMenuItem *simulatorsItem = [[NSMenuItem alloc] initWithTitle:@"Simulator" action:@selector(didPressFolderMenuItem:) keyEquivalent:@""];
    simulatorsItem.target = self;
    simulatorsItem.representedObject = kDevicesPath;
    [mainMenuItem.submenu addItem:simulatorsItem];
    
    NSString *simulatorListPath = [kDevicesPath stringByAppendingPathComponent:@"device_set.plist"];
    NSDictionary *simulators = [NSDictionary dictionaryWithContentsOfFile:simulatorListPath];
    
    if (simulators) {
        simulatorsItem.submenu = [[NSMenu alloc] initWithTitle:@"Simulator"];
        
        NSDictionary *defaultDevices = simulators[@"DefaultDevices"];
        for (NSString *key in [defaultDevices.allKeys sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)]) {
            if (![key isEqualToString:@"version"]) {
                NSString *deviceVersion = [key stringByReplacingOccurrencesOfString:@"com.apple.CoreSimulator.SimRuntime." withString:@""];
                deviceVersion = [deviceVersion stringByReplacingOccurrencesOfString:@"-" withString:@" "];
                
                NSMenuItem *versionMenuItem = [[NSMenuItem alloc] initWithTitle:deviceVersion action:nil keyEquivalent:@""];
                versionMenuItem.target = self;
                versionMenuItem.submenu = [[NSMenu alloc] initWithTitle:@"Devices"];
                [simulatorsItem.submenu addItem:versionMenuItem];
                
                NSDictionary *value = [defaultDevices objectForKey:key];
                for (NSString *key in [value.allKeys sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)]) {
                    NSString *deviceName = [key stringByReplacingOccurrencesOfString:@"com.apple.CoreSimulator.SimDeviceType." withString:@""];
                    deviceName = [deviceName stringByReplacingOccurrencesOfString:@"-" withString:@" "];
                    NSString *deviceId = value[key];
                    
                    NSMenuItem *deviceMenuItem = [[NSMenuItem alloc] initWithTitle:deviceName action:@selector(didPressFolderMenuItem:) keyEquivalent:@""];
                    deviceMenuItem.target = self;
                    deviceMenuItem.representedObject = [kDevicesPath stringByAppendingPathComponent:deviceId];
                    [versionMenuItem.submenu addItem:deviceMenuItem];
                    
                    NSArray *appsInBundlePath = [self appsInBundlePathForDeviceId:deviceId];
                    NSArray *appsInDataPath = [self appsInDataPathForDeviceId:deviceId];
                    
                    for (NSDictionary *appInBundlePath in appsInBundlePath) {
                        
                        NSDictionary *appInDataPath = [[appsInDataPath filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:[NSString stringWithFormat:@"MetadataIdentifier == '%@'", appInBundlePath[@"MetadataIdentifier"]]]] firstObject];
                        
                        if (appsInDataPath) {
                            if (!deviceMenuItem.submenu) {
                                deviceMenuItem.submenu = [[NSMenu alloc] initWithTitle:@"Apps"];
                            }
                            
                            NSMenuItem *appMenuItem = [[NSMenuItem alloc] initWithTitle:appInBundlePath[@"MetadataName"] action:@selector(didPressFolderMenuItem:) keyEquivalent:@""];
                            appMenuItem.target = self;
                            appMenuItem.representedObject = [kDevicesPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@/data/Containers/Bundle/Application/%@", deviceId, appInBundlePath[@"MetadataUUID"]]];
                            appMenuItem.submenu = [[NSMenu alloc] initWithTitle:@"Folders"];
                            [deviceMenuItem.submenu addItem:appMenuItem];
                            
                            NSMenuItem *documentsMenuItem = [[NSMenuItem alloc] initWithTitle:@"Documents" action:@selector(didPressFolderMenuItem:) keyEquivalent:@""];
                            documentsMenuItem.target = self;
                            documentsMenuItem.representedObject = [kDevicesPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@/data/Containers/Data/Application/%@/Documents", deviceId, appInDataPath[@"MetadataUUID"]]];
                            [appMenuItem.submenu addItem:documentsMenuItem];
                            
                            NSMenuItem *libraryMenuItem = [[NSMenuItem alloc] initWithTitle:@"Library" action:@selector(didPressFolderMenuItem:) keyEquivalent:@""];
                            libraryMenuItem.target = self;
                            libraryMenuItem.representedObject = [kDevicesPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@/data/Containers/Data/Application/%@/Library", deviceId, appInDataPath[@"MetadataUUID"]]];
                            [appMenuItem.submenu addItem:libraryMenuItem];
                        }
                    }
                }
            }
        }
    }
    
    return YES;
}

#pragma mark - Utils

- (NSArray *)appsInBundlePathForDeviceId:(NSString *)deviceId {
    
    NSMutableArray *apps = [NSMutableArray new];
    
    NSString *path = [kDevicesPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@/data/Containers/Bundle/Application/", deviceId]];
    NSArray *appFolders = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil];
    for (NSString *appFolder in appFolders) {
        
        NSString *plist = [kDevicesPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@/data/Containers/Bundle/Application/%@/.com.apple.mobile_container_manager.metadata.plist", deviceId, appFolder]];
        NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:plist];
        
        NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[path stringByAppendingPathComponent:appFolder] error:nil];
        NSArray *appFiles = [files filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self ENDSWITH '.app'"]];
        if (appFiles.count > 0 && dict) {
            
            [apps addObject:@{@"MetadataIdentifier": dict[@"MCMMetadataIdentifier"],
                              @"MetadataName": appFiles.firstObject,
                              @"MetadataUUID": appFolder,
                              }];
        }
    }
    
    return apps;
}

- (NSArray *)appsInDataPathForDeviceId:(NSString *)deviceId {
    
    NSMutableArray *apps = [NSMutableArray new];
    
    NSString *path = [kDevicesPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@/data/Containers/Data/Application/", deviceId]];
    NSArray *appFolders = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil];
    for (NSString *appFolder in appFolders) {
        
        NSString *plist = [kDevicesPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@/data/Containers/Data/Application/%@/.com.apple.mobile_container_manager.metadata.plist", deviceId, appFolder]];
        NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:plist];
        if (dict) {
            
            [apps addObject:@{@"MetadataIdentifier": dict[@"MCMMetadataIdentifier"],
                              @"MetadataUUID": appFolder,
                              }];
        }
    }
    
    return apps;
}

#pragma mark - MenuItem Actions

- (void)didPressProyectFolderMenuItem:(NSMenuItem *)menuItem {
    
    NSArray *workspaceWindowControllers = [NSClassFromString(@"IDEWorkspaceWindowController") valueForKey:@"workspaceWindowControllers"];
    
    id workSpace;
    for (id controller in workspaceWindowControllers) {
        if ([[controller valueForKey:@"window"] isEqual:[NSApp keyWindow]]) {
            workSpace = [controller valueForKey:@"_workspace"];
        }
    }
    
    if (workSpace) {
        NSString *workspacePath = [[workSpace valueForKey:@"representingFilePath"] valueForKey:@"_pathString"];
        [self openFolderPath:[workspacePath stringByDeletingLastPathComponent]];
    }
}

- (void)didPressFolderMenuItem:(NSMenuItem *)menuItem {
    
    [self openFolderPath:menuItem.representedObject];
}

#pragma mark - Private Actions

- (void)showAlertWithText:(NSString *)text {
    
    NSAlert *alert = [NSAlert new];
    alert.messageText = text;
    [alert runModal];
}

- (void)openFolderPath:(NSString *)folderPath {
    
    //NSLog(@"Open Folder: %@", folderPath);
    [[NSWorkspace sharedWorkspace] openFile:folderPath withApplication:@"Finder"];
}

@end
