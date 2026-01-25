# 代码库函数概览

## Gradle
- `gradle/wrapper/gradle-wrapper.properties`: 定义 Gradle 发行版版本和下载 URL。

## Build Scripts
- `build_libcore.ps1`: Windows 下构建 `libcore.aar` 的 PowerShell 脚本。会自动检查并拉取依赖 (`sing-box`, `libneko`, `gomobile`)，并使用 SSH 协议。
