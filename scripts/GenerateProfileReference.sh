#!/bin/bash

profile_manifest_source="https://raw.githubusercontent.com/ProfileManifests/ProfileManifests/refs/heads/master/Manifests/ManagedPreferencesApplications/com.jamf.setupmanager.plist"
profile_manifest_dest="/tmp/com.jamf.setupmanager.plist"
profile_manifest_json="/tmp/com.jamf.setupmanager.json"
latest_version="1.4"

curl -s -o "${profile_manifest_dest}" "${profile_manifest_source}"

if ! plutil "${profile_manifest_dest}"; then
  exit 1
fi

# Convert plist to json

sed -i '' 's/<date>/<string>/g' "${profile_manifest_dest}"
sed -i '' 's/<\/date>/<\/string>/g' "${profile_manifest_dest}"

if ! plutil "${profile_manifest_dest}"; then
  exit 1
fi

plutil -convert json "${profile_manifest_dest}" -o "${profile_manifest_json}"

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

mkdir -p "${script_dir}/../src/content/docs/profilereference"
pushd "${script_dir}/../src/content/docs/profilereference" || exit 1
rm -rf ./*

ignored_keys=("PayloadDescription" "PayloadDisplayName" "PayloadIdentifier" "PayloadType" "PayloadUUID" "PayloadVersion" "PayloadOrganization" "PFC_SegmentedControl_0")
NL=$'\n'
index_tmp="index.mdx.tmp"

jq -c '.pfm_subkeys.[]' "${profile_manifest_json}" | while read -r json_blob; do
  name=$(echo "${json_blob}" | jq -r .pfm_name)
  if [[ " ${ignored_keys[*]} " =~ " ${name}" ]]; then
    continue;
  fi
  filename=$(echo "${name}" | tr '[:upper:]' '[:lower:]' | tr -d '_')
  min_ver=$(echo "${json_blob}" | jq -r .pfm_app_min)
  deprecated_ver=$(echo "${json_blob}" | jq -r .pfm_app_deprecated)

  # Front Matter
  markdown="---${NL}title: ${name}"
  if [[ "${min_ver}" == "${latest_version}" ]]; then
    markdown+="${NL}sidebar:${NL}  badge:${NL}    text: New${NL}    variant: tip"
  fi
  if [[ "${deprecated_ver}" != "null" ]]; then
    markdown+="${NL}sidebar:${NL}  badge:${NL}    text: Deprecated${NL}    variant: caution"
  fi
  markdown+="${NL}---"

  # Availability
  if [[ "${min_ver}" == "null" ]]; then min_ver="1.0"; fi
  markdown+="${NL}${NL}## Availability${NL}* Setup Manager since version ${min_ver}"

  if [[ "${deprecated_ver}" != "null" ]]; then
    markdown+="${NL}* Deprecated since version ${deprecated_ver}"
  fi

  # Description
  description=$(echo "${json_blob}" | jq -r .pfm_description)
  markdown+="${NL}${NL}## Description${NL}${NL}${description}"

  # Data type
  type=$(echo "${json_blob}" | jq -r .pfm_type)
  markdown+="${NL}${NL}## Key type${NL}${NL}${type}"

  # Default value
  default=$(echo "${json_blob}" | jq -r .pfm_default)
  if [[ "${default}" == "null" && "${type}" == "boolean" ]]; then
    default="\`false\`"
  elif [[ "${default}" == "null" ]]; then
    default="_undefined_"
  else 
    default="\`${default}\`"
  fi
  markdown+="${NL}${NL}## Default value${NL}${NL}${default}"

  # Valid values
  range_list_json=$(echo "${json_blob}" | jq -c .pfm_range_list)
  if [[ "${range_list_json}" != "null" ]]; then
    markdown+="${NL}${NL}## Valid values${NL}"
    IFS=$'\n'
    for value in $(echo "${range_list_json}" | jq -r '.[]'); do
      markdown+="${NL}* \`${value}\`"
    done
    unset IFS
  fi

  # Color valid values
  if [[ "${description}" == *"color"* ]]; then
    markdown+="${NL}${NL}## Valid values${NL}${NL}Any valid [color notation](/docmirror/colors)."
  fi

  # Examples
  examples=$(ls "${script_dir}/ProfileReferenceExamples/${name}"*.plist 2> /dev/null)
  if [[ -n "${examples}" ]]; then
    markdown+="${NL}${NL}## Examples"
    for file in "${script_dir}/ProfileReferenceExamples/${name}"*.plist; do
      if plutil "${file}"; then
        example=$(plutil -convert xml1 -o - "${file}" | xpath -q -e '/plist/dict/*' | awk -v RS='' '{gsub(/\n\t/, "\n")}1')
        markdown+="${NL}\`\`\`xml${NL}${example}${NL}\`\`\`"
      fi
    done
  fi
  
  echo "${markdown}" > "${filename}.md"

  # index LinkCard
  short_description=$(echo "${description}" | awk -F '.' '{print $1; exit}' | tr -d '"')
  echo "<LinkCard title=\"${name}\" href=\"/profilereference/${filename}/\" description=\"${short_description}\" />" >> "${index_tmp}"
done

# Create index.mdx
sort -f -o "${index_tmp}" "${index_tmp}"
echo "---
title: Configuration Profile Reference
prev: false
tableOfContents: false
pagefind: false
---
import { LinkCard } from '@astrojs/starlight/components';
" > index.mdx
cat "${index_tmp}" >> index.mdx
rm "${index_tmp}"

popd || exit 1

exit 0
