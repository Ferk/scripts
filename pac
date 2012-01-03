#!/bin/sh

# Fernando Carmona Varo <ferkiwi@gmail.com>
# Based on packer by Matthew Bruenig <matthewbruenig@gmail.com>

# Changes:
# - POSIX compatibility (dash is faster than bash)

# TODO:
# - Allow for multiple instances to run and download stuff
# - Remove unneded features

# Licensed under GPL version 3

# set tmpfile stuff, clean tmpdir
tmpdir="${TMPDIR:-/tmp}/packertmp-$UID"

makepkgconf='/etc/makepkg.conf'
usermakepkgconf="$HOME/.makepkg.conf"
pacmanconf='/etc/pacman.conf'

RPCURL="https://aur.archlinux.org/rpc.php?type"
PKGURL="https://aur.archlinux.org/packages"

if [[ -t 1 && ! $COLOR = "NO" ]]; then
  COLOR1='\e[1;39m'
  COLOR2='\e[1;32m'
  COLOR3='\e[1;35m'
  COLOR4='\e[1;36m'
  COLOR5='\e[1;34m'
  COLOR6='\e[1;33m'
  COLOR7='\e[1;31m'
  ENDCOLOR='\e[0m' 
  S='\\'
fi
_WIDTH="$(stty size | cut -d ' ' -f 2)"

trap ctrlc INT
ctrlc() {
  echo
  exit
}

err() {
  echo -e "$1"
  exit 1
}

usage() {
  echo 'usage: packer [option] [package] [package] [...]'
  echo
  echo '    -S          - installs package'
  echo '    -Syu|-Su    - updates all packages, also takes -uu and -yy options'
  echo '    -Ss|-Ssq    - searches for package'
  echo '    -Si         - outputs info for package'
  echo '    -G          - download and extract aur tarball only'
  echo
  echo '    --quiet     - only output package name for searches'
  echo '    --ignore    - takes a comma-separated list of packages to ignore'
  echo '    --noconfirm - do not prompt for any confirmation'
  echo '    --noedit    - do not prompt to edit files'
  echo '    --auronly   - only do actions for aur'
  echo '    --devel     - update devel packages during -Su'
  echo '    --skipinteg - when using makepkg, do not check md5s'
  echo '    -h          - outputs this message'
  exit
}

# Called whenever anything needs to be run as root ($@ is the command)
runasroot() {
  if [[ $UID -eq 0 ]]; then
    "$@"
  elif sudo -v &>/dev/null && sudo -l "$@" &>/dev/null; then
    sudo "$@"
  else
    echo -n "root "
    su -c "$(printf '%q ' "$@")"
  fi
}

# Source makepkg.conf file
sourcemakepkgconf() {
  . "$makepkgconf"
  [[ -r "$usermakepkgconf" ]] && . "$usermakepkgconf"
}

# Parse IgnorePkg and --ignore, put in globally accessible ignoredpackages array
getignoredpackages() {
  IFS=','
  ignoredpackages=($ignorearg)
  IFS=$'\n'" "
  ignoredpackages+=( $(grep '^ *IgnorePkg' "$pacmanconf" | cut -d '=' -f 2-) )
}

# Checks to see if $1 is an ignored package
isignored() {
  [[ " ${ignoredpackages[@]} " =~ " $1 " ]]
}

# Tests whether $1 exists on the aur
existsinaur() {
  rpcinfo "$1"
  [[ "$(jshon -Qe type -u < "$tmpdir/$1.info")" = "info" ]]
}

# Tests whether $1 exists in pacman
existsinpacman() {
  pacman -Si -- "$1" &>/dev/null
}

# Tests whether $1 is provided in pacman, sets globally accessibly providepkg var
providedinpacman() {
  IFS=$'\n'
  providepkg=( $(pacman -Ssq -- "^$1$") )
}

# Tests whether $1 exists in a pacman group
existsinpacmangroup() {
  [[ $(pacman -Sgq "$1") ]]
}

# Tests whether $1 exists locally
existsinlocal() {
  pacman -Qq -- "$1" &>/dev/null
}

