# Google Calendar And Mail On Victus

Victus selects Dux Calendar (`dankcal`) as the DMS calendar backend, with
Thunderbird for mail and direct Google calendar access. Khal and vdirsyncer
remain enabled as a separate terminal calendar and synchronisation service.
Khal and vdirsyncer allow two-way synchronisation. You can edit events in Khal,
Thunderbird or Google Calendar where your Google account has write permission.
Shared calendars, holidays and other subscriptions may still be read-only.

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
4. Verify the local calendars against a known Google event:

   ```sh
   google-calendar sync
   khal list today 30d
   systemctl --user start google-calendar.service
   systemctl --user list-timers google-calendar.timer
   journalctl --user -u google-calendar.service -n 30
   ```

The timer runs every five minutes. Compare a known Google event's date and title
with Khal. DMS now uses Dux Calendar's own account configuration and connection;
Khal's timer does not populate that backend. Open Dux Calendar and check that
your Google account is connected, then compare the event with the DMS calendar card. Never add a synthetic test event to the remote account implicitly.

Client credentials, refresh tokens, discovery status and generated configuration
live under the user's XDG config/state directories. Calendar files live under
`~/.local/share/calendars/google`. Treat those files as private too. Do not paste
OAuth credentials, token files or verbose authentication logs into Git or chat.
The helper requires the downloaded Desktop client JSON with mode 0600 and writes
its runtime configuration with mode 0600 and umask 0077.

## Authorise Thunderbird

Khal and Thunderbird are configured independently in
`Modules/nix/home/communication/khal.nix` and `thunderbird.nix`. Khal is enabled
as a communication package on Victus, or when selected as the DMS backend;
Thunderbird is enabled by its communication package selection.

After activation, open Thunderbird's `google` profile once, then close Thunderbird.
Create the shared private config if needed, then set its permissions before editing:

```sh
install -d -m 700 ~/Private
touch ~/Private/config.toml
chmod 600 ~/Private/config.toml
```

Add the following to the shared `~/Private/config.toml`, using one
`[[thunderbird.accounts]]` section per account:

```toml
[[thunderbird.accounts]]
email = "main@gmail.com"
real_name = "Main Name"

[[thunderbird.accounts]]
email = "other@gmail.com"
real_name = "Other Name"
```

The helper configures mail for every listed account. If saved Khal/vdirsyncer
calendar discovery exists at `~/.local/state/vdirsyncer/status/google.collections`
(or the equivalent under `XDG_STATE_HOME`), it reuses those calendar IDs only for
an account whose primary email appears in that discovery. It does not read or
share Khal's OAuth tokens. Without a matching cache, use Thunderbird's native
calendar discovery as described below. Optional `calendar_ids` in an account's
TOML entry can also register specific calendars without an extra OAuth flow.

Keep the shared file at mode 0600. If `~/Private/config.toml` is absent, the helper
checks `~/.config/thunderbird/google.toml`, then the older `google.env` and `~/.env`
formats. The installed `google.toml.example` shows the standalone TOML format.
Do not put passwords or OAuth tokens in this file.

With Thunderbird closed, run:

```sh
thunderbird-google-setup
```

The helper does not open a Google consent screen. It reuses available local
calendar discovery and configures mail without requiring Khal, a custom OAuth
client, CalendarList API access or test-user registration for other accounts.
An old `oauth_client` setting is no longer used. Existing discovery tokens under
`~/.local/state/thunderbird-google/oauth` are also no longer used.

Setup is complete when the command prints:

```text
Google mail and calendars configured. Open Thunderbird and complete Google sign-in.
```

The helper reads the private file at runtime and configures Gmail IMAP/SMTP
with OAuth2 and the reused or explicitly listed CalDAV calendars in the writable
profile. Thunderbird connects directly to Google for mail and calendar access;
it does not synchronise events through Khal's local files.
It preserves unrelated preferences, reuses a matching mail identity and keeps
an original `prefs.js.before-google-setup` backup. It refuses to run while the
profile is locked. For a different profile, pass `--profile /path/to/profile`;
for a different config file, pass `--config /path/to/config.toml`.
Rerun after adding mail accounts or updating Khal discovery to register new subscriptions.
Existing subscriptions are preserved; remove unwanted ones in Thunderbird.

Open Thunderbird and complete Google's sign-in prompts for mail and calendars.
Enable the calendars in the calendar sidebar and compare a known event with
the Google web calendar for each account. Confirm that mail folders load and
that calendars finish synchronising without an error. Successful setup writes
the profile; these checks in Thunderbird establish that mail and event access
also work. Khal's synchronisation does not populate Thunderbird;
the two applications authorise and synchronise separately.

To add calendars for any account natively in Thunderbird, select calendars at
[Google's sync selection page](https://calendar.google.com/calendar/syncselect),
then choose **New Account → Calendar → On the Network** in Thunderbird, enter
your Google email address and choose **Find Calendars**. Complete sign-in and
choose **Subscribe**. See [Mozilla's instructions](https://support.mozilla.org/en-US/kb/using-lightning-google-calendar).

The private configuration and generated preferences stay outside the repository
and Nix store. The Nix configuration installs only the helper and an empty
example. This is the interim setup until SOPS integration is available; protect
the configuration file and Thunderbird profile as private user data.

## Editing And Synchronisation

Khal's generated configuration uses `readonly = False` and vdirsyncer's Google
storage uses `read_only = false`, allowing local edits to upload to Google.
After activating this configuration, refresh discovery before synchronising:

```sh
google-calendar discover google
google-calendar sync
```

Changing storage settings, including `read_only`, invalidates vdirsyncer's saved
discovery. If it reports a detected configuration change, repeat these commands.
Use the `google-calendar` wrapper for discovery and sync: it passes the generated
private configuration at `~/.local/state/vdirsyncer/google.config` (or the
equivalent under `XDG_STATE_HOME`). Bare `vdirsyncer discover google` looks for
its default config instead and can fail with a missing-file error.
The timer regenerates the runtime config and synchronises on subsequent runs.
Khal edits are uploaded on the next sync; Thunderbird edits reach Khal after
Google accepts them and vdirsyncer downloads them. Neither client can override
Google's calendar permissions. Do not use a holiday or other subscribed calendar
as the target for a new event.

Thunderbird subscriptions created by the helper are enabled for editing and use
Thunderbird's Google authorisation. Google still enforces each calendar's actual
permissions. Previously registered calendar names are preserved when available;
saved vdirsyncer discovery may provide only IDs for newly registered calendars.

Victus selects `calendarBackend = "dankcal"` for the DMS calendar card. In
DMS Settings → Time & Weather → Calendar backend, this is labelled **Dux Calendar**.
DMS supports event creation through this backend when Dux Calendar is connected;
its Khal backend only displays events. Open Dux Calendar if DMS reports that the
backend needs launching, then confirm a known event appears and the event
creation control is available. Backend selection does not grant Google write
permissions; check the selected account and calendar in Dux Calendar too.

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
