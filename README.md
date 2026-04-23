# SSH Terminal - macOS SSH 远程连接终端工具

一个仿照 Termius 制作的 macOS SSH 远程连接终端工具，使用 SwiftUI 开发。

## 功能特性

### 1. Host 信息管理
- 保存多个 SSH 服务器连接信息
- 支持的字段：
  - **Name**：显示名称（可选）
  - **Address**：服务器地址（IP 或域名）
  - **Port**：SSH 端口（默认 22）
  - **Username**：登录用户名
  - **Password**：登录密码（可选）

### 2. Host 列表展示
- 以列表形式展示所有保存的服务器
- 支持搜索功能（按名称、地址、用户名搜索）
- 显示最后连接时间
- 支持右键菜单操作

### 3. 一键连接功能
提供两种连接方式：

#### 系统终端连接（推荐）
- 自动打开 macOS 系统 Terminal.app
- 支持完整的 SSH 功能（密码提示、密钥认证等）
- 如果保存了密码，会自动填充

#### 内置终端连接
- 应用内集成的简单终端界面
- 支持命令输入和输出显示
- 支持复制输出内容
- 支持清空终端

### 4. 主题切换
- **深色模式**（默认）
- **浅色模式**
- 主题设置自动保存
- 支持菜单栏快捷键切换

### 5. 键盘快捷键
- `Cmd + N`：添加新 Host
- `Cmd + 1`：切换到浅色模式
- `Cmd + 2`：切换到深色模式
- `Cmd + Shift + T`：切换主题
- `Esc`：取消编辑

## 项目结构

```
SSHTerminal/
├── SSHTerminalApp.swift          # 应用入口
├── Models/
│   └── Host.swift                # Host 数据模型
├── ViewModels/
│   ├── HostManager.swift         # Host 管理逻辑
│   └── ThemeManager.swift        # 主题管理逻辑
├── Views/
│   ├── ContentView.swift         # 主视图
│   ├── HostListView.swift        # Host 列表视图
│   ├── HostEditView.swift        # Host 编辑视图
│   └── TerminalView.swift        # 终端视图
└── Services/
    └── SSHService.swift          # SSH 连接服务
```

## 如何运行

### 方法一：使用 Xcode（推荐）

1. 打开 Xcode
2. 选择 "Create a new Xcode project"
3. 选择 "macOS" -> "App"
4. 输入项目名称 "SSHTerminal"
5. 选择界面 "SwiftUI"，语言 "Swift"
6. 创建项目后，将 `SSHTerminal` 文件夹中的所有文件复制到新项目中
7. 确保所有文件都正确添加到项目中
8. 点击运行按钮或按 `Cmd + R`

### 方法二：使用 Swift Package Manager

1. 确保已安装 Swift 5.7 或更高版本
2. 在终端中进入项目目录
3. 运行以下命令：

```bash
swift build
swift run
```

注意：由于 SwiftUI 应用的特性，建议使用 Xcode 运行以获得最佳体验。

## 使用说明

### 添加新 Host

1. 点击左侧面板顶部的 "+" 按钮，或使用快捷键 `Cmd + N`
2. 填写服务器信息：
   - **Display Name**：为服务器起一个容易识别的名称（可选）
   - **Server Address**：服务器的 IP 地址或域名
   - **Port**：SSH 端口（默认 22）
   - **Username**：登录用户名
   - **Password**：登录密码（可选，如果使用密钥认证可以留空）
3. 点击 "Add Host" 保存

### 连接到服务器

1. 在 Host 列表中找到要连接的服务器
2. 点击服务器右侧的播放按钮，或右键点击选择 "Connect"
3. 选择连接方式：
   - **Open in System Terminal**：使用系统终端连接（推荐）
   - **Use Built-in Terminal**：使用应用内置终端

### 管理 Host

- **编辑**：右键点击 Host 选择 "Edit"，或点击工具栏菜单中的 "Edit Host"
- **删除**：右键点击 Host 选择 "Delete"，或点击工具栏菜单中的 "Delete Host"
- **搜索**：在搜索框中输入关键词进行筛选

### 切换主题

1. 点击工具栏右上角的菜单按钮
2. 选择 "Theme" 子菜单
3. 选择 "Light Mode" 或 "Dark Mode"
4. 或使用快捷键 `Cmd + Shift + T` 快速切换

## 技术细节

### 数据存储
- Host 信息使用 `UserDefaults` 进行持久化存储
- 主题设置也保存在 `UserDefaults` 中

### SSH 连接
- 使用系统的 `/usr/bin/ssh` 命令
- 系统终端连接使用 AppleScript 控制 Terminal.app
- 内置终端使用 `Process` 和 `Pipe` 进行进程通信

### 界面设计
- 使用 SwiftUI 构建现代化界面
- 支持 NavigationSplitView 三栏布局
- 响应式设计，支持窗口大小调整

## 注意事项

1. **密码安全**：当前版本密码以明文形式存储在 UserDefaults 中。在生产环境中，建议使用 Keychain 进行安全存储。

2. **内置终端限制**：内置终端是一个简化版本，可能不支持所有终端特性（如颜色、光标移动等）。建议使用系统终端进行完整的 SSH 操作。

3. **网络连接**：确保目标服务器可以从当前网络访问，并且 SSH 端口已开放。

4. **密钥认证**：如果使用 SSH 密钥认证，不需要在应用中保存密码，系统会自动使用 ~/.ssh 目录中的密钥。

## 未来改进方向

- [ ] 使用 Keychain 安全存储密码
- [ ] 集成 SwiftTerm 实现更完整的终端模拟器
- [ ] 支持 SSH 密钥管理
- [ ] 添加标签页支持，同时连接多个服务器
- [ ] 实现 SFTP 文件传输功能
- [ ] 添加终端主题自定义
- [ ] 支持导入/导出 Host 配置
- [ ] 添加自动重连功能
- [ ] 实现端口转发支持

## 许可证

MIT License

## 贡献

欢迎提交 Issue 和 Pull Request！
