#!/usr/bin/env bash
# Rebuild the Fedora packages from the source RPM matching the running installation.
set -euo pipefail

# Parse the entire installation before starting the long build.
main() {
    patch_file="$(realpath "$(dirname "$0")/../patches/kwin-6.8.3-slide-retarget.patch")"
    source_rpm="$(rpm -q --qf '%{SOURCERPM}' kwin)"
    build_root="$(mktemp -d)"
    cleanup() {
        if (( $? != 0 )) && compgen -G "$build_root/RPMS/*/*.rpm" >/dev/null; then
            echo "Saved RPMs in $build_root/RPMS" >&2
        else
            rm -rf -- "$build_root"
        fi
    }
    trap cleanup EXIT
    cd "$build_root"
    dnf download --srpm "${source_rpm%.src.rpm}"
    sudo dnf builddep -y "./$source_rpm"
    mkdir SOURCES
    (cd SOURCES && rpm2cpio "../$source_rpm" | cpio -idm --quiet)
    spec="$build_root/SOURCES/kwin.spec"
    # Apply after Fedora's own patches, in the prepared source directory.
    if [[ "$(grep -Ec '^%autosetup([[:space:]]|$)' "$spec")" != 1 ]]; then
        echo "Unrecognized Fedora %prep section in $source_rpm" >&2
        echo "Skipping the Slide fix. Continuing with the scrolling plugin." >&2
        return 0
    fi

    # Inspect Fedora's prepared tree, including any downstream fixes.
    rpmbuild -bp --quiet --define "_topdir $build_root" "$spec"
    mapfile -d '' slide_sources < <(find "$build_root/BUILD" -type f -path '*/src/plugins/slide/slide.cpp' -print0)
    if (( ${#slide_sources[@]} != 1 )); then
        echo "Slide source layout changed in $source_rpm. Skipping the Slide fix." >&2
        return 0
    fi
    slide_source="${slide_sources[0]}"
    if patch --silent --force --reverse --dry-run --fuzz=0 "$slide_source" "$patch_file" >/dev/null 2>&1; then
        echo "The Slide fix is already present in $source_rpm."
        return 0
    fi
    if ! patch --silent --force --dry-run --fuzz=0 "$slide_source" "$patch_file" >/dev/null 2>&1; then
        echo "Slide changed in $source_rpm. Skipping the patch pending review." >&2
        return 0
    fi
    install -m 644 "$patch_file" SOURCES/meta-scroll-slide.patch
    sed -i '/^%autosetup\([[:space:]]\|$\)/a patch --force --fuzz=0 -p1 < "%{_sourcedir}/meta-scroll-slide.patch"' "$spec"
    log_dir="${XDG_STATE_HOME:-$HOME/.local/state}/kwin-meta-scroll-desktop"
    mkdir -p "$log_dir"
    build_log="$(mktemp "$log_dir/rpmbuild.XXXXXXXX.log")"
    echo "Building KWin. Full log: $build_log"
    if rpmbuild -bb --define "_topdir $build_root" "$spec" 2>&1 | tee "$build_log" | awk '
    /^\[ *[0-9]+%\]/ {
        percent = $0
        sub(/^\[ */, "", percent)
        sub(/%.*/, "", percent)
        milestone = int(percent / 5) * 5
        if (milestone > last) {
            printf "KWin build: %d%%\n", milestone
            fflush()
            last = milestone
        }
    }
    /^Executing\(%(install|check)\)/ {
        print ($0 ~ /^Executing\(%install/ ? "Packaging KWin…" : "Checking KWin…")
        fflush()
    }
'; then
        echo "KWin packages built."
    else
        status=$?
        echo "KWin build failed. Full log: $build_log" >&2
        tail -n 12 "$build_log" >&2
        exit "$status"
    fi

    # Replace only matching packages already installed on this machine.
    packages=()
    for file in RPMS/*/*.rpm; do
        nevra="$(rpm -qp --qf '%{NAME}-%{VERSION}-%{RELEASE}.%{ARCH}' "$file")"
        if rpm -q --quiet "$nevra"; then
            packages+=("$PWD/$file")
        fi
    done
    if [[ "$(rpm -q --qf '%{SOURCERPM}' kwin)" != "$source_rpm" || ${#packages[@]} == 0 ]]; then
        echo "Installed KWin changed or the rebuilt packages do not match." >&2
        exit 1
    fi
    sudo dnf reinstall -y "${packages[@]}"
    echo "Patched KWin installed."
}

if [[ ${1:-} == --after-update ]]; then
    stamp=/var/lib/kwin-meta-scroll-desktop/slide-checked-for
    current="$(rpm -q kwin)"
    if [[ "$(cat "$stamp" 2>/dev/null)" == "$current" ]]; then
        exit 0
    fi
    main
    [[ "$(rpm -q kwin)" == "$current" ]]
    printf '%s\n' "$current" > "$stamp"
else
    main
fi
