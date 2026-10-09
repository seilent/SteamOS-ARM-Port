# Building

I build everything in an arm64 Linux VM (Colima on a Mac).

- Kernels: `external-and-mods/kernel-sm8650/build.sh`, `external-and-mods/kernel-sm8550/build.sh` and `external-and-mods/kernel-sm8250/build.sh` (shared script in `kernel-common/`, chip specific bits in each `soc.env`)
- Armada based kernels (`kernel-sm8250`): a `soc.env` with `ARMADA_REF` takes armada's patch series, device trees and config overrides from a clone of github.com/seilent/armada at `<port>/../armada-<ARMADA_REF>` (or `ARMADA_DIR`) instead of ROCKNIX. The sm8250 `ARMADA_REF` is the tip of armada's `steamos-port-pm2` branch. `KCONFIG=defconfig` starts from the arm64 defconfig, `KSRC_SHA256` pins the source tarball.
- gamescope: `scripts/build-gamescope-in-rootfs.sh`, source in `external-and-mods/gamescope/`
- hexagonrpcd (`SOC=sm8250` only): `make-steamos-sm8650.sh` runs `scripts/build-hexagonrpc-in-rootfs.sh`, which builds linux-msm/hexagonrpc at its pinned commit and tarball hash with meson inside the rootfs and installs `/usr/bin/hexagonrpcd` and `/usr/lib/libhexagonrpc.so.0.5`. Skipped when `/usr/share/steamos-arm/hexagonrpc-ref` in the rootfs holds that commit
- the image: `make-steamos-sm8650.sh` (`SOC=sm8550` for the 8 Gen 2 one, `SOC=sm8250` for the Snapdragon 865 one, built on its own rootfs, `rootfs-sm8250` unless `STEAMOS_ROOTFS` is set), or `./make-steamos-sm8750.sh` for the Snapdragon 8 Elite (Odin 3); `./make-steamos-sm8350.sh` turns the rootfs from `make-steamos-sm8650.sh` (or a release image) into the REDMAGIC 6 fastboot kit (kernel: `external-and-mods/kernel-sm8350/build.sh`, see [redmagic6.md](redmagic6.md))
- `make-steamos-sm8650.sh --from-img IMG` starts from the root and home of a released card image instead of Valve's rootfs. It needs a `STEAMOS_ROOTFS` other than `$STEAMOS_WORK/rootfs`, takes gamescope from the image unless `GAMESCOPE_BUILD` has a build, and records the base image's `IMAGE.txt` as `/opt/steamos-sm8650/RELEASE-BASE.txt`. Any rootfs that already carries our Mesa 26.2.3 with Valve's in `/opt/stock-steamos` (a release image, a reused rootfs) keeps that stack unless `MESA_STACK` is set. Parts we build that the rootfs already carries (mangoapp, NetworkManager, the konkr-android payload, dpl.lv2, VA-API, the KDE builds) are kept when their build dir is absent
- `TEST_KERNEL_OUT` puts a second kernel on BOOT as `TEST_KERNEL_NAME` (default `KERNEL-own`), for testers to swap in by renaming. Its modules must be in `KERNEL_OUT` too. `TEST_KERNEL_CMDLINE_EXTRA` is added to that kernel's cmdline only. On sm8550 it gets the cmdline of our own kernel; `TEST_SM8550_KERNEL=prebuilt` when the spare one is the prebuilt 7.0.14

Valve's files and the Steam client aren't in this repo, the build downloads them. How the pieces fit together is in [HOW-IT-WORKS.md](HOW-IT-WORKS.md).

## CI

`.github/workflows/build-sm8250.yml` builds the sm8250 kernel and card image on GitHub's `ubuntu-24.04-arm` runners.

- A push to `pocket-micro-2` or `pm2-draft` that touches `external-and-mods/` (other than the other SoCs' kernels), the overlays, `scripts/`, `make-steamos-sm8650.sh` or the workflow runs it with the defaults. Manual runs (`workflow_dispatch`) only work once the file is on the default branch.
- `kernel`: fetches armada at the `ARMADA_REF` of `kernel-sm8250/soc.env` into `../armada-<ARMADA_REF>`, builds with `build-gcc15.sh` in armada's pinned Fedora image, checks the patch log, DTB, firmware and config, and uploads `kernel-sm8250` (kept 7 days) and `kernel-sm8250-log`. The step summary has the gcc version, the config `WARN` lines and the KERNEL size.
- `image`: downloads the sm8650 card image of the `base_tag` release (part hashes pinned in the workflow per tag), checks its rootfs has gcc, cmake, ninja, meson, Mesa 26.2.3 with the zink env and Valve's 26.3 in `/opt/stock-steamos`, and builds the sm8250 image from it with `--from-img` on `rootfs-sm8250`, which must keep that stack without the Frame Turnip pin, and the base image's mangoapp, NetworkManager, konkr-android payload, dpl.lv2, VA-API and KDE builds without rebuilding them, and builds hexagonrpcd in it. BOOT also gets `KERNEL-cpuidle-off`, the same kernel with `cpuidle.off=1` (`TEST_KERNEL_*`). Uploads `steamos-sm8250-<date>.<commit>` (7z parts and `SHA256SUMS`, kept 3 days) and `steamos-sm8250-log`.
- The image reuses the base image's gamescope, MangoHud, NetworkManager, konkr-android, dpl.lv2, VA-API and KDE builds, so `image` fails when any of their sources or build scripts changed since the base commit. A newer base release lifts that.
- `release`: makes a draft release `sm8250-<date>.<commit>` with the image parts, on a push to `pm2-draft` or with `draft_release`, unless `kernel-regression` failed.
- `kernel-regression`: builds sm8650 at the base commit (`BASE_SHA`, v1.3.0) and at the head in one job, in the `kernel` job's pinned Fedora image, and fails if the config, DTBs, firmware, module list, KERNEL cmdline field, patched source or gcc version differ. Runs when `external-and-mods/kernel-common/` changed in the push, or with `regression`.

Inputs (manual runs):

| Input | Default | Use |
|---|---|---|
| `kernel_run_id` | empty | skip the kernel build and take `kernel-sm8250` from that run; artifacts expire after 7 days |
| `regression` | off | run `kernel-regression` |
| `base_tag` | `v1.3.0` | release whose sm8650 image the card image starts from |
| `base_repo` | `hashtagbasit/SteamOS-ARM-Port` | repository of that release |
| `verbose` | on | kernel log on the panel at boot (`CMDLINE_QUIET=0`) |
| `draft_release` | off | run `release` |
