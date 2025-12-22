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
rm -rf *

ignored_keys=("PayloadDescription" "PayloadDisplayName" "PayloadIdentifier" "PayloadType" "PayloadUUID" "PayloadVersion" "PayloadOrganization" "PFC_SegmentedControl_0")
NL=$'\n'

jq -c '.pfm_subkeys.[]' "${profile_manifest_json}" | while read -r json_blob; do
  name=$(echo "${json_blob}" | jq -r .pfm_name)
  if [[ " ${ignored_keys[@]} " =~ " ${name} " ]]; then
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

  echo "${markdown}" > "${filename}.md"
done

popd
