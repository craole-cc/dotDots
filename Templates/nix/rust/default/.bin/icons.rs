#!/usr/bin/env rust-script
//! ```cargo
//! [dependencies]
//! clap = { version = "4.5", features = ["derive"] }
//! miette = { version = "7", features = ["fancy"] }
//! reqwest = { version = "0.12", features = ["blocking", "rustls-tls"] }
//! thiserror = "2"
//! ```

use {
  clap::Parser,
  miette::{Diagnostic, IntoDiagnostic, Result},
  reqwest::blocking::Client,
  std::{
    fs,
    path::{Path, PathBuf},
    time::Duration,
  },
  thiserror::Error,
};

#[derive(Debug, Parser)]
#[command(
  name = "get-icons",
  about = "Download project technology, social, and UI icons.",
  disable_help_subcommand = true
)]
struct Cli {
  /// Overwrite icons that already exist.
  #[arg(short = 'f', long = "force")]
  force: bool,

  /// Root directory where icons should be written.
  #[arg(long = "root", default_value = "public/icons")]
  root: PathBuf,
}

#[derive(Debug, Clone, Copy)]
enum Group {
  Technology,
  Social,
  Ui,
}

impl Group {
  fn title(self) -> &'static str {
    match self {
      | Self::Technology => "Technology Icons",
      | Self::Social => "Social Icons",
      | Self::Ui => "UI Icons",
    }
  }
}

#[derive(Debug, Clone, Copy)]
struct Icon {
  group: Group,
  url: &'static str,
  target: &'static str,
}

#[derive(Debug, Error, Diagnostic)]
enum IconError {
  #[error("download failed for {target}")]
  #[diagnostic(help("Check the source URL and your network connection."))]
  DownloadFailed { target: String },

  #[error("invalid HTTP response for {target}: {status}")]
  InvalidResponse {
    target: String,
    status: reqwest::StatusCode,
  },
}

