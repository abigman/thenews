//
//  TNPostViewController.m
//  thenews
//
//  Created by Tosin Afolabi on 19/02/2014.
//  Copyright (c) 2014 Tosin Afolabi. All rights reserved.
//

#import "IonIcons.h"
#import "ionicons-codes.h"
#import "UIColor+TNColors.h"
#import "GTScrollNavigationBar.h"
#import "NJKWebViewProgressView.h"
#import "TNPostViewController.h"


NSString *loadingText = @"Loading...";
DismissActionBlock dismissAction;

@interface TNPostViewController ()

typedef NS_ENUM (NSInteger, TNToolBarButtonType) {
	TNToolBarButtonTypeBack,
	TNToolBarButtonTypeForward,
    TNToolBarButtonTypeSpacer
};
@property (strong, nonatomic) UIColor *themeColor;

@property (nonatomic, strong) NSURL *url;
@property (nonatomic, strong) NSString *titleStr;
@property (nonatomic, strong) UIWebView *webView;

@property (nonatomic, strong) UIButton *closeButton;
@property (nonatomic, strong) UIButton *shareButton;

@property (nonatomic, strong) UIButton *backButton;
@property (nonatomic, strong) UIButton *forwardButton;

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *urlLabel;

@property (nonatomic, strong) NJKWebViewProgress *progressProxy;
@property (nonatomic, strong) NJKWebViewProgressView *progressView;

@end

@implementation TNPostViewController

- (id)initWithURL:(NSURL *)url type:(TNType)type
{
    self = [super init];

    if (self) {
        self.url = url;
        self.titleStr = loadingText;

        switch (type) {
			case TNTypeDesignerNews:
				self.themeColor = [UIColor dnColor];
				break;

			case TNTypeHackerNews:
				self.themeColor = [UIColor hnColor];
				break;
		}
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[self navigationController] setNavigationBarHidden:NO animated:YES];
    [self.navigationController.navigationBar addSubview:_progressView];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [_progressView removeFromSuperview];
    [[self navigationController] setNavigationBarHidden:YES animated:YES];
    [self.navigationController setToolbarHidden:YES];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    /* Set up Navigation Bar */

    [self configureTitleView];
    [self addBarButtonItems];

	[[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
    [[UINavigationBar appearance] setBarTintColor:self.themeColor];

    /* Set Up Web View */

    self.webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
    [self.webView loadRequest:[NSURLRequest requestWithURL:self.url]];
    [self.webView setScalesPageToFit:YES];
    [self.view addSubview:self.webView];

    /* Set Up Progress Bar */

    self.progressProxy = [[NJKWebViewProgress alloc] init];
    self.webView.delegate = self.progressProxy;
    self.progressProxy.webViewProxyDelegate = self;
    self.progressProxy.progressDelegate = self;

    CGFloat progressBarHeight = 2.5f;
    CGRect navigaitonBarBounds = self.navigationController.navigationBar.bounds;
    CGRect barFrame = CGRectMake(0, navigaitonBarBounds.size.height - progressBarHeight, navigaitonBarBounds.size.width, progressBarHeight);
    self.progressView = [[NJKWebViewProgressView alloc] initWithFrame:barFrame];
    [self.progressView setProgressBarColor:[UIColor colorWithRed:0.173 green:0.243 blue:0.314 alpha:1]];

    /* Set up scrolling navigation bar */

    self.webView.scrollView.delegate = self;

    /* Set up toolbar */

}

#pragma mark - UIWebView Delegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    // Ignore First Page Load
    if (navigationType != UIWebViewNavigationTypeOther) {

        if ( [self.navigationController isToolbarHidden] ) {

            [self.navigationController setToolbarHidden:NO animated:YES];
            [self configureToolbar];
        }

        [self updateToolbarButtonState];
    }
    return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    [self.navigationController.scrollNavigationBar resetToDefaultPosition:NO];
    [self updateToolbarButtonState];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {

    /* Set Title View of Navigation Bar With Current Page Details */

    self.titleStr = [webView stringByEvaluatingJavaScriptFromString:@"document.title"];
    self.url = webView.request.mainDocumentURL;

    CATransition *animation = [CATransition animation];
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    animation.type = kCATransitionFromBottom;
    animation.duration = 0.75;

    [self.titleLabel.layer addAnimation:animation forKey:@"kCATransitionFade"];
    [self.urlLabel.layer addAnimation:animation forKey:@"kCATransitionFade"];

    [self.titleLabel setText:self.titleStr];
    [self.urlLabel setText:[self getBaseURL:self.url]];

    self.navigationController.scrollNavigationBar.scrollView = self.webView.scrollView;

    [self updateToolbarButtonState];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScrollToTop:(UIScrollView *)scrollView
{
    [self.navigationController.scrollNavigationBar resetToDefaultPosition:NO];
}

#pragma mark - NJKWebViewProgressDelegate

- (void)webViewProgress:(NJKWebViewProgress *)webViewProgress updateProgress:(float)progress
{
    [_progressView setProgress:progress animated:YES];
}

#pragma mark - Private Methods

- (void)configureTitleView {

    /*
     * Splits the Original Title View into a Title & Subtitle View
     */

    UIView *viewContainer = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 200, 44)];
    [viewContainer setBackgroundColor:[UIColor clearColor]];

    self.titleLabel = ({
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 2, 200, 24)];
        [titleLabel setText:self.titleStr];
        [titleLabel setTextColor:[UIColor whiteColor]];
        [titleLabel setFont:[UIFont fontWithName:@"Montserrat" size:13]];
        [titleLabel setTextAlignment:NSTextAlignmentCenter];
        titleLabel;
    });

    self.urlLabel = ({
        UILabel *urlLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 24, 200, 44-28)];
        urlLabel.font = [UIFont fontWithName:@"Montserrat" size:10];
        urlLabel.textAlignment = NSTextAlignmentCenter;
        urlLabel.text = [self getBaseURL:self.url];
        urlLabel.textColor = [UIColor tnLightGreyColor];
        urlLabel;
    });

    [viewContainer addSubview:self.titleLabel];
    [viewContainer addSubview:self.urlLabel];
    self.navigationItem.titleView = viewContainer;
}

