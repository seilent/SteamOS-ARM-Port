# Building

I build everything in an arm64 Linux VM (Colima on a Mac).

- Kernels: `external-and-mods/kernel-sm8650/build.sh`, `external-and-mods/kernel-sm8550/build.sh` and `external-and-mods/kernel-sm8250/build.sh` (shared script in `kernel-common/`, chip specific bits in each `soc.env`)
- Armada based kernels (`kernel-sm8250`): a `soc.env` with `ARMADA_REF` takes armada's patch series, device trees and config overrides from a clone of github.com/seilent/armada at `<port>/../armada-<ARMADA_REF>` (or `ARMADA_DIR`) instead of ROCKNIX. `KCONFIG=defconfig` starts from the arm64 defconfig, `KSRC_SHA256` pins the source tarball.
- gamescope: `scripts/build-gamescope-in-rootfs.sh`, source in `external-and-mods/gamescope/`
- the image: `make-steamos-sm8650.sh` (`SOC=sm8550` for the 8 Gen 2 one), or `./make-steamos-sm8750.sh` for the Snapdragon 8 Elite (Odin 3); `./make-steamos-sm8350.sh` turns the rootfs from `make-steamos-sm8650.sh` (or a release image) into the REDMAGIC 6 fastboot kit (kernel: `external-and-mods/kernel-sm8350/build.sh`, see [redmagic6.md](redmagic6.md))
- `make-steamos-sm8650.sh --from-img IMG` starts from the root and home of a released card image instead of Valve's rootfs. It needs a `STEAMOS_ROOTFS` other than `$STEAMOS_WORK/rootfs`, takes gamescope from the image unless `GAMESCOPE_BUILD` has a build, and records the base image's `IMAGE.txt` as `/opt/steamos-sm8650/RELEASE-BASE.txt`
- `TEST_KERNEL_OUT` puts a second kernel on BOOT as `TEST_KERNEL_NAME` (default `KERNEL-own`), for testers to swap in by renaming. Its modules must be in `KERNEL_OUT` too. `TEST_KERNEL_CMDLINE_EXTRA` is added to that kernel's cmdline only. On sm8550 it gets the cmdline of our own kernel; `TEST_SM8550_KERNEL=prebuilt` when the spare one is the prebuilt 7.0.14

Valve's files and the Steam client aren't in this repo, the build downloads them. How the pieces fit together is in [HOW-IT-WORKS.md](HOW-IT-WORKS.md).

## CI

`.github/workflows/build-sm8250.yml` builds the sm8250 kernel on GitHub's `ubuntu-24.04-arm` runners.

- A push to `pocket-micro-2` or `pm2-draft` that touches `external-and-mods/` (other than the other SoCs' kernels), the overlays, `scripts/`, `make-steamos-sm8650.sh` or the workflow runs it with the defaults. Manual runs (`workflow_dispatch`) only work once the file is on the default branch.
- `kernel`: fetches armada at the `ARMADA_REF` of `kernel-sm8250/soc.env` into `../armada-<ARMADA_REF>`, builds with `build-gcc15.sh` in armada's pinned Fedora image, checks the patch log, DTB, firmware and config, and uploads `kernel-sm8250` (kept 7 days) and `kernel-sm8250-log`. The step summary has the gcc version, the config `WARN` lines and the KERNEL size.
- `kernel-regression`: builds sm8650 at the base commit (`BASE_SHA`, v1.3.0) and at the head in one job, in the `kernel` job's pinned Fedora image, and fails if the config, DTBs, firmware, module list, KERNEL cmdline field, patched source or gcc version differ. Runs when `external-and-mods/kernel-common/` changed in the push, or with `regression`.

Inputs (manual runs):

| Input | Default | Use |
|---|---|---|
| `kernel_run_id` | empty | skip the kernel build and take `kernel-sm8250` from that run; artifacts expire after 7 days |
| `regression` | off | run `kernel-regression` |
