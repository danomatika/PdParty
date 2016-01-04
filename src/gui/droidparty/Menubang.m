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

+ (id)menubangFromAtomLine:(NSArray *)line withGui:(Gui *)gui {

	if(line.count < 6) { // sanity check
		DDLogWarn(@"Menubang: cannot create, atom line length < 6");
		return nil;
	}

	Menubang *m = [[Menubang alloc] initWithFrame:CGRectZero];

	m.name = [Gui filterEmptyStringValues:[line objectAtIndex:5]];
	m.sendName = [NSString stringWithFormat:@"menubang-%@", m.name];
	if(![m hasValidSendName]) {
		// drop something we can't interact with
		DDLogVerbose(@"Menubang: dropping, send name is empty");
		return nil;
	}
	
	m.originalFrame = CGRectZero; // doesn't draw anything
	
	// image path
	AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
	m.imagePath = [app.sceneManager.scene.patch.baseName stringByAppendingPathComponent:m.sendName];
	if(![[NSFileManager defaultManager] fileExistsAtPath:m.imagePath]) {
		DDLogVerbose(@"Menubang: no image found: %@", m.sendName);
		m.imagePath = nil;
	}
	
	return m;
}

+ (NSArray *)menubangs {
	return s_menubangs;
}

- (id)initWithFrame:(CGRect)frame {    
    self = [super initWithFrame:frame];
    if(self) {
		if(!s_menubangs) {
			s_menubangs = [[NSMutableArray alloc] init];
			[s_menubangs addObject:self];
		}
		self.label = nil; // no label
    }
    return self;
}

- (void)dealloc {
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

- (void)reshapeForGui:(Gui *)gui {
	// doesn't draw anything
}

#pragma mark Overridden Getters / Setters

- (NSString *)type {
	return @"Menubang";
}

#pragma mark WidgetListener

@end
