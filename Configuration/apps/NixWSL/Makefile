#
#  NOTE: Makefile's target name should not be the same as one of the file or directory in the current directory,
#    otherwise the target will not be executed!
#


############################################################################
#
#  Nix commands related to the local machine
#
############################################################################

wsl-init:
	sh init

wsl-reset:
	sh init --reset

git:
	git add .
	git commit -m "Updating the NixOS Flake"

check:
	git add .
	git commit -m "Checking the NixOS Flake"
	nix flake check

check-impure:
	git add .
	git commit -m "Force-checking the NixOS Flake."
	nix flake check --impure

deploy:
	git add .
	git commit -m "Deploying the NixOS Flake"
	nixos-rebuild switch --flake . --use-remote-sudo

rebuild:
	git add .
	git commit -m "Rebuilding the NixOS Flake"
	nixos-rebuild switch --use-remote-sudo

debug:
	git add .
	git commit -m "Debugging the NixOS Flake"
	nixos-rebuild switch --flake . --use-remote-sudo --show-trace --verbose

update:
	git add .
	git commit -m "Updating the NixOS Flake"
	nix flake update

history:
	nix profile history --profile /nix/var/nix/profiles/system

gc:
	# remove all generations older than 7 days
	sudo nix profile wipe-history --profile /nix/var/nix/profiles/system  --older-than 7d

	# garbage collect all unused nix store entries
	sudo nix store gc --debug

############################################################################
#
#  Idols, Commands related to my remote distributed building cluster
#
############################################################################

add-idols-ssh-key:
	ssh-add ~/.ssh/ai-idols

aqua: add-idols-ssh-key
	nixos-rebuild --flake .#aquamarine --target-host aquamarine --build-host aquamarine switch --use-remote-sudo

aqua-debug: add-idols-ssh-key
	nixos-rebuild --flake .#aquamarine --target-host aquamarine --build-host aquamarine switch --use-remote-sudo --show-trace --verbose

ruby: add-idols-ssh-key
	nixos-rebuild --flake .#ruby --target-host ruby --build-host ruby switch --use-remote-sudo

ruby-debug: add-idols-ssh-key
	nixos-rebuild --flake .#ruby --target-host ruby --build-host ruby switch --use-remote-sudo --show-trace --verbose

kana: add-idols-ssh-key
	nixos-rebuild --flake .#kana --target-host kana --build-host kana switch --use-remote-sudo

kana-debug: add-idols-ssh-key
	nixos-rebuild --flake .#kana --target-host kana --build-host kana switch --use-remote-sudo --show-trace --verbose

idols: aqua ruby kana

idols-debug: aqua-debug ruby-debug kana-debug