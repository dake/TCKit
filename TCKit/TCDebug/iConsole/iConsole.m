//
//  iConsole.m
//
//  Version 1.5.1
//
//  Created by Nick Lockwood on 20/12/2010.
//  Copyright 2010 Charcoal Design
//
//  Distributed under the permissive zlib License
//  Get the latest version from here:
//
//  https://github.com/nicklockwood/iConsole
//
//  This software is provided 'as-is', without any express or implied
//  warranty.  In no event will the authors be held liable for any damages
//  arising from the use of this software.
//
//  Permission is granted to anyone to use this software for any purpose,
//  including commercial applications, and to alter it and redistribute it
//  freely, subject to the following restrictions:
//
//  1. The origin of this software must not be misrepresented; you must not
//  claim that you wrote the original software. If you use this software
//  in a product, an acknowledgment in the product documentation would be
//  appreciated but is not required.
//
//  2. Altered source versions must be plainly marked as such, and must not be
//  misrepresented as being the original software.
//
//  3. This notice may not be removed or altered from any source distribution.
//

#ifndef TARGET_IS_EXTENSION

#ifndef TC_IOS_PUBLISH

#import "iConsole.h"
#import <stdarg.h>
#import <string.h>

#import <Availability.h>

#import "TCAlertController.h"

#if !__has_feature(objc_arc)
#error This class requires automatic reference counting
#endif


#ifdef NSLog
#undef NSLog
#endif



#define EDITFIELD_HEIGHT 32 //28
#define ACTION_BUTTON_WIDTH 44

static NSString *const kSaveKey = @"iConsoleLog";


@interface iConsole () <UITextFieldDelegate>

@property (nonatomic, strong) UITextView *consoleView;
@property (nonatomic, strong) UITextField *inputField;
@property (nonatomic, strong) UIButton *actionButton;
@property (nonatomic, strong) NSMutableArray *log;
@property (nonatomic, assign) BOOL animating;

- (void)saveSettings;

@end


#pragma mark Private methods

static void exceptionHandler(NSException *exception)
{
    [iConsole crash:@"%@", exception];
    [[iConsole sharedConsole] saveSettings];
}


@implementation iConsole

+ (NSArray *)savedLogs
{
    [NSUserDefaults.standardUserDefaults synchronize];
    return [NSUserDefaults.standardUserDefaults objectForKey:kSaveKey];
}

+ (void)clearLogs
{
    [NSUserDefaults.standardUserDefaults setObject:nil forKey:kSaveKey];
    [NSUserDefaults.standardUserDefaults synchronize];
}


#pragma mark -

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (UIWindow *)mainWindow
{
    UIApplication *app = [UIApplication sharedApplication];
    if ([app.delegate respondsToSelector:@selector(window)]) {
        return app.delegate.window;
    } else {
        return app.keyWindow;
    }
}

- (void)setConsoleText
{
    NSString *text = _infoString;
    NSUInteger touches = (TARGET_OS_SIMULATOR ? _simulatorTouchesToShow: _deviceTouchesToShow);
    if (touches > 0 && touches < 11) {
        text = [text stringByAppendingFormat:@"\nSwipe down with %lu finger%@ to hide console", (unsigned long)touches, (touches != 1)? @"s": @""];
    } else if (TARGET_OS_SIMULATOR ? _simulatorShakeToShow : _deviceShakeToShow) {
        text = [text stringByAppendingString:@"\nShake device to hide console"];
    }
    text = [text stringByAppendingString:@"\n--------------------------------------\n"];
    text = [text stringByAppendingString:[[_log arrayByAddingObject:@">"] componentsJoinedByString:@"\n"]];
    _consoleView.text = text;
    
    [_consoleView scrollRangeToVisible:NSMakeRange(_consoleView.text.length, 0)];
}

- (void)resetLog
{
    self.log = NSMutableArray.array;
    [self setConsoleText];
}