# Scrapes the aur deps from PKGBUILDS and puts in globally available dependencies array
scrapeaurdeps() {
  pkginfo "$1"
  . "$tmpdir/$1.PKGBUILD"
  IFS=$'\n'
  dependencies=( $(echo -e "${depends[*]}\n${makedepends[*]}" | sed -e 's/=.*//' -e 's/>.*//' -e 's/<.*//'| sort -u) )
}

# Finds dependencies of package $1
# Sets pacmandeps and aurdeps array, which can be accessed globally after function runs
finddeps() {
  # loop through dependencies, if not installed, determine if pacman or aur deps
  pacmandeps=()
  aurdeps=()
  scrapeaurdeps "$1"
  missingdeps=( $(pacman -T "${dependencies[@]}") )
  while [[ $missingdeps ]]; do
    checkdeps=()
    for dep in "${missingdeps[@]}"; do
      if [[ " $1 ${aurdeps[@]} ${pacmandeps[@]} " =~ " $dep " ]];  then
        continue
      fi
      if existsinpacman "$dep"; then
        pacmandeps+=("$dep")
      elif existsinaur "$dep"; then
        if [[ $aurdeps ]]; then
          aurdeps=("$dep" "${aurdeps[@]}")
        else
          aurdeps=("$dep")
        fi
        checkdeps+=("$dep")
      elif providedinpacman "$dep"; then
        pacmandeps+=("$providepkg")
      else
        [[ $option = "install" ]] &&  err "Dependency \`$dep' of \`$1' does not exist."
        echo "Dependency \`$dep' of \`$1' does not exist."
        return 1
      fi
    done
    missingdeps=()
    for dep in "${checkdeps[@]}"; do
      scrapeaurdeps "$dep"
      for depdep in "${dependencies[@]}"; do
        [[ $(pacman -T "$depdep") ]] && missingdeps+=("$depdep")
      done
    done
  done
  return 0
}

# Displays a progress bar ($1 is numerator, $2 is denominator, $3 is candy/normal)
aurbar() {
  # Delete line
  printf "\033[0G"
  
  # Get vars for output
  beginline=" aur"
  beginbar="["
  endbar="] "
  perc="$(($1*100/$2))"
  width="$(stty size)"
  width="${width##* }"
  charsbefore="$((${#beginline}+${#1}+${#2}+${#beginbar}+3))"
  spaces="$((51-$charsbefore))"
  barchars="$(($width-51-7))"
  hashes="$(($barchars*$perc/100))" 
  dashes="$(($barchars-$hashes))"

  # Print output
  printf "$beginline %${spaces}s$1  $2 ${beginbar}" ""

  # ILoveCandy
  if [[ $3 = candy ]]; then
    for ((n=1; n<$hashes; n++)); do
      if (( (n==($hashes-1)) && ($dashes!=0) )); then
        (($n%2==0)) && printf "\e[1;33mc\e[0m" || printf "\e[1;33mC\e[0m"
      else
        printf "-"
      fi
    done
    for ((n=1; n<$dashes; n++)); do
      N=$(( $n+$hashes ))
      (($hashes>0)) && N=$(($N-1))
      (($N%3==0)) && printf "o" || printf " "
    done
  else
    for ((n=0; n<$hashes; n++)); do
      printf "#"
    done
    for ((n=0; n<$dashes; n++)); do
      printf "-"
    done
  fi
  printf "%s%3s%%\r" ${endbar} ${perc}
}

rpcinfo() {
  if ! [[ -f "$tmpdir/$1.info" ]]; then
    curl -LfGs --data-urlencode "arg=$1" "$RPCURL=info" > "$tmpdir/$1.info"
  fi
}

pkginfo() {
  if ! [[ -f "$tmpdir/$1.PKGBUILD" ]]; then
    curl -Lfs "$PKGURL/$1/PKGBUILD" > "$tmpdir/$1.PKGBUILD"
  fi
}

