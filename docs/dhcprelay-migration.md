# dhcprelay Bazel 迁移报告

## 构建命令

```bash
bazel build @dhcprelay//:sonic-dhcp6relay_1.0.0-0.deb
bazel build @dhcprelay//:sonic-dhcp4relay_1.0.0-0.deb
```

## 新增文件清单

| 文件 | 作用 |
|------|------|
| `src/dhcprelay/MODULE.bazel` | 模块声明：SONiC 依赖 + apt 依赖 + PcapPlusPlus http_archive |
| `src/dhcprelay/BUILD.bazel` | 构建目标：dhcp6relay cc_binary + dhcp4relay cc_binary + 2 个 sonic_deb |
| `src/dhcprelay/pcapplusplus.BUILD` | PcapPlusPlus v24.09 的 Bazel BUILD：Common++/Packet++ 编译 + 头文件 prefix 映射 |
| `src/dhcprelay/dhcp4relay/patch/BUILD.bazel` | 暴露 PcapPlusPlus patch 文件给 http_archive 使用 |
| 根 `MODULE.bazel` 新增 | dhcprelay 注册（bazel_dep + local_path_override） |

## 与 son624 的 diff 及每处改动原因

### MODULE.bazel

| 改动 | son624 | son629 | 原因 |
|------|--------|--------|------|
| `rules_cc` 版本 | `0.2.8` | `0.2.16` | son629 根 MODULE 用 0.2.16 |
| `sonic-swss-common` 版本 | `0.0.0` | `1.0.0` | son629 的 swss-common MODULE.bazel 声明版本为 1.0.0 |
| `libyang` → `libyang3` | `libyang 1.0.73` | `libyang3 3.12.2` | son629 已从 libyang2 升级到 libyang3 |
| `platforms` 版本 | `1.0.0` | `1.1.0` | 与 son629 根 MODULE 保持一致 |
| apt suites | `bookworm` | `trixie` | son629 的 IMAGE_DISTRO 是 trixie |
| apt URI | `sonic-build.alibaba-inc.com`（内部镜像） | `deb.debian.org`（公开） | 合规要求，禁止使用内部 URL |
| boost 版本 | `1.74-dev` | `1.83-dev` | trixie 自带 boost 1.83 |
| **新增 PcapPlusPlus** | 无 | `http_archive(name="pcapplusplus")` | son624 没有 dhcp4relay；son629 需要 PcapPlusPlus 的 Packet++ 解析 DHCP 报文 |

### BUILD.bazel

| 改动 | son624 | son629 | 原因 |
|------|--------|--------|------|
| 新增 `cc_library` load | 无 | 有 | dhcp4relay 需要单独的 cc_library（后来简化后不再需要，但 load 保留无害） |
| 源文件命名 | `src/configInterface.cpp` | `dhcp6relay/src/config_interface.cpp` | son629 仓库重命名了文件（驼峰→下划线），且加了子目录层级 |
| includes | `["src"]` | `["dhcp6relay/src"]` | 对应源码路径变化 |
| `@libyang//:libyang_shared` | 是 | `@libyang3//:yang_shared` | libyang3 模块的 shared library target 名变了 |
| boost deps | `1.74-dev` | `1.83-dev` | trixie boost 版本 |
| **新增 dhcp4relay** | 无 | cc_binary + sonic_deb | son624 只迁了 dhcp6relay；son629 两个都迁 |
| dhcp4relay 依赖 PcapPlusPlus | 无 | `@pcapplusplus//:Common++`, `:Packet++`, `:pcapplusplus_hdrs` | dhcp4relay 使用 Packet++ 的 DhcpLayer/EthLayer 等类解析 DHCP 报文 |

## PcapPlusPlus 的处理方式

### Make 构建方式（`src/dhcprelay/dhcp4relay/Makefile`）

```makefile
# 1. wget 下载 PcapPlusPlus-24.09.tar.gz
# 2. sha256 校验
# 3. git init + stg import -s patch/series（应用 DhcpLayer.h 补丁）
# 4. cmake -S . -B build && cmake --build build
# 5. sudo cmake --install .（安装到系统 /usr/local/）
# 6. 编译 dhcp4relay 时 -L$(PCAPPLUSPLUS_DIR)/lib -lPcap++ -lPacket++ -lCommon++
```

Make 产出的 dhcp4relay 二进制有 **RUNPATH 指向开发路径** `/sonic/src/dhcprelay/dhcp4relay/PcapPlusPlus-24.09/lib`——这在 SONiC 镜像中运行时实际依赖 `sudo cmake --install` 的结果。

### Bazel 构建方式

