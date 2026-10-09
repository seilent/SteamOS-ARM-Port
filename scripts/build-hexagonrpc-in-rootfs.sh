#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
R="${1:-${ROOT}/rootfs}"
R="$(cd "$R" && pwd)"
REF=da7a3742ab8d5273a281b70ee11f16fb2cb6a690
SHA256=651ab53dcf92a2766ba6ec42cac2ccdbd67382da5211b14c5fa33b618153c435
TARBALL="${HEXAGONRPC_TARBALL:-/tmp/hexagonrpc-${REF}.tar.gz}"
BUILD="${HEXAGONRPC_BUILD:-/tmp/hexagonrpc-build}"

[[ -d "$R/usr" ]] || { echo "ERROR: bad rootfs $R" >&2; exit 1; }
for t in gcc meson ninja; do
  [[ -x "$R/usr/bin/$t" ]] || { echo "ERROR: rootfs has no $t" >&2; exit 1; }
done
command -v bwrap >/dev/null 2>&1 || { echo "ERROR: bwrap required" >&2; exit 1; }
if ! echo "$SHA256  $TARBALL" | sha256sum -c --quiet >/dev/null 2>&1; then
  echo "==> download linux-msm/hexagonrpc@$REF"
  curl -fsSL -o "$TARBALL.tmp" "https://github.com/linux-msm/hexagonrpc/archive/${REF}.tar.gz"
  mv -f "$TARBALL.tmp" "$TARBALL"
  echo "$SHA256  $TARBALL" | sha256sum -c --quiet || { echo "ERROR: hexagonrpc tarball hash mismatch" >&2; exit 1; }
fi
rm -rf "$BUILD"
mkdir -p "$BUILD/src"
tar -xzf "$TARBALL" -C "$BUILD/src" --strip-components=1

run() {
  bwrap --bind "$R" / \
    --bind /tmp /tmp \
    --bind "$BUILD" /build \
    --dev /dev --proc /proc --tmpfs /run \
    --unshare-pid --die-with-parent --chdir /build \
    "$@"
}

echo "==> meson hexagonrpc against $R"
run /usr/bin/meson setup --prefix=/usr --libdir=lib --buildtype=release /build/out /build/src
run /usr/bin/meson compile -C /build/out
run /usr/bin/meson install -C /build/out --destdir /build/dest
install -D -m0755 "$BUILD/dest/usr/bin/hexagonrpcd" "$R/usr/bin/hexagonrpcd"
install -D -m0755 "$BUILD/dest/usr/lib/libhexagonrpc.so.0.5" "$R/usr/lib/libhexagonrpc.so.0.5"
echo "OK: hexagonrpcd installed into $R"
