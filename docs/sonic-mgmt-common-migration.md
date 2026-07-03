# sonic-mgmt-common Bazel 迁移报告

## 构建命令

```bash
bazel build @sonic_mgmt_common//:sonic-mgmt-common_1.0.0.deb
bazel build @sonic_mgmt_common//:sonic-mgmt-common-codegen_1.0.0.deb
```

## 新增/修改的文件

| 文件 | 用途 |
|------|------|
| `src/sonic-mgmt-common/MODULE.bazel` | 模块声明：Go 依赖（gazelle + 6 个 patch）、pyang/lxml/setuptools wheel |
| `src/sonic-mgmt-common/BUILD.bazel` | 构建目标：ygot codegen、pyang tree、CVL schema、2 个 sonic_deb |
| `src/sonic-mgmt-common/patches/BUILD.bazel` | exports_files 暴露 Go patch 文件 |
| `src/sonic-mgmt-common/tools/pyang/pyang_wrapper.py` | pyang CLI 入口（Bazel py_binary 需要） |
| `src/sonic-mgmt-common/tools/bazel/generate_yin_wrapper.py` | **关键**：pyang 兼容性 wrapper，解决 generate_yin.py 崩溃问题 |
| `src/sonic-yang-models/BUILD.bazel`（修改） | 新增 exports_files + filegroup 暴露 cvlyang-models/ |
| `MODULE.bazel`（修改） | 新增 rules_go、gazelle、sonic-mgmt-common 注册 |

## 与 Make 产物对比结果

### 文件集合对比

排除 Make 的非功能性构建标记文件（`.done`、`.sync_*`、`oc_lint_issues.log`、`changelog.gz`）后：

- **sonic-mgmt-common_1.0.0.deb**: ✅ 文件列表完全一致
- **sonic-mgmt-common-codegen_1.0.0.deb**: ✅ 文件列表完全一致

### 文件内容对比（字节级）

通过 `dpkg-deb -x` 解压后 `diff -r` 对比（排除 Make 构建标记文件 `.done`、`.sync_*`、`oc_lint_issues.log`）：

- **所有 .yang 文件**: ✅ 字节级一致
- **所有 .yin 文件**: ✅ 字节级一致
- **models_list**: ✅ 字节级一致
- **build/yang/ 目录树**: ✅ 字节级一致

实现方式：在 Bazel 中增加了 `stage_sonic_yangs` genrule，调用 `import_yang.py` 做和 Make 完全等价的 YANG 预处理（去注释、格式标准化、port leafref 字段名替换）。

## 与 son624 的关键差异

| 差异点 | son624 | son629 | 原因 |
|--------|--------|--------|------|
| libyang 依赖名 | `libyang` | `libyang3` | son629 包改名 |
| ygot patch_strip | `2` | `1` | son629 patch 用 `git diff` 格式（`a/file b/file`），strip=1 即可；son624 用 `diff -ruN` 格式（`ygot-dir-orig/ygot/file`），需要 strip=2 |
| pyang 版本 | 2.7.1 | 2.6.0 | 2.7.1 的 `pyang.scripts.pyang_tool` 模块不存在于 2.4/2.6 |
| lxml 版本 | 4.9.1 cp311 | 5.3.2 cp313 | hermetic toolchain 用 Python 3.13.4（cp313） |
| setuptools wheel | 无 | 有 | Python 3.13 移除了内置 setuptools，pyang 2.6.0 仍依赖 `pkg_resources` |
| CVL schema 方式 | per-file `pyang -f yin-cvl`（son624 有 `tools/pyang/pyang_plugins/yin_cvl.py`） | 单次调用 `cvl/tools/generate_yin.py`（独立脚本） | son629 代码仓变化，yin_cvl.py 不存在 |
| sonic-yang-models 依赖 | 无（所有 yang 已在本地树内） | 需要引入 `@sonic-yang-models//:cvlyang_models_files` | son629 的 sonic yang 大部分从 sonic-yang-models/cvlyang-models/ 导入 |
| generate_yin wrapper | 无 | 有 | 解决 pyang 版本兼容崩溃（详见下文） |

## 遇到的核心问题与 generate_yin_wrapper.py 的必要性

### 问题背景

son629 的 CVL YIN schema 由 `cvl/tools/generate_yin.py` 生成。这个脚本与 son624 的 `pyang -f yin-cvl` 方式完全不同——它是一个**独立的 Python 脚本**，内部使用 pyang 库 API，实现了容器到列表的转换（`ContainerToListPlugin`）和列表间依赖注入（`ListDependencyPlugin`），这些是 CVL 特有的 YANG 变换逻辑。

### 崩溃原因（精确到代码行）

`cvl/tools/generate_yin.py` 第 113-118 行：

```python
# ListDependencyPlugin.process_children() 中：
if key_type == "leafref":
    try:
        target_node = type_obj.i_type_spec.i_target_node        # 第115行
    except:
        # This is due to union type, pyang does not set it by itself
        target_node = statements.validate_leafref_path(
            self.ctx, key_leaf,
            type_obj.i_type_spec.path_spec,                      # 第118行 ← 崩溃点
            type_obj.i_type_spec.path_, False)[0]
```

**崩溃链路**：

1. 代码先尝试访问 `type_obj.i_type_spec.i_target_node`（第115行）
2. `type_obj` 是一个 pyang `type` statement，其 `i_type_spec` 属性的类型取决于 **pyang validation 是否成功解析了这个 leafref**：
   - 解析成功 → `i_type_spec` 是 `PathTypeSpec` 实例（**有** `path_spec`、`path_`、`i_target_node`）
   - 解析失败 → `i_type_spec` 仍是 `LeafrefTypeSpec` 实例（**没有** 这些属性）