- (void)saveSettings
{
    if (_saveLogToDisk) {
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

- (BOOL)findAndResignFirstResponder:(UIView *)view
{
    if ([view isFirstResponder]) {
        [view resignFirstResponder];
        return YES;
    }
    
    for (UIView *subview in view.subviews) {
        if ([self findAndResignFirstResponder:subview]) {
            return YES;
        }
    }
    return NO;
}

- (void)infoAction
{
    [self findAndResignFirstResponder:[self mainWindow]];
    
#ifdef TC_IOS_DEBUG
    NSString *title = [@"测试环境 " stringByAppendingString:[[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey]];
#else
    
#if defined(TC_IOS_RELEASE) || !(defined(TC_IOS_DEBUG) || defined(TC_IOS_PUBLISH))
    NSString *title = [self.isProductionEnv ? @"生产环境 " : @"预发布环境 " stringByAppendingString:[[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey]];
#else
    NSString *title = [@"生产环境 " stringByAppendingString:[[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey]];
#endif
    
#endif // TC_IOS_DEBUG
    
    __weak typeof(self) wSelf = self;
    TCAlertController *alert = [[TCAlertController alloc] initActionSheetWithTitle:title
                                                                     presentCtrler:self
                                                                      cancelAction:[TCAlertAction cancelActionWithTitle:@"Cancel" handler:nil]
                                                                 destructiveAction:[TCAlertAction destructiveActionWithTitle:@"Clear Log" handler:^(TCAlertAction *action) {
        [iConsole clear];
        if ([iConsole sharedConsole].saveLogToDisk) {
            [iConsole clearLogs];
        }
    }]
                                                                       otherAction:[TCAlertAction defaultActionWithTitle:@"调试信息面板" handler:^(TCAlertAction *action) {
        if ([wSelf.delegate respondsToSelector:@selector(debugPanelTapped:)]) {
            [wSelf.delegate debugPanelTapped:wSelf];
        }
    }], nil];
    
    
    alert.popoverPresentationController.sourceView = _actionButton;
    [alert show];
}

- (CGAffineTransform)viewTransform
{
    CGFloat angle = 0;
    
    switch ([UIApplication sharedApplication].statusBarOrientation) {
        case UIInterfaceOrientationPortrait:
            angle = 0;
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            angle = (CGFloat)M_PI;
            break;
        case UIInterfaceOrientationLandscapeLeft:
            angle = (CGFloat)-M_PI_2;
            break;
        case UIInterfaceOrientationLandscapeRight:
            angle = (CGFloat)M_PI_2;
            break;
            
        default:
            break;
    }
    
    return CGAffineTransformMakeRotation(angle);
}

- (CGRect)onscreenFrame
{
    return UIScreen.mainScreen.bounds;
}

- (CGRect)offscreenFrame
{
    CGRect frame = [self onscreenFrame];
    
    switch ([UIApplication sharedApplication].statusBarOrientation) {
        case UIInterfaceOrientationPortrait:
            frame.origin.y = frame.size.height;
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            frame.origin.y = -frame.size.height;
            break;
        case UIInterfaceOrientationLandscapeLeft:
            frame.origin.x = frame.size.width;
            break;
        case UIInterfaceOrientationLandscapeRight:
            frame.origin.x = -frame.size.width;
            break;
            
        default:
            break;
    }
    
    return frame;
}

- (void)showConsole
{
    if (!_animating && self.view.superview == nil) {
        [self setConsoleText];
        
        [self findAndResignFirstResponder:[self mainWindow]];
        
        self.view.frame = [self offscreenFrame];
        
        UIWindow *window = self.mainWindow;
        
        UIViewController *ctrler = self;//self.navigationController;
        //        if (nil == ctrler) {
        //            ctrler = [[UINavigationController alloc] initWithRootViewController:self];
        //            self.navigationController.navigationBar.translucent = YES;
        //            self.navigationController.navigationBar.barStyle = UIBarStyleDefault;
        ////            self.navigationController.navigationBar.hidden = YES;
        //
        //            UIImage *bgImg = [[UIImage alloc] init];//[UIImage imageWithColor:[UIColor whiteColor] size:CGSizeMake(8, 8)];
        //            [self.navigationController.navigationBar setBackgroundImage:bgImg forBarMetrics:UIBarMetricsDefault];
        //        }
        
        UIViewController *parentCtrler = window.rootViewController;
        if (nil != parentCtrler.presentedViewController) {
            parentCtrler = parentCtrler.presentedViewController;
        }
        [parentCtrler addChildViewController:ctrler];
        [parentCtrler.view addSubview:ctrler.view];
        [ctrler didMoveToParentViewController:parentCtrler];
        
        _animating = YES;
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.4f];
        [UIView setAnimationDelegate:self];
        [UIView setAnimationDidStopSelector:@selector(consoleShown)];
        [iConsole sharedConsole].view.frame = [self onscreenFrame];
        [iConsole sharedConsole].view.transform = [self viewTransform];
        [UIView commitAnimations];
    }
}

- (void)consoleShown
{
    _animating = NO;
    [self findAndResignFirstResponder:[self mainWindow]];
}

- (void)hideConsole
{
    if (!_animating && self.view.superview != nil) {
        [self findAndResignFirstResponder:[self mainWindow]];
        
        _animating = YES;
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.4];
        [UIView setAnimationDelegate:self];
        [UIView setAnimationDidStopSelector:@selector(consoleHidden)];
        self.view.frame = [self offscreenFrame];
        [UIView commitAnimations];
    }
}

- (void)consoleHidden
{
    _animating = NO;
    [self willMoveToParentViewController:nil];
    [self.view removeFromSuperview];
    [self removeFromParentViewController];
}

- (void)rotateView:(NSNotification *)notification
{
    self.view.transform = [self viewTransform];
    self.view.frame = [self onscreenFrame];
    
    if (_delegate != nil) {
        //workaround for autoresizeing glitch
        CGRect frame = self.view.bounds;
        frame.size.height -= EDITFIELD_HEIGHT + 10;
        self.consoleView.frame = frame;
    }
}

- (void)resizeView:(NSNotification *)notification
{
    CGRect bounds = [UIScreen mainScreen].bounds;
    
    CGRect frame = [[notification.userInfo valueForKey:UIApplicationStatusBarFrameUserInfoKey] CGRectValue];
    switch ([UIApplication sharedApplication].statusBarOrientation) {
        case UIInterfaceOrientationPortrait:
            bounds.origin.y += frame.size.height;
            bounds.size.height -= frame.size.height;
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            bounds.size.height -= frame.size.height;
            break;
        case UIInterfaceOrientationLandscapeLeft:
            bounds.origin.x += frame.size.width;
            bounds.size.width -= frame.size.width;
            break;
        case UIInterfaceOrientationLandscapeRight:
            bounds.size.width -= frame.size.width;
            break;
            
        default:
            break;
    }
    
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    [UIView setAnimationDuration:0.35];
    self.view.frame = bounds;
    [UIView commitAnimations];
}

- (void)keyboardWillShow:(NSNotification *)notification
{
    CGFloat duration = [[notification.userInfo valueForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    UIViewAnimationCurve curve = [[notification.userInfo valueForKey:UIKeyboardAnimationCurveUserInfoKey] intValue];
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:duration];
    [UIView setAnimationCurve:curve];
    
    CGRect bounds = [self onscreenFrame];
    
    CGRect frame = [[notification.userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    switch ([UIApplication sharedApplication].statusBarOrientation) {
        case UIInterfaceOrientationPortrait:
            bounds.size.height -= frame.size.height;
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            bounds.origin.y += frame.size.height;
            bounds.size.height -= frame.size.height;
            break;
        case UIInterfaceOrientationLandscapeLeft:
            bounds.size.width -= frame.size.width;
            break;
        case UIInterfaceOrientationLandscapeRight:
            bounds.origin.x += frame.size.width;
            bounds.size.width -= frame.size.width;
            break;
            
        default:
            break;
    }
    
    self.view.frame = bounds;
    
    [UIView commitAnimations];
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    CGFloat duration = [[notification.userInfo valueForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    UIViewAnimationCurve curve = [[notification.userInfo valueForKey:UIKeyboardAnimationCurveUserInfoKey] intValue];
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:duration];
    [UIView setAnimationCurve:curve];
    
    self.view.frame = [self onscreenFrame];
    
    [UIView commitAnimations];
}

- (void)logOnMainThread:(NSString *)message
{
    if (_log.count > _maxLogItems) {
        [_log removeObjectsInRange:NSMakeRange(0, _maxLogItems-20)];
    }
    
    [_log addObject:[@"> " stringByAppendingString:message]];
    [NSUserDefaults.standardUserDefaults setObject:_log forKey:kSaveKey];
    if (self.view.superview) {
        [self setConsoleText];
    }
}


#pragma mark - UITextFieldDelegate

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    if (textField.text.length > 0) {
        [iConsole log:textField.text];
        if (nil != _delegate) {
            if ([_delegate respondsToSelector:@selector(handleConsoleCommand:)]) {
                [_delegate handleConsoleCommand:textField.text];
            }
        }
        
        textField.text = @"";
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField
{
    return YES;
}


#pragma mark -
#pragma mark Life cycle

+ (iConsole *)sharedConsole
{
    @synchronized(self) {
        static iConsole *sharedConsole = nil;
        if (sharedConsole == nil) {
            sharedConsole = [[self alloc] init];
        }
        return sharedConsole;
    }
}


- (void)setDelegate:(id<iConsoleDelegate>)delegate
{
    _delegate = delegate;
    
    if (nil != delegate && nil == _inputField) {
        [self setUpInputView];
    }
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        
#if ICONSOLE_ADD_EXCEPTION_HANDLER
        NSSetUncaughtExceptionHandler(&exceptionHandler);
#endif
        
        
#if defined(TC_IOS_RELEASE) || !(defined(TC_IOS_DEBUG) || defined(TC_IOS_PUBLISH))
        _isProductionEnv = YES;
#endif
        
        _enabled = YES;
        _logLevel = iConsoleLogLevelInfo;
        _saveLogToDisk = YES;
        _maxLogItems = 150;
        
        _simulatorTouchesToShow = 2;
        _deviceTouchesToShow = 3;
        _simulatorShakeToShow = YES;
        _deviceShakeToShow = NO;
        
        self.infoString = @"iConsole: Copyright © 2010 Charcoal Design";
        self.inputPlaceholderString = @"Enter command...";
        self.logSubmissionEmail = nil;
        
        self.backgroundColor = [UIColor.blackColor colorWithAlphaComponent:0.9f];
        self.textColor = [UIColor colorWithRed:59/255.0f green:252/255.0f blue:51/255.0f alpha:255/255.0f];
        
        
        [NSUserDefaults.standardUserDefaults synchronize];
        self.log = [NSMutableArray arrayWithArray:[NSUserDefaults.standardUserDefaults objectForKey:kSaveKey]];
        
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(saveSettings)
                                                   name:UIApplicationDidEnterBackgroundNotification
                                                 object:nil];
        
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(saveSettings)
                                                   name:UIApplicationWillTerminateNotification
                                                 object:nil];
        
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(rotateView:)
                                                   name:UIApplicationDidChangeStatusBarOrientationNotification
                                                 object:nil];
        
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(resizeView:)
                                                   name:UIApplicationWillChangeStatusBarFrameNotification
                                                 object:nil];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.clipsToBounds = YES;
    self.view.backgroundColor = _backgroundColor;
    self.view.autoresizesSubviews = YES;
    
    CGRect frame = self.view.bounds;
    frame.size.height -= EDITFIELD_HEIGHT;
    _consoleView = [[UITextView alloc] initWithFrame:frame];
    _consoleView.font = [UIFont fontWithName:@"Menlo" size:12] ?: [UIFont fontWithName:@"Courier" size:12];
    _consoleView.textColor = _textColor;
    _consoleView.backgroundColor = UIColor.clearColor;
    _consoleView.editable = NO;
    _consoleView.scrollsToTop = YES;
    _consoleView.showsVerticalScrollIndicator = YES;
    _consoleView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [self setConsoleText];
    [self.view addSubview:_consoleView];
}

- (void)setUpInputView
{
    _inputField = [[UITextField alloc] initWithFrame:CGRectMake(10, self.view.frame.size.height - EDITFIELD_HEIGHT - 5,
                                                                self.view.frame.size.width - 20,
                                                                EDITFIELD_HEIGHT)];
    _inputField.borderStyle = UITextBorderStyleRoundedRect;
    _inputField.font = [UIFont fontWithName:@"Menlo" size:12] ?: [UIFont fontWithName:@"Courier" size:12];
    _inputField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    _inputField.autocorrectionType = UITextAutocorrectionTypeNo;
    _inputField.returnKeyType = UIReturnKeyDone;
    _inputField.keyboardType = UIKeyboardTypeURL;
    _inputField.enablesReturnKeyAutomatically = NO;
    _inputField.clearButtonMode = UITextFieldViewModeWhileEditing;
    _inputField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    _inputField.placeholder = _inputPlaceholderString;
    _inputField.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
    _inputField.delegate = self;
    CGRect frame = self.view.bounds;
    frame.size.height -= EDITFIELD_HEIGHT + 10;
    _consoleView.frame = frame;
    [self.view addSubview:_inputField];
    
    _actionButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [_actionButton setTitle:@"⚙  " forState:UIControlStateNormal];
    [_actionButton setTitleColor:_textColor forState:UIControlStateNormal];
    _actionButton.frame = CGRectMake(0, 0, ACTION_BUTTON_WIDTH, EDITFIELD_HEIGHT);
    [_actionButton addTarget:self action:@selector(infoAction) forControlEvents:UIControlEventTouchUpInside];
    _inputField.rightViewMode = UITextFieldViewModeAlways;
    _inputField.rightView = _actionButton;
    
    [self.consoleView scrollRangeToVisible:NSMakeRange(self.consoleView.text.length, 0)];
    
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(keyboardWillShow:)
                                               name:UIKeyboardWillShowNotification
                                             object:nil];
    
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(keyboardWillHide:)
                                               name:UIKeyboardWillHideNotification
                                             object:nil];
}


#pragma mark -
#pragma mark Public methods

+ (void)log:(NSString *)format arguments:(va_list)argList
{
    NSString *message = [[NSString alloc] initWithFormat:format arguments:argList];
    NSLog(@"%@", message);
    
    if ([self sharedConsole].enabled) {
        if ([NSThread isMainThread]) {
            [[self sharedConsole] logOnMainThread:message];
        } else {
            [[self sharedConsole] performSelectorOnMainThread:@selector(logOnMainThread:)
                                                   withObject:message waitUntilDone:NO];
        }
    }
}

+ (void)log:(NSString *)format, ...
{
    if ([self sharedConsole].logLevel >= iConsoleLogLevelNone) {
        va_list argList;
        va_start(argList,format);
        [self log:format arguments:argList];
        va_end(argList);
    }
}

+ (void)info:(NSString *)format, ...
{
    if ([self sharedConsole].logLevel >= iConsoleLogLevelInfo) {
        va_list argList;
        va_start(argList, format);
        [self log:[@"INFO: " stringByAppendingString:format] arguments:argList];
        va_end(argList);
    }
}

+ (void)warn:(NSString *)format, ...
{
    if ([self sharedConsole].logLevel >= iConsoleLogLevelWarning) {
        va_list argList;
        va_start(argList, format);
        [self log:[@"WARNING: " stringByAppendingString:format] arguments:argList];
        va_end(argList);
    }
}

+ (void)error:(NSString *)format, ...
{
    if ([self sharedConsole].logLevel >= iConsoleLogLevelError) {
        va_list argList;
        va_start(argList, format);
        [self log:[@"ERROR: " stringByAppendingString:format] arguments:argList];
        va_end(argList);
    }
}

+ (void)crash:(NSString *)format, ...
{
    if ([self sharedConsole].logLevel >= iConsoleLogLevelCrash) {
        va_list argList;
        va_start(argList, format);
        [self log:[@"CRASH: " stringByAppendingString:format] arguments:argList];
        va_end(argList);
    }
}

+ (void)clear
{
    [[iConsole sharedConsole] resetLog];
}

+ (void)show
{
    [[iConsole sharedConsole] showConsole];
}

+ (void)hide
{
    [[iConsole sharedConsole] hideConsole];
}

@end


@implementation iConsoleWindow

- (void)sendEvent:(UIEvent *)event
{
#ifndef TC_IOS_PUBLISH
    @try {
        [super sendEvent:event]; // Apple says you must always call this!
    } @catch (NSException *exception) {
        NSLog(@"%@\n%@", exception, exception.callStackSymbols);
    }
#else
    [super sendEvent:event]; // Apple says you must always call this!
#endif
    
    
    if ([iConsole sharedConsole].enabled && event.type == UIEventTypeTouches) {
        NSSet *touches = [event allTouches];
        if ([touches count] == (TARGET_OS_SIMULATOR ? [iConsole sharedConsole].simulatorTouchesToShow: [iConsole sharedConsole].deviceTouchesToShow)) {
            BOOL allUp = YES;
            BOOL allDown = YES;
            BOOL allLeft = YES;
            BOOL allRight = YES;
            
            for (UITouch *touch in touches) {
                CGFloat next_y = [touch locationInView:self].y;
                CGFloat pre_y = [touch previousLocationInView:self].y;
                if (next_y <= pre_y) {
                    allDown = NO;
                }
                if (next_y >= pre_y) {
                    allUp = NO;
                }
                
                CGFloat next_x = [touch locationInView:self].x;
                CGFloat pre_x = [touch previousLocationInView:self].x;
                if (next_x <= pre_x) {
                    allLeft = NO;
                }
                if (next_x >= pre_x) {
                    allRight = NO;
                }
            }
            
            switch ([UIApplication sharedApplication].statusBarOrientation) {
                case UIInterfaceOrientationPortrait: {
                    if (allUp) {
                        [iConsole show];
                    } else if (allDown) {
                        [iConsole hide];
                    }
                    break;
                }
                case UIInterfaceOrientationPortraitUpsideDown: {
                    if (allDown) {
                        [iConsole show];
                    } else if (allUp) {
                        [iConsole hide];
                    }
                    break;
                }
                case UIInterfaceOrientationLandscapeLeft: {
                    if (allRight) {
                        [iConsole show];
                    } else if (allLeft) {
                        [iConsole hide];
                    }
                    break;
                }
                case UIInterfaceOrientationLandscapeRight: {
                    if (allLeft) {
                        [iConsole show];
                    } else if (allRight) {
                        [iConsole hide];
                    }
                    break;
                }
                    
                default:
                    break;
            }
        }
    }
}

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
    [super motionEnded:motion withEvent:event];
    
    if ([iConsole sharedConsole].enabled &&
        (TARGET_OS_SIMULATOR ? [iConsole sharedConsole].simulatorShakeToShow: [iConsole sharedConsole].deviceShakeToShow)) {
        if (event.type == UIEventTypeMotion && event.subtype == UIEventSubtypeMotionShake) {
            if ([iConsole sharedConsole].view.superview == nil) {
                [iConsole show];
            } else {
                [iConsole hide];
            }
        }
    }
}

@end

#endif

#endif
