#!/usr/bin/env bash
exit  # RUN THESE COMMAND INTERACTIVELY, AND FROM WITHIN THE ROOT OF THE OUTPUT DIRECTORY

# NON-STANDARD REGIONS (i.e. anything but us-west-1 and us-east-2)
find . -type f -name "*[1-9].json" | grep -v 'us-[we][ae]st-1' > non-standard-regions.txt

# NON-STANDARD REGION RESOURCES
# for l in $(cat non-standard-regions.txt); do echo "### ${l}: ###" ; jq -r '.ResourceTagMappingList[].ResourceARN' "${l}"; done > non-standard-regions-resourceArns.txt
# while read -r line; do echo "### ${line}: ###"; jq -r '.ResourceTagMappingList[].ResourceARN' "${line}"; done < non-standard-regions.txt > non-standard-regions-resourceArns.txt
while IFS= read -r line; do echo "### ${line}: ###"; jq -r '.ResourceTagMappingList[].ResourceARN' "${line}"; done < non-standard-regions.txt > non-standard-regions-resourceArns.txt
