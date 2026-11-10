#!/usr/bin/env python3
"""
把 ThreadsPulse 注入「已解密」的 Threads IPA。

做的事：
  1. 解開 IPA
  2. ThreadsPulse.dylib → Threads.app/Frameworks/
     ThreadsPulse.bundle → Threads.app/
  3. 在 Threads 主程式加入一個 LC_LOAD_DYLIB 載入指令（@executable_path/Frameworks/ThreadsPulse.dylib）
  4. 選用：--no-plugins 移除所有延伸功能；--appex 加入延伸功能（例如「在 Threads 開啟」Safari 延伸功能）
  5. 重新壓成 IPA（未簽名，安裝時由簽名工具簽名）

ThreadsPulse 用 ObjC runtime 直接 hook，不需要 CydiaSubstrate / ElleKit。
只用 Python 標準函式庫與系統的 zip / unzip，不需要安裝其他套件。

用法：
  # sideload 版（證書簽名）：保留延伸功能，並加入 Safari 延伸功能
  python3 inject_ipa.py -i Threads.ipa -d ThreadsPulse.dylib -b ThreadsPulse.bundle \
      --appex OpenThreadsSafariExtension.appex -o 輸出.ipa
  # noplugins 版（SideStore / AltStore 免費帳號）：移除所有延伸功能
  python3 inject_ipa.py -i Threads.ipa -d ThreadsPulse.dylib -b ThreadsPulse.bundle --no-plugins -o 輸出.ipa
"""
import argparse
import os
import plistlib
import shutil
import struct
import subprocess
import sys
import tempfile

DYLIB_LOAD_PATH = "@executable_path/Frameworks/ThreadsPulse.dylib"

MH_MAGIC_64 = 0xFEEDFACF
FAT_MAGIC = 0xCAFEBABE
FAT_MAGIC_64 = 0xCAFEBABF
LC_SEGMENT_64 = 0x19
LC_LOAD_DYLIB = 0x0C
LC_LOAD_WEAK_DYLIB = 0x80000018
LC_ENCRYPTION_INFO_64 = 0x2C
ZEROFILL_TYPES = (0x1, 0xC, 0x12)  # S_ZEROFILL, S_GB_ZEROFILL, S_THREAD_LOCAL_ZEROFILL：檔案裡沒有內容


def fail(msg):
    print(f"::error::{msg}" if os.environ.get("GITHUB_ACTIONS") else f"錯誤：{msg}", file=sys.stderr)
    sys.exit(1)


def patch_slice(buf, off, load_path):
    """在 off 開始的 64 位元 Mach-O 加入載入指令；已經有就略過。回傳是否有修改。"""
    if struct.unpack_from("<I", buf, off)[0] != MH_MAGIC_64:
        fail("只支援 64 位元（arm64）的執行檔")
    ncmds, sizeofcmds = struct.unpack_from("<II", buf, off + 16)
    header_size = 32
    p = off + header_size
    first_data = None   # 第一個有實際內容的 section 位置：載入指令區最多只能延伸到這裡
    for _ in range(ncmds):
        cmd, cmdsize = struct.unpack_from("<II", buf, p)
        if cmd in (LC_LOAD_DYLIB, LC_LOAD_WEAK_DYLIB):
            name_off = struct.unpack_from("<I", buf, p + 8)[0]
            name = bytes(buf[p + name_off:p + cmdsize]).split(b"\0")[0].decode(errors="replace")
            if name == load_path:
                return False
        elif cmd == LC_ENCRYPTION_INFO_64:
            cryptid = struct.unpack_from("<I", buf, p + 16)[0]
            if cryptid != 0:
                fail("這個 IPA 尚未解密（App Store 加密），請改用已解密的 Threads IPA")
        elif cmd == LC_SEGMENT_64:
            nsects = struct.unpack_from("<I", buf, p + 64)[0]
            for i in range(nsects):
                s = p + 72 + i * 80
                sec_off = struct.unpack_from("<I", buf, s + 48)[0]
                sec_type = struct.unpack_from("<I", buf, s + 64)[0] & 0xFF
                if sec_off and sec_type not in ZEROFILL_TYPES:
                    first_data = sec_off if first_data is None else min(first_data, sec_off)
        p += cmdsize

    name = load_path.encode() + b"\0"
    size = (24 + len(name) + 7) & ~7          # dylib_command 24 bytes + 路徑，8 bytes 對齊
    end = off + header_size + sizeofcmds
    if first_data is None:
        fail("找不到程式內容的位置，無法判斷可用空間")
    if end + size > off + first_data:
        fail(f"執行檔的 header 空間不足（需要 {size} bytes）")
    if any(buf[end:end + size]):
        fail("執行檔 header 後方不是空白，無法安全插入")

    command = struct.pack("<IIIIII", LC_LOAD_DYLIB, size, 24, 2, 0x10000, 0x10000) + name
    buf[end:end + size] = command + b"\0" * (size - len(command))
    struct.pack_into("<II", buf, off + 16, ncmds + 1, sizeofcmds + size)
    return True


