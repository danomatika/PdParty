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
#import "ControlsView.h"

#import "Log.h"
#import "Util.h"

@interface ControlsView ()
@property (readwrite, nonatomic) float defaultHeight;
@property (readwrite, nonatomic) float defaultSpacing;
@property (readwrite, nonatomic) float defaultToolbarHeight;
@end

@implementation ControlsView

- (id)initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame];
	if(self) {
		self.translatesAutoresizingMaskIntoConstraints = NO;

		// sizing
		self.defaultHeight = ControlsView.baseHeight;
		self.defaultSpacing = ControlsView.baseSpacing;
		self.defaultToolbarHeight = ControlsView.baseToolbarHeight;

		// toolbar buttons
		self.leftButton = [self createLeftButton];
		self.rightButton = [self createRightButton];
		UIBarButtonItem *leftSpace =
			[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace
			                                              target:nil
			                                              action:nil];
		leftSpace.width = self.defaultSpacing;
		UIBarButtonItem *middleSpace =
			[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
			                                              target:nil
			                                              action:nil];
		UIBarButtonItem *rightSpace =
			[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace
			                                              target:nil
			                                              action:nil];
		rightSpace.width = self.defaultSpacing;

		// toolbar
		self.toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(frame), self.toolbarHeight)];
		self.toolbar.translatesAutoresizingMaskIntoConstraints = NO;
		self.toolbar.translucent = NO;
		[self.toolbar setItems:@[leftSpace, self.leftButton, middleSpace, self.rightButton, rightSpace]];
		[self addSubview:self.toolbar];

		// slider
		self.slider = [self createSlider];
		[self addSubview:self.slider];
		
		// auto layout constraints
		
		// keep overall height from getting too small
		heightConstraint =
			[NSLayoutConstraint constraintWithItem:self
			                             attribute:NSLayoutAttributeHeight
			                             relatedBy:NSLayoutRelationGreaterThanOrEqual
			                                toItem:nil
			                             attribute:NSLayoutAttributeNotAnAttribute
			                            multiplier:1.0
			                              constant:self.defaultHeight];
		
		// lock toolbar height to given size
		toolbarHeightConstraint =
			[NSLayoutConstraint constraintWithItem:self.toolbar
			                             attribute:NSLayoutAttributeHeight
			                             relatedBy:NSLayoutRelationEqual
			                                toItem:nil
			                             attribute:NSLayoutAttributeNotAnAttribute
			                            multiplier:1.0
			                              constant:self.defaultToolbarHeight];
		
		// keep slider centered within space under toolbar
		sliderLeadingConstraint =
			[NSLayoutConstraint constraintWithItem:self.slider
			                             attribute:NSLayoutAttributeLeading
			                             relatedBy:NSLayoutRelationEqual
			                                toItem:self
			                             attribute:NSLayoutAttributeLeading
			                            multiplier:1.0
			                              constant:self.defaultSpacing];
		sliderTrailingConstraint =
			[NSLayoutConstraint constraintWithItem:self.slider
			                             attribute:NSLayoutAttributeTrailing
			                             relatedBy:NSLayoutRelationEqual
			                                toItem:self
			                             attribute:NSLayoutAttributeTrailing
			                            multiplier:1.0
			                              constant:-self.defaultSpacing];
		sliderCenterYConstraint =
			[NSLayoutConstraint constraintWithItem:self.slider
			                             attribute:NSLayoutAttributeCenterY
			                             relatedBy:NSLayoutRelationEqual
			                                toItem:self
			                             attribute:NSLayoutAttributeCenterY
			                            multiplier:1.0
			                              constant:self.defaultToolbarHeight/2];
		
		[self addConstraints:@[heightConstraint, toolbarHeightConstraint,
			
			// keep toolbar at top with full width
			[NSLayoutConstraint constraintWithItem:self.toolbar
			                             attribute:NSLayoutAttributeLeading
			                             relatedBy:NSLayoutRelationEqual
			                                toItem:self
			                             attribute:NSLayoutAttributeLeading
			                            multiplier:1.0
			                              constant:0],
			[NSLayoutConstraint constraintWithItem:self.toolbar
			                             attribute:NSLayoutAttributeTrailing
			                             relatedBy:NSLayoutRelationEqual
			                                toItem:self
			                             attribute:NSLayoutAttributeTrailing
			                            multiplier:1.0
			                              constant:0],
			[NSLayoutConstraint constraintWithItem:self.toolbar
			                             attribute:NSLayoutAttributeTop
			                             relatedBy:NSLayoutRelationEqual
			                                toItem:self
			                             attribute:NSLayoutAttributeTop
			                            multiplier:1.0
			                              constant:10],
			
			// slider
			sliderLeadingConstraint, sliderTrailingConstraint, sliderCenterYConstraint]
		];

		// colors
		self.lightBackground = NO;
	}
    return self;
}

#pragma mark UI

- (UIBarButtonItem *)createLeftButton {
	return [[UIBarButtonItem alloc] initWithTitle:@"left"
											style:UIBarButtonItemStylePlain
	                                       target:self
	                                       action:@selector(buttonPressed:)];
}

- (UIBarButtonItem *)createRightButton {
	return [[UIBarButtonItem alloc] initWithTitle:@"right"
	                                        style:UIBarButtonItemStylePlain
	                                       target:self
	                                       action:@selector(buttonPressed:)];
}

