#import <UIKit/UIKit.h>

@class AlertView;

typedef void (^AlertViewCompletionBlock) (AlertView *alertView, NSString *buttonTitle);

typedef enum {
	AlertViewStyleAlert,
	AlertViewStyleText
} AlertViewStyle;

@interface AlertView : UIViewController

@property (copy, nonatomic) AlertViewCompletionBlock tapBlock;

- (id)initWithTitle:(NSString *)title
			message:(NSString *)message
			  style:(AlertViewStyle)style
  cancelButtonTitle:(NSString *)cancelButtonTitle
  otherButtonTitles:(NSArray *)otherButtonTitles;
			 //tapBlock:(AlertViewCompletionBlock)tapBlock;

- (void)show;

- (UITextField *)textFieldAtIndex:(NSInteger)index;

@end