const ICONS: &[Icon] = &[
  // Languages
  Icon {
    group: Group::Technology,
    url: "https://cdn.worldvectorlogo.com/logos/rust.svg",
    target: "logos/rust.svg",
  },
  Icon {
    group: Group::Technology,
    url: "https://cdn.simpleicons.org/rust",
    target: "logos/rust-simple.svg",
  },
  Icon {
    group: Group::Technology,
    url: "https://cdn.worldvectorlogo.com/logos/python-5.svg",
    target: "logos/python.svg",
  },
  Icon {
    group: Group::Technology,
    url: "https://cdn.simpleicons.org/python",
    target: "logos/python-simple.svg",
  },
  Icon {
    group: Group::Technology,
    url: "https://raw.githubusercontent.com/ziglang/logo/4f97e7a9ebce12fa48511c0b6502b6190005bc0e/zig-mark.svg",
    target: "logos/zig.svg",
  },
  Icon {
    group: Group::Technology,
    url: "https://cdn.simpleicons.org/zig",
    target: "logos/zig-simple.svg",
  },
  Icon {
    group: Group::Technology,
    url: "https://cdn.worldvectorlogo.com/logos/go-8.svg",
    target: "logos/go.svg",
  },
  Icon {
    group: Group::Technology,
    url: "https://cdn.simpleicons.org/go",
    target: "logos/go-simple.svg",
  },
  Icon {
    group: Group::Technology,
    url: "https://cdn.worldvectorlogo.com/logos/bash-2.svg",
    target: "logos/bash.svg",
  },
  Icon {
    group: Group::Technology,
    url: "https://cdn.worldvectorlogo.com/logos/powershell.svg",
    target: "logos/powershell.svg",
  },
  // Rust ecosystem
  Icon {
    group: Group::Technology,
    url: "https://raw.githubusercontent.com/tokio-rs/website/master/public/img/icons/tokio.svg",
    target: "logos/tokio.svg",
  },
  Icon {
    group: Group::Technology,
    url: "https://raw.githubusercontent.com/leptos-rs/leptos/6e83f712d2d64014e000302c9cd265d4a9a61311/logos/Simple_Icon.svg",
    target: "logos/leptos.png",
  },
  Icon {
    group: Group::Technology,
    url: "https://cdn.worldvectorlogo.com/logos/tauri-1.svg",
    target: "logos/tauri.svg",
  },
  Icon {
    group: Group::Technology,
    url: "https://usw2-zeet-misc.s3.us-west-2.amazonaws.com/images/SurrealDB.png",
    target: "logos/surrealdb.png",
  },
  Icon {
    group: Group::Technology,
    url: "https://raw.githubusercontent.com/surrealdb/surrealdb/main/img/logo.svg",
    target: "logos/surrealdb.svg",
  },
  // Data
  Icon {
    group: Group::Technology,
    url: "https://upload.wikimedia.org/wikipedia/commons/f/f3/Apache_Spark_logo.svg",
    target: "logos/apache-spark.svg",
  },
  Icon {
    group: Group::Technology,
    url: "https://cdn.worldvectorlogo.com/logos/scala-4.svg",
    target: "logos/scala.svg",
  },
  Icon {
    group: Group::Technology,
    url: "https://cdn.prod.website-files.com/68c803b3497f18f5503b830d/68da505ee9382ac2316b3e67_66192bf45f99cf9cd103c8b3_delta.svg",
    target: "logos/deltalake.svg",
  },
  Icon {
    group: Group::Technology,
    url: "https://cdn.worldvectorlogo.com/logos/kafka.svg",
    target: "logos/kafka.svg",
  },
  Icon {
    group: Group::Technology,
    url: "https://upload.wikimedia.org/wikipedia/commons/2/29/Postgresql_elephant.svg",
    target: "logos/postgresql.svg",
  },
  Icon {
    group: Group::Technology,
    url: "https://cdn.worldvectorlogo.com/logos/mysql-logo-pure.svg",
    target: "logos/mysql.svg",
  },
  Icon {
    group: Group::Technology,
    url: "https://cdn.worldvectorlogo.com/logos/duckdb-logo.svg",
    target: "logos/duckdb.svg",
  },
  // Web
  Icon {
    group: Group::Technology,
    url: "https://cdn.worldvectorlogo.com/logos/typescript.svg",
    target: "logos/typescript.svg",
  },
  Icon {
    group: Group::Technology,
    url: "https://cdn.worldvectorlogo.com/logos/javascript-1.svg",
    target: "logos/javascript.svg",
  },
  Icon {
    group: Group::Technology,
    url: "https://cdn.worldvectorlogo.com/logos/html-1.svg",
    target: "logos/html.svg",
  },
  Icon {
    group: Group::Technology,
    url: "https://cdn.worldvectorlogo.com/logos/css-3.svg",
    target: "logos/css.svg",
  },
  Icon {
    group: Group::Technology,
    url: "https://cdn.worldvectorlogo.com/logos/sass-1.svg",
    target: "logos/sass.svg",
  },
  Icon {
    group: Group::Technology,
    url: "https://cdn.worldvectorlogo.com/logos/tailwind-css-2.svg",
    target: "logos/tailwind.svg",
  },
  Icon {
    group: Group::Technology,
    url: "https://cdn.worldvectorlogo.com/logos/svelte-1.svg",
    target: "logos/svelte.svg",
  },
  Icon {
    group: Group::Technology,
    url: "https://raw.githubusercontent.com/vitejs/vite/main/docs/public/logo.svg",
    target: "logos/vite.svg",
  },
  Icon {
    group: Group::Technology,
    url: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTuW9lcdXGNSXkg7EsdpXy0wNhPz8YcGXFwRA&s",
    target: "logos/htmx.png",
  },
  Icon {
    group: Group::Technology,
    url: "https://logo.svgcdn.com/logos/htmx-icon.png",
    target: "logos/htmx.png",
  },
  // Operating systems
  Icon {
    group: Group::Technology,
    url: "https://cdn.worldvectorlogo.com/logos/windows-3.svg",
    target: "logos/windows.svg",
  },
  Icon {
    group: Group::Technology,
    url: "https://cdn.worldvectorlogo.com/logos/raspberry-pi.svg",
    target: "logos/raspberry-pi.svg",
  },
  Icon {
    group: Group::Technology,
    url: "https://raw.githubusercontent.com/NixOS/nixos-artwork/master/logo/nixos-white.svg",
    target: "logos/nixos.svg",
  },
  Icon {
    group: Group::Technology,
    url: "https://cdn.worldvectorlogo.com/logos/linux-tux.svg",
    target: "logos/linux-tux.svg",
  },
  Icon {
    group: Group::Technology,
    url: "https://upload.wikimedia.org/wikipedia/commons/1/13/Arch_Linux_%22Crystal%22_icon.svg",
    target: "logos/arch.svg",
  },
  Icon {
    group: Group::Technology,
    url: "https://cdn.worldvectorlogo.com/logos/arch-linux-logo.svg",
    target: "logos/archlinux.svg",
  },
  // DevOps
  Icon {
    group: Group::Technology,
    url: "https://cdn.worldvectorlogo.com/logos/visual-studio-code-1.svg",
    target: "logos/vscode.svg",
  },
  Icon {
    group: Group::Technology,
    url: "https://cdn.worldvectorlogo.com/logos/docker.svg",
    target: "logos/docker-full.svg",
  },
  Icon {
    group: Group::Technology,
    url: "https://raw.githubusercontent.com/kubernetes/kubernetes/master/logo/logo.svg",
    target: "logos/kubernetes.svg",
  },
  Icon {
    group: Group::Technology,
    url: "https://cdn.worldvectorlogo.com/logos/git-icon.svg",
    target: "logos/git.svg",
  },
  Icon {
    group: Group::Technology,
    url: "https://cdn.worldvectorlogo.com/logos/git-bash.svg",
    target: "logos/gitbash.svg",
  },
  Icon {
    group: Group::Technology,
    url: "https://raw.githubusercontent.com/helix-editor/helix/master/logo_dark.svg",
    target: "logos/helix-editor.svg",
  },
  Icon {
    group: Group::Technology,
    url: "https://upload.wikimedia.org/wikipedia/commons/3/3a/Neovim-mark.svg",
    target: "logos/neovim.svg",
  },
  Icon {
    group: Group::Technology,
    url: "https://cdn.worldvectorlogo.com/logos/vim.svg",
    target: "logos/vim.svg",
  },
  Icon {
    group: Group::Technology,
    url: "https://cdn.worldvectorlogo.com/logos/sony-logo-1.svg",
    target: "logos/sony.svg",
  },
  Icon {
    group: Group::Technology,
    url: "https://cdn.worldvectorlogo.com/logos/sony-alpha-logo.svg",
    target: "logos/sony-alpha.svg",
  },
  // Social
  Icon {
    group: Group::Social,
    url: "https://cdn.worldvectorlogo.com/logos/slack-new-logo.svg",
    target: "logos/slack.svg",
  },
  Icon {
    group: Group::Social,
    url: "https://cdn.worldvectorlogo.com/logos/github-icon.svg",
    target: "logos/github-refined.svg",
  },
  Icon {
    group: Group::Social,
    url: "https://cdn.simpleicons.org/github",
    target: "logos/github-simple.svg",
  },
  Icon {
    group: Group::Social,
    url: "https://cdn.worldvectorlogo.com/logos/gitlab-3.svg",
    target: "logos/gitlab.svg",
  },
  Icon {
    group: Group::Social,
    url: "https://cdn.simpleicons.org/gitlab",
    target: "logos/gitlab-simple.svg",
  },
  Icon {
    group: Group::Social,
    url: "https://cdn.worldvectorlogo.com/logos/linkedin-icon-2.svg",
    target: "logos/linkedin.svg",
  },
  Icon {
    group: Group::Social,
    url: "https://cdn.worldvectorlogo.com/logos/x-twitter.svg",
    target: "logos/x.svg",
  },
  Icon {
    group: Group::Social,
    url: "https://cdn.simpleicons.org/x",
    target: "logos/x-simple.svg",
  },
  Icon {
    group: Group::Social,
    url: "https://cdn.worldvectorlogo.com/logos/facebook-modern-design-.svg",
    target: "logos/facebook-trimmed.svg",
  },
  Icon {
    group: Group::Social,
    url: "https://cdn.simpleicons.org/facebook",
    target: "logos/facebook-simple.svg",
  },
  Icon {
    group: Group::Social,
    url: "https://cdn.worldvectorlogo.com/logos/meta-3.svg",
    target: "logos/meta.svg",
  },
  Icon {
    group: Group::Social,
    url: "https://cdn.worldvectorlogo.com/logos/instagram-2016-5.svg",
    target: "logos/instagram.svg",
  },
  Icon {
    group: Group::Social,
    url: "https://cdn.simpleicons.org/instagram",
    target: "logos/instagram-simple.svg",
  },
  Icon {
    group: Group::Social,
    url: "https://cdn.worldvectorlogo.com/logos/whatsapp-8.svg",
    target: "logos/whatsapp.svg",
  },
  Icon {
    group: Group::Social,
    url: "https://cdn.worldvectorlogo.com/logos/bluesky-1.svg",
    target: "logos/bluesky.svg",
  },
  Icon {
    group: Group::Social,
    url: "https://cdn.worldvectorlogo.com/logos/official-gmail-icon-2020-.svg",
    target: "logos/gmail.svg",
  },
  Icon {
    group: Group::Social,
    url: "https://cdn.simpleicons.org/gmail",
    target: "logos/gmail-simple.svg",
  },
  Icon {
    group: Group::Social,
    url: "https://cdn.simpleicons.org/protonmail",
    target: "logos/protonmail-simple.svg",
  },
  Icon {
    group: Group::Social,
    url: "https://cdn.simpleicons.org/tuta",
    target: "logos/tuta-simple.svg",
  },
  Icon {
    group: Group::Social,
    url: "https://cdn.simpleicons.org/maildotru",
    target: "logos/maildotru-simple.svg",
  },
  Icon {
    group: Group::Social,
    url: "https://cdn.simpleicons.org/mailgun",
    target: "logos/mailgun-simple.svg",
  },
  // UI
  Icon {
    group: Group::Ui,
    url: "https://raw.githubusercontent.com/tailwindlabs/heroicons/master/src/24/outline/home.svg",
    target: "common/home.svg",
  },
  Icon {
    group: Group::Ui,
    url: "https://raw.githubusercontent.com/tailwindlabs/heroicons/master/src/24/outline/bars-3.svg",
    target: "common/menu.svg",
  },
  Icon {
    group: Group::Ui,
    url: "https://raw.githubusercontent.com/tailwindlabs/heroicons/master/src/24/outline/x-mark.svg",
    target: "common/close.svg",
  },
  Icon {
    group: Group::Ui,
    url: "https://raw.githubusercontent.com/tailwindlabs/heroicons/master/src/24/outline/magnifying-glass.svg",
    target: "common/search.svg",
  },
  Icon {
    group: Group::Ui,
    url: "https://raw.githubusercontent.com/tailwindlabs/heroicons/master/src/24/outline/circle-stack.svg",
    target: "common/database.svg",
  },
  Icon {
    group: Group::Ui,
    url: "https://raw.githubusercontent.com/tailwindlabs/heroicons/master/src/24/outline/cpu-chip.svg",
    target: "common/cpu.svg",
  },
  Icon {
    group: Group::Ui,
    url: "https://raw.githubusercontent.com/tailwindlabs/heroicons/master/src/24/outline/cloud.svg",
    target: "common/cloud.svg",
  },
  Icon {
    group: Group::Ui,
    url: "https://raw.githubusercontent.com/tailwindlabs/heroicons/master/src/24/outline/bolt.svg",
    target: "common/bolt.svg",
  },
];

