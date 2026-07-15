on escapeForShell(raw)
    if raw is missing value or raw is "EMPTY" then return ""
    set AppleScript's text item delimiters to "\""
    set escaped to raw as text
    set AppleScript's text item delimiters to ""
    return escaped
end escapeForShell

on formatDateISO(d)
    set y to year of d
    set m to month of d as integer
    set dd to day of d
    set hh to hours of d
    set mm to minutes of d
    set ss to seconds of d

    set m to my pad2(m)
    set dd to my pad2(dd)
    set hh to my pad2(hh)
    set mm to my pad2(mm)
    set ss to my pad2(ss)

    return (y as text) & "-" & m & "-" & dd & " " & hh & ":" & mm & ":" & ss
end formatDateISO

on pad2(n)
    set n to n as text
    if (length of n) = 1 then
        return "0" & n
    else
        return n
    end if
end pad2

on jstr(t)
    if t is missing value then set t to ""
    set s to t as text

    set AppleScript's text item delimiters to "\""
    set parts to every text item of s
    set AppleScript's text item delimiters to "\\\""
    set s to parts as text
    set AppleScript's text item delimiters to ""

    return "\"" & s & "\""
end jstr

on meetingStart(eventId, title, allday, startDate, endDate, eventLocation, repeatingEvent, attendeeCount, meetingUrl, meetingService, meetingNotes)

    if title is missing value or title is "" or title is "EMPTY" then set title to "No title"
    if eventLocation is missing value or eventLocation is "EMPTY" then set eventLocation to "No location"
    if meetingService is missing value or meetingService is "EMPTY" then set meetingService to "Unknown"
    if meetingNotes is missing value or meetingNotes is "EMPTY" then set meetingNotes to "No notes available"

    set startText to startDate as text
    set endText to endDate as text
    set alldayText to allday as text
    set repeatingText to repeatingEvent as text
    set attendeeCountText to attendeeCount as text

    set msg to "Start: " & formatDateISO(startDate) & return & "End: " & formatDateISO(endDate)
    set subtitle to meetingService
    set soundName to "Glass"

    set jsonText to "{ "
    set jsonText to jsonText & "\"eventId\": " & jstr(eventId) & ", "
    set jsonText to jsonText & "\"title\": " & jstr(title) & ", "
    set jsonText to jsonText & "\"allday\": " & jstr(alldayText) & ", "
    set jsonText to jsonText & "\"start\": " & jstr(startText) & ", "
    set jsonText to jsonText & "\"end\": " & jstr(endText) & ", "
    set jsonText to jsonText & "\"location\": " & jstr(eventLocation) & ", "
    set jsonText to jsonText & "\"repeating\": " & jstr(repeatingText) & ", "
    set jsonText to jsonText & "\"attendees\": " & jstr(attendeeCountText) & ", "
    set jsonText to jsonText & "\"meetingUrl\": " & jstr(meetingUrl) & ", "
    set jsonText to jsonText & "\"meetingService\": " & jstr(meetingService) & ", "
    set jsonText to jsonText & "\"notes\": " & jstr(meetingNotes)
    set jsonText to jsonText & " }"

    set userHome to POSIX path of (path to home folder)
    set logDir to POSIX path of (path to library folder from user domain) & "Logs/MeetingBar/"
    set jsonPath to logDir & eventId & ".json"
    do shell script "mkdir -p " & quoted form of logDir
    do shell script "printf %s " & quoted form of jsonText & " > " & quoted form of jsonPath

    set zshCode to "
    source \"$XDG_CONFIG_HOME/zsh/src/meetingbar.zsh\"
    meetingbar_send_notification " & quoted form of jsonPath

    set shellCmd to "/bin/zsh -c " & quoted form of zshCode
    do shell script shellCmd
end meetingStart