- (void)addBarButtonItems
{
    self.closeButton = ({
        UIButton *closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [closeButton setFrame:CGRectMake(0, 0, 30, 30)];

        UIImage *icon = [IonIcons imageWithIcon:icon_ios7_close_empty size:120.0f color:[UIColor whiteColor]];

        [closeButton setImage:icon forState:UIControlStateNormal];

        [closeButton addTarget:self action:@selector(dismissButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        closeButton;
    });

	//self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonItemStylePlain target:nil action:nil];
}

- (void)configureToolbar
{
    CGFloat negativeSpacerWidth = -5;
    CGFloat positiveSpaceWidth = 25;

    /* Negative Spacer */
    UIBarButtonItem *negativeSpacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace
                                                                                    target:nil
                                                                                    action:nil];
    negativeSpacer.width = negativeSpacerWidth;

    /* Positive Spacer */
    UIBarButtonItem *positiveSpacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace
                                                                                    target:nil
                                                                                    action:nil];
    positiveSpacer.width = positiveSpaceWidth;

    /* Back Button */
    self.backButton = [self createToolbarNavButton:TNToolBarButtonTypeBack];
    UIBarButtonItem *backButtonBarItem =[[UIBarButtonItem alloc] initWithCustomView:self.backButton];

    /* Forward Button */
    self.forwardButton = [self createToolbarNavButton:TNToolBarButtonTypeForward];
    UIBarButtonItem *forwardButtonBarItem =[[UIBarButtonItem alloc] initWithCustomView:self.forwardButton];

    NSArray *items = @[negativeSpacer, backButtonBarItem, positiveSpacer, forwardButtonBarItem];
    [self.navigationController.toolbar setItems:items animated:NO];
}

- (UIButton *)createToolbarNavButton:(TNToolBarButtonType)buttonType
{
    NSString *iconString = [[NSString alloc] init];
    UIColor *darkGray = [UIColor colorWithRed:0.529 green:0.596 blue:0.643 alpha:1];
    UIColor *lightGray = [UIColor colorWithRed:0.816 green:0.839 blue:0.855 alpha:1];

    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setFrame:CGRectMake(0, 0, 23, 23)];

    switch (buttonType) {

        case TNToolBarButtonTypeBack:
            iconString = icon_ios7_arrow_left;
            [button addTarget:self.webView action:@selector(goBack) forControlEvents:UIControlEventTouchUpInside];
            break;

        case TNToolBarButtonTypeForward:
            iconString = icon_ios7_arrow_right;
            [button addTarget:self.webView action:@selector(goForward) forControlEvents:UIControlEventTouchUpInside];
            break;

        default:
            break;
    }

    UIImage *icon = [IonIcons imageWithIcon:iconString size:25.0f color:darkGray];
    [button setImage:icon forState:UIControlStateNormal];

    UIImage *iconDisabled = [IonIcons imageWithIcon:iconString size:25.0f color:lightGray];
    [button setImage:iconDisabled forState:UIControlStateDisabled];

    return button;
}

- (void)updateToolbarButtonState
{
    // Called in all three delegate methods to avoid bug
    // where after first link is clicked, backButton is still disabled
    self.backButton.enabled = [self.webView canGoBack];
    self.forwardButton.enabled = [self.webView canGoForward];
}

- (NSString *)getBaseURL:(NSURL *)url
{
    return[[NSURL URLWithString:@"/" relativeToURL:url] absoluteString];
}

- (void)dismissButtonPressed {
    dismissAction();
}

- (void)setDismissAction:(DismissActionBlock)dismissActionBlock {
    dismissAction = dismissActionBlock;
}


@end
