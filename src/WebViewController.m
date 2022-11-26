/*
 * Copyright (c) 2016 Dan Wilcox <danomatika@gmail.com>
 *
 * BSD Simplified License.
 * For information on usage and redistribution, and for a DISCLAIMER OF ALL
 * WARRANTIES, see the file, "LICENSE.txt," in this distribution.
 *
 * See https://github.com/danomatika/PdParty for documentation
 *
 */
#import "WebViewController.h"

#import "AppDelegate.h"

@interface WebViewController () {
	BOOL sceneRotations; // stick to preferred scene rotations?
}
@end

@implementation WebViewController

- (UIStatusBarStyle)preferredStatusBarStyle {
	return UIStatusBarStyleLightContent;
}

// lock to orientations allowed by the current scene
- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
	if(sceneRotations) {
		AppDelegate *app = (AppDelegate *)UIApplication.sharedApplication.delegate;
		if(app.sceneManager.scene && !app.sceneManager.isRotated) {
			return app.sceneManager.scene.preferredOrientations;
		}
	}
	if(Util.isDeviceATablet) {
		return UIInterfaceOrientationMaskAll;
	}
	else {
		return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown;
	}
}

- (void)openURL:(NSURL *)url withTitle:(NSString *)title sceneRotationsOnly:(BOOL)sceneRotationsOnly {

	AppDelegate *app = (AppDelegate *)UIApplication.sharedApplication.delegate;
	sceneRotations = sceneRotationsOnly;

	// assume relative file path if no http:, file:, etc
	if(!url.scheme) {
		if(!app.sceneManager.scene) {
			DDLogError(@"AppDelegate: can't open relative path url without scene: %@", url.path);
			return;
		}
		url = [NSURL fileURLWithPath:[app.sceneManager.currentPath stringByAppendingPathComponent:url.path]];
	}
	
	// create web view and load
	UIWebView *webView = [[UIWebView alloc] init];
	webView.dataDetectorTypes = UIDataDetectorTypeNone;
	if([url isFileURL]) {
		NSError *error;
		if(![url checkResourceIsReachableAndReturnError:&error]) {
			[[UIAlertController alertControllerWithTitle:@"Couldn't launch URL"
			                                     message:error.localizedDescription
			                           cancelButtonTitle:@"Ok"] show];
			return;
		}
		NSString *html = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:&error];
		[webView loadHTMLString:html baseURL:nil];
	}
	else { // external url
		[webView loadRequest:[NSURLRequest requestWithURL:url]];
	}
	
	// show webview in nav controller
	self.view = webView;
	self.title = (title ? title : @"URL");
	self.modalPresentationStyle = UIModalPresentationPageSheet;
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
	                                           initWithBarButtonSystemItem:UIBarButtonSystemItemDone
	                                           target:self
	                                           action:@selector(donePressed:)];
}

#pragma mark UI

- (void)donePressed:(id)sender {
	[self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

@end
