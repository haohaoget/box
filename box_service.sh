#!/system/bin/sh

(
    until [ $(getprop init.svc.bootanim) = "stopped" ]; do
        sleep 10
    done

    if [ -f "/data/adb/box/scripts/start.sh" ]; then
        chmod 755 /data/adb/box/scripts/*
        /data/adb/box/scripts/start.sh
        SCRIPTS_DIR="/data/adb/box/scripts"

        while [ ! -f /data/misc/net/rt_tables ]; do
            sleep 3
        done

        IP_BIN="/system/bin/ip"
        SH_BIN="/system/bin/sh"
        if [[ -f "$IP_BIN" && -f "$SH_BIN" ]]; then
            # 确保启动前清理可能残留的旧监听进程
            pkill -f "$IP_BIN monitor rule"
            # 替换为基于 Netlink 的内核路由规则监听
            (
            $IP_BIN monitor rule | while read -r event; do
                    case "$event" in
                        *"from all fwmark 0x0/0xffff iif lo lookup "*)
                            # 防抖逻辑：如果 .inotify 没在运行，则触发执行并传入网络接口参数
                            if ! pgrep -f "/data/adb/box/scripts/net.inotify" > /dev/null; then
                                $SH_BIN /data/adb/box/scripts/net.inotify w> /dev/null 2>&1 &
                            fi
                            
                            if ! pgrep -f "/data/adb/box/scripts/ctr.inotify" > /dev/null; then
                                RUN_DIR="/data/adb/box/run" \
                                $SH_BIN /data/adb/box/scripts/ctr.inotify w> /dev/null 2>&1 &
                            fi
                            ;;
                    esac
                done
            ) > /dev/null 2>&1 &
        else
            inotifyd ${SCRIPTS_DIR}/net.inotify /data/misc/net/rt_tables > /dev/null 2>&1 &
            inotifyd ${SCRIPTS_DIR}/ctr.inotify /data/misc/net/rt_tables > /dev/null 2>&1 &
        fi
    else
        echo "未找到文件 '/data/adb/box/scripts/start.sh'"
    fi
)&
