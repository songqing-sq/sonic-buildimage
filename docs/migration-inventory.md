# Bazel 迁移清单

跟踪当前 son629 仓库中已用 Bazel 复刻 Make 构建的模块与其产物。所有条目对应 `MODULE.bazel` 里的 `bazel_dep` + `local_path_override`，可直接 `bazel build @<name>//:<target>`。

## 每模块专项文档

以下每份文档均包含 son629 vs son624 的差异分析与实现细节：

| 模块 | 文档 |
|---|---|
| libnl3 | [libnl3-son624-diff.md](libnl3-son624-diff.md) |
| libyang3 | [libyang3-son624-diff.md](libyang3-son624-diff.md) |
| libyang3-py3 | [libyang3-py3-migration.md](libyang3-py3-migration.md) |
| sonic-yang-models / -mgmt | [sonic-yang-models-mgmt-migration.md](sonic-yang-models-mgmt-migration.md) |
| sonic-fib | [sonic-fib-migration.md](sonic-fib-migration.md)（son624 无此模块） |
| sonic-eventd | [sonic-eventd-migration.md](sonic-eventd-migration.md) |
| sonic-swss-common | [sonic-swss-common-son624-diff.md](sonic-swss-common-son624-diff.md) |
| sonic-supervisord-utilities-rs | [sonic-supervisord-utilities-rs-status.md](sonic-supervisord-utilities-rs-status.md)（son624 无；含[链接失败排查报告](sonic-supervisord-utilities-rs-link-fix-report.md)）|
| redis-dump-load-py3 | [redis-dump-load-py3-migration.md](redis-dump-load-py3-migration.md)（含 son624 漏 patch 的修正） |
| sonic-py-swsssdk | [sonic-py-swsssdk-migration.md](sonic-py-swsssdk-migration.md)（含 son624 加错 entry_points 的修正） |
| sonic-py-common / sonic-config-engine | [sonic-py-common-config-engine-migration.md](sonic-py-common-config-engine-migration.md)（含 son624 错误 exclude sonic_db_dump_load.py 的修正） |
| sonic-platform-common / sonic-utilities | [sonic-platform-common-utilities-migration.md](sonic-platform-common-utilities-migration.md)（严格照 son629 上游 setup.py，剔除 son624 downstream 加料）|
| sonic-host-services / sonic-containercfgd | [sonic-host-services-containercfgd-migration.md](sonic-host-services-containercfgd-migration.md)（son624 多余 deps 与 downstream 脚本差异）|
| sonic-supervisord-utilities | [sonic-supervisord-utilities-migration.md](sonic-supervisord-utilities-migration.md)（son624 用 py_binary+uv，son629 用 py_wheel 匹配 Make）|
| sonic-platform-daemons + system-health | [sonic-platform-daemons-system-health-migration.md](sonic-platform-daemons-system-health-migration.md)（11 个 daemon wheel 批量迁移）|
| lm-sensors | [lm-sensors-migration.md](lm-sensors-migration.md)（apt 重打包 + sensord 源码编译混合方法）|
| asyncsnmp | [asyncsnmp-migration.md](asyncsnmp-migration.md)（纯 Python wheel，`src/sonic-snmpagent`，find_packages('src') 布局）|
| bmp-watchdog | [bmp-watchdog-migration.md](bmp-watchdog-migration.md)（Rust binary，crate.from_cargo，无 C FFI）|
| sonic-mgmt-common | [sonic-mgmt-common-migration.md](sonic-mgmt-common-migration.md)（Go+YANG 混合包，ygot codegen + pyang + CVL schema，含 pyang 兼容 wrapper）|
| dhcprelay | [dhcprelay-migration.md](dhcprelay-migration.md)（dhcp6relay + dhcp4relay，含 PcapPlusPlus v24.09 静态链接 + patch）|
| gnmi-watchdog | Rust binary（`dockers/docker-gnmi-watchdog/watchdog`），仅 chrono 依赖，与 bmp-watchdog 同模式 |

Rust 相关基础设施：
- [sonic-rust-infrastructure.md](sonic-rust-infrastructure.md)：rules_rust 注册、libclang 闭包、crate_universe 集成

其它相关文档：
- [bazel-cross-link-root-cause.md](bazel-cross-link-root-cause.md)：Bazel 交叉链接架构根因
- [rules-distroless-merged-usr-fix.md](rules-distroless-merged-usr-fix.md)：rules_distroless merged-usr 兼容修复