```
http_archive(name="pcapplusplus")
  ├── 下载 v24.09 tarball (GitHub)
  ├── sha256 校验
  ├── 应用 patch/0001-dhcpv4-relay-accept-random-src-port.patch (-p1)
  └── build_file = "pcapplusplus.BUILD"
        ├── cc_library("Common++")  — 10 个 .cpp
        ├── cc_library("Packet++")  — 63 个 .cpp（依赖 Common++）
        ├── 3rdParty: EndianPortable, hash-library, json, LightPcapNg
        └── pcapplusplus_hdrs（include_prefix="pcapplusplus" 映射）
```

**dhcp4relay 只用 Packet++ 层类**（`DhcpLayer`, `EthLayer`, `IPv4Layer`, `Packet`, `PayloadLayer`, `UdpLayer`），不用 Pcap++ 的抓包功能。因此：
- 不编译 `Pcap++/src/*.cpp`
- 不需要 libpcap-dev
- PcapPlusPlus 完全**静态链接**进 dhcp4relay（比 Make 版本更 self-contained）

### Patch 说明

`dhcp4relay/patch/0001-dhcpv4-relay-accept-random-src-port.patch` 修改 `Packet++/header/DhcpLayer.h` 的 `isDhcpPorts()` 函数：

```diff
-   return (portSrc == 68 && portDst == 67) || (portSrc == 67 && portDst == 68);
+   return (portDst == 67) || (portDst == 68);
```

放宽 DHCP 源端口校验，接受使用随机临时端口的 DHCP 客户端。通过 `http_archive(patches=[...])` 在下载解压后自动应用。

## 与 Make 产物的对比

### sonic-dhcp6relay_1.0.0-0.deb

| 检查项 | 结果 |
|--------|------|
| 文件列表 | ✅ 一致（`/usr/sbin/dhcp6relay`） |
| control 字段 | 仅元数据差异（Installed-Size, sonic_deb 限制） |
| ELF NEEDED | Bazel 多列 transitive shared libs（`cc_binary + dynamic_deps` 已知行为，运行时等价） |
| 二进制大小 | Make ~50KB vs Bazel ~68KB |

### sonic-dhcp4relay_1.0.0-0.deb

| 检查项 | Make | Bazel |
|--------|------|-------|
| 文件列表 | ✅ `/usr/sbin/dhcp4relay` | ✅ 相同 |
| PcapPlusPlus 链接方式 | 动态依赖（RUNPATH 指向开发路径） | **静态嵌入**（更正确） |
| PcapPlusPlus 类符号 | 3 个字符串引用 | 290 个嵌入符号 |
| NEEDED libpcap | ❌ 无 | ❌ 无（正确，dhcp4relay 不抓包） |
| Patch 应用 | ✅ stg import | ✅ http_archive patches |
| 二进制大小 | 1.2MB | 1.6MB（静态嵌入 PcapPlusPlus 更大） |

**Bazel 版本更优**：Make 版本依赖 RUNPATH `/sonic/src/.../PcapPlusPlus-24.09/lib` 这个开发时路径在运行时存在（实际通过 docker 构建时的 `sudo cmake --install` 安装到系统），而 Bazel 版本把 PcapPlusPlus 完全静态编译进去，self-contained 无运行时路径依赖。

## pcapplusplus.BUILD 结构

```
pcapplusplus.BUILD
├── 3rdParty
│   ├── EndianPortable (header-only cc_library)
│   ├── json (header-only, nlohmann/json)
│   ├── hash-library (1 cpp: md5)
│   └── LightPcapNg (12 C files)
├── Common++ (10 cpp, 依赖 EndianPortable + json)
├── Packet++ (63 cpp, 依赖 Common++ + hash-library)
├── pcapplusplus_hdrs (3 个 include_prefix="pcapplusplus" cc_library 聚合)
│   ├── common_prefix_hdrs (Common++/header/*.h → <pcapplusplus/*.h>)
│   ├── packet_prefix_hdrs (Packet++/header/*.h → <pcapplusplus/*.h>)
│   └── pcap_prefix_hdrs (Pcap++/header/*.h → <pcapplusplus/*.h>)
└── Pcap++ srcs/headers (filegroup, 供需要抓包功能的模块用, dhcp4relay 不用)
```

`include_prefix="pcapplusplus"` + `strip_include_prefix="<Module>/header"` 让 dhcp4relay 代码中的 `#include <pcapplusplus/DhcpLayer.h>` 能正确解析到 `Packet++/header/DhcpLayer.h`，模拟 CMake `cmake --install` 将头文件装到 `/usr/include/pcapplusplus/` 的效果。
