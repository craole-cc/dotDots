#!/bin/sh
# shellcheck enable=all
# force=1
#╔═══════════════════════════════════════════════════════════╗
#║ Color Output                                              ║
#╚═══════════════════════════════════════════════════════════╝
if [ -t 1 ]; then
	GREEN=$(tput setaf 2)
	RED=$(tput setaf 1)
	CYAN=$(tput setaf 6)
	YELLOW=$(tput setaf 3)
	BOLD=$(tput bold)
	NC=$(tput sgr0)
else
	GREEN=""
	RED=""
	CYAN=""
	YELLOW=""
	BOLD=""
	NC=""
fi

#╔═══════════════════════════════════════════════════════════╗
#║ Directories                                               ║
#╚═══════════════════════════════════════════════════════════╝
icons="${PWD}/public/icons"
common="${icons}/common"
logos="${icons}/logos"
mkdir -p "${logos}" "${common}"

#╔═══════════════════════════════════════════════════════════╗
#║ Function                                                  ║
#╚═══════════════════════════════════════════════════════════╝
download_icon() {
	url="$1"
	output="$2"
	filename=$(basename "${output}")

	printf 'Fetching %-30s ... ' "${filename}"

	#? Some "Real" sources like Wikimedia/GitHub block empty User-Agents
	if [ -f "${output}" ] && [ -z "${force:-}" ]; then
		printf '%sSKIPPED%s\n' "${YELLOW}" "${NC}"
		return
	fi
	if curl -fsSL -A "Mozilla/5.0" "${url}" -o "${output}" 2>/dev/null; then
		printf '%sOK%s\n' "${GREEN}" "${NC}"
	else
		printf '%sFAILED%s\n' "${RED}" "${NC}"
		rm -f "${output}" 2>/dev/null
	fi
}

#╔═══════════════════════════════════════════════════════════╗
#║ Icons: Technology                                         ║
#╚═══════════════════════════════════════════════════════════╝
printf '\n%s%s=== Downloading Technology Icons ===%s\n' \
	"${BOLD}" "${CYAN}" "${NC}"

# -- Languages --
download_icon \
	"https://cdn.worldvectorlogo.com/logos/rust.svg" \
	"${logos}/rust.svg"
download_icon \
	"https://cdn.simpleicons.org/rust" \
	"${logos}/rust-simple.svg"
download_icon \
	"https://cdn.worldvectorlogo.com/logos/python-5.svg" \
	"${logos}/python.svg"
download_icon \
	"https://cdn.simpleicons.org/python" \
	"${logos}/python-simple.svg"
download_icon \
	"https://raw.githubusercontent.com/ziglang/logo/4f97e7a9ebce12fa48511c0b6502b6190005bc0e/zig-mark.svg" \
	"${logos}/zig.svg"
download_icon \
	"https://cdn.simpleicons.org/zig" \
	"${logos}/zig-simple.svg"
download_icon \
	"https://cdn.worldvectorlogo.com/logos/go-8.svg" \
	"${logos}/go.svg"
download_icon \
	"https://cdn.simpleicons.org/go" \
	"${logos}/go-simple.svg"
download_icon \
	"https://cdn.worldvectorlogo.com/logos/bash-2.svg" \
	"${logos}/bash.svg"
download_icon \
	"https://cdn.worldvectorlogo.com/logos/powershell.svg" \
	"${logos}/powershell.svg"

# -- Rust Ecosystem --
download_icon \
	"https://raw.githubusercontent.com/tokio-rs/website/master/public/img/icons/tokio.svg" \
	"${logos}/tokio.svg"
download_icon \
	"https://raw.githubusercontent.com/leptos-rs/leptos/6e83f712d2d64014e000302c9cd265d4a9a61311/logos/Simple_Icon.svg" \
	"${logos}/leptos.png"
download_icon \
	"https://cdn.worldvectorlogo.com/logos/tauri-1.svg" \
	"${logos}/tauri.svg"
download_icon \
	"https://usw2-zeet-misc.s3.us-west-2.amazonaws.com/images/SurrealDB.png" \
	"${logos}/surrealdb.png"
download_icon \
	"https://raw.githubusercontent.com/surrealdb/surrealdb/main/img/logo.svg" \
	"${logos}/surrealdb.svg"

# -- Data --
download_icon \
	"https://upload.wikimedia.org/wikipedia/commons/f/f3/Apache_Spark_logo.svg" \
	"${logos}/apache-spark.svg"