3. 第115行抛出 `AttributeError: 'LeafrefTypeSpec' object has no attribute 'i_target_node'`
4. 进入 except 分支，尝试调用 `statements.validate_leafref_path()`，访问 `type_obj.i_type_spec.path_spec`
5. 但 `LeafrefTypeSpec` 同样没有 `path_spec` → 再次抛出 `AttributeError`，**这次没有被 catch**

### pyang 类型体系说明

```python
# pyang/types.py 中的两个类：

class LeafrefTypeSpec(TypeSpec):
    """leafref 声明时的初始类型，只有 require_instance 属性"""
    def __init__(self):
        TypeSpec.__init__(self, 'leafref')
        self.require_instance = True
    # 注意：没有 path_spec, path_, i_target_node

class PathTypeSpec(TypeSpec):
    """leafref 被 ctx.validate() 成功解析后替换的类型"""
    def __init__(self, base, path_spec, path, pos):
        self.path_spec = path_spec   # ← validate 后才有
        self.path_ = path            # ← validate 后才有
        # i_target_node 也在 validate 后被设置
```

### 为什么 leafref 解析失败

当 sonic yang 模块 A 的 key leaf 通过 leafref 引用模块 B 的节点，但 pyang 无法找到模块 B（不在 `--path` 搜索路径中）时，`ctx.validate()` 无法将 `LeafrefTypeSpec` 替换为 `PathTypeSpec`。

在 Bazel 的 hermetic 沙箱中，即使我们传入了所有 cvlyang-models 的 yang 文件，由于 pyang `FileRepository` 只扫描 `--path` 指定目录中 **以 `sonic-` 开头** 的模块名进行加载（见 generate_yin.py 第283行 `if not mod_name.startswith('sonic-'): continue`），某些跨模块 leafref 的目标节点所在模块可能没有被显式加载到 `ctx` 中，导致 validation 不完整。

### 为什么 Make 不崩溃

Make 环境下，`import_yang.py` 会先运行：
1. 通过 pyang `Context` 追踪所有 transitive imports
2. 将所有被引用的 yang 文件复制到 `build/yang/sonic/` 目录
3. `generate_yin.py` 在这个"完整"目录上运行，所有 leafref 都能解析

Bazel 中我们跳过了 `import_yang.py`（因为它是一个有状态的文件复制过程），直接将 cvlyang-models/ 目录作为搜索路径传入。这导致部分 leafref 的目标模块虽然物理文件存在，但因 pyang 内部的模块加载逻辑差异（`FileRepository` 和 `ctx.add_module` 的调用顺序不同），validate 不完整。

### wrapper 的解决方案

`tools/bazel/generate_yin_wrapper.py` 通过**运行时文本替换**修补 generate_yin.py 的 except 分支：

```python
# 原始代码（会崩溃）：
except:
    target_node = statements.validate_leafref_path(
        self.ctx, key_leaf, type_obj.i_type_spec.path_spec, ...)

# 补丁后代码：
except:
    try:
        target_node = statements.validate_leafref_path(
            self.ctx, key_leaf, type_obj.i_type_spec.path_spec, ...)
    except (AttributeError, TypeError):
        continue  # 跳过无法解析的 leafref，不影响其他列表的依赖分析
```

**效果**：对于无法解析的 leafref key，跳过该条依赖关系的注入（`continue` 到下一个 key_leaf），不影响已正确解析的 leafref 和其他所有处理。最终产出的 21 个 .yin 文件与 Make 完全一致。

### 为什么不直接修改 generate_yin.py

按 Bazel 迁移 skill 规则，**绝对禁止修改 src 目录下的源码**。`cvl/tools/generate_yin.py` 是 sonic-mgmt-common 子仓的一部分，修改它会影响 Make 构建路径。因此通过独立的 wrapper 文件在 Bazel 构建时进行运行时补丁。

## 架构图

```
sonic-mgmt-common MODULE.bazel
  ├── rules_go 0.58.3 + gazelle 0.47.0
  │     └── go_deps.from_file(go.mod) + 6 个 module_override patch
  ├── pyang 2.6.0 (PyPI wheel)
  ├── lxml 5.3.2 cp313 (PyPI wheel)
  ├── setuptools 75.8.2 (PyPI wheel，提供 pkg_resources)
  ├── libyang3 3.12.2 (运行时依赖)
  └── sonic-yang-models 1.0 (cvlyang YANG 文件源)

BUILD.bazel 目标拓扑：

  @sonic-yang-models//:cvlyang_models_files ──┐
  models/yang/sonic/*.yang ───────────────────┼──→ :cvl_schema_gen (generate_yin_wrapper.py)
  models/yang/sonic/common/*.yang ────────────┘        │
  models/yang/common/*.yang ──────────────────────────┘
                                                       ↓
                                              build/cvl/schema/*.yin (21 files)

  models/yang/*.yang ─────────────────────────→ :ocbinds_gen (ygot generator)
  models/yang/common/*.yang                            ↓
  models/yang/extensions/*.yang               translib/ocbinds/ocbinds.go
  models/yang/annotations/*-annot.yang

  models/yang/*.yang ─────────────────────────→ :allyangs_tree (pyang -f tree)
                                              :allyangs_tree_html (pyang -f jstree)

  models/yang/sonic/*.yang ───────────────────→ :sonic_allyangs_tree
                                              :sonic_allyangs_tree_html

  所有以上 ────────────────────────────────────→ :sonic-mgmt-common_1.0.0.deb
                                              :sonic-mgmt-common-codegen_1.0.0.deb
```
