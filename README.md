# obs-countdown-to-time
Countdown timer, where you specify the time of the day when the event will start, and it will count down to that time.

This script is a modified version of the countdown script for OBS. Instead of specifying the length of time for the countdown, you specify the time of day.

When you select your text field, the script will overwrite the contents with the remaining hours, minutes, and seconds until the specified time. It starts automatically.

When the event start time is reached, an alternative message is written to the text field.

Configurable Options:
* Event start time - Hours, Minutes, and Seconds
* Prefix text - prepended to the HH:MM:SS timer text
* Postfix text - appended to the HH:MM:SS timer text
* Final text - Text displayed when timer reaches 0

For its output, the timer will show HH:MM:SS. When there is at least one hour, the minutes and seconds are padded with 0s as needed. When less than an hour remains, the minutes are no longer 0 padded. When less than a minute remains, the seconds are no longer padded.

For example, when 4 hour 4 minutes and 4 seconds are left, the timer looks like this:

`PREFIX TEXT 4:04:04 POSTFIX TEXT`

When 4 minutes and 4 seconds are left, it looks like this:

`PREFIX TEXT 4:04 POSTFIX TEXT`

And when just 4 seconds are left:

`PREFIX TEXT 4 POSTFIX TEXT`

Prefix and postfix fields are optional and can be left blank.

Note: this script is not currently compatible with multiday countdowns. This also means that if your event starts just after midnight, the counter will not work until the new day starts. The event date is assumed to be `today`, and the `Final Text` field data will be displayed if the current time is after the event time.
