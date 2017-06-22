#   Based on hubot-ical-notifier by 
#   Ryota Kameoka <kameoka.ryota@gmail.com>
# Description
#   Notifies schedule for tomorrow from registered iCal calendars
#
# Configuration:
#   ICAL_NOTIFIER_ROOM
#
# Commands:
#   !today or !tomorrow - Show the Tech locations for today or tomorrow
#
# Author:
#   Brian Giguere <briangig@gmail.com>

async = require('async')
cron = require('cron').CronJob
ical = require('ical')
moment = require('moment')


config =
  room: process.env.ICAL_NOTIFIER_ROOM



registerJob = (expr, cb) ->
  new cron expr, cb, null, true


getEventsFromICalURL = (url, cb) ->
  ical.fromURL url, {}, (err, data) ->
    return if err

    tomorrow = moment().add(1, 'd')
    events = (data[key] for key of data).map (e) ->
      e.start = moment(e.start)
      e.end = moment(e.end)
      e
    .filter (e) -> e.start.isSame(tomorrow, 'day')

    cb(events)

getMondayEventsFromICalURL = (url, cb) ->
  ical.fromURL url, {}, (err, data) ->
    return if err

    monday = moment().add(3, 'd')
    events = (data[key] for key of data).map (e) ->
      e.start = moment(e.start)
      e.end = moment(e.end)
      e
    .filter (e) -> e.start.isSame(monday, 'day')

    cb(events)

getTodayEventsFromICalURL = (url, cb) ->
  ical.fromURL url, {}, (err, data) ->
    return if err

    today = moment().d
    rightnow = moment().format('LLLL')
    events = (data[key] for key of data).map (e) ->
      e.start = moment(e.start)
      e.end = moment(e.end)
      e
    .filter (e) -> (e.start.isSame(today, 'day') && (moment().format('LLLL') != moment(e.start).format('LLLL') || moment().format('LLLL') != moment(e.end).format('LLLL')))

    cb(events)


pl = (n) ->
  if n is 1 then '' else 's'


module.exports = (robot) ->
  getCalendarList = -> robot.brain.get('calendars') || []
  clearCalendarList = -> robot.brain.set('calendars', [])

  registerJob '0 45 15 * * 1,2,3,4', ->
    cals = getCalendarList()

    processes = cals.map (cal) ->
      return (cb) ->
        getEventsFromICalURL cal, (events) ->
          cb(null, events)

    async.parallel processes, (err, events) ->
      events = events.reduce (acc, x) ->
        acc.concat x
      , []
      tmrw = moment().add(1, 'd').format("dddd, MMMM Do")
      count = events.length

      if count is 0
        robot.send room: config.room, 'There are no techs out tomorrow!'
        return

      text = ">*Tech Locations for #{tmrw}, with #{count} item#{pl count} in total.*\n"
      text += events.map (e) ->
        location = if e.location then " @#{e.location}" else ''
        start = e.start.format('h:mm A')
        end = e.end.format('h:mm A')
        time = if start is '12:00 AM' and end is '12:00 AM'
          'all day'
        else
          "#{start} - #{end}"
        "*#{e.summary}*#{location} _(#{time})_"
      .join "\n"
      text += "\n You can call this info at anytime by using _'!today'_ or _'!tomorrow'_ to get information for today or tomorrow."

      robot.send { room: config.room }, text

  registerJob '0 45 15 * * 5', ->
    cals = getCalendarList()

    processes = cals.map (cal) ->
      return (cb) ->
        getMondayEventsFromICalURL cal, (events) ->
          cb(null, events)

    async.parallel processes, (err, events) ->
      events = events.reduce (acc, x) ->
        acc.concat x
      , []
      monday = moment().add(3, 'd').format("dddd, MMMM Do")
      count = events.length

      if count is 0
        robot.send room: config.room, 'There are no techs out tomorrow!'
        return

      text = ">*Tech Locations for #{monday}, with #{count} item#{pl count} in total.*\n"
      text += events.map (e) ->
        location = if e.location then " @#{e.location}" else ''
        start = e.start.format('h:mm A')
        end = e.end.format('h:mm A')
        time = if start is '12:00 AM' and end is '12:00 AM'
          'all day'
        else
          "#{start} - #{end}"
        "*#{e.summary}*#{location} _(#{time})_"
      .join "\n"
      text += "\n You can call this info at anytime by using _'!today'_ or _'!tomorrow'_ to get information for today or tomorrow."

      robot.send { room: config.room }, text

  robot.respond /cal:add (.+)/, (msg) ->
    newCal = msg.match[1]
    cals = getCalendarList()
    cals.push newCal
    robot.brain.set 'calendars', cals

    count = cals.length
    text = "New calendar has been added!\n"
    text += "Now you have #{count} calendar#{pl count}."
    msg.send text


  robot.respond /cal:list/, (msg) ->
    cals = getCalendarList()
    count = cals.length
    text =
      if count is 0
        'You have no calendars'
      else
        "You have #{count} calendar#{pl count}."

    msg.send "#{text}\n" + cals.join "\n"


  robot.respond /cal:clere/, (msg) ->
    clearCalendarList()
    msg.send 'All calendars have been cleared.'


  robot.hear /!tomorrow/, (msg) ->
    cals = getCalendarList()
    processes = cals.map (cal) ->
      return (cb) ->
        getEventsFromICalURL cal, (events) ->
          cb(null, events)

    async.parallel processes, (err, events) ->
      events = events.reduce (acc, x) ->
        acc.concat x
      , []
      tmrw = moment().add(1, 'd').format("dddd, MMMM Do")
      count = events.length

      if count is 0
        text = "*There are no techs scheduled out tomorrow...wait, who is on-call?*"
        msg.send text
        return


      text = ">*Tech Locations for #{tmrw}, with #{count} item#{pl count} in total.*\n"
      text += events.map (e) ->
        location = if e.location then " @#{e.location}" else ''
        start = e.start.format('h:mm A')
        end = e.end.format('h:mm A')
        time = if start is '12:00 AM' and end is '12:00 AM'
          'all day'
        else
          "#{start} - #{end}"
        "*#{e.summary}*#{location} _(#{time})_"
      .join "\n"
      text += "\n You can call this info at anytime by using _'!today'_ or _'!tomorrow'_ to get information for today or tomorrow."

      msg.send text


  robot.hear /!today/, (msg) ->
    cals = getCalendarList()
    processes = cals.map (cal) ->
      return (cb) ->
        getTodayEventsFromICalURL cal, (events) ->
          cb(null, events)

    async.parallel processes, (err, events) ->
      events = events.reduce (acc, x) ->
        acc.concat x
      , []
      today = moment().format("dddd, MMMM Do")
      count = events.length

      if count is 0
        text = "*There are no techs scheduled out today...wait, who is on-call?*"
        msg.send text
        return



      text = ">*Tech Locations for #{today}, with #{count} item#{pl count} in total.*\n"
      text += events.map (e) ->
        location = if e.location then " @#{e.location}" else ''
        start = e.start.format('h:mm A')
        end = e.end.format('h:mm A')
        time = if start is '12:00 AM' and end is '12:00 AM'
          'all day'
        else
          "#{start} - #{end}"
        "*#{e.summary}*#{location} _(#{time})_"
      .join "\n"
      text += "\n You can call this info at anytime by using _'!today'_ or _'!tomorrow'_ to get information for today or tomorrow."

      msg.send text
