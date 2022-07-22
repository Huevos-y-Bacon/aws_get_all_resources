#!/usr/bin/env bash
# shellcheck disable=2086,2048

# SOURCE THIS!
(return 0 2>/dev/null) && sourced=1 || sourced=0
[[ $sourced -eq 0 ]] && { echo "SOURCE THIS SCRIPT!"; exit 1; }

# check_PREREQS
check_prereqs(){
  if ! type jq      > /dev/null; then echo "jq not found";      return 1; fi  # brew install jq
  if ! type aws     > /dev/null; then echo "aws not found";     return 1; fi  # brew install awscli
  if ! type awsume  > /dev/null; then echo "awsume not found";  return 1; fi  # brew install awsume
}

colours(){  
  set_colours(){
    # RESET
    NORM=$(tput sgr0 :-"" 2>/dev/null); RESET=${NORM}; export NORM RESET

    # BOLD & ITALICS
    BOLD=$(tput bold :-"" 2>/dev/null); export BOLD 
    ITAL=$(tput sitm :-"" 2>/dev/null); export ITAL  # doesn't work in zsh? 

    # UNDERLINE
    SMUL=$(tput smul :-"" 2>/dev/null); export SMUL  # Start UL text
    RMUL=$(tput rmul :-"" 2>/dev/null); export RMUL  # End UL text

    # INVERT
    SMSO=$(tput smso :-"" 2>/dev/null); export SMSO  # Start “standout” mode
    RMSO=$(tput rmso :-"" 2>/dev/null); export RMSO  # End “standout” mode

    # REVERSE & BLINK
    REV=$(tput rev :-"" 2>/dev/null); export REV
    BLINK=$(tput blink :-"" 2>/dev/null); export BLINK  # doesn't work in zsh?

    # TEXT COLOURS
    BLACK=$(  tput setaf 0 :-"" 2>/dev/null); export BLACK
    RED=$(    tput setaf 1 :-"" 2>/dev/null); export RED 
    GREEN=$(  tput setaf 2 :-"" 2>/dev/null); export GREEN 
    YELLOW=$( tput setaf 3 :-"" 2>/dev/null); export YELLOW 
    BLUE=$(   tput setaf 4 :-"" 2>/dev/null); export BLUE 
    MAGENTA=$(tput setaf 5 :-"" 2>/dev/null); export MAGENTA 
    CYAN=$(   tput setaf 6 :-"" 2>/dev/null); export CYAN 
    WHITE=$(  tput setaf 7 :-"" 2>/dev/null); export WHITE

    # BACKGROUND COLOURS
    BGBLACK=$(  tput setab 0 :-"" 2>/dev/null); export BGBLACK
    BGRED=$(    tput setab 1 :-"" 2>/dev/null); export BGRED 
    BGGREEN=$(  tput setab 2 :-"" 2>/dev/null); export BGGREEN 
    BGYELLOW=$( tput setab 3 :-"" 2>/dev/null); export BGYELLOW 
    BGBLUE=$(   tput setab 4 :-"" 2>/dev/null); export BGBLUE 
    BGMAGENTA=$(tput setab 5 :-"" 2>/dev/null); export BGMAGENTA 
    BGCYAN=$(   tput setab 6 :-"" 2>/dev/null); export BGCYAN 
    BGWHITE=$(  tput setab 7 :-"" 2>/dev/null); export BGWHITE

    # LINES
    draw_line(){ printf '%*s' "${COLUMNS:-$(tput cols)}" '' | tr ' ' - ; }
  }

  unset_colours(){
    unset NORM
    unset BOLD
    unset ITAL
    unset SMUL
    unset RMUL
    unset SMSO
    unset RMSO
    unset REV
    unset BLINK
    unset BLACK
    unset RED
    unset GREEN
    unset YELLOW
    unset BLUE
    unset MAGENTA
    unset CYAN
    unset WHITE
    unset BGBLACK
    unset BGRED
    unset BGGREEN
    unset BGYELLOW
    unset BGBLUE
    unset BGMAGENTA
    unset BGCYAN
    unset BGWHITE
  }

  if [[ -n $NOCOLOUR ]]; then
    unset_colours
  else
    set_colours $*
  fi
}