# Checks if package is newer on aur ($1 is package name, $2 is local version)
aurversionisnewer() {
  rpcinfo "$1"
  unset aurversion
  if existsinaur "$1"; then
    aurversion="$(jshon -Q -e results -e Version -u < "$tmpdir/$1.info")"
    if [[ "$(LC_ALL=C vercmp "$aurversion" "$2")" -gt 0  ]]; then
      return 0
    fi
  fi
  return 1
}

isoutofdate() {
  rpcinfo "$1"
  [[ "$(jshon -Q -e results -e OutOfDate -u < "$tmpdir/$1.info")" = "1" ]]
}

# $1 is prompt, $2 is file
confirm_edit() {
  if [[ (! -f "$2") || "$noconfirm" || "$noedit" ]]; then
    return
  fi
  echo -en "$1"
  if proceed; then
    ${EDITOR:-vi} "$2"
  fi
}

# Installs packages from aur ($1 is package, $2 is dependency or explicit)
aurinstall() {
  dir="${TMPDIR:-/tmp}/packerbuild-$UID/$1"

  # Prepare the installation directory
  # If there is an old directory and aurversion is not newer, use old directory
  if . "$dir/$1/PKGBUILD" &>/dev/null && ! aurversionisnewer "$1" "$pkgver-$pkgrel"; then
    cd "$dir/$1"
  else
    [[ -d $dir ]] && rm -rf $dir
    mkdir -p "$dir"
    cd "$dir"
    curl -Lfs "$PKGURL/$1/$1.tar.gz" > "$1.tar.gz"
    tar xf "$1.tar.gz"
    cd "$1"

    # customizepkg
    if [[ -f "/etc/customizepkg.d/$1" ]] && type -t customizepkg &>/dev/null; then
      echo "Applying customizepkg instructions..."
      customizepkg --modify
    fi
  fi

  # Allow user to edit PKGBUILD
  confirm_edit "${COLOR6}Edit $1 PKGBUILD with \$EDITOR? [Y/n]${ENDCOLOR} " PKGBUILD
  if ! [[ -f PKGBUILD ]]; then
    err "No PKGBUILD found in directory."
  fi

  # Allow user to edit .install
  unset install
  . PKGBUILD
  confirm_edit "${COLOR6}Edit $install with \$EDITOR? [Y/n]${ENDCOLOR} " "$install"

  # Installation (makepkg and pacman)
  if [[ $UID -eq 0 ]]; then
    makepkg $MAKEPKGOPTS --asroot -f
  else
    makepkg $MAKEPKGOPTS -f
  fi

  [[ $? -ne 0 ]] && echo "The build failed." && return 1
  if  [[ $2 = dependency ]]; then
    runasroot pacman ${PACOPTS[@]} --asdeps -U $pkgname-*$PKGEXT
  elif [[ $2 = explicit ]]; then
    runasroot pacman ${PACOPTS[@]} -U $pkgname-*$PKGEXT
  fi

  # Clean tmpdir
  rm -rf "$dir" &>/dev/null
  mkdir -p "$dir"
}

