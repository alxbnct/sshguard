#!/bin/sh
# sshg-fw-iptables
# This file is part of SSHGuard.

run_iptables() {
    cmd=iptables
    if [ "6" = "$2" ]; then
        cmd=ip6tables
    fi

    # Check if iptables supports the '-w' flag.
    if $cmd -w -V >/dev/null 2>&1; then
        $cmd -w $1
    else
        $cmd $1
    fi
}

fw_init() {
    run_iptables "-L -n"
}

fw_block() {
    if [ $2 -eq 4 ]; then
        blocklist="$blocklist,$1/$3"
    else
        blocklist6="$blocklist6,$1/$3"
    fi
    if [ ! $batch_enabled ] || [ $(( $SECONDS - $lastblock )) -ge $window ]; then
        if [ "$blocklist" ]; then
            blocklist=${blocklist:1}
            run_iptables "-I sshguard -s $blocklist -j DROP" 4
            blocklist=''
        fi
        if [ "$blocklist6" ]; then
            blocklist6=${blocklist6:1}
            run_iptables "-I sshguard -s $blocklist6 -j DROP" 6
            blocklist6=''
        fi
        lastblock=$SECONDS
    fi
}

fw_release() {
    if [ $2 -eq 4 ]; then
        releaselist="$releaselist,$1/$3"
    else
        releaselist6="$releaselist6,$1/$3"
    fi
    if [ ! $batch_enabled ] || [ $(( $SECONDS - $lastrelease )) -ge $window ]; then
        if [ "$releaselist" ]; then
            releaselist=${releaselist:1}
            run_iptables "-D sshguard -s $releaselist -j DROP" 4
            releaselist=''
        fi
        if [ "$releaselist6" ]; then
            releaselist6=${releaselist6:1}
            run_iptables "-D sshguard -s $releaselist6 -j DROP" 6
            releaselist6=''
        fi
        lastrelease=$SECONDS
    fi
}

fw_flush() {
    run_iptables "-F sshguard" 4
    run_iptables "-F sshguard" 6
}

fw_fin() {
    :
}
