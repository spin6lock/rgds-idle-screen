# RGDS Idle Screen

给 ANBERNIC RG DS / RG DS Plus Linux 系统使用的背光控制程序。下载前在 Apps 中开启，连续 30 分钟没有触摸或普通按键后熄灭双屏背光；触摸或按键恢复原亮度，随后重新计时。

程序仅修改 `/sys/class/backlight/*/brightness`，不触发系统休眠，不修改网络，不启动或停止下载任务。不依赖 systemd，也不需要重启 Weston。

## 环境

已在一台运行 Buildroot 2024.02、Weston 14.0.2、Python 3.11 的 Rockchip RK3568 双屏设备上使用。其他固件或设备未经验证。

需要 Linux、Python 3 标准库，以及读 `/dev/input/event*`、写背光 sysfs 节点的权限。以下命令假定 `nds` 是已配置为 root 用户的 SSH 主机别名，请替换为自己的设备连接目标。Apps 目录采用该设备原厂菜单的 `/mnt/mmc/Roms/APPS`。

## 安装

在电脑上执行：

```sh
git clone https://github.com/spin6lock/rgds-idle-screen.git
cd rgds-idle-screen
ssh nds 'test -d /mnt/mmc/Roms/APPS && command -v python3'
scp bin/nds-screen-off nds:/usr/bin/nds-screen-off
scp apps/*.sh nds:/mnt/mmc/Roms/APPS/
ssh nds 'chmod 755 /usr/bin/nds-screen-off'
```

如果正在更新已运行的旧版，复制文件前先执行 `ssh nds '/usr/bin/nds-screen-off --stop'`，让旧进程恢复背光并退出。安装不会自动启动程序，也不会设置开机自启。

## Apps 使用

返回 Apps 列表，必要时退出列表后重新进入：

- **自动熄屏-开启(30分钟)**：开启后台计时，随后返回菜单，可继续运行下载器。重复点击不会启动多个监听进程。
- **自动熄屏-关闭**：停止计时；如果背光由本程序关闭，恢复熄屏前各屏亮度。

开启后的工作流程：

1. 连续 30 分钟没有触摸或普通按键，关闭所有背光节点。
2. 触摸或按普通按键，恢复各屏熄灭前的亮度。
3. 重新开始计时，持续循环，直到关闭程序或设备重启。

## SSH 命令

```sh
# 后台开启 30 分钟循环计时
ssh nds '/usr/bin/nds-screen-off --start --idle-minutes 30'

# 查询进程 PID 和闲置分钟数
ssh nds '/usr/bin/nds-screen-off --status'

# 手动亮屏并重新开始计时
ssh nds '/usr/bin/nds-screen-off --wake'

# 停止程序，必要时恢复亮度
ssh nds '/usr/bin/nds-screen-off --stop'

# 立即熄屏，输入唤醒后退出，不循环（前台运行）
ssh nds '/usr/bin/nds-screen-off'
```

自定义时长：先 `--stop`，再用 `--start --idle-minutes 10` 等正数重新启动。Apps 开启入口固定为 30 分钟。

后台日志：`/tmp/nds-screen-off.log`。进程锁和状态：`/tmp/nds-screen-off.lock`。不运行时状态文件可能保留，是否运行以 `--status` 为准。

## 输入与限制

- 下载、画面刷新、SSH 操作不会重置闲置计时。监听的是本机输入事件。
- 不独占输入设备。唤醒的那次触摸或按键也会传给当前应用，可能触发界面操作。
- 电源、休眠、挂起键保留系统原行为，不作为本程序的唤醒键，建议用触摸或普通按键。
- 识别键盘/手柄按钮，以及带 `BTN_TOUCH` 能力的触摸屏；不把摇杆轴变化作为活动。
- 仅监听启动时已存在的输入设备。插入新的键盘等设备后，需要关闭再开启；已有输入设备断开时程序会退出并恢复背光。
- 关闭的是背光，系统和显示应用仍继续运行；没有测量整机功耗下降幅度。
- 正常停止、输入设备断开及常见退出信号会恢复亮度。强制 `SIGKILL` 无法执行恢复逻辑；程序退出后 `--wake` 也不会替它恢复亮度，此时应通过 SSH 手动写入背光亮度。

## 验证记录

开发时已验证输入重置计时、触摸/按键事件唤醒、释放按键不唤醒、循环计时、不同屏幕亮度恢复，以及停止后的恢复行为。实机使用缩短的计时间隔验证了两路背光熄灭、SSH 唤醒、再次超时熄灭和 Apps 入口启动/停止；30 分钟配置已查询确认。立即熄屏模式的实体输入唤醒也已由设备使用者确认。

## 文件

- `bin/nds-screen-off`：独立 Python 程序，仅依赖标准库。
- `apps/`：两个原厂 Apps 菜单 shell 入口。

MIT License，见 [LICENSE](LICENSE)。
