# Google Calendar And Mail On Victus

Victus selects Khal for DMS and Thunderbird for communication. Dux Calendar's
background unit is removed; the application remains installed for comparison.
The Google calendar mirror is read-only at the remote storage and in Khal.
Use Google Calendar or Thunderbird to edit events.

## Authorise Calendar Synchronisation

After the committed configuration has been built and explicitly activated:

1. In Google Cloud Console, create a project, enable the **CalDAV API**, configure
   its OAuth consent screen and create a **Desktop application** OAuth client.
   If the app is in testing, add your Google account as a test user. Google may
   expire testing-mode refresh tokens; choose the appropriate publishing status
   for your personal application.
2. Download the client JSON privately. Keep it outside this repository:

   ```sh
   install -d -m 700 ~/.config/vdirsyncer
   install -m 600 /path/to/downloaded-client.json ~/.config/vdirsyncer/google-client.json
   google-calendar setup
   ```

3. Follow the browser authorisation using your Google account. Confirm discovery
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

Khal and Thunderbird are configured independently in
`Modules/nix/home/communication/khal.nix` and `thunderbird.nix`. Khal is enabled
when selected as the DMS calendar backend or as a communication package;
Thunderbird is enabled by its communication package selection.

After activation, open Thunderbird's `google` profile once, then close Thunderbird.
Create your private environment file from the installed template:

```sh
install -d -m 700 ~/.config/thunderbird
install -m 600 ~/.config/thunderbird/google.env.example ~/.config/thunderbird/google.env
```

Edit `~/.config/thunderbird/google.env` and set `GOOGLE_EMAIL` and
`GOOGLE_REAL_NAME`. Optionally set `GOOGLE_CALENDAR_IDS` to a comma-separated
list of calendar IDs from Google Calendar's settings. If omitted, the helper
uses your email address as the primary calendar ID. Values are literal text,
optionally quoted; shell commands and variable expansion are not supported.
Do not put passwords or OAuth tokens in this file.

With Thunderbird closed, run:

```sh
thunderbird-google-setup
```

The helper reads the private file at runtime and configures Gmail IMAP/SMTP
with OAuth2 and the selected Google CalDAV calendars in the writable profile.
It preserves unrelated preferences, reuses a matching mail identity and keeps
an original `prefs.js.before-google-setup` backup. It refuses to run while the
profile is locked. For a different profile, pass `--profile /path/to/profile`;
for a different environment file, pass `--env /path/to/private.env`.
Rerun after changing the file; removing a calendar ID does not unsubscribe an
existing calendar. Remove unwanted subscriptions in Thunderbird.

Open Thunderbird and complete Google's sign-in prompts for mail and calendars.
Enable the calendars in the calendar sidebar and compare a known event with
the Google web calendar. Khal's synchronisation does not populate Thunderbird;
the two applications authorise and synchronise separately.

If you prefer calendar discovery, select calendars at
[Google's sync selection page](https://calendar.google.com/calendar/syncselect),
then choose **New Account → Calendar → On the Network** in Thunderbird, enter
your Google email address and choose **Find Calendars**. Complete sign-in and
choose **Subscribe**. See [Mozilla's instructions](https://support.mozilla.org/en-US/kb/using-lightning-google-calendar).

The real environment file and generated preferences stay outside the repository
and Nix store. The Nix configuration installs only the helper and an empty
example. This is the interim setup until SOPS integration is available; protect
the environment file and Thunderbird profile as private user data.

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