## 平台层（`sonic_rules`）

Bazel 规则库（不产 deb / wheel），供各叶子模块使用：

- `sonic_shared_library_versioned` —— `.so` + `.so.<major>` + `.so.<full>` + `_dev_link_direct`（.so 直指全版本号）
- `sonic_deb` —— Debian 二进制包，支持 `${LIBDIR}` / `${LIBDIR_BASE}` 多 arch 占位、`gen_dbg=True` 自动生成 `-dbgsym` 副包
- `static_archive` —— 从 `cc_library` 抽 `.a`
- GCC toolchain —— f0rmiga 预编译 GCC 14.3.0（x86_64 + aarch64 交叉），trixie sysroot
- Python toolchain —— 3.13.4（默认，匹配 trixie 系统 Python）+ 3.11.3（备用）
- **Rust toolchain** —— rules_rust 0.61.0，Rust 1.86.0（root MODULE 注册），aarch64 extra target
- **libclang closure** —— 目前放在 `src/sonic-swss-common/bazel/`（模块内私有，因为仅 swss-common Rust crate 一个 bindgen 消费者；未来若有第 2 个消费者再抽到 sonic_rules 共享）

## 已迁移叶子模块

### libnl3（`src/libnl3`）

C 库，Netlink 家族，多 arch 路径已按 dpkg 惯例分 `${LIBDIR_BASE}`（runtime）与 `${LIBDIR}`（dev）。

| 类型 | 产物 |
|---|---|
| deb | `libnl-3-200_3.7.0-0.2+b1sonic1.deb` |
| deb | `libnl-3-dev_3.7.0-0.2+b1sonic1.deb` |
| deb | `libnl-genl-3-200_3.7.0-0.2+b1sonic1.deb` |
| deb | `libnl-genl-3-dev_3.7.0-0.2+b1sonic1.deb` |
| deb | `libnl-route-3-200_3.7.0-0.2+b1sonic1.deb` |
| deb | `libnl-route-3-dev_3.7.0-0.2+b1sonic1.deb` |
| deb | `libnl-nf-3-200_3.7.0-0.2+b1sonic1.deb` |
| deb | `libnl-nf-3-dev_3.7.0-0.2+b1sonic1.deb` |
| deb | `libnl-cli-3-200_3.7.0-0.2+b1sonic1.deb` |
| deb | `libnl-cli-3-dev_3.7.0-0.2+b1sonic1.deb` |
| deb (dbgsym) | 每个 runtime 包对应一个 `-dbgsym` |

### libyang3（`src/libyang3`）

YANG 解析 C 库 + 命令行工具。

| 类型 | 产物 |
|---|---|
| deb | `libyang3_3.12.2-1.deb` |
| deb | `libyang3-tools_3.12.2-1.deb` |
| deb | `libyang-dev_3.12.2-1.deb` |
| deb (dbgsym) | `libyang3-dbgsym_3.12.2-1.deb` |
| deb (dbgsym) | `libyang3-tools-dbgsym_3.12.2-1.deb` |

### libyang3-py3（`src/libyang3-py3`）

libyang 的 Python 3 绑定（C 扩展），产 wheel 与 deb。dh_python3 egg-info 已用 genrule 复刻。

| 类型 | 产物 |
|---|---|
| deb | `python3-libyang_3.1.0-1.deb` |

### sonic-yang-models（`src/sonic-yang-models`）

纯 Python，含全部 YANG 模型 `.yang` 与 244 个测试文件。

| 类型 | 产物 |
|---|---|
| py_wheel | `sonic_yang_models-1.0-py3-none-any.whl` |
| tar | `install`（docker 层，安装 py 文件到 dist-packages） |

### sonic-yang-mgmt（`src/sonic-yang-mgmt`）

配套 sonic_yang / sonic_yang_ext / sonic_yang_path 三个 Python 模块 + `sonic-cfg-help` 脚本。

| 类型 | 产物 |
|---|---|
| py_wheel | `sonic_yang_mgmt-1.0-py3-none-any.whl` |
| tar | `install`（docker 层） |

### sonic-fib（`src/libraries/sonic-fib`）

C++ 共享库 `libnexthopgroup`。