download_icon \
	"https://cdn.worldvectorlogo.com/logos/scala-4.svg" \
	"${logos}/scala.svg"
download_icon \
	"https://cdn.prod.website-files.com/68c803b3497f18f5503b830d/68da505ee9382ac2316b3e67_66192bf45f99cf9cd103c8b3_delta.svg" \
	"${logos}/deltalake.svg"
download_icon \
	"https://cdn.worldvectorlogo.com/logos/kafka.svg" \
	"${logos}/kafka.svg"
download_icon \
	"https://upload.wikimedia.org/wikipedia/commons/2/29/Postgresql_elephant.svg" \
	"${logos}/postgresql.svg"
download_icon \
	"https://cdn.worldvectorlogo.com/logos/mysql-logo-pure.svg" \
	"${logos}/mysql.svg"
download_icon \
	"https://cdn.worldvectorlogo.com/logos/duckdb-logo.svg" \
	"${logos}/duckdb.svg"

# -- Web --
download_icon \
	"https://cdn.worldvectorlogo.com/logos/typescript.svg" \
	"${logos}/typescript.svg"
download_icon \
	"https://cdn.worldvectorlogo.com/logos/javascript-1.svg" \
	"${logos}/javascript.svg"
download_icon \
	"https://cdn.worldvectorlogo.com/logos/html-1.svg" \
	"${logos}/html.svg"
download_icon \
	"https://cdn.worldvectorlogo.com/logos/css-3.svg" \
	"${logos}/css.svg"
download_icon \
	"https://cdn.worldvectorlogo.com/logos/sass-1.svg" \
	"${logos}/sass.svg"
download_icon \
	"https://cdn.worldvectorlogo.com/logos/tailwind-css-2.svg" \
	"${logos}/tailwind.svg"
download_icon \
	"https://cdn.worldvectorlogo.com/logos/svelte-1.svg" \
	"${logos}/svelte.svg"
download_icon \
	"https://raw.githubusercontent.com/vitejs/vite/main/docs/public/logo.svg" \
	"${logos}/vite.svg"
download_icon \
	"https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTuW9lcdXGNSXkg7EsdpXy0wNhPz8YcGXFwRA&s" \
	"${logos}/htmx.png"
download_icon \
	"https://logo.svgcdn.com/logos/htmx-icon.png" \
	"${logos}/htmx.png"

# -- Operating System --
download_icon \
	"https://cdn.worldvectorlogo.com/logos/windows-3.svg" \
	"${logos}/windows.svg"
download_icon \
	"https://cdn.worldvectorlogo.com/logos/raspberry-pi.svg" \
	"${logos}/raspberry-pi.svg"
download_icon \
	"https://raw.githubusercontent.com/NixOS/nixos-artwork/master/logo/nixos-white.svg" \
	"${logos}/nixos.svg"
download_icon \
	"https://cdn.worldvectorlogo.com/logos/linux-tux.svg" \
	"${logos}/linux-tux.svg"
download_icon \
	"https://upload.wikimedia.org/wikipedia/commons/1/13/Arch_Linux_%22Crystal%22_icon.svg" \
	"${logos}/arch.svg"
download_icon \
	"https://cdn.worldvectorlogo.com/logos/arch-linux-logo.svg" \
	"${logos}/archlinux.svg"

# -- DevOps --
download_icon \
	"https://cdn.worldvectorlogo.com/logos/visual-studio-code-1.svg" \
	"${logos}/vscode.svg"
download_icon \
	"https://cdn.worldvectorlogo.com/logos/docker.svg" \
	"${logos}/docker-full.svg"
download_icon \
	"https://raw.githubusercontent.com/kubernetes/kubernetes/master/logo/logo.svg" \
	"${logos}/kubernetes.svg"
download_icon \
	"https://cdn.worldvectorlogo.com/logos/git-icon.svg" \
	"${logos}/git.svg"
download_icon \
	"https://cdn.worldvectorlogo.com/logos/git-bash.svg" \
	"${logos}/gitbash.svg"
download_icon \
	"https://raw.githubusercontent.com/helix-editor/helix/master/logo_dark.svg" \
	"${logos}/helix-editor.svg"
download_icon \
	"https://upload.wikimedia.org/wikipedia/commons/3/3a/Neovim-mark.svg" \
	"${logos}/neovim.svg"
download_icon \
	"https://cdn.worldvectorlogo.com/logos/vim.svg" \
	"${logos}/vim.svg"

