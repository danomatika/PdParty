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
#import "Menubang.h"

#import "AppDelegate.h"
#import "Gui.h"
#import "UIAlertView+Blocks.h"

static NSMutableArray *s_menubangs;

@implementation Menubang

- (id)initWithAtomLine:(NSArray *)line andGui:(Gui *)gui {
	if(line.count < 6) { // sanity check
		DDLogWarn(@"Menubang: cannot create, atom line length < 6");
		return nil;
	}
	self = [super initWithAtomLine:line andGui:gui];
	if(self) {
		self.label = nil; // no label
		
		self.name = [Gui filterEmptyStringValues:[line objectAtIndex:5]];
		self.sendName = [NSString stringWithFormat:@"menubang-%@", self.name];
		if(!self.name || [self.name isEqualToString:@""]) {
			// drop something we can't interact with
			DDLogVerbose(@"Menubang: dropping, name is empty");
			return nil;
		}
		
		self.originalFrame = CGRectZero; // doesn't draw anything
		self.inits = YES;
	}
	return self;
}

- (void)setup {
	if(!s_menubangs) {
		s_menubangs = [[NSMutableArray alloc] init];
	}
	[s_menubangs addObject:self];

	// access the patch file path after its been loaded to get the correct image path
	AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
	self.imagePath = [NSString stringWithFormat:@"%@/%@.png", app.sceneManager.scene.patch.pathName, self.sendName];
	if(![[NSFileManager defaultManager] fileExistsAtPath:self.imagePath]) {
		DDLogVerbose(@"Menubang %@: no image found at %@", self.name, self.imagePath);
		self.imagePath = nil;
	}
}

- (void)cleanup {
	if(s_menubangs) {
		[s_menubangs removeObject:self];
		if(s_menubangs.count == 0) {
			s_menubangs = nil;
		}
	}
}

- (void)drawRect:(CGRect)rect {
	// doesn't draw anything
}

- (void)reshape {
	// doesn't draw anything
}

#pragma mark Static Access

+ (NSArray *)menubangs {
	return s_menubangs;
}

+ (int)menubangCount {
	return s_menubangs ? (int) s_menubangs.count : 0;
}

#pragma mark Overridden Getters / Setters

- (NSString *)type {
	return @"Menubang";
}

@end