| 类型 | 产物 |
|---|---|
| deb | `libnexthopgroup_1.0.0.deb` |
| deb | `libnexthopgroup-dev_1.0.0.deb` |
| deb (dbgsym) | `libnexthopgroup-dbgsym_1.0.0.deb` |

### sonic-swss-common（`src/sonic-swss-common`）

SWSS 通用 C++ 库 + Python 3 SWIG 绑定 + `sonic-db-cli` 二进制。cfg_schema.h 由自研 Python 正则解析器动态生成，字节等价于 Make 的 gen_cfg_schema.py。

| 类型 | 产物 |
|---|---|
| deb | `libswsscommon_1.0.0.deb` |
| deb | `libswsscommon-dev_1.0.0.deb` |
| deb | `python3-swsscommon_1.0.0.deb` |
| deb | `sonic-db-cli_1.0.0.deb` |
| deb (dbgsym) | `libswsscommon-dbgsym_1.0.0.deb` |
| deb (dbgsym) | `python3-swsscommon-dbgsym_1.0.0.deb` |
| deb (dbgsym) | `sonic-db-cli-dbgsym_1.0.0.deb` |

### sonic-eventd（`src/sonic-eventd`）

C++ 事件服务：eventd 主进程 + eventdb 事件持久化 + events_tool + rsyslog_plugin。

| 类型 | 产物 |
|---|---|
| deb | `sonic-eventd_1.0.0-0.deb` |
| deb | `sonic-rsyslog-plugin_1.0.0-0.deb` |
| deb (dbgsym) | `sonic-eventd-dbgsym_1.0.0-0.deb` |
| deb (dbgsym) | `sonic-rsyslog-plugin-dbgsym_1.0.0-0.deb` |

son624 有较早的 Bazel 迁移（缺 eventdb、缺数据文件、缺 Depends），son629 补齐并对齐 Make dpkg-shlibdeps 输出。

### sonic-supervisord-utilities-rs（`src/sonic-supervisord-utilities-rs`）—— **完成**

Rust 项目，用作 supervisord 进程退出监听器。son624 无此模块。

| 类型 | 产物 |
|---|---|
| rust_library | `:sonic_supervisord_utilities_rs_lib` |
| rust_binary | `:supervisor-proc-exit-listener-rs`（含 `experimental_use_cc_common_link = 1` 修复链接）|
| deb | `sonic-supervisord-utilities-rs_1.0.0.deb` |

包含 Bazel 首个成功的 Rust binary + swss-common Rust FFI 链接示范。详细状态与决策：[`sonic-supervisord-utilities-rs-status.md`](sonic-supervisord-utilities-rs-status.md)。链接失败排查过程与根因分析：[`sonic-supervisord-utilities-rs-link-fix-report.md`](sonic-supervisord-utilities-rs-link-fix-report.md)。

### redis-dump-load-py3（`src/redis-dump-load`）

纯 Python wheel（`SONIC_PYTHON_WHEELS`）。用于 SONiC warm-restart 时的 Redis 状态转储。

| 类型 | 产物 |
|---|---|
| py_wheel | `redis_dump_load-1.1-py3-none-any.whl` |
| tar | `install`（OCI 层：`/usr/lib/python3/dist-packages/redisdl.py` + `/usr/local/bin/redis-{load,dump}` + doc）|

关键点：**修正了 son624 遗漏的上游 patch 0001**（`Use-pipelines-when-dumping-52.patch` 是源码 patch，直接影响 `redisdl.py` 运行时行为）。详细：[`redis-dump-load-py3-migration.md`](redis-dump-load-py3-migration.md)。

### sonic-py-swsssdk（`src/sonic-py-swsssdk`）

纯 Python wheel（`SONIC_PYTHON_WHEELS`）。SONiC Switch State Service 的 Python utility library（ConfigDBConnector / SonicV2Connector / sonic_db_dump_load 等），是几乎所有 SONiC 服务的基础依赖。

| 类型 | 产物 |
|---|---|
| py_wheel | `swsssdk-2.0.1-py3-none-any.whl` |
| tar | `install`（OCI 层：`/usr/lib/python3/dist-packages/swsssdk/` + `swsssdk/config/database_config.json`）|
关键点：son629 上游 setup.py `entry_points={}` 空——**son624 BUILD 却加了 `sonic-db-load` / `sonic-db-dump` console_scripts**（与 setup.py 不匹配、与 Make wheel 不一致）。son629 严格照 Make 输出，不加 entry_points。详细：[`sonic-py-swsssdk-migration.md`](sonic-py-swsssdk-migration.md)。

