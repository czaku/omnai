#!/usr/bin/env bash
# release.sh - Create and publish omnai releases

set -e

VERSION_FILE="omnai.sh"
CHANGELOG="CHANGELOG.md"
REPO="czaku/omnai"

usage() {
    cat << EOF
Usage: $0 <version> [--draft]

Create a GitHub release for omnai.

Arguments:
    version     Version tag (e.g., v1.0.0, v1.0.0-rc1, v1.1.0-beta)

Options:
    --draft     Create as draft (default: published)

Examples:
    $0 v1.0.0-rc1
    $0 v1.0.0 --draft
EOF
    exit 1
}

create_release() {
    local version="$1"
    local is_draft="${2:-false}"

    echo "Creating release $version..."

    # Create tarball
    local tarball="omnai-${version}.tar.gz"
    git archive --prefix="omnai-${version}/" -o "$tarball" HEAD

    # Calculate SHA256
    local sha=$(shasum -a 256 "$tarball" | cut -d' ' -f1)
    echo "SHA256: $sha"

    # Update version in source file
    sed -i.bak "s/OMNAI_VERSION=\"[^\"]*\"/OMNAI_VERSION=\"${version#v}\"/" "$VERSION_FILE"
    rm -f "${VERSION_FILE}.bak"

    # Update version in CHANGELOG
    local date=$(date +"%B %Y")
    sed -i.bak "s/## \[Unreleased\] - v[0-9.]*/## [Unreleased] - \\n\\n## [${version}] - ${date}/" "$CHANGELOG"
    rm -f "${CHANGELOG}.bak"

    # Commit version bump
    git add "$VERSION_FILE" "$CHANGELOG"
    git commit -m "chore: bump version to ${version}"

    # Create GitHub release
    local draft_flag=""
    if [[ "$is_draft" == "true" ]]; then
        draft_flag="--draft"
    fi

    gh release create "$version" \
        --title "omnai ${version}" \
        --notes "See CHANGELOG.md for details" \
        $draft_flag \
        "$tarball"

    echo ""
    echo "Release created: https://github.com/${REPO}/releases/tag/${version}"
    echo "Don't forget to push: git push && git push origin ${version}"
}

main() {
    if [[ $# -lt 1 ]]; then
        usage
    fi

    local version="$1"
    local is_draft="false"

    shift
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --draft)
                is_draft="true"
                ;;
            *)
                echo "Unknown option: $1"
                usage
                ;;
        esac
        shift
    done

    create_release "$version" "$is_draft"
}

main "$@"