fn section(group: Group) {
  eprintln!();
  eprintln!("=== Downloading {} ===", group.title());
}

fn status(name: &str, state: &str) {
  eprintln!("Fetching {:<30} ... {}", name, state);
}

fn download_icon(client: &Client, root: &Path, icon: Icon, force: bool) -> Result<bool> {
  let target = root.join(icon.target);
  let filename = target
    .file_name()
    .and_then(|name| name.to_str())
    .unwrap_or(icon.target);

  if target.is_file() && !force {
    status(filename, "SKIPPED");
    return Ok(false);
  }

  if let Some(parent) = target.parent() {
    fs::create_dir_all(parent).into_diagnostic()?;
  }

  let response =
    client
      .get(icon.url)
      .send()
      .into_diagnostic()
      .map_err(|_| IconError::DownloadFailed {
        target: icon.target.to_string(),
      })?;

  if !response.status().is_success() {
    let status = response.status();

    let _ = fs::remove_file(&target);

    return Err(
      IconError::InvalidResponse {
        target: icon.target.to_string(),
        status,
      }
      .into(),
    );
  }

  let bytes = response.bytes().into_diagnostic()?;
  fs::write(&target, bytes).into_diagnostic()?;

  status(filename, "OK");
  Ok(true)
}

fn main() -> Result<()> {
  let cli = Cli::parse();

  let client = Client::builder()
    .user_agent("Mozilla/5.0")
    .timeout(Duration::from_secs(30))
    .build()
    .into_diagnostic()?;

  fs::create_dir_all(cli.root.join("logos")).into_diagnostic()?;
  fs::create_dir_all(cli.root.join("common")).into_diagnostic()?;

  let mut current_group: Option<Group> = None;
  let mut failed = false;

  for icon in ICONS {
    if current_group != Some(icon.group) {
      current_group = Some(icon.group);
      section(icon.group);
    }

    if let Err(error) = download_icon(&client, &cli.root, *icon, cli.force) {
      failed = true;
      status(
        Path::new(icon.target)
          .file_name()
          .and_then(|name| name.to_str())
          .unwrap_or(icon.target),
        "FAILED",
      );
      eprintln!("{error:?}");
    }
  }

  eprintln!();
  eprintln!("=== Complete ===");

  if failed {
    std::process::exit(1);
  }

  Ok(())
}
