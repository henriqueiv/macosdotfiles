# ---------
# Functions
# ---------
function gi() { curl -L -s https://www.gitignore.io/api/$@ ;}

# $1 (first param) should be the name of a .m4a input file, with .m4a extension
# $2 should be name of output file, with extension
function normalizeAudio {
	INPUTFILE=$1
	OUTPUTFILE=$2

	DBLEVEL=`ffmpeg -i "${INPUTFILE}" -vn -af "volumedetect" -f null /dev/null 2>&1 | grep max_volume | awk -F': ' '{print $2}' | cut -d' ' -f1`

	# We're only going to increase db level if max volume has negative db level.
	# Bash doesn't do floating comparison directly
	COMPRESULT=`echo ${DBLEVEL}'<'0 | bc -l`
	if [ ${COMPRESULT} -eq 1 ]; then
		DBLEVEL=`echo "-(${DBLEVEL})" | bc -l`
		BITRATE=`ffmpeg -i "${INPUTFILE}" 2>&1 | grep Audio | awk -F', ' '{print $5}' | cut -d' ' -f1`

		echo "Normalizing audio applying" $DBLEVEL"db gain"

		# echo $DBLEVEL
		# echo $BITRATE

		ffmpeg -i "${INPUTFILE}" -af "volume=${DBLEVEL}dB" -c:v copy -c:a aac -strict experimental -b:a ${BITRATE}k ${OUTPUTFILE} -loglevel quiet

	else
		echo "Already at max db level:" $DBLEVEL "just copying exact file"
		cp ${INPUTFILE} ${OUTPUTFILE}
	fi
}

function wav2mp3() {
	if exists ffmpeg ; then
		ffmpeg -i "$1" -vn -ar 44100 -ac 2 -ab 192k -f mp3 "$2"
	fi
}

function testezao() {
	if $(exists foo) == 1 ; then
		ffmpeg -i "$1" -vn -ar 44100 -ac 2 -ab 192k -f mp3 "$2";
	fi
}

function ytmp3() {
	if [ -n "$2" ]; then
		youtube-dl --extract-audio --audio-format mp3 --audio-quality $1 $2;
	else
		youtube-dl --extract-audio --audio-format mp3 --audio-quality 0 $1;
	fi
}

function ytbest() {
	youtube-dl -f best $1
}

function openurls() {
	open $(grep "http" "$1")
	grep "http" "$1" | echo $(wc -l) " url opened in your default browser"
}

# function github-create() {
# 	repo_name=$1

# 	dir_name=`basename $(pwd)`

# 	if [ "$repo_name" = "" ]; then
# 	echo "Repo name (hit enter to use '$dir_name')?"
# 	read repo_name
# 	fi

# 	if [ "$repo_name" = "" ]; then
# 	repo_name=$dir_name
# 	fi

# 	username=`git config github.user`
# 	if [ "$username" = "" ]; then
# 	echo "Could not find username, run 'git config --global github.user <username>'"
# 	invalid_credentials=1
# 	fi

# 	token=`git config github.token`
# 	if [ "$token" = "" ]; then
# 	echo "Could not find token, run 'git config --global github.token <token>'"
# 	invalid_credentials=1
# 	fi

# 	if [ "$invalid_credentials" == "1" ]; then
# 	return 1
# 	fi

# 	echo -n "Creating Github repository '$repo_name' ..."
# 	curl -u "$username:$token" https://api.github.com/user/repos -d '{"name":"'$repo_name'"}' > /dev/null 2>&1
# 	echo " done."

# 	echo -n "Pushing local code to remote ..."
# 	git remote add origin git@github.com:$username/$repo_name.git > /dev/null 2>&1
# 	git push -u origin master > /dev/null 2>&1
# 	echo " done."
# }

# ---------
# Paths
# ---------
export PATH="$HOME/.fastlane/bin:$PATH"
export PATH="/Applications/XAMPP/xamppfiles/bin:$PATH"

# ---------
# Aliases
# ---------
alias clr="clear" # Clear your terminal screen
# alias flush="sudo discoveryutil udnsflushcaches" # Flush DNS (Yosemite)
alias flush="sudo killall -HUP mDNSResponder" # Flush DNS (Mavericks, Mountain Lion, Lion)
# alias flush="dscacheutil -flushcache" # Flush DNS (Snow Leopard, Leopard)
alias ip="curl icanhazip.com" # Your public IP address
alias ll="ls -al" # List all files in current directory in long list format
alias ldir="ls -al | grep ^d" # List all directories in current directory in long list format
alias o="open ." # Open the current directory in Finder
alias ut="uptime" # Computer uptime
alias clrss="find ~/Desktop -name \"Screen Shot *.png\" |
  grep -E 'Screen Shot \d{4}-\d{2}-\d{2} at \d{1,2}\.\d{2}\.\d{2}( (AM|PM))?(( (\d)?\(\d+\))| \d)?\.png' |
  tr '\n' '\0' |
  xargs -0 rm -f"
alias oyt="open ~/Downloads/Youtube/"
alias clrdd="rm -rf ~/Library/Developer/Xcode/DerivedData/"
alias mkexec="chmod a+x "

# ------------
# Git Shortcuts
# ------------
alias gd='git diff'
alias gs='git status'
alias gst='git status -sb'
alias ga='git add'
alias gau='git add -u' # Removes deleted files
alias gpl='git pull'
alias gps='git push'
alias gc='git commit -v'
alias gcm='git commit -v -m' # With message
alias gca='git commit -v -a' # Does both add and commit in same command, add -m 'blah' for comment
alias gco='git checkout'
alias gl='git log --oneline'

# -----------
# .bash_prompt
# -----------
#!/usr/bin/env bash

# Shell prompt based on the Solarized Dark theme.
# Screenshot: http://i.imgur.com/EkEtphC.png
# Heavily inspired by @necolas’s prompt: https://github.com/necolas/dotfiles
# iTerm → Profiles → Text → use 13pt Monaco with 1.1 vertical spacing.

if [[ $COLORTERM = gnome-* && $TERM = xterm ]] && infocmp gnome-256color >/dev/null 2>&1; then
	export TERM='gnome-256color';
elif infocmp xterm-256color >/dev/null 2>&1; then
	export TERM='xterm-256color';
fi;

prompt_git() {
	local s='';
	local branchName='';

	# Check if the current directory is in a Git repository.
	if [ $(git rev-parse --is-inside-work-tree &>/dev/null; echo "${?}") == '0' ]; then

		# check if the current directory is in .git before running git checks
		if [ "$(git rev-parse --is-inside-git-dir 2> /dev/null)" == 'false' ]; then

			# Ensure the index is up to date.
			git update-index --really-refresh -q &>/dev/null;

			# Check for uncommitted changes in the index.
			if ! $(git diff --quiet --ignore-submodules --cached); then
				s+='+';
			fi;

			# Check for unstaged changes.
			if ! $(git diff-files --quiet --ignore-submodules --); then
				s+='!';
			fi;

			# Check for untracked files.
			if [ -n "$(git ls-files --others --exclude-standard)" ]; then
				s+='?';
			fi;

			# Check for stashed files.
			if $(git rev-parse --verify refs/stash &>/dev/null); then
				s+='$';
			fi;

		fi;

		# Get the short symbolic ref.
		# If HEAD isn’t a symbolic ref, get the short SHA for the latest commit
		# Otherwise, just give up.
		branchName="$(git symbolic-ref --quiet --short HEAD 2> /dev/null || \
			git rev-parse --short HEAD 2> /dev/null || \
			echo '(unknown)')";

		[ -n "${s}" ] && s=" [${s}]";

		echo -e "${1}${branchName}${2}${s}";
	else
		return;
	fi;
}

if tput setaf 1 &> /dev/null; then
	tput sgr0; # reset colors
	bold=$(tput bold);
	reset=$(tput sgr0);
	# Solarized colors, taken from http://git.io/solarized-colors.
	black=$(tput setaf 0);
	blue=$(tput setaf 33);
	cyan=$(tput setaf 37);
	green=$(tput setaf 64);
	orange=$(tput setaf 166);
	purple=$(tput setaf 125);
	red=$(tput setaf 124);
	violet=$(tput setaf 61);
	white=$(tput setaf 15);
	yellow=$(tput setaf 136);
else
	bold='';
	reset="\e[0m";
	black="\e[1;30m";
	blue="\e[1;34m";
	cyan="\e[1;36m";
	green="\e[1;32m";
	orange="\e[1;33m";
	purple="\e[1;35m";
	red="\e[1;31m";
	violet="\e[1;35m";
	white="\e[1;37m";
	yellow="\e[1;33m";
fi;

# Highlight the user name when logged in as root.
if [[ "${USER}" == "root" ]]; then
	userStyle="${red}";
else
	userStyle="${cyan}";
fi;

# Highlight the hostname when connected via SSH.
if [[ "${SSH_TTY}" ]]; then
	hostStyle="${bold}${red}";
else
	hostStyle="${violet}";
fi;

# Set the terminal title and prompt.
PS1="\[\033]0;\W\007\]"; # working directory base name
PS1+="\[${bold}\]\n"; # newline
PS1+="\[${userStyle}\]\u"; # username
PS1+="\[${white}\] at ";
PS1+="\[${hostStyle}\]\h"; # host
PS1+="\[${white}\] in ";
PS1+="\[${green}\]\w"; # working directory full path
PS1+="\$(prompt_git \"\[${white}\] on \[${violet}\]\" \"\[${blue}\]\")"; # Git repository details
PS1+="\n";
PS1+="\[${white}\]\$ \[${reset}\]"; # `$` (and reset color)
export PS1;

PS2="\[${yellow}\]→ \[${reset}\]";
export PS2;
