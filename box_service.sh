#!/system/bin/sh

(
    until [ $(getprop init.svc.bootanim) = "stopped" ]; do
        sleep 10
    done

    if [ -f "/data/adb/box/scripts/start.sh" ]; then
        chmod 755 /data/adb/box/scripts/*
        /data/adb/box/scripts/start.sh


        while [ ! -f /data/misc/net/rt_tables ]; do
            sleep 3
        done
        # 清理可能残留的旧监听进程
        pkill -f "ip monitor rule"
        # 使用基于 Netlink 的内核路由规则监听
        (
            ip monitor rule | while read -r event; do
                case "$event" in
                    *"from all fwmark 0x0/0xffff iif lo lookup "*)
                        
                        # 防抖逻辑：如果 .inotify 没在运行，则触发执行并传入网络接口参数
                        if ! pgrep -f "/data/adb/box/scripts/net.inotify" > /dev/null; then
                            sh /data/adb/box/scripts/net.inotify w> /dev/null 2>&1 &
                        fi
                        if ! pgrep -f "/data/adb/box/scripts/ctr.inotify" > /dev/null; then
                            sh /data/adb/box/scripts/ctr.inotify w> /dev/null 2>&1 &
                        fi
                        ;;
                esac
            done
        ) > /dev/null 2>&1 &
        # inotifyd ${SCRIPTS_DIR}/ctr.inotify /data/misc/net/rt_tables > /dev/null 2>&1 &
    else
        echo "未找到文件 '/data/adb/box/scripts/start.sh'"
    fi
)&
