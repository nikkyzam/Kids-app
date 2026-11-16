#!/usr/bin/env python3
"""Add (or refresh) an iOS flavor for one app of the family.

    python3 tool/add_ios_flavor.py --id soundsteps \\
        --bundle-id com.nikkyzam.soundsteps.app --name SoundSteps \\
        --icon docs/soundsteps_icon_1024.png

Flutter's `--flavor <id>` on iOS needs a scheme named <id> and build
configurations Debug-<id>, Release-<id> and Profile-<id>. This script makes
them by copying the existing Debug/Release/Profile configurations (so every
build setting, xcconfig and CocoaPods hook stays identical) and then setting,
on the app target only: the bundle ID, the home-screen name (via
APP_DISPLAY_NAME, which Info.plist reads) and the app icon set. It also adds
the configurations to the Podfile and, with --icon, generates the icon set.

Idempotent: re-running updates what is there and adds nothing twice. Plain
`flutter build ios` (no flavor) keeps using the original configurations.
Run without Xcode; a macOS CI build is the check that the result is valid.
"""
import argparse
import hashlib
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
IOS = os.path.join(ROOT, "ios")
PBXPROJ = os.path.join(IOS, "Runner.xcodeproj", "project.pbxproj")
SCHEMES = os.path.join(IOS, "Runner.xcodeproj", "xcshareddata", "xcschemes")
PODFILE = os.path.join(IOS, "Podfile")
INFO_PLIST = os.path.join(IOS, "Runner", "Info.plist")
ASSETS = os.path.join(IOS, "Runner", "Assets.xcassets")
MODES = {"Debug": "debug", "Release": "release", "Profile": "release"}

BLOCK = re.compile(
    r"\t\t(?P<id>[0-9A-F]{24}) /\* (?P<name>[^*]+?) \*/ = \{\n"
    r"\t\t\tisa = XCBuildConfiguration;\n.*?\n\t\t\};\n",
    re.S,
)
LIST = re.compile(
    r"(\t\t[0-9A-F]{24} /\* Build configuration list for [^*]+\*/ = \{\n"
    r"\t\t\tisa = XCConfigurationList;\n\t\t\tbuildConfigurations = \(\n)"
    r"(?P<items>.*?)(\t\t\t\);)",
    re.S,
)
ITEM = re.compile(r"\t\t\t\t(?P<id>[0-9A-F]{24}) /\* (?P<name>[^*]+?) \*/,\n")


def new_id(*parts):
    return hashlib.md5("|".join(parts).encode()).hexdigest()[:24].upper()


def set_setting(block, key, value):
    """Set `key = value;` inside a block's buildSettings, adding it if absent."""
    line = re.compile(r"(\t\t\t\t%s = )[^;]*;" % re.escape(key))
    if line.search(block):
        return line.sub(lambda m: m.group(1) + value + ";", block, count=1)
    return block.replace(
        "\t\t\tbuildSettings = {\n",
        "\t\t\tbuildSettings = {\n\t\t\t\t%s = %s;\n" % (key, value),
        1,
    )


def is_app_target(block):
    return "INFOPLIST_FILE = Runner/Info.plist;" in block


def is_test_target(block):
    return "RunnerTests;" in block and "TEST_HOST" in block


def configure(block, a):
    if is_app_target(block):
        block = set_setting(block, "PRODUCT_BUNDLE_IDENTIFIER", a.bundle_id)
        block = set_setting(block, "APP_DISPLAY_NAME", '"%s"' % a.name)
        block = set_setting(block, "ASSETCATALOG_COMPILER_APPICON_NAME", a.icon_set)
    elif is_test_target(block):
        block = set_setting(block, "PRODUCT_BUNDLE_IDENTIFIER", a.bundle_id + ".RunnerTests")
    return block