download_icon \
	"https://cdn.worldvectorlogo.com/logos/sony-logo-1.svg" \
	"${logos}/sony.svg"
download_icon \
	"https://cdn.worldvectorlogo.com/logos/sony-alpha-logo.svg" \
	"${logos}/sony-alpha.svg"

#╔═══════════════════════════════════════════════════════════╗
#║ Icons: Social                                             ║
#╚═══════════════════════════════════════════════════════════╝
printf '\n%s%s=== Downloading Social Icons ===%s\n' "${BOLD}" "${CYAN}" "${NC}"
download_icon \
	"https://cdn.worldvectorlogo.com/logos/slack-new-logo.svg" \
	"${logos}/slack.svg"
download_icon \
	"https://cdn.worldvectorlogo.com/logos/github-icon.svg" \
	"${logos}/github-refined.svg"
download_icon \
	"https://cdn.simpleicons.org/github" \
	"${logos}/github-simple.svg"
download_icon \
	"https://cdn.worldvectorlogo.com/logos/gitlab-3.svg" \
	"${logos}/gitlab.svg"
download_icon \
	"https://cdn.simpleicons.org/gitlab" \
	"${logos}/gitlab-simple.svg"
download_icon \
	"https://cdn.worldvectorlogo.com/logos/linkedin-icon-2.svg" \
	"${logos}/linkedin.svg"
download_icon \
	"https://cdn.worldvectorlogo.com/logos/x-twitter.svg" \
	"${logos}/x.svg"
download_icon \
	"https://cdn.simpleicons.org/x" \
	"${logos}/x-simple.svg"
download_icon \
	"https://cdn.worldvectorlogo.com/logos/facebook-modern-design-.svg" \
	"${logos}/facebook-trimmed.svg"
download_icon \
	"https://cdn.simpleicons.org/facebook" \
	"${logos}/facebook-simple.svg"
download_icon \
	"https://cdn.worldvectorlogo.com/logos/meta-3.svg" \
	"${logos}/meta.svg"
download_icon \
	"https://cdn.worldvectorlogo.com/logos/instagram-2016-5.svg" \
	"${logos}/instagram.svg"
download_icon \
	"https://cdn.simpleicons.org/instagram" \
	"${logos}/instagram-simple.svg"
download_icon \
	"https://cdn.worldvectorlogo.com/logos/whatsapp-8.svg" \
	"${logos}/whatsapp.svg"
download_icon \
	"https://cdn.worldvectorlogo.com/logos/bluesky-1.svg" \
	"${logos}/bluesky.svg"
download_icon \
	"https://cdn.worldvectorlogo.com/logos/official-gmail-icon-2020-.svg" \
	"${logos}/gmail.svg"
download_icon \
	"https://cdn.simpleicons.org/gmail" \
	"${logos}/gmail-simple.svg"
download_icon \
	"https://cdn.simpleicons.org/protonmail" \
	"${logos}/protonmail-simple.svg"
download_icon \
	"https://cdn.simpleicons.org/tuta" \
	"${logos}/tuta-simple.svg"
download_icon \
	"https://cdn.simpleicons.org/maildotru" \
	"${logos}/maildotru-simple.svg"
download_icon \
	"https://cdn.simpleicons.org/mailgun" \
	"${logos}/mailgun-simple.svg"

#╔═══════════════════════════════════════════════════════════╗
#║ Icons: UI                                                 ║
#╚═══════════════════════════════════════════════════════════╝
printf '\n%s%s=== Downloading UI Icons ===%s\n' "${BOLD}" "${CYAN}" "${NC}"
HERO_SRC="https://raw.githubusercontent.com/tailwindlabs/heroicons/master/src/24/outline"
download_icon "${HERO_SRC}/home.svg" "${common}/home.svg"
download_icon "${HERO_SRC}/bars-3.svg" "${common}/menu.svg"
download_icon "${HERO_SRC}/x-mark.svg" "${common}/close.svg"
download_icon "${HERO_SRC}/magnifying-glass.svg" "${common}/search.svg"
download_icon "${HERO_SRC}/circle-stack.svg" "${common}/database.svg"
download_icon "${HERO_SRC}/cpu-chip.svg" "${common}/cpu.svg"
download_icon "${HERO_SRC}/cloud.svg" "${common}/cloud.svg"
download_icon "${HERO_SRC}/bolt.svg" "${common}/bolt.svg"

printf '\n%s%s=== Complete ===%s\n' "${BOLD}" "${GREEN}" "${NC}"