def patch_binary(path, load_path):
    with open(path, "rb") as f:
        buf = bytearray(f.read())
    magic = struct.unpack_from(">I", buf, 0)[0]
    changed = False
    if magic in (FAT_MAGIC, FAT_MAGIC_64):
        nfat = struct.unpack_from(">I", buf, 4)[0]
        for i in range(nfat):
            if magic == FAT_MAGIC:
                _, _, offset, _, _ = struct.unpack_from(">iiIII", buf, 8 + i * 20)
            else:
                _, _, offset, _, _, _ = struct.unpack_from(">iiQQII", buf, 8 + i * 32)
            changed |= patch_slice(buf, offset, load_path)
    else:
        changed = patch_slice(buf, 0, load_path)
    if changed:
        with open(path, "wb") as f:
            f.write(buf)
    return changed


def main():
    ap = argparse.ArgumentParser(description="把 ThreadsPulse 注入已解密的 Threads IPA")
    ap.add_argument("-i", "--ipa", required=True, help="已解密的 Threads IPA")
    ap.add_argument("-d", "--dylib", required=True, help="ThreadsPulse.dylib")
    ap.add_argument("-b", "--bundle", required=True, help="ThreadsPulse.bundle 資料夾")
    ap.add_argument("-o", "--output", required=True, help="輸出的 IPA")
    ap.add_argument("--no-plugins", action="store_true",
                    help="移除所有延伸功能（小工具、分享等），給 SideStore / AltStore 免費帳號使用")
    ap.add_argument("--appex", action="append", default=[], metavar="PATH",
                    help="加入延伸功能（.appex 資料夾），可重複指定")
    ap.add_argument("--github-output", help="把 Threads 版本寫到這個檔案（GitHub Actions 用）")
    args = ap.parse_args()

    for tool in ("zip", "unzip"):
        if not shutil.which(tool):
            fail(f"找不到 {tool} 指令")

    work = tempfile.mkdtemp(prefix="tp-ipa-")
    try:
        # 用系統 unzip / zip，才會保留執行權限
        r = subprocess.run(["unzip", "-q", os.path.abspath(args.ipa), "-d", work])
        if r.returncode not in (0, 1):
            fail("IPA 解壓縮失敗，檔案可能不是 IPA")
        payload = os.path.join(work, "Payload")
        apps = [d for d in os.listdir(payload) if d.endswith(".app")] if os.path.isdir(payload) else []
        if len(apps) != 1:
            fail("IPA 裡找不到 Payload/*.app")
        app = os.path.join(payload, apps[0])

        with open(os.path.join(app, "Info.plist"), "rb") as f:
            info = plistlib.load(f)
        bundle_id = info.get("CFBundleIdentifier", "")
        threads_version = info.get("CFBundleShortVersionString", "unknown")
        if bundle_id != "com.burbn.barcelona":
            print(f"::warning::這個 IPA 的 Bundle ID 是 {bundle_id}，不是 Threads（com.burbn.barcelona）")
        print(f"Threads {threads_version}（{bundle_id}）")

        # 1) 放入 dylib 與語系 bundle
        frameworks = os.path.join(app, "Frameworks")
        os.makedirs(frameworks, exist_ok=True)
        shutil.copy2(args.dylib, os.path.join(frameworks, "ThreadsPulse.dylib"))
        dst_bundle = os.path.join(app, "ThreadsPulse.bundle")
        shutil.rmtree(dst_bundle, ignore_errors=True)
        shutil.copytree(args.bundle, dst_bundle)

        # 2) 主程式加入載入指令
        exe = os.path.join(app, info["CFBundleExecutable"])
        if patch_binary(exe, DYLIB_LOAD_PATH):
            print(f"已加入載入指令：{DYLIB_LOAD_PATH}")
        else:
            print("主程式已經有 ThreadsPulse 的載入指令，略過")

        # 3) 延伸功能：noplugins 全部移除；否則加入指定的 .appex
        if args.no_plugins:
            if args.appex:
                fail("--no-plugins 與 --appex 不能同時使用")
            for sub in ("PlugIns", "Extensions", "Watch"):
                shutil.rmtree(os.path.join(app, sub), ignore_errors=True)
            print("已移除所有延伸功能（noplugins）")
        for appex in args.appex:
            appex = appex.rstrip("/")
            if not appex.endswith(".appex") or not os.path.isfile(os.path.join(appex, "Info.plist")):
                fail(f"不是有效的延伸功能：{appex}")
            plugins = os.path.join(app, "PlugIns")
            os.makedirs(plugins, exist_ok=True)
            dst = os.path.join(plugins, os.path.basename(appex))
            shutil.rmtree(dst, ignore_errors=True)
            shutil.copytree(appex, dst, symlinks=True)
            # 帶有別人簽名資料的檔案不要放進去，安裝時由簽名工具重新簽名
            for junk in ("embedded.mobileprovision", "_CodeSignature"):
                path = os.path.join(dst, junk)
                if os.path.isdir(path): shutil.rmtree(path)
                elif os.path.exists(path): os.remove(path)
            print(f"已加入延伸功能：{os.path.basename(appex)}")

        # 4) 重新壓成 IPA
        out = os.path.abspath(args.output)
        if os.path.exists(out):
            os.remove(out)
        subprocess.run(["zip", "-qry", out, "Payload"], cwd=work, check=True)
        print(f"完成：{out}")

        if args.github_output:
            with open(args.github_output, "a") as f:
                f.write(f"threads_version={threads_version}\n")
    finally:
        shutil.rmtree(work, ignore_errors=True)


if __name__ == "__main__":
    main()