# Goes through all of the install tests and execution ($@ is packages to be installed)
installhandling() {
  packageargs=("$@")
  getignoredpackages
  sourcemakepkgconf
  # Figure out all of the packages that need to be installed
  for package in "${packageargs[@]}"; do
    # Determine whether package is in pacman repos
    if ! [[ $auronly ]] && existsinpacman "$package"; then
      pacmanpackages+=("$package")
    elif ! [[ $auronly ]] && existsinpacmangroup "$package"; then
      pacmanpackages+=("$package")
    elif existsinaur "$package"; then
      if finddeps "$package"; then
        # here is where dep dupes are created
        aurpackages+=("$package")
        aurdepends=("${aurdeps[@]}" "${aurdepends[@]}")
        pacmandepends+=("${pacmandeps[@]}")
      fi
    else
      err "Package \`$package' does not exist."
    fi
  done

  # Check if any aur target packages are ignored
  for package in "${aurpackages[@]}"; do
    if isignored "$package"; then
      echo -ne "${COLOR5}:: ${COLOR1}$package is in IgnorePkg/IgnoreGroup. Install anyway?${ENDCOLOR} [Y/n] "
      if [[ -z "$noconfirm" && $(! proceed) ]]; then
        continue
      fi
    fi
    aurtargets+=("$package")
  done

  # Check if any aur dependencies are ignored
  for package in "${aurdepends[@]}"; do
    if isignored "$package"; then
      echo -ne "${COLOR5}:: ${COLOR1}$package is in IgnorePkg/IgnoreGroup. Install anyway?${ENDCOLOR} [Y/n] "
      if [[ -z "$noconfirm" && $(! proceed) ]]; then
          echo "Unresolved dependency \`$package'"
          unset aurtargets
          break
      fi
    fi
  done
 
  # First install the explicit pacman packages, let pacman prompt
  if [[ $pacmanpackages ]]; then
    runasroot pacman "${PACOPTS[@]}" -S -- "${pacmanpackages[@]}"
  fi
  if [[ -z $aurtargets ]]; then
    exit
  fi
  # Test if aurpackages are already installed; echo warning if so
  for pkg in "${aurtargets[@]}"; do
    if existsinlocal "$pkg"; then
      localversion="$(pacman -Qs "$pkg" | grep -F "local/$pkg" | cut -d ' ' -f 2)"
      if ! aurversionisnewer "$pkg" "$localversion"; then
        echo -e "${COLOR6}warning:$ENDCOLOR $pkg-$localversion is up to date -- reinstalling"
      fi
    fi
  done

  # Echo warning if packages are out of date
  for pkg in "${aurtargets[@]}" "${aurdepends[@]}"; do
    if isoutofdate "$pkg"; then
      echo -e "${COLOR6}warning:$ENDCOLOR $pkg is flagged out of date"
    fi
  done
    
  # Prompt for aur packages and their dependencies
  echo
  if [[ $aurdepends ]]; then
    num="$((${#aurdepends[@]}+${#aurtargets[@]}))"
    echo -e "${COLOR6}Aur Targets    ($num):${ENDCOLOR} ${aurdepends[@]} ${aurtargets[@]}"
  else 
    echo -e "${COLOR6}Aur Targets    ($((${#aurtargets[@]}))):${ENDCOLOR} ${aurtargets[@]}"
  fi
  if [[ $pacmandepends ]]; then
    IFS=$'\n'
    pacmandepends=( $(printf "%s\n" "${pacmandepends[@]}" | sort -u) )
    echo -e "${COLOR6}Pacman Targets (${#pacmandepends[@]}):${ENDCOLOR} ${pacmandepends[@]}"
  fi

  # Prompt to proceed
  echo -en "\nProceed with installation? [Y/n] "
  if ! [[ $noconfirm ]]; then
    proceed || exit
  else
    echo
  fi

  # Install pacman dependencies
  if [[ $pacmandepends ]]; then
    runasroot pacman --noconfirm --asdeps -S -- "${pacmandepends[@]}" || err "Installation failed."
  fi 

  # Install aur dependencies
  if [[ $aurdepends ]]; then
    for dep in "${aurdepends[@]}"; do
      aurinstall "$dep" "dependency"
    done
  fi 

  # Install the aur packages
  for package in "${aurtargets[@]}"; do
    scrapeaurdeps "$package"
    if pacman -T "${dependencies[@]}" &>/dev/null; then
      aurinstall "$package" "explicit"
    else
      echo "Dependencies for \`$package' are not met, not building..."
    fi
  done
}

# proceed with installation prompt
proceed() {
  read -n 1
  echo
  case "$REPLY" in
    'Y'|'y'|'') return 0 ;;
    *)          return 1 ;;
  esac
}

# process busy loop
nap() {
  while (( $(jobs | wc -l) >= 8 )); do
    jobs > /dev/null
  done
}

