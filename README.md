# iOS Keyboard Notification extension for Defold

This extension lets you subscribe to the keyboard events on iOS. Such as show/hide.

Read more about the underlying API here:

- [Managing the Keyboard](https://developer.apple.com/library/archive/documentation/StringsTextFonts/Conceptual/TextAndWebiPhoneOS/KeyboardManagement/KeyboardManagement.html#//apple_ref/doc/uid/TP40009542-CH5-SW3)
- [UIKeyboardWillShowNotification](https://developer.apple.com/documentation/uikit/uikeyboardwillshownotification?language=objc)

# Project Settings

Add this URL to the dependencies section in `game.project`.

- `https://github.com/Lerg/extension-ios_keyboard_notification/archive/master.zip`

# API reference

## ios_keyboard_notification.init(params)

Call this function to set a listener for keyboard events.

### `params` reference

- `listener`, function. Receives keyboard event. See event section below.

### Event reference

`listener` receives an `event` table for each keyboard phase.

- `name`, string, `'ios_keyboard_notification'`.
- `phase`, string, keyboard state chage phase, one of `'will_show'`, `'did_show'`, `'will_hide'`, `'did_hide'`, `'will_change_frame'`, `'did_change_frame'`.
- `animation_curve`, string, name of animation curve used to move the keyboard, one of `'ease_in_out'`, `'ease_in'`, `'ease_out'`, `'linear'` or a number converted to string for undocumented easing functions, in particular there is `'7'` animation curve since iOS 7.
- `animation_duration`, number, duration of animation in seconds.
- `is_local`, boolean, identifies whether the keyboard belongs to the current app. With multitasking on iPad, all visible apps are notified when the keyboard appears and disappears. The value of this key is `true` for the app that caused the keyboard to appear and `false` for any other apps.
- `frame_begin`, rectange table, start size and position of the keyboard.
- `frame_end`, rectange table, end size and position of the keyboard.

#### Rectangle Table

This table describes a rectangular shape.

- `x`, number, origin x.
- `y`, number, origin y.
- `width`, number, width.
- `height`, number, height.

### Syntax

```language-lua
ios_keyboard_notification.init{
	listener = function(event)
		print(event.phase)
	end
}
```