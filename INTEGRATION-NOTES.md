# BBSC - open pull requests reviewed and integrated (2026-10-28)

Base: `origin/main` = `4f11faf` "BBSC 0.0.2". All 25 PR heads of `CLSAMG22/BBSC` were fetched
(`refs/pull/*/head`), diffed against their merge base, reviewed, and the ones that fix a real
reported issue were merged onto this tree. Nothing was run in the game; see "Verification" below.

## Applied

| PR | What it fixes | How it was applied |
|---|---|---|
| #39 | Join plate goes transparent for ~8 s between the summon load and the second reload | merged as-is (preferred over #33, same symptom, later fix) |
| #22 | Fall deaths after a respawn at a far lamp / a join beside the host (fall guard, respawn beside the survivor) | merged as-is |
| #9 | Wipe handling: guest reload goes to the host not its own lamp, guest echoes come back when the host takes its stain, one wipe reload per repeat death, stale boss bar after a load, host's boss bar counts as a boss-fight death for the guest | merged as-is (contains #17's fix plus its regression fix) |
| #14 | False boss clear on a guest following the host; poison/toxic and half HP after a revive in place; SpEffect 2 (dead) left on after a revive | merged; **hand edit**: the 30 s "boss clear probe" only logs SpEffect 4680 now, it no longer strips it (the PR itself calls that a guess) |
| #10 | Guest cannot pick up items / use ladders after a boss kill (its own slot was marked "leaving") | written against 0.0.1 and conflicted; the four hunks were placed by hand at the right anchors |
| #23 | Host does not draw a re-inserted guest (opacity 0 after a wipe) | merged as-is |
| #24 | Guest falls through the Dream floor at a summon when the Dream flags differ a lot - one extra reload | merged as-is |
| #27 | Guest walked into a host map that never got the host's flags (doors shut, boss "Prey Slaughtered") - one catch-up reload | merged as-is |
| #31 | Guest's bloodstain placed at the forced summon spot instead of where it died | merged; one log line that both #9 and #31 had edited was reconciled by hand |
| #42 | Ludwig's exit fog wall stays shut in a kept session after the kill | merged; **hand edit**: the tick only acts while map m34 is resident (the PR called the object switches after every load in every map) |
| #28 | Guest left in a hostless world when the host quits - goes home | merged; **hand edits**: timeout 45 s -> 90 s (the host is silent during its own loads), the follow packet must be from this session (the last packet time is never reset between sessions, a fresh join could have been sent home at once), and no exit while a host copy is still in the world |
| #13 | Host's first requests to its own server timed out when `host_overrides.json` names its own VPN address - the game now reaches its own server over 127.0.0.1 | merged as-is (mod DLL, `bbsc_http.cpp`) |
| #19 | Kin Bell / Bloodlust Bell greyed out ("not available in this area") after a boss | only commit `9c41d44` (the patch-table fix); the sign-logging commit was left out |
| #21 | "?ActionEventInfo?" shown instead of the leave / session texts | only commits `9463310` + `d730b87` (the text-id mapping hook); the four logging commits were left out |
| #29 | Free camera: controller ignored under BBport, L2/R2 still reach the character while the camera is on | merged as-is (mod DLL, `bbsc_mod.cpp`); **BBport-only path, risky** (patches the exe's SDL import table while the camera is on) - test with a controller |
| #38 (2 commits) | `69b28c2`: a phantom type left on the guest at home after a crashed respawn load (bells refuse). `f396a37`: after the wipe reload the guest sat at 0 HP for ~6 s waiting for the host's copy | cherry-picked; `f396a37` needed the revive-feature lines dropped from its context |

Two integration-only edits:
- `BbscBossClearHook`: with #14, a guest that spectates on the **host's** boss bar (new in #9) never
  gets `BlockClear2_1`, so nothing would release its spectate; the skip branch now sets
  `bbsc_boss_killed_ms` when the host's bar was recent, so the host's kill still gets it up.
- `docs/CHANGELOG.md` has a summary entry.

## Left out (and why)