# Argument parsing
[[ $1 ]] || usage
packageargs=()
while [[ $1 ]]; do
  case "$1" in
    '-S') option=install ;;
    '-Ss') option=search ;;
    '-Ssq'|'-Sqs') option=search ; quiet='1' ;;
    '-Si') option=info ;;
    -S*u*) option=update ; pacmanarg="$1" ;;
    '-G') option=download ;;
    '-h'|'--help') usage ;;
    '--quiet') quiet='1' ;;
    '--ignore') ignorearg="$2" ; PACOPTS+=("--ignore" "$2") ; shift ;;
    '--noconfirm') noconfirm='1' PACOPTS+=("--noconfirm");;
    '--noedit') noedit='1' ;;
    '--auronly') auronly='1' ;;
    '--devel') devel='1' ;;
    '--skipinteg') MAKEPKGOPTS="--skipinteg" ;;
    '--') shift ; packageargs+=("$@") ; break ;;
    -*) echo "packer: Option \`$1' is not valid." ; exit 5 ;;
    *) packageargs+=("$1") ;;
  esac
  shift
done

# Sanity checks
[[ $option ]] || option="searchinstall"
[[ $option != "update" && -z $packageargs ]] && err "Must specify a package."

# Install (-S) handling
if [[ $option = install ]]; then
  installhandling "${packageargs[@]}"
  exit
fi

# Update (-Su) handling
if [[ $option = update ]]; then
  getignoredpackages
  sourcemakepkgconf
  # Pacman update
  if ! [[ $auronly ]]; then
    runasroot pacman "${PACOPTS[@]}" "$pacmanarg"
  fi

  # Aur update
  echo -e "${COLOR5}:: ${COLOR1}Synchronizing aur database...${ENDCOLOR}"
  IFS=$'\n'
  packages=( $(pacman -Qm) )
  newpackages=()
  checkignores=()
  total="${#packages[@]}"
  grep -q '^ *ILoveCandy' "$pacmanconf" && bartype='candy' || bartype='normal'

  if [[ $devel ]]; then
    for ((i=0; i<$total; i++)); do 
      aurbar "$((i+1))" "$total" "$bartype"
      pkg="${packages[i]%% *}"
      if isignored "$pkg"; then
        checkignores+=("${packages[i]}")
        continue
      fi
      pkginfo "$pkg" &
      nap
    done
    wait
    for ((i=0; i<$total; i++)); do 
      pkg="${packages[i]%% *}"
      ver="${packages[i]##* }"
      if [[ ! -s "$tmpdir/$pkg.PKGBUILD" ]]; then
        continue
      fi
      if isignored "$pkg"; then
        continue
      fi
      unset _darcstrunk _cvsroot _gitroot _svntrunk _bzrtrunk _hgroot
      . "$tmpdir/$pkg.PKGBUILD"
      if [[ "$(LC_ALL=C vercmp "$pkgver-$pkgrel" "$ver")" -gt 0 ]]; then
        newpackages+=("$pkg")
      elif [[ ${_darcstrunk} || ${_cvsroot} || ${_gitroot} || ${_svntrunk} || ${_bzrtrunk} || ${_hgroot} ]]; then 
        newpackages+=("$pkg")
      fi
    done
  else
    for ((i=0; i<$total; i++)); do 
      aurbar "$((i+1))" "$total" "$bartype"
      pkg="${packages[i]%% *}"
      rpcinfo "$pkg" &
      nap
    done
    wait
    for ((i=0; i<$total; i++)); do
      pkg="${packages[i]%% *}"
      ver="${packages[i]##* }"
      if isignored "$pkg"; then
        checkignores+=("${packages[i]}")
      elif aurversionisnewer "$pkg" "$ver"; then
        newpackages+=("$pkg")
    fi
    done
  fi
  echo

  echo -e "${COLOR5}:: ${COLOR1}Starting full aur upgrade...${ENDCOLOR}"

  # Check and output ignored package update info
  for package in "${checkignores[@]}"; do
    if aurversionisnewer "${package%% *}" "${package##* }"; then
      echo -e "${COLOR6}warning:${ENDCOLOR} $package: ignoring package upgrade (${package##* } => $aurversion)"
    fi
  done

  # Now for the installation part
  if [[ $newpackages ]]; then
    auronly='1'
    installhandling "${newpackages[@]}"
  fi
  echo " local database is up to date"
