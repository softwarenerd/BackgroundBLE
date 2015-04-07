//
//  The MIT License (MIT)
//
//  Copyright (c) 2015 Brian Lambert.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//
//  BackgroundBLE
//  TSNAppView.m
//

#import <UIColor+Extensions.h>
#import <UIView+Extensions.h>
#import <TSNLogger.h>
#import <TSNAtomicFlag.h>
#import <TSNThreading.h>
#import "TSNAppView.h"
#import "TSNNearbyPeersView.h"
#import "TSNBubbleView.h"
#import "TSNSettingsView.h"

// TSNAppView (UITabBarDelegate) interface.
@interface TSNAppView (UITabBarDelegate) <UITabBarDelegate>
@end

// TSNAppView (Internal) interface.
@interface TSNAppView (Internal)

// buttonSendMessageTouchUpInside action.
- (void)buttonSendMessageTouchUpInsideAction:(UIButton *)sender;

// UIKeyboardWillShowNotification callback.
- (void)keyboardWillShowNotificationCallback:(NSNotification *)notification;

// UIKeyboardWillHideNotification callback.
- (void)keyboardWillHideNotificationCallback:(NSNotification *)notification;

// UIApplicationWillResignActiveNotification callback.
- (void)applicationWillResignActiveNotification:(NSNotification *)notification;

// UIApplicationDidEnterBackgroundNotification callback.
- (void)applicationDidEnterBackgroundNotification:(NSNotification *)notification;

// UIApplicationWillEnterForegroundNotification callback.
- (void)applicationWillEnterForegroundNotification:(NSNotification *)notification;

// UIApplicationDidBecomeActiveNotification callback.
- (void)applicationDidBecomeActiveNotification:(NSNotification *)notification;

@end

// TSNAppView implementation.
@implementation TSNAppView
{
@private
    // The workspace view. It contains the view for whatever tab is selected.
    UIView * _viewWorkspace;
    
    // The nearby peers tab bar item.
    UITabBarItem * _tabBarItemNearbyPeers;

    // The logging tab bar item.
    UITabBarItem * _tabBarItemLogging;

    // The tab bar.
    UITabBar * _tabBar;
    
    // The nearby peers view.
    TSNNearbyPeersView * _nearbyPeersView;

    // The bubble view.
    TSNBubbleView * _bubbleView;
    
    // The settings view.
    TSNSettingsView * _settingsView;

    // The logger view.
    UIView * _loggerView;
    
    UIView * _viewCurrentWorkspaceView;

    // The send message button.
    UIButton * _buttonSendMessage;

    // The message number.
    NSUInteger _messageNumber;
    
    // In background atomic flag.
    TSNAtomicFlag * _atomicFlagInBackground;
}

// Class initializer.
- (instancetype)initWithFrame:(CGRect)frame
{
    // Initialize superclass.
    self = [super initWithFrame:frame];
    
    // Handle errors.
    if (!self)
    {
        return nil;
    }
    
    // Initialize.
    [self setBackgroundColor:[UIColor whiteColor]];
    [self setAutoresizesSubviews:YES];
    [self setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
    
    // The default tint color for all UIViews is what we need to tint the tab bar items below.
    UIColor * highlightTintColor = [self tintColor];
    
    // Set-up font title text attributes for the tab bar items.
    UIFont * tabBarItemFont = [UIFont systemFontOfSize:12.0];
    NSDictionary * normalTabBarItemTitleTextAttributes = @{NSFontAttributeName:                 tabBarItemFont,
                                                           NSForegroundColorAttributeName:      [UIColor darkGrayColor]};
    NSDictionary * selectedTabBarItemTitleTextAttributes = @{NSFontAttributeName:               tabBarItemFont,
                                                             NSForegroundColorAttributeName:    highlightTintColor};

    // Allocate and initialize the nearby peers tab bar item.
    _tabBarItemNearbyPeers = [[UITabBarItem alloc] initWithTitle:@"Nearby Peers"
                                                           image:[UIImage imageNamed:@"Nearby Peers"]
                                                             tag:0];
    [_tabBarItemNearbyPeers setTitleTextAttributes:normalTabBarItemTitleTextAttributes
                                          forState:UIControlStateNormal];
    [_tabBarItemNearbyPeers setTitleTextAttributes:selectedTabBarItemTitleTextAttributes
                                          forState:UIControlStateSelected];
    
    // Allocate and initialize the logging tab bar item.
    _tabBarItemLogging = [[UITabBarItem alloc] initWithTitle:@"Logging"
                                                       image:[UIImage imageNamed:@"Log"]
                                                         tag:0];
    [_tabBarItemLogging setTitleTextAttributes:normalTabBarItemTitleTextAttributes
                                      forState:UIControlStateNormal];
    [_tabBarItemLogging setTitleTextAttributes:selectedTabBarItemTitleTextAttributes
                                      forState:UIControlStateSelected];

    // Allocate, initialize and add the tab bar.
    _tabBar = [[UITabBar alloc] initWithFrame:CGRectMake(0.0, [self height] - 49.0, [self width], 49.0)];
    [_tabBar setBarStyle:UIBarStyleDefault];
    [_tabBar setItems:@[_tabBarItemNearbyPeers, _tabBarItemLogging]];
    [_tabBar setDelegate:(id<UITabBarDelegate>)self];
    [_tabBar setSelectedItem:_tabBarItemNearbyPeers];
    [self addSubview:_tabBar];
    
    // Get the height of the status bar. The workspace begins below it.
    CGFloat statusBarHeight = [[UIApplication sharedApplication] statusBarFrame].size.height;

    // Allocate, initialize, and add the workspace view. It contains the view for whatever tab is selected.
    _viewWorkspace = [[UIView alloc] initWithFrame:CGRectMake(0.0, statusBarHeight, [self width], [self height] - statusBarHeight - [_tabBar height])];
    [_viewWorkspace setBackgroundColor:[UIColor whiteColor]];
    [self addSubview:_viewWorkspace];
    
    CGRect workspaceFrame = [_viewWorkspace bounds];
    
    // Allocate, initialize, and add the nearby peers view.
    _nearbyPeersView = [[TSNNearbyPeersView alloc] initWithFrame:workspaceFrame];
    [_viewWorkspace addSubview:_nearbyPeersView];
    _viewCurrentWorkspaceView = _nearbyPeersView;
    
    // Allocate, initialize, and add the bubble view.
    _bubbleView = [[TSNBubbleView alloc] initWithFrame:workspaceFrame];
    
    // Allocate and initialize the logger view.
    _loggerView = [[TSNLogger singleton] createLoggerViewWithFrame:workspaceFrame
                                                   backgroundColor:[UIColor colorWithRGB:0xecf0f1]
                                                   foregroundColor:[UIColor blackColor]];

    // Allocate and initialize the settings view.
    _settingsView = [[TSNSettingsView alloc] initWithFrame:workspaceFrame];
    
    // Add our observers.
    NSNotificationCenter * notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self
                           selector:@selector(keyboardWillShowNotificationCallback:)
                               name:UIKeyboardWillShowNotification
                             object:nil];
    [notificationCenter addObserver:self
                           selector:@selector(keyboardWillHideNotificationCallback:)
                               name:UIKeyboardWillHideNotification
                             object:nil];
    [notificationCenter addObserver:self
                           selector:@selector(applicationWillResignActiveNotification:)
                               name:UIApplicationWillResignActiveNotification
                             object:nil];
    [notificationCenter addObserver:self
                           selector:@selector(applicationDidEnterBackgroundNotification:)
                               name:UIApplicationDidEnterBackgroundNotification
                             object:nil];
    [notificationCenter addObserver:self
                           selector:@selector(applicationWillEnterForegroundNotification:)
                               name:UIApplicationWillEnterForegroundNotification
                             object:nil];
    [notificationCenter addObserver:self
                           selector:@selector(applicationDidBecomeActiveNotification:)
                               name:UIApplicationDidBecomeActiveNotification
                             object:nil];

    // Done.
	return self;
}

