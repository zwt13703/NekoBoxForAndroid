# 项目过程记录

## 2026-01-01
### [配置 Gradle 下载镜像源]
- **时间**: 2026-01-01
- **关联任务**: ID:1
- **操作目标**: 修改 Gradle Wrapper 配置，使用国内镜像源替代官方源，解决下载慢的问题。
- **影响范围**: `gradle/wrapper/gradle-wrapper.properties`
- **修改结果**:
    - **改动摘要**: 将 Gradle distributionUrl 更新为腾讯云镜像 (`gradle-8.10.2-all.zip`)。
    - **验证**: 通过命令行 `.\gradlew.bat --version` 验证，成功从腾讯云镜像下载并解压。

### [修复依赖缺失与 SSH 克隆]
- **时间**: 2026-01-01
- **关联任务**: fix_dependencies, update_script_ssh
- **操作目标**: 解决用户本地只能使用 SSH 拉取代码的问题，修复缺失的依赖库。
- **影响范围**: 
    - `build_libcore.ps1`
    - `external/sing-box/` (新增)
    - `external/libneko/` (新增)
    - `external/gomobile/` (新增)
- **修改结果**:
    - **改动摘要**: 
        1. 修改 `build_libcore.ps1` 脚本，将 `sing-box`, `libneko`, `gomobile` 的 git clone URL 从 HTTPS 改为 SSH 格式。
        2. 手动执行 git clone 命令，使用 SSH 协议拉取了上述三个依赖库到 `external/` 目录。
    - **验证**: 命令行执行 git clone 成功，`external` 目录下已存在相应子目录。

### [修复 gomobile 构建问题]
- **时间**: 2026-01-01
- **关联任务**: fix_gomobile_init, fix_android_sdk_path
- **操作目标**: 解决 `gomobile init` 尝试联网下载 `gobind` 失败以及找不到 Android SDK 的问题。
- **影响范围**:
    - `external/gomobile/cmd/gomobile/init.go`
    - `build_libcore.ps1`
- **修改结果**:
    - **改动摘要**:
        1. 修改 `external/gomobile/cmd/gomobile/init.go`，注释掉 `goInstall` 调用，防止其尝试联网更新 `gobind`。
        2. 修改 `build_libcore.ps1`，添加读取 `local.properties` 并自动设置 `ANDROID_HOME` 环境变量的逻辑。
        3. 修改 `build_libcore.ps1`，强制每次都重新编译 `gomobile`，以确保我们的源码修改生效。
    - **验证**: 需要用户重新运行构建脚本进行验证。
