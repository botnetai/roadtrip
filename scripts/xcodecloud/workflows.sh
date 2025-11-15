#!/usr/bin/env bash
set -euo pipefail

API_BASE="https://api.appstoreconnect.apple.com"
WORKFLOW_DIR="${WORKFLOW_DIR:-xcodecloud/workflows}"
ASC_JWT=""

err() { printf 'error: %s\n' "$1" >&2; }
usage() {
  cat <<'USAGE'
Automate Xcode Cloud workflow creation via the App Store Connect API.

Required env vars:
  ASC_KEY_ID, ASC_ISSUER_ID, ASC_PRIVATE_KEY_PATH, APP_BUNDLE_ID
Optional env vars:
  CI_PRODUCT_ID, SCM_REPOSITORY_ID, XCODE_VERSION_ID, MACOS_VERSION_ID
  WORKFLOW_DIR (defaults to xcodecloud/workflows)

Commands:
  list-prereqs   Resolve app/product/repo IDs and list Xcode/macOS versions
  create         Create every workflow JSON definition located in WORKFLOW_DIR

Examples:
  ./scripts/xcodecloud/workflows.sh list-prereqs
  XCODE_VERSION_ID="Xcode15.4" MACOS_VERSION_ID="14F" \
    ./scripts/xcodecloud/workflows.sh create
USAGE
}

require_var() {
  local name="$1"
  if [[ -z "${!name:-}" ]]; then
    err "${name} is not set"
    exit 1
  fi
}

urlsafe_b64() {
  openssl base64 -e -A | tr '+/' '-_' | tr -d '='
}

build_jwt() {
  if [[ -n "$ASC_JWT" ]]; then
    return
  fi
  require_var ASC_KEY_ID
  require_var ASC_ISSUER_ID
  require_var ASC_PRIVATE_KEY_PATH
  local iat exp header payload signature
  iat=$(date +%s)
  exp=$((iat + 1200))
  header=$(printf '{"alg":"ES256","kid":"%s","typ":"JWT"}' "$ASC_KEY_ID" | urlsafe_b64)
  payload=$(printf '{"iss":"%s","iat":%d,"exp":%d,"aud":"appstoreconnect-v1"}' "$ASC_ISSUER_ID" "$iat" "$exp" | urlsafe_b64)
  signature=$(printf '%s.%s' "$header" "$payload" | \
    openssl dgst -sha256 -sign "$ASC_PRIVATE_KEY_PATH" | urlsafe_b64)
  ASC_JWT="$header.$payload.$signature"
}

asc_request() {
  local method="$1" path="$2" data_file="${3:-}"
  build_jwt
  local curl_args=(
    -sS -X "$method" "$API_BASE/$path"
    -H "Authorization: Bearer $ASC_JWT"
    -H 'Content-Type: application/json'
  )
  if [[ -n "$data_file" ]]; then
    curl_args+=(--data-binary "@$data_file")
  fi
  curl "${curl_args[@]}"
}

fetch_app_id() {
  require_var APP_BUNDLE_ID
  asc_request GET "v1/apps?filter%5BbundleId%5D=$APP_BUNDLE_ID&limit=1" | jq -er '.data[0].id'
}

fetch_ci_product_id() {
  local app_id="$1"
  asc_request GET "v1/apps/$app_id/ciProduct" | jq -er '.data.id'
}

fetch_repository_id() {
  local product_id="$1"
  asc_request GET "v1/ciProducts/$product_id/repository" | jq -er '.data.id'
}

list_xcode_versions() {
  asc_request GET "v1/ciXcodeVersions?limit=200" | jq -r '.data[] | "\(.id)\t\(.attributes.name)"'
}

list_macos_versions() {
  asc_request GET "v1/ciMacOsVersions?limit=200" | jq -r '.data[] | "\(.id)\t\(.attributes.name)"'
}

list_prereqs() {
  local app_id product_id repo_id
  app_id=$(fetch_app_id)
  product_id=$(fetch_ci_product_id "$app_id")
  repo_id=$(fetch_repository_id "$product_id")
  cat <<EOF
App bundle: $APP_BUNDLE_ID
App id: $app_id
CI product id: $product_id
SCM repository id: $repo_id

Available Xcode versions:
$(list_xcode_versions)

Available macOS versions:
$(list_macos_versions)
EOF
}

create_workflows() {
  if [[ ! -d "$WORKFLOW_DIR" ]]; then
    err "Workflow directory $WORKFLOW_DIR does not exist"
    exit 1
  fi
  local app_id product_id repo_id
  app_id=$(fetch_app_id)
  product_id="${CI_PRODUCT_ID:-$(fetch_ci_product_id "$app_id")}"
  repo_id="${SCM_REPOSITORY_ID:-$(fetch_repository_id "$product_id")}"
  require_var XCODE_VERSION_ID
  require_var MACOS_VERSION_ID
  local found=false
  for file in "$WORKFLOW_DIR"/*.json; do
    [[ -e "$file" ]] || continue
    found=true
    local attrs workflow_name tmp response
    attrs=$(jq -c '.' "$file")
    workflow_name=$(jq -r '.name' "$file")
    tmp=$(mktemp)
    cat >"$tmp" <<JSON
{
  "data": {
    "type": "ciWorkflows",
    "attributes": $attrs,
    "relationships": {
      "xcodeVersion": {"data": {"type": "ciXcodeVersions", "id": "$XCODE_VERSION_ID"}},
      "macOsVersion": {"data": {"type": "ciMacOsVersions", "id": "$MACOS_VERSION_ID"}},
      "product": {"data": {"type": "ciProducts", "id": "$product_id"}},
      "repository": {"data": {"type": "scmRepositories", "id": "$repo_id"}}
    }
  }
}
JSON
    response=$(asc_request POST v1/ciWorkflows "$tmp")
    rm "$tmp"
    printf 'Created %s -> %s\n' "$workflow_name" "$(echo "$response" | jq -r '.data.id')"
  done
  if [[ "$found" == false ]]; then
    err "No workflow templates found in $WORKFLOW_DIR"
    exit 1
  fi
}

cmd="${1:-}"
case "$cmd" in
  list-prereqs)
    list_prereqs
    ;;
  create)
    shift
    create_workflows "$@"
    ;;
  ""|-h|--help)
    usage
    ;;
  *)
    err "Unknown command: $cmd"
    usage
    exit 1
    ;;
esac
