#import <Foundation/Foundation.h>

#import "Log.h"

/// a threadsafe Lumberjack logger that writes to a given text view
@interface TextViewLogger : Logger <UIScrollViewDelegate>

/// set this as the target for text updates
@property (weak, nonatomic) UITextView *textView;

/// backing log line data
@property (strong, readonly, atomic) NSMutableString *text;
@property (readonly, atomic) NSInteger lineCount;

/// is the automatic scroll animated? (default: NO),
/// animated scrolling looks nicer but can lose track of the contentOffset
/// if log lines are coming in very quickly while the textView is scrolling
@property (assign, nonatomic) BOOL animateScroll;

/// adds a line to the log data, appends to textView if set
/// removes oldest line if we're at the limit
- (void)addLine:(NSString *)line;

/// update the text view if set, scrolls to bottom if the textView is not
/// currenly scrolling and at the contentOffset is close to the bottom already
- (void)update;

/// clear the buffer and textView if set
- (void)clear;

@end
