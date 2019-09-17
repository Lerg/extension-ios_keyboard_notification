#if defined(DM_PLATFORM_IOS)

#include <dmsdk/sdk.h>
#include "extension.h"

#import <CoreGraphics/CGGeometry.h>
#import <UIKit/UIKit.h>
#import "ios/utils.h"

// Using proper Objective-C object for main extension entity.
@interface ExtensionInterface : NSObject
@end

@implementation ExtensionInterface {
    LuaScriptListener *script_listener;
}

static NSString *const EVENT_PHASE = @"phase";
static NSString *const EVENT_WILL_SHOW = @"will_show";
static NSString *const EVENT_DID_SHOW = @"did_show";
static NSString *const EVENT_WILL_HIDE = @"will_hide";
static NSString *const EVENT_DID_HIDE = @"did_hide";
static NSString *const EVENT_WILL_CHANGE_FRAME = @"will_change_frame";
static NSString *const EVENT_DID_CHANGE_FRAME = @"did_change_frame";

static NSString *const EVENT_ANIMATION_CURVE = @"animation_curve";
static NSString *const EVENT_ANIMATION_DURATION = @"animation_duration";
static NSString *const EVENT_IS_LOCAL = @"is_local";
static NSString *const EVENT_FRAME_BEGIN = @"frame_begin";
static NSString *const EVENT_FRAME_END = @"frame_end";

static NSString *const EVENT_X = @"x";
static NSString *const EVENT_Y = @"y";
static NSString *const EVENT_WIDTH = @"width";
static NSString *const EVENT_HEIGHT = @"height";

static NSDictionary *rect_to_dict(CGRect rect) {
	NSDictionary *rect_dict = @{
		EVENT_X: @(rect.origin.x),
		EVENT_Y: @(rect.origin.y),
		EVENT_WIDTH: @(rect.size.width),
		EVENT_HEIGHT: @(rect.size.height)
	};
	return rect_dict;
}

static ExtensionInterface *extension_instance;
int EXTENSION_INIT(lua_State *L) {return [extension_instance init_:L];}

-(id)init:(lua_State*)L {
	self = [super init];

	script_listener = [LuaScriptListener new];
    script_listener.listener = LUA_REFNIL;
	script_listener.script_instance = LUA_REFNIL;

	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:self
		selector:@selector(keyboardWillShow:)
		name:UIKeyboardWillShowNotification
		object:nil];
	[nc addObserver:self
		selector:@selector(keyboardDidShow:)
		name:UIKeyboardDidShowNotification
		object:nil];
	[nc addObserver:self
		selector:@selector(keyboardWillHide:)
		name:UIKeyboardWillHideNotification
		object:nil];
	[nc addObserver:self
		selector:@selector(keyboardDidHide:)
		name:UIKeyboardDidHideNotification
		object:nil];
	[nc addObserver:self
		selector:@selector(keyboardWillChangeFrame:)
		name:UIKeyboardWillChangeFrameNotification
		object:nil];
	[nc addObserver:self
		selector:@selector(keyboardDidChangeFrame:)
		name:UIKeyboardDidChangeFrameNotification
		object:nil];

	return self;
}

# pragma mark - Lua functions -

// ios_keyboard_notification.init(params)
-(int)init_:(lua_State*)L {
	[Utils check_arg_count:L count:1];
    Scheme *scheme = [[Scheme alloc] init];
    [scheme function:@"listener"];

    Table *params = [[Table alloc] init:L index:1];
    [params parse:scheme];

	[Utils delete_ref_if_not_nil:script_listener.listener];
	[Utils delete_ref_if_not_nil:script_listener.script_instance];
    script_listener.listener = [params get_function:@"listener" default:LUA_REFNIL];
	dmScript::GetInstance(L);
	script_listener.script_instance = [Utils new_ref:L];

	return 0;
}

-(void)dispatch_keyboard_event:(NSString *)event_phase info:(NSDictionary *)info {
	NSMutableDictionary *event = [Utils new_event:@(EXTENSION_NAME_STRING)];
	event[EVENT_PHASE] = event_phase;
	NSNumber *animation_curve = [info objectForKey:UIKeyboardAnimationCurveUserInfoKey];
	if (animation_curve != nil) {
		NSString *curve_name = @"";
		switch (animation_curve.unsignedIntegerValue) {
			case UIViewAnimationCurveEaseInOut:
				curve_name = @"ease_in_out";
				break;
			case UIViewAnimationCurveEaseIn:
				curve_name = @"ease_in";
				break;
			case UIViewAnimationCurveEaseOut:
				curve_name = @"ease_out";
				break;
			case UIViewAnimationCurveLinear:
				curve_name = @"linear";
				break;
			default:
				curve_name = animation_curve.stringValue;
				break;
		}
		[Utils put:event key:EVENT_ANIMATION_CURVE value:curve_name];
	}
	[Utils put:event key:EVENT_ANIMATION_DURATION value:[info objectForKey:UIKeyboardAnimationDurationUserInfoKey]];
	NSNumber *is_local = [info objectForKey:UIKeyboardIsLocalUserInfoKey];
	if (is_local != nil) {
		[Utils put:event key:EVENT_IS_LOCAL value:@(is_local.boolValue)];
	}
	NSValue *frame_begin = [info objectForKey:UIKeyboardFrameBeginUserInfoKey];
	if (frame_begin != nil) {
		[Utils put:event key:EVENT_FRAME_BEGIN value:rect_to_dict([frame_begin CGRectValue])];
	}
	NSValue *frame_end = [info objectForKey:UIKeyboardFrameEndUserInfoKey];
	if (frame_end != nil) {
		[Utils put:event key:EVENT_FRAME_END value:rect_to_dict([frame_end CGRectValue])];
	}
	[Utils dispatch_event:script_listener event:event];
}

#pragma mark - Keyboard Events -

-(void)keyboardWillShow:(NSNotification *)notification {
	[self dispatch_keyboard_event:EVENT_WILL_SHOW info:notification.userInfo];
}

-(void)keyboardDidShow:(NSNotification *)notification {
	[self dispatch_keyboard_event:EVENT_DID_SHOW info:notification.userInfo];
}

-(void)keyboardWillHide:(NSNotification *)notification {
	[self dispatch_keyboard_event:EVENT_WILL_HIDE info:notification.userInfo];
}

-(void)keyboardDidHide:(NSNotification *)notification {
	[self dispatch_keyboard_event:EVENT_DID_HIDE info:notification.userInfo];
}

-(void)keyboardWillChangeFrame:(NSNotification *)notification {
	[self dispatch_keyboard_event:EVENT_WILL_CHANGE_FRAME info:notification.userInfo];
}

-(void)keyboardDidChangeFrame:(NSNotification *)notification {
	[self dispatch_keyboard_event:EVENT_DID_CHANGE_FRAME info:notification.userInfo];
}

@end

#pragma mark - Defold lifecycle -

void EXTENSION_INITIALIZE(lua_State *L) {
	extension_instance = [[ExtensionInterface alloc] init:L];
}

void EXTENSION_UPDATE(lua_State *L) {
	[Utils execute_tasks:L];
}

void EXTENSION_APP_ACTIVATE(lua_State *L) {
}

void EXTENSION_APP_DEACTIVATE(lua_State *L) {
}

void EXTENSION_FINALIZE(lua_State *L) {
    extension_instance = nil;
}

#endif
