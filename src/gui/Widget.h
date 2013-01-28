/*
 * Copyright (c) 2011 Dan Wilcox <danomatika@gmail.com>
 *
 * BSD Simplified License.
 * For information on usage and redistribution, and for a DISCLAIMER OF ALL
 * WARRANTIES, see the file, "LICENSE.txt," in this distribution.
 *
 * See https://github.com/danomatika/robotcowboy for documentation
 *
 */
#import <UIKit/UIKit.h>
#import "PdBase.h"

#define WIDGET_FILL_COLOR [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0]
#define WIDGET_FRAME_COLOR [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:1.0]

@interface Widget : UIView <PdListener>

@property (nonatomic, retain) UIColor *fillColor;
@property (nonatomic, retain) UIColor *frameColor;

@property (nonatomic, assign) float minValue;
@property (nonatomic, assign) float maxValue;
@property (nonatomic, assign) float value;
@property (nonatomic, assign) int init;

@property (nonatomic, assign) SEL valueAction;
@property (nonatomic, assign) id valueTarget;

@property (nonatomic, retain) NSString *sendName;
@property (nonatomic, retain) NSString *receiveName;

@property (nonatomic, retain) UILabel *label;

- (void)addValueTarget:(id)target action:(SEL)action;

// get the widget type as a string, overridden by other widgets
- (NSString*)getType;

@end

//#include "ofMain.h"
//
//#include "ofxPd.h"
//#include "../Types.h"
//
//namespace gui {
//
//class Gui;
//
//class Widget : public pd::PdReceiver {
//
//	public:
//	
//		Widget(Gui& parent);
//		virtual ~Widget() {}
//
//		virtual void draw() = 0;
//		
//		virtual void drawLabel();
//		
//		string setLabel(string& newLabel);
//		
//		void send(string msg);
//		
//		void sendFloat(float f);
//		
//		/// add the receive name and register this widget to
//		/// receieve messages from ofxPd
//		void setupReceive();
//		
//		void setVal(float v, float alt);
//		
//		inline float getVal() {return val;}
//		
//		virtual void initVal();
//		
//		/// get the Gui type as a string
//		virtual string getType() = 0;
//		
//		/// PdReceiver callbacks
//		virtual void receiveBang(const string& dest);
//		virtual void receiveFloat(const string& dest, float value);
//		virtual void receiveSymbol(const string& dest, const string& symbol);
//		virtual void receiveList(const string& dest, const pd::List& list);
//		virtual void receiveMessage(const string& dest, const string& msg, const pd::List& list);
//		
//		/// input event callbacks
//		virtual void mousePressed(ofMouseEventArgs &e);
//		
//		/// variables
//		ofRectangle rect;
//		float val;
//		int init;
//		string sendName, receiveName;
//		string label;
//		ofVec2f labelPos;
//		
//	protected:
//		
//		Gui& parent;
//};
//
//} // namespace