#!/bin/bash
# Turn the built binary into a self-contained, ad-hoc-signed PulseView.app + .dmg + .zip (arm64).
set -e
WORKSPACE="${WORKSPACE:-$(cd "$(dirname "$0")/../.." && pwd)}"
PREFIX=$WORKSPACE/prefix
OUT="${OUT:-$WORKSPACE/dist}"
REL="${REL:-$WORKSPACE/release}"
VER="${VER:-0.5.0-git-$(git -C "$WORKSPACE/pulseview" rev-parse --short=7 HEAD)}"
HERE="$(cd "$(dirname "$0")" && pwd)"
export PATH="/opt/homebrew/bin:$PATH"
PYSRC="$(brew --prefix python@3.14)/Frameworks/Python.framework/Versions/3.14"
APP=$OUT/PulseView.app; C=$APP/Contents

rm -rf "$OUT" && mkdir -p $C/{MacOS,Frameworks,Resources} "$REL"
cp "$WORKSPACE/pulseview/build/pulseview" $C/MacOS/PulseView
sed "s/@VERSION@/$VER/" "$HERE/Info.plist.in" > $C/Info.plist
cp -R "$PREFIX/share/libsigrokdecode/decoders" $C/Resources/decoders

# 1. Qt + Homebrew/prefix libraries
DYLD_LIBRARY_PATH="$PREFIX/lib" "$(brew --prefix qt)/bin/macdeployqt" "$APP" -libpath="$PREFIX/lib" -libpath=/opt/homebrew/lib >/dev/null 2>&1 || true

# 2. Drop unneeded Qt image/input plugins and the libs only they used
cd $C/PlugIns
rm -f platforminputcontexts/libqtvirtualkeyboardplugin.dylib imageformats/libq{pdf,webp,tiff,mng,jp2,macheif,icns,ico,tga,wbmp}.dylib
rmdir platforminputcontexts 2>/dev/null || true
cd $C/Frameworks
rm -f libwebp.7.dylib libwebpdemux.2.dylib libwebpmux.3.dylib libsharpyuv.0.dylib libtiff.6.dylib libmng.2.dylib libjasper.7.dylib liblcms2.2.dylib

# 3. Trimmed Python runtime as a plain dylib + stdlib (a framework without Info.plist cannot be signed)
mkdir -p $C/Resources/python/lib
cp "$PYSRC/Python" $C/Frameworks/libpython3.14.dylib
rsync -a --exclude='__pycache__' --exclude='test' --exclude='tests' --exclude='idlelib' --exclude='tkinter' \
  --exclude='turtledemo' --exclude='turtle.py' --exclude='site-packages' --exclude='ensurepip' --exclude='lib2to3' \
  --exclude='config-*' --exclude='pydoc_data' --exclude='distutils' --exclude='venv' --exclude='sqlite3' \
  --exclude='unittest' --exclude='asyncio' --exclude='curses' --exclude='dbm' "$PYSRC/lib/python3.14" $C/Resources/python/lib/
mkdir -p $C/Resources/python/lib/python3.14/site-packages
for f in $C/Resources/python/lib/python3.14/lib-dynload/*.so; do   # drop extensions linking non-system libs
  otool -L "$f" | tail -n +2 | awk '{print $1}' | grep -qE '^/(opt|usr/local)' && rm -f "$f"
done
install_name_tool -id @executable_path/../Frameworks/libpython3.14.dylib $C/Frameworks/libpython3.14.dylib 2>/dev/null
install_name_tool -change "$PYSRC/Python" @executable_path/../Frameworks/libpython3.14.dylib $C/Frameworks/libsigrokdecode.4.dylib 2>/dev/null

# 4. Launcher script sets Python home and decoder path
mv $C/MacOS/PulseView $C/MacOS/pulseview-bin
cp "$HERE/launcher.sh" $C/MacOS/PulseView && chmod +x $C/MacOS/PulseView

# 5. Icon, licence, notice
T=$(mktemp -d)/pv.iconset; mkdir -p "$T"
qlmanage -t -s 1024 -o "$(dirname "$T")" "$WORKSPACE/pulseview/icons/pulseview.svg" >/dev/null 2>&1 || true
if [ -f "$(dirname "$T")/pulseview.svg.png" ]; then
  for s in 16 32 128 256 512; do
    sips -z $s $s "$(dirname "$T")/pulseview.svg.png" --out "$T/icon_${s}x${s}.png" >/dev/null
    sips -z $((s*2)) $((s*2)) "$(dirname "$T")/pulseview.svg.png" --out "$T/icon_${s}x${s}@2x.png" >/dev/null
  done
  iconutil -c icns "$T" -o $C/Resources/pulseview.icns
fi
cp "$WORKSPACE/pulseview/COPYING" $C/Resources/COPYING
cp "$HERE/NOTICE.txt" $C/Resources/NOTICE.txt

# 6. Ad-hoc sign every Mach-O inside-out, then frameworks, then the app
while IFS= read -r f; do file -b "$f" | grep -q Mach-O && codesign --force --sign - "$f" >/dev/null 2>&1; done \
  < <(find $C -type f ! -type l ! -path '*/MacOS/PulseView' ! -path '*.framework/*')
for fw in $C/Frameworks/*.framework; do codesign --force --sign - "$fw" >/dev/null 2>&1; done
codesign --force --sign - "$APP" >/dev/null 2>&1
codesign --verify --deep --strict "$APP" && echo "signature OK"

# 7. Package
STAGE=$(mktemp -d); cp -R "$APP" "$STAGE/"; ln -s /Applications "$STAGE/Applications"
rm -f "$REL/PulseView-$VER-macos-arm64".{dmg,zip}
hdiutil create -volname PulseView -srcfolder "$STAGE" -ov -format UDZO "$REL/PulseView-$VER-macos-arm64.dmg" >/dev/null
(cd "$OUT" && ditto -c -k --keepParent PulseView.app "$REL/PulseView-$VER-macos-arm64.zip")
shasum -a 256 "$REL"/PulseView-$VER-macos-arm64.*
