# Known issues

## 8 Gen 3 (KONKR Pocket FIT, AYANEO Pocket S2)

- **Games flicker below 1080p** (picture jumps between full screen and the top-left corner). Fixed by the [v1.2.1 hotfix](https://github.com/hashtagbasit/SteamOS-ARM-Port/releases/tag/v1.2.1), and built into v1.3.

## 8 Gen 2 (beta)

- Nobody has booted this on real hardware yet, that's what the beta is for.
- No internal storage installer yet, SD card only.

## Snapdragon 865 (AYANEO Pocket MICRO 2)

- Wi-Fi stays on in standby.
- s2idle (`konkrctl sleep s2idle`) sleeps the CPUs but not the rest of the SoC. Standby is the default.
- USB charging negotiates 5 V only.
- The LC and RC front keys do nothing.
- The stick RGB LEDs are not driven, they keep their last state, also in sleep.
- Headset mic untested.
- The CPU runs its stock clocks on every power profile.
- No internal storage installer yet, SD card only.
- No USB debug shell at boot, `bootlog.txt` on the BOOT partition is the early boot log.
- `psci: [Firmware Bug]: failed to set PC mode: -3` at boot is harmless.

If something else breaks for you, [open an issue](https://github.com/hashtagbasit/SteamOS-ARM-Port/issues) and say which device you have.
