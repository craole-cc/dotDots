# Google Calendar And Mail On Victus

Victus selects Khal for DMS and Thunderbird for communication. Dux Calendar's
background unit is removed; the application remains installed for comparison.
The Google calendar mirror is read-only at the remote storage and in Khal.
Use Google Calendar or Thunderbird to edit events.

## Authorise Calendar Synchronisation

After the committed configuration has been built and explicitly activated:

1. In Google Cloud Console, create a project, enable the **CalDAV API**, configure
   its OAuth consent screen and create a **Desktop application** OAuth client.
   If the app is in testing, add `iamcraole@gmail.com` as a test user. Google may
   expire testing-mode refresh tokens; choose the appropriate publishing status
   for your personal application.
2. Download the client JSON privately. Keep it outside this repository:

   ```sh
   install -d -m 700 ~/.config/vdirsyncer
   install -m 600 /path/to/downloaded-client.json ~/.config/vdirsyncer/google-client.json
   google-calendar setup
   ```

3. Follow the browser authorisation using `iamcraole@gmail.com`. Confirm discovery
   when prompted. Setup discovers calendars and synchronises events. Google virtual
   calendars do not reliably expose metadata, so setup does not run metasync.
   Only successful completion creates the readiness marker used by the timer.
4. Verify the mirror, then check the DMS calendar card for a known event:

   ```sh
   google-calendar sync
   khal list today 30d
   systemctl --user start google-calendar.service
   systemctl --user list-timers google-calendar.timer
   journalctl --user -u google-calendar.service -n 30
   ```

The timer runs every five minutes. DMS queries Khal when it loads the calendar
range; reopen the calendar card after a sync. An empty agenda alone does not
prove synchronisation: compare a known Google event's date and title with both
Khal and DMS. Never add a synthetic test event to the remote account implicitly.

Client credentials, refresh tokens, discovery status and generated configuration
live under the user's XDG config/state directories. Calendar files live under
`~/.local/share/calendars/google`. Treat those files as private too. Do not paste
OAuth credentials, token files or verbose authentication logs into Git or chat.
The helper requires the downloaded Desktop client JSON with mode 0600 and writes
its runtime configuration with mode 0600 and umask 0077.

## Authorise Thunderbird

Open Thunderbird's declared `google` profile. Gmail IMAP and SMTP use OAuth2;
complete Google's sign-in and consent prompts for `iamcraole@gmail.com`.
Thunderbird stores authorisation in its writable profile, outside Nix.

First select the calendars at [Google's sync selection page](https://calendar.google.com/calendar/syncselect).
In Thunderbird choose **New Account → Calendar → On the Network**, enter
`iamcraole@gmail.com`, then choose **Find Calendars**. Complete Google's sign-in
and choose **Subscribe** for the calendars you want. Compare a known event with
the Google web calendar. Thunderbird and vdirsyncer authorise separately.
See [Mozilla's instructions](https://support.mozilla.org/en-US/kb/using-lightning-google-calendar).

## Deployment And Evidence

Commit and push before building. Building requires a user request; activation
requires an explicit user request. Source configuration and Nix evaluation do
not establish successful deployment, Google access or visible DMS events.

The user owns Google consent and the private client download. After activation
and consent, run the checks above together to establish runtime success.

References: [vdirsyncer Google setup](https://vdirsyncer.pimutils.org/en/stable/tutorials/google.html)
and [Google CalDAV guide](https://developers.google.com/workspace/calendar/caldav/v2/guide).

## DMS Toolkit Transform

The central `dms-shell` toolkit source now applies the theme-control and
Catppuccin patches through `transform`. The DMS component consumes the resulting
record, package and executable paths without a separate package override.
