#! /bin/sh

#==================================================
#
# Paru
#
#==================================================

# _________________________________ DOCUMENTATION<|

#TODO: https://github.com/Morganamilo/paru

# _________________________________________ LOCAL<|

#> Install <#
if ! weHave yarn; then
	if weHave npm; then
		case $sys_TYPE in
		Linux) sudo npm install -g yarn ;;
		Windows) npm install -g yarn ;;
		*) ;;
		esac
	fi
fi

#> Verify Instalation <#
weHave yarn || return
"$NeedForSpeed" || weHave --report version yarn >>"$DOTS_loaded_apps"

# _______________________________________ EXPORT<|

#> Activate Aliases <#
alias Y='yarn'
alias Yh='yarn help'
alias Yi='yarn init -2'
alias Yd='yarn dev'   #TODO: Starts the development server.
alias Yb='yarn build' #TODO: Package the app for production.
alias Ys='yarn start' #TODO: Runs the built app in production mode.
alias Ya='yarn add '
alias YaD='yarn add --dev '
alias YaP='yarn add --peer '
alias Yu='yarn update '
alias Yr='yarn remove '
alias YuL='yarn set version latest'
alias Yvs='yarn dlx @yarnpkg/sdks vscode'

yNext() {

	#> Add to JavaScript Projects <#
	mcd "$prJS/$*"

	#> Create NextJS App with Typescript <#
	yarn create next-app --typescript .

	#> Initialize Yarn <#
	yarn init -2

	#> Add Modules <#
	yarn add next
	yarn add react
	yarn add react-dom
	yarn add --dev @types/node
	yarn add --dev @types/react
	yarn add --dev eslint
	yarn add --dev eslint-config-next
	yarn add --dev typescript
	yarn dlx @yarnpkg/sdks vscode
	yarn plugin import typescript

	#> Enable Debug Scripts <#
	ex package.json <<EOF
4 insert
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "lint": "next lint"
  },
.
xit
EOF

	#> Load Templates <#

	rm \
		--recursive --force \
		components/ \
		pages/ \
		styles/ \
		test/

	templates="$prJS/templates/NEXTts"
	cp \
		--archive \
		"$templates/." \
		.

	#> Develop in VSCode <#
	code .
	yarn dev

}