### sonic-py-common（`src/sonic-py-common`）

纯 Python wheel。SONiC 基础库：daemon 基类、设备信息、日志、多 ASIC 支持等。

| 类型 | 产物 |
|---|---|
| py_wheel | `sonic_py_common-1.0-py3-none-any.whl` |
| tar | `install`（OCI 层：14 个 `.py` + 2 个 console-script shim）|

关键点：**修正 son624 错误的 `exclude sonic_db_dump_load.py`**（Make wheel 包含该文件，son624 漏了）。详细：[`sonic-py-common-config-engine-migration.md`](sonic-py-common-config-engine-migration.md)。

### sonic-config-engine（`src/sonic-config-engine`）

纯 Python wheel。SONiC 配置生成器（`sonic-cfggen`），依赖 sonic-py-common + sonic-yang-mgmt/models。

| 类型 | 产物 |
|---|---|
| py_wheel | `sonic_config_engine-1.0-py3-none-any.whl` |
| tar | `install`（OCI 层：7 个顶层 `.py` + `sonic-cfggen` script + 3 个 `.j2` 模板）|

### sonic-platform-common（`src/sonic-platform-common`）

纯 Python wheel。SONiC 硬件平台抽象层：EEPROM、SFP/QSFP transceiver、fan、PSU、thermal 等 API。50+ 子包共 200 个文件。

| 类型 | 产物 |
|---|---|
| py_wheel | `sonic_platform_common-1.0-py3-none-any.whl` |
| tar | `install`（OCI 层：全部包铺到 `/usr/lib/python3/dist-packages/`）|

关键点：**不含 son624 downstream 的 `sonic_fwmgr` 包**（son629 上游 setup.py 未声明）。详细：[`sonic-platform-common-utilities-migration.md`](sonic-platform-common-utilities-migration.md)。

### sonic-utilities（`src/sonic-utilities`）

纯 Python wheel。SONiC 命令行工具集：`config`, `show`, `sfputil`, `fwutil`, `pcieutil`, `sonic-installer`, `sonic-package-manager` 等 31 个 console_scripts + 91 个 shell/python scripts + 33 个 Python 顶层包 = **1059 个文件**。

| 类型 | 产物 |
|---|---|
| py_wheel | `sonic_utilities-1.2-py3-none-any.whl`（含 91 scripts + 31 entry_points + 200+ tests 数据） |

关键点：**严格按 son629 上游 setup.py**，不引入 son624 downstream fork 独有的 5 个包（platformspec/serial/switch/switch/minigraph_tool/swsssdkV2）和 23 个额外 scripts。文件清单与 Make wheel **1059=1059 完全一致**。

### sonic-host-services（`src/sonic-host-services`）

纯 Python wheel。SONiC 主机端 D-Bus 服务模块集（config_engine, docker_service, file_service, gcu, host_service, image_service, reboot, showtech, systemd_service）+ utils。

| 类型 | 产物 |
|---|---|
| py_wheel | `sonic_host_services-1.0-py3-none-any.whl`（2 packages + 11 scripts） |
| tar | `install`（OCI 层：host_modules/ + utils/ + scripts → /usr/local/bin/） |

关键点：son629 含 `gnoi_shutdown_daemon.py` + `console-monitor`（son624 缺）；son629 不引入 son624 多余的 sonic-py-common / sonic-utilities wheel 依赖（运行时由容器提供）。

### sonic-containercfgd（`src/sonic-containercfgd`）

纯 Python wheel。SONiC 容器配置守护进程，仅 2 个 .py + 1 个 console_script。

| 类型 | 产物 |
|---|---|
| py_wheel | `sonic_containercfgd-1.0-py3-none-any.whl`（containercfgd + tests 包） |
| tar | `install`（OCI 层：containercfgd/ + /usr/local/bin/containercfgd script） |

关键点：son624 不含 `tests/` 包（son629 setup.py 明确声明 `packages=['containercfgd', 'tests']`）。

### sonic-supervisord-utilities（`src/sonic-supervisord-utilities`）

纯 Python wheel。supervisord 进程退出监听器（Python 版本，区别于 `-rs` Rust 版本）。