// Dealloc.
- (void)dealloc
{
    // Remove our observers.
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end

// TSNAppView (UITabBarDelegate) implementation.
@implementation TSNAppView (UITabBarDelegate)

// Called when a new view is selected by the user (but not programatically).
- (void)tabBar:(UITabBar *)tabBar
 didSelectItem:(UITabBarItem *)item
{
    // Select the new workspace view, if the mode has changed.
    UIView * newWorkspaceView;
    if (item == _tabBarItemNearbyPeers)
    {
        newWorkspaceView = _viewCurrentWorkspaceView != _nearbyPeersView ? _nearbyPeersView : nil;
    }
    else if (item == _tabBarItemLogging)
    {
        newWorkspaceView = _viewCurrentWorkspaceView != _loggerView ? _loggerView : nil;
    }
    else
    {
        // Bug.
        return;
    }
    
    // If we have a new workspace view, transition to it.
    if (newWorkspaceView)
    {
        [UIView transitionFromView:_viewCurrentWorkspaceView
                            toView:newWorkspaceView
                          duration:0.15
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        completion:nil];
        _viewCurrentWorkspaceView = newWorkspaceView;
    }
}

@end

// TSNAppView (Internal) implementation.
@implementation TSNAppView (Internal)

// UIKeyboardWillShowNotification callback.
- (void)keyboardWillShowNotificationCallback:(NSNotification *)notification
{
    NSDictionary * dictionary = [notification userInfo];
    [UIView beginAnimations:nil
                    context:NULL];
    [UIView setAnimationDuration:[dictionary[UIKeyboardAnimationDurationUserInfoKey] doubleValue]];
    [UIView setAnimationCurve:[dictionary[UIKeyboardAnimationCurveUserInfoKey] unsignedIntegerValue]];
    [UIView setAnimationBeginsFromCurrentState:YES];
    
    [_tabBar setAlpha:0.0];
    
    [UIView commitAnimations];
}

// UIKeyboardWillHideNotification callback.
- (void)keyboardWillHideNotificationCallback:(NSNotification *)notification
{
    NSTimeInterval animationDuration = [[notification userInfo][UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    [UIView animateWithDuration:animationDuration
                          delay:animationDuration
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         [_tabBar setAlpha:1.0];
                     }
                     completion:nil];
}

// buttonSendMessageTouchUpInside action.
- (void)buttonSendMessageTouchUpInsideAction:(UIButton *)sender
{
//    NSString * message = [NSString stringWithFormat:@"From %@ comes message %lu", [[UIDevice currentDevice] name], (unsigned long)_messageNumber];
//    _messageNumber++;
}

// UIApplicationWillResignActiveNotification callback.
- (void)applicationWillResignActiveNotification:(NSNotification *)notification
{
}

// UIApplicationDidEnterBackgroundNotification callback.
- (void)applicationDidEnterBackgroundNotification:(NSNotification *)notification
{
    [_atomicFlagInBackground trySet];
}

// UIApplicationWillEnterForegroundNotification callback.
- (void)applicationWillEnterForegroundNotification:(NSNotification *)notification
{
    [_atomicFlagInBackground tryClear];
}

// UIApplicationDidBecomeActiveNotification callback.
- (void)applicationDidBecomeActiveNotification:(NSNotification *)notification
{
}

@end