fi

# Download (-G) handling
if [[ $option = download ]]; then
  for package in "${packageargs[@]}"; do
    if existsinaur "$package"; then
      pkglist+=("$package")
    else
      err "Package \`$package' does not exist on aur."
    fi
  done

  for package in "${pkglist[@]}"; do
    curl -Lfs "$PKGURL/$package/$package.tar.gz" > "$package.tar.gz"
    tar xf "$package.tar.gz" 
  done
fi

# Search (-Ss) handling
if [[ $option = search || $option = searchinstall ]]; then
  # Pacman searching 
  if ! [[ $auronly ]]; then
    if [[ $quiet ]]; then
      results="$(pacman -Ssq -- "${packageargs[@]}")"
    else
      results="$(pacman -Ss -- "${packageargs[@]}")"
      results="$(sed -r "s|^[^ ][^/]*/|$S${COLOR3}&$S${COLOR1}|" <<< "$results")"
      results="$(sed -r "s|^([^ ]+) ([^ ]+)(.*)$|\1 $S${COLOR2}\2$S${ENDCOLOR}\3|" <<< "$results")"
    fi
    if [[ $option = search ]]; then
      echo -e "$results" | fmt -"$_WIDTH" -s
    else  # interactive
      echo -e "$results" | fmt -"$_WIDTH" -s | nl -v 0 -w 1 -s ' ' -b 'p^[^ ]'
    fi | sed '/^$/d'
    pacname=( $(pacman -Ssq -- "${packageargs[@]}") )
    pactotal="${#pacname[@]}"
  else
    pactotal=0
  fi

  # Aur searching and tmpfile preparation
  for package in "${packageargs[@]}"; do
    curl -LfGs --data-urlencode "arg=$package" "$RPCURL=search" | \
    jshon -Q -e results -a -e Name -u -p -e Version -u -p -e NumVotes -u -p -e Description -u | \
    sed 's/^$/-/' |  paste -s -d "\t\t\t\n" | sort -nr -k 3 > "$tmpdir/$package.search" &
  done
  wait
  cp "$tmpdir/${packageargs[0]}.search" "$tmpdir/search.results"
  for ((i=1 ; i<${#packageargs[@]} ; i++)); do
    grep -xFf "$tmpdir/search.results" "$tmpdir/${packageargs[$i]}.search" > "$tmpdir/search.results-2"
    mv "$tmpdir/search.results-2" "$tmpdir/search.results"
  done
  sed -i '/^$/d' "$tmpdir/search.results"

  # Prepare tmp file and arrays
  IFS=$'\n'
  aurname=( $(cut -f 1 "$tmpdir/search.results") )
  aurtotal="${#aurname[@]}"
  alltotal="$(($pactotal+$aurtotal))"
  # Echo out the -Ss formatted package information

  IFS=$'\t\n'
  if [[ $option = search ]]; then
    if [[ $quiet ]]; then
      printf "%s\n" ${aurname[@]}
    elif [[ -s "$tmpdir/search.results" ]]; then
      printf "${COLOR3}aur/${COLOR1}%s ${COLOR2}%s${ENDCOLOR} (%s)\n    %s\n" $(cat "$tmpdir/search.results")
    fi
  else
    # interactive
    if [[ $quiet ]]; then
	fifo=$(mktemp); mkfifo $fifo
	cut -f 1 "$tmpdir/search.results" > $fifo & nl -v ${pactotal:-0} -w 1 -s ' ' $fifo
	rm $fifo
    elif [[ -s "$tmpdir/search.results" ]]; then
      printf "%d ${COLOR3}aur/${COLOR1}%s ${COLOR2}%s${ENDCOLOR} (%s)\n    %s\n" $(nl -v ${pactotal:-0} -w 1 < "$tmpdir/search.results")
    fi
  fi | fmt -"$_WIDTH" -s

  # Prompt and install selected numbers
  if [[ $option = searchinstall ]]; then
    pkglist=()
    allpackages=( "${pacname[@]}" "${aurname[@]}" )

    # Exit if there are no matches
    [[ $allpackages ]] || exit

    # Prompt for numbers
    echo
    echo -e "${COLOR2}Type numbers to install. Separate each number with a space.${ENDCOLOR}"
    echo -ne "${COLOR2}Numbers: ${ENDCOLOR}"
    read -r
    
    # Parse answer
    if [[ $REPLY ]]; then
      IFS=' '
      for num in $REPLY; do
        if [[ $num -lt $alltotal ]]; then
          pkglist+=("${allpackages[$num]}")
        else
          err "Number \`$num' is not assigned to any of the packages."
        fi
      done
    fi

    # Call installhandling to take care of the packages chosen 
    installhandling "${pkglist[@]}"
  fi

  # Remove the tmpfiles
  rm -f "$tmpdir/*search" &>/dev/null
  rm -f "$tmpdir/search.result" &>/dev/null
  exit
fi

# Info (-Si) handling
if [[ $option = info ]]; then
  # Pacman info check
  sourcemakepkgconf
  for package in "${packageargs[@]}"; do
    if ! [[ $auronly ]] && existsinpacman "$package"; then
      results="$(pacman -Si -- "$package")"
      results="$(sed -r "s|^(Repository[^:]*:)(.*)$|\1$S${COLOR3}\2$S${ENDCOLOR}|" <<< "$results")"
      results="$(sed -r "s|^(Name[^:]*:)(.*)$|\1$S${COLOR1}\2$S${ENDCOLOR}|" <<< "$results")"
      results="$(sed -r "s|^(Version[^:]*:)(.*)$|\1$S${COLOR2}\2$S${ENDCOLOR}|" <<< "$results")"
      results="$(sed -r "s|^(URL[^:]*:)(.*)$|\1$S${COLOR4}\2$S${ENDCOLOR}|" <<< "$results")"
      results="$(sed -r "s|^[^ ][^:]*:|$S${COLOR1}&$S${ENDCOLOR}|" <<< "$results")"
      echo -e "$results"
      exit
    else # Check to see if it is in the aur
      pkginfo "$package"
      [[ -s "$tmpdir/$package.PKGBUILD" ]] || err "${COLOR7}error:${ENDCOLOR} package '$package' was not found"
      . "$tmpdir/$package.PKGBUILD"

      # Echo out the -Si formatted package information
      # Retrieve each element in order and echo them immediately
      echo -e "${COLOR1}Repository     : ${COLOR3}aur"
      echo -e "${COLOR1}Name           : $pkgname"
      echo -e "${COLOR1}Version        : ${COLOR2}$pkgver-$pkgrel"
      echo -e "${COLOR1}URL            : ${COLOR4}$url"
      echo -e "${COLOR1}Licenses       : ${ENDCOLOR}${license[@]}"
      echo -e "${COLOR1}Groups         : ${ENDCOLOR}${groups[@]:-None}"
      echo -e "${COLOR1}Provides       : ${ENDCOLOR}${provides[@]:-None}"
      echo -e "${COLOR1}Depends On     : ${ENDCOLOR}${depends[@]}"
      echo -e "${COLOR1}Make Depends   : ${ENDCOLOR}${makedepends[@]}"
      echo -e -n "${COLOR1}Optional Deps  : ${ENDCOLOR}"

      len="${#optdepends[@]}"
      if [[ $len -eq 0 ]]; then
        echo "None"
      else
        for ((i=0 ; i<$len ; i++)); do
          if [[ $i = 0 ]]; then
            echo "${optdepends[$i]}"
          else
            echo -e "                 ${optdepends[$i]}" 
          fi
        done
      fi

      echo -e "${COLOR1}Conflicts With : ${ENDCOLOR}${conflicts[@]:-None}"
      echo -e "${COLOR1}Replaces       : ${ENDCOLOR}${replaces[@]:-None}"
      echo -e "${COLOR1}Architecture   : ${ENDCOLOR}${arch[@]}"
      echo -e "${COLOR1}Description    : ${ENDCOLOR}$pkgdesc"
      echo
    fi
  done
fi