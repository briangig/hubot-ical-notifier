# hubot-ical-notifier

Notifies schedule for tomorrow from registered iCal calendars at 3:45 pm every day

Can also call by using !today or !tomorrow.  Scheduled notification is aware of weekends, will give Monday's schedule on Fridays.

Then add **hubot-ical-notifier** to your `external-scripts.json`:

```json
[
  "hubot-ical-notifier"
]
```

Then set `ICAL_NOTIFIER_ROOM` in environment variable to specify the room where hubot posts notifications.

## Usage

To add a new calendar,

```
hubot cal:add http://example.com/your_ical_calendar.ics
```

To show the list of registered calendars,

```
hubot cal:list
```

To clear all of the registered calendars (yes its spelled wrong),

```
hubot cal:clere
```