| 类型 | 产物 |
|---|---|
| py_wheel | `sonic_supervisord_utilities-1.0-py3-none-any.whl`（仅 1 个 script，无 Python 包）|
| tar | `install`（OCI 层：`/usr/local/bin/supervisor-proc-exit-listener`）|

关键点：son624 用 `py_binary` + `uv` pip lockfile 方式（不产 wheel），son629 用 `py_wheel` 严格匹配 Make 产物。

### sonic-platform-daemons（`src/sonic-platform-daemons`）—— 11 个子包

pmon 容器内平台守护进程伞模块。各子 daemon 独立构建。

| 子包 | 产物 | 特点 |
|---|---|---|
| sonic-ledd | `sonic_ledd-1.1-py3-none-any.whl` | 仅 script |
| sonic-pcied | `sonic_pcied-1.0-py3-none-any.whl` | 仅 script |
| sonic-psud | `sonic_psud-1.0-py3-none-any.whl` | script + tests 包 |
| sonic-sensormond | `sonic_sensormond-1.0-py3-none-any.whl` | script + tests 包 |
| sonic-stormond | `sonic_stormond-1.0-py3-none-any.whl` | 仅 script |
| sonic-syseepromd | `sonic_syseepromd-1.0-py3-none-any.whl` | 仅 script |
| sonic-thermalctld | `sonic_thermalctld-1.0-py3-none-any.whl` | script + tests 包 |
| sonic-chassisd | `sonic_chassisd-1.0-py3-none-any.whl` | 2 scripts + tests 包 |
| sonic-bmcctld | `sonic_bmcctld-1.0-py3-none-any.whl` | script + tests 包 |
| sonic-xcvrd | `sonic_xcvrd-1.0-py3-none-any.whl` | find_packages + entry_point `xcvrd` |
| sonic-ycabled | `sonic_ycabled-1.0-py3-none-any.whl` | proto gen + entry_point `ycabled` |

关键点：son629 用 `glob()` 匹配文件（不含 son624 downstream 的 `pm_mgr.py` / `ccmis_alarm/`）；ycabled 需 protobuf + grpc（root MODULE 声明）。

### system-health（`src/system-health`）

纯 Python wheel。SONiC 系统健康检查守护进程。

| 类型 | 产物 |
|---|---|
| py_wheel | `system_health-1.0-py3-none-any.whl`（health_checker + tests 包 + healthd script）|
| tar | `install`（OCI 层）|

### lm-sensors（`src/lm-sensors`）

硬件监控栈基础库。**混合方法**：apt 重打包 3 个 + 源码编译 1 个（sensord）。

| deb | 方法 | 说明 |
|---|---|---|
| `lm-sensors_3.6.0-7.1_amd64.deb` | Approach A（apt） | 主命令：`sensors`, `sensors-detect` |
| `libsensors5_3.6.0-7.1_amd64.deb` | Approach A（apt） | `libsensors.so.5` 共享库 |
| `fancontrol_3.6.0-7.1_all.deb` | Approach A（apt） | 风扇控制脚本 |
| `sensord_3.6.0-7.1_amd64.deb` | **Approach B（源码编译）** | 硬件传感器日志守护进程 |

关键点：son624 因 bookworm apt 无 `sensord` 包选择跳过；son629 严格照 Make 产物，用 `cc_binary` 编 `prog/sensord/*.c`，链接 apt 的 `libsensors-dev` + `librrd-dev`。

### asyncsnmp（`src/sonic-snmpagent`）

纯 Python wheel。SONiC SNMP AgentX 实现（ax_interface 协议层 + sonic_ax_impl MIB 实现）。

| 类型 | 产物 |
|---|---|
| py_wheel | `asyncsnmp-2.1.0-py3-none-any.whl`（37 个 .py 文件，2 包 ax_interface + sonic_ax_impl）|
| tar | `install`（OCI 层）|

关键点：setup.py 用 `find_packages('src')` + `package_dir` 映射，Bazel 用 `glob(["src/**/*.py"])` + `strip_path_prefixes=["src/"]` 实现等价。son624 无此模块。

### sonic-mgmt-common（`src/sonic-mgmt-common`）

Go + YANG 混合包，产 2 个 deb。通过 gazelle + ygot + pyang 生成 Go bindings、YANG tree、CVL YIN schema。