- (UISlider *)createSlider {
	UISlider *slider = [[UISlider alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.frame), self.defaultHeight)];
	[slider addTarget:self action:@selector(sliderStartedTracking:) forControlEvents:UIControlEventTouchDown];
	[slider addTarget:self action:@selector(sliderStoppedTracking:) forControlEvents:(UIControlEventTouchUpInside | UIControlEventTouchUpOutside)];
	[slider addTarget:self action:@selector(sliderValueChanged:) forControlEvents:UIControlEventValueChanged];

	slider.translatesAutoresizingMaskIntoConstraints = NO;
	slider.minimumValue = 0.0;
	slider.maximumValue = 1.0;
	return slider;
}

- (void)buttonPressed:(id)sender {
	if(!self.delegate) {return;}
	if(sender == self.leftButton) {
		[self.delegate controlsViewLeftPressed:self];
	}
	else if(sender == self.rightButton) {
		[self.delegate controlsViewRightPressed:self];
	}
}

- (void)sliderStartedTracking:(id)sender {
	if(!self.delegate) {return;}
	[self.delegate controlsView:self sliderStartedTracking:self.slider.value];
}

- (void)sliderStoppedTracking:(id)sender {
	if(!self.delegate) {return;}
	[self.delegate controlsView:self sliderStoppedTracking:self.slider.value];
}

- (void)sliderValueChanged:(id)sender {
	if(!self.delegate) {return;}
	[self.delegate controlsView:self sliderValueChanged:self.slider.value];
}

#pragma mark Sizing

+ (float)baseWidth {
	if(Util.isDeviceATablet) {
		return 320;
	}
	else { // smaller popups on iPhone
		return 300;
	}
}

+ (float)baseHeight {
	return Util.isDeviceATablet ? 222 : 126;
}

+ (float)baseSpacing {
	return Util.isDeviceATablet ? 84 : 42;
}

+ (float)baseToolbarHeight {
	return Util.isDeviceATablet ? 128 : 84;
}

- (void)halfSize {
	self.height = 126;
	self.spacing = self.defaultSpacing/2;
	self.toolbarHeight = self.defaultToolbarHeight/2;
	[self setNeedsUpdateConstraints];
}

- (void)defaultSize {
	self.height = self.defaultHeight;
	self.spacing = Util.isDeviceATablet ? self.defaultSpacing*2 : self.defaultSpacing;
	self.toolbarHeight = self.defaultToolbarHeight;
	[self setNeedsUpdateConstraints];
}

#pragma Layout

- (void)alignToSuperview {
	[self.superview addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[view]|"
	                                                                       options:0
	                                                                       metrics:nil
	                                                                         views:@{@"view" : self}]];
	[self.superview addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[view]|"
	                                                                       options:0
	                                                                       metrics:nil
	                                                                         views:@{@"view" : self}]];
}

- (void)alignToSuperviewBottom {
	[self.superview addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[view]|"
	                                                                       options:0
	                                                                       metrics:nil
	                                                                         views:@{@"view" : self}]];
	[self.superview addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[view]|"
	                                                                       options:0
	                                                                       metrics:nil
	                                                                         views:@{@"view" : self}]];
}

- (void)alignToSuperviewTop {
	[self.superview addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[view]|"
	                                                                       options:0
	                                                                       metrics:nil
	                                                                         views:@{@"view" : self}]];
	[self.superview addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[view]"
	                                                                       options:0
	                                                                       metrics:nil
	                                                                         views:@{@"view" : self}]];
}

#pragma mark Overridden Getters / Setters

- (void)setHeight:(float)height {
	heightConstraint.constant = height;
}

- (float)height {
	return heightConstraint.constant;
}

- (void)setSpacing:(float)spacing {
	sliderLeadingConstraint.constant = spacing;
	sliderTrailingConstraint.constant = -spacing;
	
	// assume tool bar fixed width spaces are first and last
	[self.toolbar.items.firstObject setWidth:spacing];
	[self.toolbar.items.lastObject setWidth:spacing];
}

- (float)spacing {
	return sliderLeadingConstraint.constant;
}

- (void)setToolbarHeight:(float)toolbarHeight {
	toolbarHeightConstraint.constant = toolbarHeight;
	sliderCenterYConstraint.constant = toolbarHeight/2;
}

- (float)toolbarHeight {
	return toolbarHeightConstraint.constant;
}

- (void)setLightBackground:(BOOL)lightBackground {
	_lightBackground = lightBackground;
	if(lightBackground) {
		if(@available(iOS 13.0, *)) {
			self.backgroundColor = UIColor.systemBackgroundColor;
			self.toolbar.backgroundColor = UIColor.systemBackgroundColor;
			self.toolbar.barTintColor = UIColor.systemBackgroundColor;
		}
		else {
			self.backgroundColor = UIColor.whiteColor;
			self.toolbar.backgroundColor = UIColor.whiteColor;
			self.toolbar.barTintColor = UIColor.whiteColor;
		}
	}
	else {
		self.backgroundColor = UIColor.blackColor;
		self.toolbar.backgroundColor = UIColor.blackColor;
		self.toolbar.barTintColor = UIColor.blackColor;
	}
}

@end
