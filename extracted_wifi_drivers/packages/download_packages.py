#!/usr/bin/env python3
"""
从 ImmortalWrt 软件源下载所有 WiFi 相关的 .apk 包
支持多源尝试、断点续传、并发下载
"""

import os
import re
import sys
import time
import requests
from concurrent.futures import ThreadPoolExecutor, as_completed
from urllib.parse import urljoin

# 软件源列表 (按优先级排序)
REPOS = [
    "https://downloads.immortalwrt.org/snapshots/targets/airoha/an7581/packages",
    "https://downloads.immortalwrt.org/snapshots/packages/aarch64_cortex-a53/base",
    "https://downloads.immortalwrt.org/snapshots/packages/aarch64_cortex-a53/airoha",
    "https://downloads.immortalwrt.org/snapshots/packages/aarch64_cortex-a53/pon_drivers",
    "https://downloads.immortalwrt.org/snapshots/packages/aarch64_cortex-a53/packages",
    "https://downloads.immortalwrt.org/snapshots/packages/aarch64_cortex-a53/luci",
    "https://downloads.immortalwrt.org/snapshots/packages/aarch64_cortex-a53/routing",
]

OUTPUT_DIR = os.path.dirname(os.path.abspath(__file__))
PACKAGE_LIST_FILE = os.path.join(OUTPUT_DIR, "full_package_list.txt")
FAILED_LOG = os.path.join(OUTPUT_DIR, "download_failed.txt")
SUCCESS_LOG = os.path.join(OUTPUT_DIR, "download_success.txt")

session = requests.Session()
session.headers.update({
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
})

def parse_package_list(filepath):
    """解析包列表文件，返回包名列表"""
    packages = []
    with open(filepath, 'r', encoding='utf-8') as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith('#'):
                packages.append(line)
    return packages

def try_download(package_name, repo_base):
    """尝试从单个源下载包"""
    # apk 文件通常在 packages/ 子目录或直接在 repo 下
    # 尝试多种可能的路径
    possible_paths = [
        f"{repo_base}/{package_name}.apk",
        f"{repo_base}/packages/{package_name}.apk",
    ]
    
    for url in possible_paths:
        try:
            # 先 HEAD 请求检查存在
            resp = session.head(url, timeout=10, allow_redirects=True)
            if resp.status_code == 200:
                # 下载文件
                local_path = os.path.join(OUTPUT_DIR, f"{package_name}.apk")
                
                # 断点续传支持
                headers = {}
                if os.path.exists(local_path):
                    downloaded = os.path.getsize(local_path)
                    headers['Range'] = f'bytes={downloaded}-'
                else:
                    downloaded = 0
                
                resp = session.get(url, headers=headers, timeout=30, stream=True)
                if resp.status_code in (200, 206):
                    mode = 'ab' if downloaded > 0 else 'wb'
                    total = downloaded + int(resp.headers.get('Content-Length', 0))
                    
                    with open(local_path, mode) as f:
                        for chunk in resp.iter_content(chunk_size=8192):
                            if chunk:
                                f.write(chunk)
                    
                    # 验证文件大小
                    final_size = os.path.getsize(local_path)
                    expected = int(resp.headers.get('Content-Length', 0)) + downloaded
                    if expected > 0 and final_size != expected:
                        print(f"  ⚠ Size mismatch: {package_name} ({final_size}/{expected})")
                    
                    return True, url
                elif resp.status_code == 416:  # Range not satisfiable - already complete
                    return True, url
        except requests.RequestException:
            continue
    return False, None

def download_package(package_name):
    """从多个源尝试下载单个包"""
    for repo in REPOS:
        success, url = try_download(package_name, repo)
        if success:
            return True, package_name, url
        time.sleep(0.1)  # 避免过快请求
    return False, package_name, None

def main():
    print("=" * 60)
    print("ImmortalWrt WiFi 离线包下载器")
    print("=" * 60)
    
    packages = parse_package_list(PACKAGE_LIST_FILE)
    print(f"发现 {len(packages)} 个包待下载")
    
    # 检查已下载
    existing = [f for f in os.listdir(OUTPUT_DIR) if f.endswith('.apk')]
    print(f"已存在 {len(existing)} 个 .apk 文件")
    
    # 过滤已下载
    to_download = []
    for pkg in packages:
        apk_file = f"{pkg}.apk"
        if apk_file not in existing:
            to_download.append(pkg)
    
    print(f"需要下载: {len(to_download)} 个包")
    
    if not to_download:
        print("所有包已下载完成！")
        return
    
    # 并发下载
    max_workers = 4
    success_count = 0
    failed = []
    
    with ThreadPoolExecutor(max_workers=max_workers) as executor:
        future_to_pkg = {executor.submit(download_package, pkg): pkg for pkg in to_download}
        
        for future in as_completed(future_to_pkg):
            success, pkg, url = future.result()
            if success:
                success_count += 1
                print(f"✓ [{success_count}/{len(to_download)}] {pkg} <- {url}")
                with open(SUCCESS_LOG, 'a') as f:
                    f.write(f"{pkg}\t{url}\n")
            else:
                failed.append(pkg)
                print(f"✗ FAILED: {pkg}")
                with open(FAILED_LOG, 'a') as f:
                    f.write(f"{pkg}\n")
    
    print("\n" + "=" * 60)
    print(f"下载完成: 成功 {success_count}, 失败 {len(failed)}")
    if failed:
        print(f"失败列表已保存至: {FAILED_LOG}")
        print("失败的包可手动从软件源网页下载")
    print("=" * 60)

if __name__ == '__main__':
    main()