| 类型 | 产物 |
|---|---|
| deb | `sonic-mgmt-common_1.0.0.deb`（YANG 模型 + CVL schema + cvl_cfg.json）|
| deb | `sonic-mgmt-common-codegen_1.0.0.deb`（ocbinds.go + tree dumps + build/yang 目录树）|

关键点：
- 用 `import_yang.py` genrule 做 YANG 文件预处理（去注释、格式标准化、port leafref 替换），产物与 Make **字节级一致**
- `generate_yin_wrapper.py` 解决 pyang 2.6 与 `generate_yin.py` 的 `LeafrefTypeSpec.path_spec` 兼容问题
- Go 依赖通过 gazelle `go_deps.from_file(go_mod)` + 6 个 `module_override` patch 管理
- son624 无 dhcp4relay、无 sonic-yang-models 导入、无 import_yang 预处理

### dhcprelay（`src/dhcprelay`）

DHCPv6 + DHCPv4 中继代理（C++17），依赖 sonic-swss-common + PcapPlusPlus。

| 类型 | 产物 |
|---|---|
| deb | `sonic-dhcp6relay_1.0.0-0.deb`（`/usr/sbin/dhcp6relay`）|
| deb | `sonic-dhcp4relay_1.0.0-0.deb`（`/usr/sbin/dhcp4relay`）|
| deb (dbgsym) | 各自对应 `-dbgsym` |

关键点：
- PcapPlusPlus v24.09 通过 `http_archive` 从 GitHub 拉取，自动应用 `DhcpLayer.h` patch（放宽 DHCP 源端口检查）
- dhcp4relay 只用 Packet++ 层类（DhcpLayer/EthLayer/IPv4Layer），PcapPlusPlus **全静态链接**进二进制
- 比 Make 版本更优：Make 留有 RUNPATH 指向开发路径，Bazel 完全 self-contained
- son624 只迁了 dhcp6relay，且源码路径和文件名不同（`configInterface` vs `config_interface`）

## 尚未迁移的产物类型

本会话覆盖的都是 `deb` / `py_wheel` / `tar`。以下类型 **尚未开工**：

- **docker image / OCI 镜像** —— 各 sonic-* 容器（swss, syncd, bgp, teamd 等）
- **kernel deb** —— Linux 内核树
- **initramfs / squashfs** —— 最终 SONiC 镜像
- **ONIE installer / .bin** —— 安装器封装

## 汇总

- 已迁移模块：**36 个完整**（libnl3, libyang3, libyang3-py3, sonic-yang-models, sonic-yang-mgmt, sonic-fib, sonic-swss-common, sonic-eventd, sonic-supervisord-utilities-rs, redis-dump-load-py3, sonic-py-swsssdk, sonic-py-common, sonic-config-engine, sonic-platform-common, sonic-utilities, sonic-host-services, sonic-containercfgd, sonic-supervisord-utilities, sonic-ledd, sonic-pcied, sonic-psud, sonic-sensormond, sonic-stormond, sonic-syseepromd, sonic-thermalctld, sonic-chassisd, sonic-bmcctld, sonic-xcvrd, sonic-ycabled, system-health, lm-sensors, asyncsnmp, bmp-watchdog, gnmi-watchdog, **sonic-mgmt-common**, **dhcprelay**）
- 产出 deb 总数：**~45 个**（含 dbgsym；lm-sensors 家族 +4；sonic-mgmt-common +2；dhcprelay +4）
- 产出 wheel：**24 个**
- 新增 Rust 基础设施：rules_rust 1.86.0 toolchain（root MODULE 注册）+ swss-common 模块私有的 libclang 闭包（`src/sonic-swss-common/bazel/`）+ swss-common Rust crate + supervisord-rs Rust binary（`experimental_use_cc_common_link = 1` 打通 rust_binary × cc_library 链接）
- 平台层规则改动：`sonic_deb`（LIBDIR_BASE、dbgsym build-id 修复）、`shared_library`（`_dev_link_direct`）、toolchain（GCC 14.3.0 + Python 3.13.4）

所有 deb / wheel 均已与 Make 参考产物做 dpkg-deb 级别的元数据 + 文件清单比对；`.so` 做过 `objdump -T` 动态符号表比对。剩余差异集中在：
1. libstdc++ 模板实例化符号集（GCC prebuilt vs Debian-patched，无法根除）
2. Bazel 传递 DT_NEEDED 比 Make 多（可选加 `-Wl,--as-needed` 消除）
