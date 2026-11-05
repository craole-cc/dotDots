{
  mkAliasFamily,
  mergeDisjoint,
  mkSource,
  ...
}: {
  cmus = mkSource {
    categories = ["media" "audio"];
    description = "console-based music player";
    aliases = mergeDisjoint [
      (mkAliasFamily "cmus-remote" {
        aliasPrefix = "cmus";
        Next = {
          args = ["-n"];
          description = "skip to the next track";
        };
        Pause = {
          args = ["-u"];
          description = "toggle playback pause";
        };
        Play = {
          args = ["-p"];
          description = "start or resume playback";
        };
        Previous = {
          args = ["-r"];
          description = "return to the previous track";
        };
        Quit = {
          args = ["-q"];
          description = "quit the running cmus instance";
        };
        Repeat = {
          args = ["-R"];
          description = "toggle repeat mode";
        };
        Shuffle = {
          args = ["-S"];
          description = "toggle shuffle mode";
        };
        Status = {
          args = ["-Q"];
          description = "print the current player status and track metadata";
        };
        Stop = {
          args = ["-s"];
          description = "stop playback";
        };
      })
      (mkAliasFamily "cmus" {
        Help = {
          args = ["-h"];
          description = "show command-line help";
        };
        Version = {
          args = ["-v"];
          description = "show the installed version";
        };
      })
    ];
  };

  kew = mkSource {
    categories = ["media" "audio"];
    description = "terminal music player and library browser";
    aliases = mkAliasFamily "kew" {
      Albums = {
        args = ["albums"];
        description = "play albums from the music library in random order";
      };
      All = {
        args = ["all"];
        description = "play all songs in the music library shuffled";
      };
      Dir = {
        args = ["dir"];
        description = "find and play a directory by name";
      };
      Exact = {
        args = ["--exact"];
        description = "match a song, album, or artist name exactly";
      };
      Favorites = {
        args = ["."];
        description = "play the favourites playlist";
      };
      Help = {
        args = ["--help"];
        description = "show command-line help";
      };
      List = {
        args = ["list"];
        description = "play a named playlist";
      };
      NoCover = {
        args = ["--nocover"];
        description = "start without displaying cover art";
      };
      NoUi = {
        args = ["--noui"];
        description = "play without displaying the user interface";
      };
      Path = {
        args = ["path"];
        description = "set the music library path";
      };
      Play = {
        args = ["play"];
        description = "play one or more file or directory paths";
      };
      QuitOnStop = {
        args = ["--quitonstop"];
        description = "exit after the playlist finishes";
      };
      Shuffle = {
        args = ["shuffle"];
        description = "shuffle a matching song or album playlist";
      };
      Song = {
        args = ["song"];
        description = "find and play a song by name";
      };
      Theme = {
        args = ["theme"];
        description = "set the interface theme";
      };
      Verbose = {
        args = ["--verbose"];
        description = "log additional diagnostic information";
      };
      Version = {
        args = ["--version"];
        description = "show the installed version";
      };
    };
  };

  mpv = mkSource {
    categories = ["media" "video"];
    description = "versatile command-line media player";
    aliases = mkAliasFamily "mpv" {
      Audio = {
        args = ["--no-video"];
        description = "play media as audio without displaying video";
      };
      Fullscreen = {
        args = ["--fullscreen"];
        description = "start playback in fullscreen mode";
      };
      Help = {
        args = ["--help"];
        description = "show command-line help";
      };
      Loop = {
        args = ["--loop-file=inf"];
        description = "repeat each played file indefinitely";
      };
      Playlist = {
        args = ["--playlist"];
        description = "play entries from a playlist file";
      };
      Version = {
        args = ["--version"];
        description = "show the installed version";
      };
    };
  };
}