| PR | Reason |
|---|---|
| #4 | Linux port + CI. Conflicts in all five mod files (0.0.2 rewrote them); no Windows benefit. One hunk may be worth a small PR later: keeping the URL's port/path in `Override()` for BBport's `online.py`. |
| #12 | THD message feature (server). Also: its `blood_exist` erases a host's stored messages even with the feature off. |
| #20 | Log upload. Logging only, and the server half calls `_relay_send` which no longer exists on 0.0.2 (would raise). |
| #26 | Communion Chalice - a new gameplay feature (also contains a `HYPOTHESIS` weapon-removal routine). |
| #38 | Revive feature (hold X to revive a fallen hunter) - new gameplay, six new code hooks. Only the two standalone fixes above were taken. |
| #33 | Same symptom as #39, earlier and with 1.5 s of pop-in; superseded. |
| #17 | Earlier version of #9's stale-bar fix that wiped Paarl's real bar; #9 has the corrected one. |
| #25 | 0.0.2 already fixes the "second reload keeps the phantom type" case differently (`new_load` via the transition-idle stamp); its first hunk would weaken the v6 path. |
| #11 | 0.0.2 already reads the kit tables from the param repository (`BbscGameParamTable`); the PR edits functions that no longer exist. |
| #32 | Sends the guest home to the nearest lamp / the Dream; 0.0.2 deliberately keeps "back home where we were" (`PutBbscHomeSpot`), which would overwrite it anyway. |

## Verification done here

- `emulator/src/core/bloodborne_re.cpp` passes `g++ -std=c++23 -fsyntax-only` in both flavours
  (emulator includes, and `-DBBSC_MOD` with `mod/shim`). No link, no run.
- `server/gameserver/bbsc_gameserver.py` is unchanged (compiles).
- The mod DLL files changed by #13 and #29 (`bbsc_http.cpp`, `bbsc_mod.cpp`, `bbsc_relay.cpp`)
  are Windows-only and were reviewed, not compiled. Build with `emulator/mod/build-mod.cmd`.
- Every added line of every applied PR was checked to be present in the merged tree (except the
  three deliberately dropped probe lines of #14).

## Building for BBport

On BBport all of BBSC runs in the mod DLL: `bbsc-launch.exe` stands in for `bb-probe.exe`, starts
it suspended and injects `bbsc.dll` (see `emulator/mod/bbsc_launch.cpp`). None of the applied PRs
touch `bbport/` (the BBport source patch), so `bb-probe.exe` from the BBSC 0.0.2 BBport package
stays as it is - only `bbsc.dll` has to be rebuilt.

- On a Windows PC: Visual Studio 2022 (any edition or Build Tools) with "Desktop development with
  C++" and "C++ Clang tools for Windows", then from the repository folder
  `git submodule update --init --depth 1 emulator/externals/fmt emulator/externals/xbyak` (not
  needed with the zip that already carries them) and `emulator\mod\build-mod.cmd`.
  Output: `build\mod\bbsc.dll` (or `%BBSC_OUT%`, or `D:\BBSC\build\mod` when `D:\BBSC` exists).
- On GitHub: push this tree to a repository of yours, Actions -> "Build BBSC mod" -> Run workflow,
  download the `bbsc-mod` artifact (`.github/workflows/build-mod.yml`).
- Install: put the new `bbsc.dll` over the old one in the BBport package (the folder holding
  `bbsc-launch.exe`). Back it up first.

`build-mod.cmd` was changed for this: Visual Studio is found with vswhere (any edition, not only
Community), clear messages when clang-cl or the submodules are missing, and the output folder no
longer has to be `D:\BBSC`. The compile and link lines are unchanged.

## Things to test first

1. Kin Bell in the Hunter's Dream after #19 (the bell now takes the vanilla Small Resonant branch).
2. A boss wipe with host + guest (#9, #14, #22, the two #38 fixes) - the most intertwined set.
3. Free camera with a controller under BBport (#29).
4. The host leaving mid-session (#28): the guest should go home ~90 s later, not during a host load.

## Files touched vs 0.0.2

```
INTEGRATION-NOTES.md                 (new)
.github/workflows/build-mod.yml      (new - Windows build of bbsc.dll)
emulator/mod/build-mod.cmd           (portable: vswhere, output folder)
docs/CHANGELOG.md                    (entry added)
emulator/mod/bbsc_http.cpp           (#13)
emulator/mod/bbsc_mod.cpp            (#29)
emulator/mod/bbsc_relay.cpp          (#9)
emulator/src/core/bbsc_patch_tables.h (#19)
emulator/src/core/bloodborne_re.cpp  (everything else)
emulator/src/core/bloodborne_re.h    (#9)
```

`bbsc-pr-integration.patch` (next to the zip) is the same set of changes as one `git diff` against
`4f11faf`, for applying onto a clone with `git apply`.
