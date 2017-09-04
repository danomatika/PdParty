#import "AlertView.h"
#import "Util.h"

@interface AlertView () <UIAlertViewDelegate> {
	UIViewController *alert;
}
@end

@implementation AlertView

- (id)initWithTitle:(NSString *)title
			message:(NSString *)message
			  style:(AlertViewStyle)style
  cancelButtonTitle:(NSString *)cancelButtonTitle
  otherButtonTitles:(NSArray *)otherButtonTitles {
	self = [super init];
	if(self) {
		if([Util version] < 8.0) {
			NSString *firstObject = otherButtonTitles.count ? otherButtonTitles[0] : nil;
			UIAlertView *a = [[UIAlertView alloc] initWithTitle:title
														message:message
													   delegate:self
											  cancelButtonTitle:cancelButtonTitle
											  otherButtonTitles:firstObject, nil];
			switch(style) {
				case AlertViewStyleText:
					a.alertViewStyle = UIAlertViewStylePlainTextInput;
					break;
				default:
					break;
			}
			if(otherButtonTitles.count > 1) {
				for (NSString *buttonTitle in [otherButtonTitles subarrayWithRange:NSMakeRange(1, otherButtonTitles.count - 1)]) {
					[a addButtonWithTitle:buttonTitle];
				}
			}
			alert = (UIViewController *)a;
		}
		else {
			UIAlertController* a = [UIAlertController alertControllerWithTitle:title
                               message:message
                               preferredStyle:UIAlertControllerStyleAlert];
			
			UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:cancelButtonTitle style:UIAlertActionStyleCancel
			   handler:^(UIAlertAction * action) {
				AlertViewCompletionBlock completion = self.tapBlock;
				if(completion) {
					completion(self, action.title);
				}
			}];
			[a addAction:cancelAction];
			
			for(NSString *title in otherButtonTitles) {
				UIAlertAction * action = [UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
					AlertViewCompletionBlock completion = self.tapBlock;
					if(completion) {
						completion(self, action.title);
					}
				}];
			}
		}
	}
	return self;
}

- (void)show {
	if([Util version] < 8.0) {
		UIAlertView *a = (UIAlertView *)alert;
		[a show];
	}
	else {
		UIAlertController *a = (UIAlertController *)alert;
		UIViewController *root = [[[UIApplication sharedApplication] keyWindow] rootViewController];
		[root presentViewController:a animated:YES completion:nil];
	}
}

- (UITextField *)textFieldAtIndex:(NSInteger)index {
	if([Util version] < 8.0) {
		UIAlertView *a = (UIAlertView *)alert;
		return [a textFieldAtIndex:index];
	}
	else {
		UIAlertController *a = (UIAlertController *)alert;
		return [a.textFields objectAtIndex:index];
	}
}

#pragma mark UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	AlertViewCompletionBlock completion = [(AlertView *)alertView tapBlock];
	if(completion) {
		completion(self, [alertView buttonTitleAtIndex:buttonIndex]);
	}
}

@end
