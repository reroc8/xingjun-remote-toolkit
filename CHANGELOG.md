# 更新日志

本文件记录 **星君常用远程工具** 的版本变更。

> v1.6 之前通过 [gp45.ys168.com](https://gp45.ys168.com) 分发，未在本仓库归档，因此没有更早的记录。

---

## [v1.6] — 2026-09-25

首个 GitHub 发布版。

**下载**：[XingjunRemoteTool-v1.6.bat](https://github.com/reroc8/xingjun-remote-toolkit/releases/download/v1.6/XingjunRemoteTool-v1.6.bat)
**SHA256**：`ce0a7bb62659dbf3efce19d7d2e7da256d4d69e68eb12578701b531bba484c06`

### 新增

- 端口占用排查（功能 13）—— 查出占用进程的 PID，确认后可强制结束
- UAC 状态查看（功能 23）
- 恢复快捷方式箭头（功能 25）—— 会先检测是否已去除，避免无谓操作

### 变更

- 菜单按功能域分组：网络 / 防火墙端口 / 系统硬件 / 系统更新 / UAC / 桌面美化，编号重排为 0-25
- 网络配置导出改为带时间戳的独立文件，统一输出到 `导出` 目录
- 改配置类功能（防火墙、系统更新、UAC、箭头）统一加入**二次确认**与**执行后验证**，操作完回读当前状态确认生效

### 改进

- 端口号 / PID 输入增加纯数字校验，避免非法输入直接传给系统命令
- 增加管理员权限预检，权限不足时给出明确指引而不是让命令直接失败

### 已知限制（待 v1.7 处理）

- 权限检测用 `net session`，Server 服务（`LanmanServer`）被停用时会把管理员误判为普通用户
- 禁用系统更新只处理 `wuauserv` 和 `bits`，未处理会把服务拉起的 `UsoSvc`

---

## 未发布

### v1.7（计划）

- [ ] 权限检测改用更可靠的方式（如 `fsutil dirty query %systemdrive%`），修掉 Server 服务停用时的误判
- [ ] 禁用系统更新时一并处理 `UsoSvc`（Update Orchestrator），并在文档里说清残留项
- [ ] 放行端口前先删除同名规则，避免"规则已存在"报错
- [ ] 增加"还原全部改动"入口，一键恢复防火墙 / 更新 / UAC / 箭头
- [ ] 菜单输入容错：忽略前后空格、接受全角数字

---

[v1.6]: https://github.com/reroc8/xingjun-remote-toolkit/releases/tag/v1.6
