#!/bin/bash

profile_manifest_source="https://raw.githubusercontent.com/ProfileManifests/ProfileManifests/refs/heads/master/Manifests/ManagedPreferencesApplications/com.jamf.setupmanager.plist"
profile_manifest_dest="/tmp/com.jamf.setupmanager.plist"
profile_manifest_json="/tmp/com.jamf.setupmanager.json"

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

jq -c '.pfm_subkeys.[]' "${profile_manifest_json}" | while read -r json_blob; do
  name=$(echo "${json_blob}" | jq -r .pfm_name)
  if [[ " ${ignored_keys[@]} " =~ " ${name} " ]]; then
    continue;
  fi
  filename=$(echo "${name}" | tr '[:upper:]' '[:lower:]' | tr -d '_')
  markdown="---
title: ${name}
---"
  min_ver=$(echo "${json_blob}" | jq -r .pfm_app_min)
  if [[ "${min_ver}" == "null" ]]; then min_ver="1.0"; fi
  markdown="${markdown}

## Supported on:
* Setup Manager since version ${min_ver}"

  deprecated_ver=$(echo "${json_blob}" | jq -r .pfm_app_deprecated)
  if [[ "${deprecated_ver}" != "null" ]]; then
    markdown="${markdown}
* Deprecated since version ${deprecated_ver}"
  fi

  description=$(echo "${json_blob}" | jq -r .pfm_description)
  markdown="${markdown}

## Description

${description}"

  echo "${markdown}" > "${filename}.md"
done

popd
