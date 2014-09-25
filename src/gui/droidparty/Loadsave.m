/*
 * Copyright (c) 2013 Dan Wilcox <danomatika@gmail.com>
 *
 * BSD Simplified License.
 * For information on usage and redistribution, and for a DISCLAIMER OF ALL
 * WARRANTIES, see the file, "LICENSE.txt," in this distribution.
 *
 * See https://github.com/danomatika/PdParty for documentation
 *
 */
#import "Loadsave.h"

#import "AppDelegate.h"
#import "Gui.h"
#import "FileBrowser.h"

@implementation Loadsave

+ (id)loadsaveFromAtomLine:(NSArray *)line withGui:(Gui *)gui {

	if(line.count < 6) { // sanity check
		DDLogWarn(@"Loadsave: cannot create, atom line length < 7");
		return nil;
	}

	Loadsave *l = [[Loadsave alloc] initWithFrame:CGRectZero];

	l.name = [Gui filterEmptyStringValues:[line objectAtIndex:5]];
	l.receiveName = l.name;
	if(![l hasValidReceiveName]) {
		// drop something we can't interact with
		DDLogVerbose(@"Loadsave: dropping, receive name is empty");
		return nil;
	}
	
	l.originalFrame = CGRectZero; // doesn't draw anything
	
	return l;
}

- (id)initWithFrame:(CGRect)frame {    
    self = [super initWithFrame:frame];
    if(self) {
		self.label.textAlignment = NSTextAlignmentCenter;
		self.label.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
	// doesn't draw anything
}

- (void)reshapeForGui:(Gui *)gui {
	// doesn't draw anything
}

#pragma mark Overridden Getters / Setters

- (NSString *)type {
	return @"Loadsave";
}

#pragma mark WidgetListener

- (BOOL)receiveEditMessage:(NSString *)message withArguments:(NSArray *)arguments {
	if(([message isEqualToString:@"load"] || [message isEqualToString:@"save"])) {
		DDLogVerbose(@"Loadsave %@: received %@ message: %@ %@", self.receiveName, message, self.directory, self.ext);

		if(arguments.count > 0 && [arguments isStringAt:0]) {
			self.directory = [arguments objectAtIndex:0];
		}
		else {
			self.directory = @"";
		}
		
		if(arguments.count > 1 && [arguments isStringAt:1]) {
			self.ext = [arguments objectAtIndex:1];
		}
		else {
			self.ext = @"";
		}
		
		self.sendName = [self.name stringByAppendingFormat:@"-%@", message];
		
		AppDelegate *app = [[UIApplication sharedApplication] delegate];
		FileBrowser *browser = [[FileBrowser alloc] initWithStyle:UITableViewStylePlain];
		browser.extension = [self.ext isEqualToString:@""] ? nil : self.ext;
		browser.didSelectFile = ^(FileBrowser *b, NSString *selection) {
			[self sendSymbol:selection];
			[b dismissViewControllerAnimated:YES completion:nil];
		};
		browser.modalPresentationStyle = UIModalPresentationFormSheet;
		
		UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:browser];
		navigationController.navigationBar.barStyle = UIBarStyleBlack;
		[app.window.rootViewController presentViewController:navigationController animated:YES completion:nil];
		[browser loadDirectory:app.sceneManager.currentPath];
		
		return YES;
	}
	return NO;
}

@end