aws_list_regions(){
  check_prereqs || return 1
  aws ec2 describe-regions --query 'Regions[].RegionName' | jq -r '.[]'
}

aws_who_ami(){
  STSGCI=$(aws sts get-caller-identity --out json 2> /dev/null)
  # shellcheck disable=2181
  if [[ $? == 0 ]]
  then
    echo -e "${YELLOW}AWS ACCOUNT ID : $(echo $STSGCI | jq -r '.Account')${NORM}"
    echo -e "${YELLOW}AWS USER ID    : $(echo $STSGCI | jq -r '.UserId')${NORM}"
    echo ""
  fi

  if [[ $AWS_ACCESS_KEY_ID != "" ]]
  then echo -e "AWS_ACCESS_KEY_ID     : $AWS_ACCESS_KEY_ID"
  fi

  if [[ $AWS_SESSION_TOKEN != "" ]]
  then echo -e "AWS_SESSION_TOKEN     : $(echo $AWS_SESSION_TOKEN | cut -c1-8)...<truncated>...$(echo $AWS_SESSION_TOKEN | grep -o '.\{8\}$')"
  fi

  if [[ $AWS_SECRET_ACCESS_KEY != "" ]]
  then echo -e "AWS_SECRET_ACCESS_KEY : $(echo $AWS_SECRET_ACCESS_KEY | cut -c1-8)...<truncated>...$(echo $AWS_SECRET_ACCESS_KEY | grep -o '.\{8\}$')"
  fi

  if [[ $AWS_SESSION_TOKEN_EXPIRY != "" ]]
  then echo -e "AWS_SESSION_TOKEN_EXPIRY  : $AWS_SESSION_TOKEN_EXPIRY"
  fi

  if [[ $AWS_SESSION_FILE != "" ]]
  then echo -e "AWS_SESSION_FILE      : $AWS_SESSION_FILE"
  fi

  if [[ $AWS_REGION != "" ]]
  then echo -e "AWS_REGION            : $AWS_REGION\n"
  fi

  if [[ $AWSUME_PROFILE != "" ]]
  then echo -e "${GREEN}${BOLD}AWSUME_PROFILE    : $AWSUME_PROFILE${NORM}"
  fi

  if [[ $AWSUME_EXPIRATION != "" ]]
  then echo -e "${GREEN}AWSUME_EXPIRATION : $AWSUME_EXPIRATION${NORM}\n"
  fi
}

aws_set_region(){
  # check_debug_verbose $*
  if [[ -z $1 ]]; then
    echo -n "Enter region (current: ${AWS_REGION}): "
    # shellcheck disable=2162
    read _region
  else _region="$1"
  fi

  if [[ -n $_region ]]; then
    AWS_REGION="${_region}"
    AWS_DEFAULT_REGION="${_region}"
    export AWS_REGION AWS_DEFAULT_REGION
    unset _region
  fi

  [[ -n $VERBOSE ]] && {
    echo "AWS Region variables:";
    env | grep '^AWS.*REGION';
  }
}

everywhere(){
  AWSUME_INITIAL_PROFILE=${AWSUME_PROFILE}

  echo -e "${BOLD}${YELLOW}Extracting AWS Resources in ALL REGIONS ... ${NORM}\n"

  for P in $(awsume -l | grep ^AUDIT | awk '{print $1}'); do
    awsume ${P}
    ./aws_get_all_resources.sh
  done

  echo -e "\n${BOLD}${YELLOW}DONE${NORM}\n"
  draw_line

  # reset oroginal awsume profile, if set
  if [[ -n $AWSUME_INITIAL_PROFILE ]]; then
    awsume "${AWSUME_INITIAL_PROFILE}"
    aws_who_ami
  else
    awsume -u
  fi
}

everywhere
