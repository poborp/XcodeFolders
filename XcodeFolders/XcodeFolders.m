//
//  XcodeFolders.m
//  XcodeFolders
//
//  Created by Jacobo Rodriguez on 13/5/16.
//  Copyright © 2016 tBear Software. All rights reserved.
//

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
    
//    NSMenuItem *menuItem = [[NSApp mainMenu] itemWithTitle:@"View"];
//    if (menuItem) {
//
//        [menuItem.submenu addItem:[NSMenuItem separatorItem]];
//    
//        NSMenuItem *menuBarItem = [[NSMenuItem alloc] initWithTitle:@"XCode Folders" action:NULL keyEquivalent:@""];
//        
//        NSMenu *newMenu = [[NSMenu alloc] initWithTitle:@"Folders"];
//        [menuBarItem setSubmenu:newMenu];
//        [[menuItem submenu] addItem:menuBarItem];
//
//        return YES;
//    } else {
//    
//        return NO;
//    }
    
    NSMenuItem *foldersBarItem = [[NSMenuItem alloc] initWithTitle:@"Folders" action:NULL keyEquivalent:@""];
    foldersBarItem.submenu = [[NSMenu alloc] initWithTitle:@"Folders"];
    [[NSApp mainMenu] insertItem:foldersBarItem atIndex:3];
    
    NSMenuItem *item;
    
    item = [[NSMenuItem alloc] initWithTitle:@"CodeSnippets" action:@selector(didPressSnippetsPluginsMenuItem:) keyEquivalent:@""];
    item.target = self;
    [foldersBarItem.submenu addItem:item];
    
    item = [[NSMenuItem alloc] initWithTitle:@"File Templates" action:@selector(didPressFolderFileTemplatesMenuItem:) keyEquivalent:@""];
    item.target = self;
    [foldersBarItem.submenu addItem:item];
    
    item = [[NSMenuItem alloc] initWithTitle:@"Plug-ins" action:@selector(didPressFolderPluginsMenuItem:) keyEquivalent:@""];
    item.target = self;
    [foldersBarItem.submenu addItem:item];
    
    [foldersBarItem.submenu addItem:[NSMenuItem separatorItem]];

    item = [[NSMenuItem alloc] initWithTitle:@"Current Proyect" action:@selector(didPressProyectFolderMenuItem:) keyEquivalent:@""];
    item.target = self;
    [foldersBarItem.submenu addItem:item];
    
    NSMenuItem *simulatorsItem = [[NSMenuItem alloc] initWithTitle:@"Simulator" action:@selector(didPressSimulatorFolderMenuItem:) keyEquivalent:@""];
    simulatorsItem.target = self;
    [foldersBarItem.submenu addItem:simulatorsItem];
    
    NSString *libraryPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *simulatorListPath = [libraryPath stringByAppendingPathComponent:@"/Developer/CoreSimulator/Devices/device_set.plist"];
    NSDictionary *simulators = [NSDictionary dictionaryWithContentsOfFile:simulatorListPath];
    
    if (simulators) {
        simulatorsItem.submenu = [[NSMenu alloc] initWithTitle:@"Simulator"];
        
        NSDictionary *defaultDevices = simulators[@"DefaultDevices"];
        for (NSString *key in [defaultDevices.allKeys sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)]) {
            if (![key isEqualToString:@"version"]) {
                NSString *name = [key stringByReplacingOccurrencesOfString:@"com.apple.CoreSimulator.SimRuntime." withString:@""];
                name = [name stringByReplacingOccurrencesOfString:@"-" withString:@" "];
                
                NSMenuItem *versionMenuItem = [[NSMenuItem alloc] initWithTitle:name action:nil keyEquivalent:@""];
                versionMenuItem.target = self;
                versionMenuItem.submenu = [[NSMenu alloc] initWithTitle:@"Devices"];
                [simulatorsItem.submenu addItem:versionMenuItem];
                
                NSDictionary *value = [defaultDevices objectForKey:key];
                for (NSString *key in [value.allKeys sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)]) {
                    NSString *name = [key stringByReplacingOccurrencesOfString:@"com.apple.CoreSimulator.SimDeviceType." withString:@""];
                    name = [name stringByReplacingOccurrencesOfString:@"-" withString:@" "];
                    
                    NSMenuItem *deviceMenuItem = [[NSMenuItem alloc] initWithTitle:name action:@selector(didPressSimulatorDeviceFolderMenuItem:) keyEquivalent:@""];
                    deviceMenuItem.target = self;
                    deviceMenuItem.representedObject = value[key];
                    [versionMenuItem.submenu addItem:deviceMenuItem];
                }
            }
        }
    }
    
    return YES;
}

#pragma mark - MenuItem Actions

- (void)didPressSnippetsPluginsMenuItem:(NSMenuItem *)menuItem {
    
    NSString *libraryPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    [self openFolderPath:[libraryPath stringByAppendingPathComponent:@"/Developer/Xcode/UserData/CodeSnippets"]];
}

- (void)didPressFolderFileTemplatesMenuItem:(NSMenuItem *)menuItem {
    
    NSString *libraryPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    [self openFolderPath:[libraryPath stringByAppendingPathComponent:@"/Developer/Xcode/Templates/File Templates"]];
}

- (void)didPressFolderPluginsMenuItem:(NSMenuItem *)menuItem {
    
    NSString *libraryPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    [self openFolderPath:[libraryPath stringByAppendingPathComponent:@"/Application Support/Developer/Shared/Xcode/Plug-ins"]];
}

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

- (void)didPressSimulatorFolderMenuItem:(NSMenuItem *)menuItem {
    
    NSString *libraryPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    [self openFolderPath:[libraryPath stringByAppendingPathComponent:@"/Developer/CoreSimulator/Devices/"]];
}

- (void)didPressSimulatorDeviceFolderMenuItem:(NSMenuItem *)menuItem {
    
    NSString *libraryPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    [self openFolderPath:[libraryPath stringByAppendingPathComponent:[NSString stringWithFormat:@"/Developer/CoreSimulator/Devices/%@", menuItem.representedObject]]];
    ///Library/Developer/CoreSimulator/Devices/62E2B03E-45B5-41ED-AF45-454636D0F978/data/Containers/Data/Application/EC9D1EF8-4DEB-4458-BAB7-4C44EE9E0E99/Documents
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