def update_pbxproj(a):
    text = open(PBXPROJ).read()
    blocks = {m.group("id"): m.group(0) for m in BLOCK.finditer(text)}

    # The original (unflavored) app configs must define APP_DISPLAY_NAME too,
    # now that Info.plist reads it: keep whatever name they show today.
    current_name = re.search(
        r"<key>CFBundleDisplayName</key>\s*<string>([^<]*)</string>", open(INFO_PLIST).read()
    ).group(1)
    for bid, block in list(blocks.items()):
        if is_app_target(block) and "APP_DISPLAY_NAME" not in block and not current_name.startswith("$("):
            updated = set_setting(block, "APP_DISPLAY_NAME", '"%s"' % current_name)
            text = text.replace(block, updated)
            blocks[bid] = updated

    added = []

    def rewrite_list(m):
        items = {i.group("name"): i.group("id") for i in ITEM.finditer(m.group("items"))}
        new_items = m.group("items")
        for base in MODES:
            name = "%s-%s" % (base, a.id)
            src = blocks[items[base]]
            if name in items:  # refresh the existing copy
                bid = items[name]
                fresh = configure(src.replace(items[base], bid, 1).replace(
                    "/* %s */" % base, "/* %s */" % name, 1).replace(
                    "\t\t\tname = %s;" % base, "\t\t\tname = %s;" % name), a)
                added.append(("replace", blocks[bid], fresh))
            else:
                bid = new_id(m.group(1), name)
                copy = src.replace(items[base], bid, 1).replace(
                    "/* %s */" % base, "/* %s */" % name, 1).replace(
                    "\t\t\tname = %s;" % base, "\t\t\tname = %s;" % name)
                added.append(("add", None, configure(copy, a)))
                new_items += "\t\t\t\t%s /* %s */,\n" % (bid, name)
        return m.group(1) + new_items + m.group(3)

    text = LIST.sub(rewrite_list, text)
    end = "/* End XCBuildConfiguration section */"
    for kind, old, block in added:
        if kind == "replace":
            text = text.replace(old, block)
        else:
            text = text.replace(end, block + end, 1)
    open(PBXPROJ, "w").write(text)


def update_info_plist():
    plist = open(INFO_PLIST).read()
    plist = re.sub(
        r"(<key>CFBundleDisplayName</key>\s*<string>)[^<]*(</string>)",
        r"\1$(APP_DISPLAY_NAME)\2",
        plist,
    )
    open(INFO_PLIST, "w").write(plist)


def write_scheme(a):
    src = open(os.path.join(SCHEMES, "Runner.xcscheme")).read()
    out = re.sub(
        r'buildConfiguration = "(Debug|Release|Profile)"',
        lambda m: 'buildConfiguration = "%s-%s"' % (m.group(1), a.id),
        src,
    )
    open(os.path.join(SCHEMES, "%s.xcscheme" % a.id), "w").write(out)


def update_podfile(a):
    pod = open(PODFILE).read()
    m = re.search(r"project 'Runner', \{\n(.*?)\n\}", pod, re.S)
    body = m.group(1)
    for base, mode in MODES.items():
        name = "%s-%s" % (base, a.id)
        if "'%s'" % name not in body:
            body += "\n  '%s' => :%s," % (name, mode)
    open(PODFILE, "w").write(pod[: m.start(1)] + body + pod[m.end(1):])


def write_icons(a):
    from PIL import Image

    src_set = os.path.join(ASSETS, "AppIcon.appiconset")
    dst_set = os.path.join(ASSETS, "%s.appiconset" % a.icon_set)
    os.makedirs(dst_set, exist_ok=True)
    contents = json.load(open(os.path.join(src_set, "Contents.json")))
    art = Image.open(a.icon).convert("RGB")  # App Store icons must not have alpha
    for img in contents["images"]:
        points = float(img["size"].split("x")[0])
        px = round(points * float(img["scale"].rstrip("x")))
        art.resize((px, px), Image.LANCZOS).save(os.path.join(dst_set, img["filename"]))
    json.dump(contents, open(os.path.join(dst_set, "Contents.json"), "w"), indent=2)


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--id", required=True, help="flavor id, e.g. soundsteps")
    p.add_argument("--bundle-id", required=True)
    p.add_argument("--name", required=True, help="home-screen name")
    p.add_argument("--icon", help="1024x1024 PNG; omit to reuse the existing AppIcon set")
    a = p.parse_args()
    if not re.fullmatch(r"[a-z][a-z0-9]*", a.id):
        sys.exit("--id must be lowercase letters/digits, like the Android flavor")
    a.icon_set = "AppIcon-%s" % a.id if a.icon else "AppIcon"
    if a.icon:
        write_icons(a)
    update_pbxproj(a)
    update_info_plist()
    write_scheme(a)
    update_podfile(a)
    print("iOS flavor '%s' ready: scheme %s, configs Debug/Release/Profile-%s" % (a.id, a.id, a.id))


if __name__ == "__main__":
    main()
