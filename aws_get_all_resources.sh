#!/bin/bash
# shellcheck disable=2086

# Get all (taggable) resources in all AWS regions for current account.
# Uses resource groups tagging api.

OUTROOT="$HOME/tmp/aws_get_all_resources"

# check_PREREQS
check_prereqs(){
  if ! type jq      > /dev/null 2>&1; then echo "jq not found";      return 1; fi  # brew install jq
  if ! type aws     > /dev/null 2>&1; then echo "aws not found";     return 1; fi  # brew install awscli
  if ! type awsume  > /dev/null 2>&1; then echo "awsume not found";  return 1; fi  # brew install awsume
}
check_prereqs || exit 1

if [[ -z $AWS_REGION ]]; then
  echo "No AWS_REGION set. Get AWS cli session"
  exit 1
fi

ACC_ID=$(aws sts get-caller-identity --query 'Account' --out text 2> /dev/null) || exit 1
ACC_ALIAS=$(aws iam list-account-aliases --query 'AccountAliases[]' --out text 2> /dev/null)
[[ -n $ACC_ALIAS ]] && ACC_ALIAS="-${ACC_ALIAS}"

OUT="${OUTROOT}/${ACC_ID}${ACC_ALIAS}"
mkdir -p "${OUT}"

makecsv(){
  t="$1"
  # add csv header
  echo "service,region,accountid,type,details_1,details_2,details_3,details_4,details_5,details_6,details_7,details_8"
  # shellcheck disable=2002
  cat "${t}" | sed -r 's/arn:aws://g' | awk -F'[/:]' '{print $1","$2","$3","$4","$5","$6","$7","$8","$9","$10","$11","$12}'
}

main(){
  for r in $(aws ec2 describe-regions --query 'Regions[].RegionName' --out text)
  do
    # f="${OUT}/${region}_resources"
    f="${OUT}/${r}"
    j="${f}.json"
    l="${f}_arns.txt"
    c="${f}.csv"

    echo -e "Listing Resources in '${r}' ..."
    aws resourcegroupstaggingapi get-resources --region ${r} > "${j}"

    # Check for and delete "empty" json (i.e. <= 37 bytes), else do stuff
    s=$(wc -c "${j}" 2> /dev/null | awk '{print $1}')
    if [[ $s -le 37 ]]; then
      rm -f "${j}"
    else
      jq -r '.ResourceTagMappingList[] | .ResourceARN' "${j}" > "${l}" && \
      makecsv "${l}" > "${c}" && \
      rm -f "${l}"
    fi
  done
}

main
