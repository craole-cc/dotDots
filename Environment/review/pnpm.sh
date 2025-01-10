#! /bin/sh

#==================================================
#
# PNPM
#
#==================================================

# _________________________________ DOCUMENTATION<|

#| https://pnpm.io/

# _________________________________________ LOCAL<|

#> Install <#
if ! weHave pnpm; then
	if weHave npm; then #? Use NPM
		case $sys_TYPE in
		Linux) sudo npm install --global pnpm ;;
		Windows) npm install --global pnpm ;;
		*) ;;
		esac
	elif weHave curl; then #? Use CURL
		if weHave node; then
			curl -f https://get.pnpm.io/v6.16.js | node - add --global pnpm
		else
			curl -fsSL https://get.pnpm.io/install.sh | sh -
			pnpm env use --global latest
		fi
	elif weHave wget; then #? Use WGET
		wget -qO- https://get.pnpm.io/install.sh | sh -
		pnpm env use --global latest
	fi
fi

#> Verify Instalation <#
weHave pnpm || return
"$NeedForSpeed" || weHave --report version pnpm >>"$DOTS_loaded_apps"

# _______________________________________ EXPORT<|

#> Activate Aliases <#
alias PM='pnpm'
alias PMh='pnpm help'

#> Scripts <#
alias PMd='pnpm dev'    #| Starts the development server.
alias PMb='pnpm build'  #| Package the app for production.
alias PMs='pnpm start'  #| Runs the built app in production mode.
alias PMc='pnpm create' #| Install app from template.
alias PMx='pnpm dlx'    #| Run package without installing as dependency
alias PMrs='pnpm run'   #| Install app from template.
alias PMt='pnpm test'   #| Starts the development server.
alias npx='pnpm dlx'

#> Install Project Packages <#
alias PMi='pnpm install'
alias PMiP='pnpm install --prod'             #| Production Dependencies
alias PMiD='pnpm install --dev'              #| devDependencies.
alias PMiO='pnpm install --no-optional'      #| Ignore optionalDependencies
alias PMiF='pnpm install --fix-lockfile'     #| Fix broken lockfile entries automatically.
alias PMiRs='pnpm install --reporter=silent' #| Silent except for fatal errors
alias PMiL='pnpm up --latest'                #| Upgrade to the lates packages

#> Add Packages <#
alias PMa='pnpm add'
alias PMaP='pnpm add --save-prod'     #| Production Dependencies
alias PMaD='pnpm add --save-dev'      #| devDependencies
alias PMaO='pnpm add --save-optional' #| optionalDependencies
alias PMap='pnpm add --save-peer'     #| peerDependencies
alias PMaE='pnpm add --save-exact'    #| Use exact version given
alias PMaG='pnpm add --global'        #| Global
alias PMar='pnpm add --ignore-workspace-root-check'
alias PMarP='PMar --save-prod'     #| Production Dependencies
alias PMarD='PMar --save-dev'      #| devDependencies
alias PMarO='PMar --save-optional' #| optionalDependencies
alias PMarp='PMar --save-peer'     #| peerDependencies
alias PMarE='PMar --save-exact'    #| Use exact version given

#> Update Packages <#
alias PMu='pnpm up'                 #| Adhere to package.json ranges
alias PMuL='pnpm up --latest'       #| Ignore package.json ranges
alias PMuP='pnpm up --prod'         #| dependencies & optionalDependencies
alias PMuD='pnpm up --dev'          #| devDependencies
alias PMuNO='pnpm up --no-optional' #| Ignore optionalDependencies
alias PMuI='pnpm up --interactive'  #| Select dependencies
alias PMur='pnpm up --recursive'    #| Recursivly
alias PMuG='pnpm up --global'       #| Global packages
alias PMuS='pnpm add -g pnpm'       #| Self [PNPM]

#> Remove Packages <#
alias PMr='pnpm remove'
alias PMrR='pnpm remove --recursive'     #| Recursive
alias PMrG='pnpm remove --global'        #| Global
alias PMrP='pnpm remove --save-prod'     #| Production Dependencies
alias PMrD='pnpm remove --save-dev'      #| devDependencies.
alias PMrO='pnpm remove --save-optional' #| optionalDependencies

