# PulseView for Apple Silicon (unofficial macOS arm64 build)

> This is a fork of [sigrokproject/pulseview](https://github.com/sigrokproject/pulseview). The original upstream README follows the macOS section, [below](#original-pulseview-readme-upstream-unmodified).

The [`macos-packaging/`](macos-packaging) directory contains the scripts used to build a
**self-contained `PulseView.app`** for Apple Silicon Macs. It is an **unmodified** build of upstream
[sigrok PulseView](https://sigrok.org/wiki/PulseView), repackaged. It is **not** an official
sigrok release and is not endorsed by the sigrok project.

Download the prebuilt `.dmg` / `.zip` from this repository's **Releases** page.

## Why this fork exists

Upstream PulseView does not offer a working download for Apple Silicon Macs, and the usual
routes failed when I tried them on an M1 MacBook:

- **The official nightly `pulseview-NIGHTLY-arm.dmg` crashes on launch.** The app is unsigned,
  and Apple Silicon kills unsigned code ("Code Signature Invalid"). Its `QtDBus.framework`
  was also packaged with copied files where symlinks should be, and several libraries
  (e.g. `libdbus`) are linked from `/opt/homebrew/...` instead of being bundled, so the app
  fails with "Library not loaded" on any Mac without the same Homebrew packages.
- **Homebrew has no PulseView formula**, and its `libsigrok` is built without the C++ bindings
  (`libsigrokcxx`) that PulseView needs. So PulseView cannot simply be built against Homebrew's
  libraries.

This fork keeps upstream's source unmodified and adds only the `macos-packaging/` scripts that
build `libsigrok` (with C++ bindings) and `libsigrokdecode`, build PulseView, and package a
self-contained, signed `PulseView.app`, so anyone with an Apple Silicon Mac can run it without
compiling anything. Keeping the build scripts next to the exact source also makes it
straightforward to meet the GPL's source-availability requirements for the binaries.

## Requirements (prebuilt app)

- Apple Silicon Mac (M1 or newer)
- **macOS 26 (Tahoe) or newer.** The app bundles Homebrew bottles that are built for macOS 26,
  so it will not run on older macOS. Supporting older versions would require compiling every
  dependency from source with a lower deployment target.

## Launching on an M-series MacBook

1. Download `PulseView-<version>-macos-arm64.dmg` from the **Releases** page of this repository.
2. Open the `.dmg` and drag **PulseView** into **Applications**.
3. The first launch will be blocked, because the app is **ad-hoc signed, not notarized** (no Apple
   Developer ID) and downloaded files are quarantined. Do **one** of these:
   - In Finder, right-click (or Control-click) `PulseView` in Applications, choose **Open**, then
     **Open** again in the dialog. If macOS only offers "Move to Trash", go to
     **System Settings -> Privacy & Security**, scroll down and click **Open Anyway**.
   - Or remove the quarantine flag in Terminal, then open it normally:
     ```
     xattr -cr /Applications/PulseView.app
     open /Applications/PulseView.app
     ```
4. After the first successful launch it opens like any other app (Launchpad, Spotlight, Dock).

Check the setup without any hardware: in PulseView pick the **Demo device** and press **Run**.

**If it does not start**, launch it from Terminal to see the error message:

```
/Applications/PulseView.app/Contents/MacOS/PulseView
```

(`-l 5` adds verbose sigrok logging.) Please include that output when reporting an issue.

## Known limitations

- Tested: the app launches in a clean environment, loads its own bundled libraries (none from
  `/opt/homebrew`), and initialises its bundled Python 3.14 runtime.
- Not tested: real logic-analyzer hardware, and each protocol decoder individually.
- The bundled Python is a trimmed standard library (no `ssl`, `sqlite3`, `tkinter`, `asyncio`, ...).
  The sigrok decoders only need basic modules.
- libsigrokdecode also searches a few build-time paths (e.g. `/opt/homebrew/lib/python3.14/site-packages`);
  they do not exist on most Macs and are harmless.

## Source for this build (GPL-3.0-or-later)

| Project | Commit |
|---|---|
| [pulseview](https://github.com/sigrokproject/pulseview) | `af02198741b4e57c9f9b796bd5e6c0f2ae9f2f2b` (this repo, unmodified) |
| [libsigrok](https://github.com/sigrokproject/libsigrok) | `0bc2487778e660f4d3116729b6f4aee2b1996bb0` |
| [libsigrokdecode](https://github.com/sigrokproject/libsigrokdecode) | `71f451443029322d57376214c330b518efd84f88` |

The only additions to upstream in this repo are the `macos-packaging/` directory and this
`README.md` (the upstream README is kept unchanged in the file `README`, and reproduced below). Bundled
third-party libraries (Qt 6 under LGPL-3.0, glib/glibmm/libsigc++ LGPL-2.1+, Boost, libusb,
libftdi, libserialport, hidapi, libzip, Python 3.14, ...) are dynamically linked and live in
`PulseView.app/Contents/Frameworks`; see `NOTICE.txt` inside the app.

## Rebuilding

Tools (Homebrew): `cmake boost qt glibmm@2.66 glib libzip libserialport libusb libftdi hidapi autoconf automake libtool pkgconf doxygen swig`.

Create a workspace directory containing three checkouts at the commits above:

```
workspace/
  pulseview/          <- this repo
  libsigrok/
  libsigrokdecode/
```

Then, from anywhere:

```
bash workspace/pulseview/macos-packaging/1-build-libs.sh      # libsigrok (+C++ bindings) and libsigrokdecode -> workspace/prefix
bash workspace/pulseview/macos-packaging/2-build-pulseview.sh # cmake + make
bash workspace/pulseview/macos-packaging/3-package-app.sh     # PulseView.app, .dmg, .zip -> workspace/release
```

Homebrew's own `libsigrok` has no C++ bindings (`libsigrokcxx`), which PulseView requires,
which is why `libsigrok` is built from source here.

## License

PulseView, libsigrok and libsigrokdecode are GPL-3.0-or-later; see `COPYING` in the repository
root. The scripts in this directory are provided under the same license.

---

## Original PulseView README (upstream, unmodified)

```text
-------------------------------------------------------------------------------
README
-------------------------------------------------------------------------------

The sigrok project aims at creating a portable, cross-platform,
Free/Libre/Open-Source signal analysis software suite that supports various
device types (such as logic analyzers, oscilloscopes, multimeters, and more).

PulseView is a Qt-based LA/scope/MSO GUI for sigrok.


Status
------

PulseView is in a usable state and has had official tarball releases.


Copyright and license
---------------------

PulseView is licensed under the terms of the GNU General Public License
(GPL), version 3 or later.

While some individual source code files are licensed under the GPLv2+, and
some files are licensed under the GPLv3+ or MIT, this doesn't change the fact
that the program as a whole is licensed under the terms of the GPLv3+ (e.g.
also due to the fact that it links against GPLv3+ libraries).

Please see the individual source files for the full list of copyright holders.


Copyright notices
-----------------

A copyright notice indicating a range of years, must be interpreted as having
had copyrightable material added in each of those years.

Example:

 Copyright (C) 2010-2013 Contributor Name

is to be interpreted as

 Copyright (C) 2010,2011,2012,2013 Contributor Name


Resource authors and licenses
-----------------------------

icons/application-exit.png,
icons/document-new.png,
icons/document-open.png,
icons/document-save-as.png,
icons/edit-paste.svg,
icons/help-browser.png,
icons/media-playback-pause.png,
icons/media-playback-start.png,
icons/preferences-system.png,
icons/search.svg,
icons/window-new.png,
icons/zoom-fit-best.png,
icons/zoom-in.png,
icons/zoom-out.png: Tango Icon Library
  http://tango.freedesktop.org/Tango_Desktop_Project
  License:
    Public Domain

icons/information.svg: Bobarino
  https://en.wikipedia.org/wiki/File:Information.svg
  License:
    GFDL 1.2 or later / CC-BY-SA 3.0
    https://en.wikipedia.org/wiki/File:Information.svg#Licensing

icons/add-math-channel.svg: Inductiveload
  https://en.wikipedia.org/wiki/File:Icon_Mathematical_Plot.svg
  License:
    Public Domain

QDarkStyleSheet: Colin Duquesnoy
  https://github.com/ColinDuquesnoy/QDarkStyleSheet
  License:
    CC-BY 4.0
    https://github.com/ColinDuquesnoy/QDarkStyleSheet/blob/master/LICENSE.md

DarkStyle: Juergen Skrotzky
  https://github.com/Jorgen-VikingGod/Qt-Frameless-Window-DarkStyle
  License:
    MIT license
    https://github.com/Jorgen-VikingGod/Qt-Frameless-Window-DarkStyle#licence

QHexView: Victor Anjin
  https://github.com/virinext/QHexView
  License:
    MIT license
    https://github.com/virinext/QHexView/blob/master/LICENSE

ExprTk: Arash Partow
  https://www.partow.net/programming/exprtk/index.html
  License:
    MIT license


Mailing list
------------

 https://lists.sourceforge.net/lists/listinfo/sigrok-devel


IRC
---

You can find the sigrok developers in the #sigrok IRC channel on Libera.Chat.


Website
-------

 http://sigrok.org/wiki/PulseView
```