#> Prune Packages <#
alias PMpP='pnpm prune --prod'         #| Remove devDependencies.
alias PMpNO='pnpm prune --no-optional' #| Remove optionalDependencies

#> List Packages <#
#| This command will output all the versions of packages that are installed, as well as their dependencies, in a tree-structure.
alias PMl='pnpm list'                 #| List
alias PMlP='pnpm list --prod'         #| dependencies & optionalDependencies
alias PMlD='pnpm list --dev'          #| devDependencies
alias PMlNO='pnpm list --no-optional' #| Ignore optionalDependencies
alias PMlr='pnpm list --recursive'    #| Recursivly
alias PMlG='pnpm list --global'       #| Globally installed.
alias PMlJ='pnpm list --json'         #| Log output in JSON format.
alias PMlL='pnpm list --long'         #| Show extended information.
alias PMlL='pnpm list --parseable'    #| Outputs package directories in a parseable format.

#> Set Environment <#
alias PMenvL='pnpm env use nightly'           #| Node.js Latest
alias PMenvN='pnpm env use nightly'           #| Node.js Nightly
alias PMenvLG='pnpm env use --global latest'  #| Node.js Latest, globally
alias PMenvNG='pnpm env use --global nightly' #| Node.js Nightly, globally

#> Utils <#
Rr() { #| Install and Upgrade to the latest packages
	#? Move to root directory
	cd "$(git rev-parse --show-toplevel)" || return

	#? Remove all node_modules
	find . -name node_modules -prune -exec rm -rf {} \;
	find . -name .turbo -prune -exec rm -rf {} \;
	rm --recursive --force pnpm-lock.yaml

	#? Reintall packages based on package.json
	pnpm install

	#? Update out-dated packages
	pnpm up --latest

	#? Return to previous directory
	cd "$OLDPWD" || return
}

Rb() { #| Run Build
	#? Move to root directory
	cd "$(git rev-parse --show-toplevel)" || return

	# Build
	pnpm build
	pnpm prepare

	#? Return to previous directory
	cd "$OLDPWD" || return
}

Rl() { #| Run Lint
	#? Move to root directory
	cd "$(git rev-parse --show-toplevel)" || return

	# Lint
	pnpm lint

	#? Return to previous directory
	cd "$OLDPWD" || return
}

Rlb() { #| Lint and build
	#? Move to root directory
	cd "$(git rev-parse --show-toplevel)" || return

	clear
	pnpm prepare
	pnpm lint
	pnpm build

	#? Return to previous directory
	cd "$OLDPWD" || return
}

alias Rd='pnpm dev'     #| Run Dev
alias Rp='pnpm prepare' #| Run Prepare
alias rrd='Rr && Rd'    #| Reinstall packages and run dev
alias rrl='Rr && Rl'    #| Reinstall packages and lint
alias rrb='Rr && Rb'    #| Reinstall packages and build
alias riu='pnpm install && pnpm up --latest'

PMtailwind() {
	#? Move to config directory
	cd "$(git rev-parse --show-toplevel)/packages/tailwind" || return

	#? Add Tailwindand plugins
	pnpm add --save-dev \
		tailwindcss@latest \
		@tailwindcss/typography@latest \
		@tailwindcss/forms@latest \
		@tailwindcss/aspect-ratio@latest \
		@tailwindcss/line-clamp@latest \
		postcss@latest \
		autoprefixer@latest

	#? Initialize Tailwindand
	pnpm dlx tailwindcss init -p
}

PMnext() { #| Inside a monorepo
	#? Move to apps directory
	cd "$(git rev-parse --show-toplevel)/apps" || return

	#? Instal Next.js with Typescript
	# pnpm dlx create-next-app@latest --typescript "$@"
	pnpm dlx create-next-app@latest --typescript --example with-tailwindcss "$@"

}
