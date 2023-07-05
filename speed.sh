#!/bin/bash
#######################################################
# A modified version of tocdo.net that does not require root
# tocdo.net Linux Server Benchmarks v1.5
# Run speed test:
# curl -Lso- tocdo.net | bash
#######################################################

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
PLAIN='\033[0m'

# check for wget
if [ ! -e '/usr/bin/wget' ]; then
  echo -e "wget is required to do speed test. Please install it yourself."
  exit 1
fi

get_opsy() {
  [ -f /etc/redhat-release ] && awk '{print ($1,$3~/^[0-9]/?$3:$4)}' /etc/redhat-release && return
  [ -f /etc/os-release ] && awk -F'[= "]' '/PRETTY_NAME/{print $3,$4,$5}' /etc/os-release && return
  [ -f /etc/lsb-release ] && awk -F'[="]+' '/DESCRIPTION/{print $2}' /etc/lsb-release && return
}

next() {
  printf "%-70s\n" "-" | sed 's/\s/-/g'
}

speed_test() {
  local speedtest=$(wget -4O /dev/null -T300 $1 2>&1 | awk '/\/dev\/null/ {speed=$3 $4} END {gsub(/\(|\)/,"",speed); print speed}')
  local ipaddress=$(ping -c1 -4 -n $(awk -F'/' '{print $3}' <<<$1) | awk -F'[()]' '{print $2;exit}')
  local nodeName=$2
  printf "${YELLOW}%-40s${GREEN}%-16s${RED}%-14s${PLAIN}\n" "${nodeName}" "${ipaddress}" "${speedtest}"
}

speed_test_v6() {
  local speedtest=$(wget -6O /dev/null -T300 $1 2>&1 | awk '/\/dev\/null/ {speed=$3 $4} END {gsub(/\(|\)/,"",speed); print speed}')
  local ipaddress=$(ping6 -c1 -n $(awk -F'/' '{print $3}' <<<$1) | awk -F'[()]' '{print $2;exit}')
  local nodeName=$2
  printf "${YELLOW}%-40s${GREEN}%-16s${RED}%-14s${PLAIN}\n" "${nodeName}" "${ipaddress}" "${speedtest}"
}

speed() {
  speed_test 'http://cachefly.cachefly.net/100mb.test' 'CacheFly'
  speed_test 'https://lax-ca-us-ping.vultr.com/vultr.com.100MB.bin' 'Vultr, Los Angeles, CA'
  speed_test 'https://wa-us-ping.vultr.com/vultr.com.100MB.bin' 'Vultr, Seattle, WA'
  speed_test 'http://speedtest.tokyo2.linode.com/100MB-tokyo.bin' 'Linode, Tokyo, JP'
  speed_test 'http://speedtest.singapore.linode.com/100MB-singapore.bin' 'Linode, Singapore, SG'
  speed_test 'http://speedtest.hkg02.softlayer.com/downloads/test100.zip' 'Softlayer, HongKong, CN'
  speed_test 'http://speedtest1.vtn.com.vn/speedtest/random4000x4000.jpg' 'VNPT, Ha Noi, VN'
  speed_test 'http://speedtest5.vtn.com.vn/speedtest/random4000x4000.jpg' 'VNPT, Da Nang, VN'
  speed_test 'http://speedtest3.vtn.com.vn/speedtest/random4000x4000.jpg' 'VNPT, Ho Chi Minh, VN'
  speed_test 'http://speedtestkv1a.viettel.vn/speedtest/random4000x4000.jpg' 'Viettel Network, Ha Noi, VN'
  speed_test 'http://speedtestkv2a.viettel.vn/speedtest/random4000x4000.jpg' 'Viettel Network, Da Nang, VN'
  speed_test 'http://speedtestkv3a.viettel.vn/speedtest/random4000x4000.jpg' 'Viettel Network, Ho Chi Minh, VN'
  # speed_test 'http://speedtesthn.fpt.vn/speedtest/random4000x4000.jpg' 'FPT Telecom, Ha Noi, VN'
  speed_test 'http://speedtest.fpt.vn/speedtest/random4000x4000.jpg' 'FPT Telecom, Ho Chi Minh, VN'
}

calc_disk() {
  local total_size=0
  local array=$@
  for size in ${array[@]}; do
    [ "${size}" == "0" ] && size_t=0 || size_t=$(echo ${size:0:${#size}-1})
    [ "$(echo ${size:(-1)})" == "M" ] && size=$(awk 'BEGIN{printf "%.1f", '$size_t' / 1024}')
    [ "$(echo ${size:(-1)})" == "T" ] && size=$(awk 'BEGIN{printf "%.1f", '$size_t' * 1024}')
    [ "$(echo ${size:(-1)})" == "G" ] && size=${size_t}
    total_size=$(awk 'BEGIN{printf "%.1f", '$total_size' + '$size'}')
  done
  echo ${total_size}
}

test() {
  cname=$(awk -F: '/model name/ {name=$2} END {print name}' /proc/cpuinfo | sed 's/^[ \t]*//;s/[ \t]*$//')
  cores=$(awk -F: '/model name/ {core++} END {print core}' /proc/cpuinfo)
  freq=$(awk -F: '/cpu MHz/ {freq=$2} END {print freq}' /proc/cpuinfo | sed 's/^[ \t]*//;s/[ \t]*$//')
  tram=$(free -m | awk '/Mem/ {print $2}')
  uram=$(free -m | awk '/Mem/ {print $3}')
  swap=$(free -m | awk '/Swap/ {print $2}')
  uswap=$(free -m | awk '/Swap/ {print $3}')
  up=$(awk '{a=$1/86400;b=($1%86400)/3600;c=($1%3600)/60} {printf("%d days, %d hour %d min\n",a,b,c)}' /proc/uptime)
  load=$(w | head -1 | awk -F'load average:' '{print $2}' | sed 's/^[ \t]*//;s/[ \t]*$//')
  opsy=$(get_opsy)
  arch=$(uname -m)
  lbit=$(getconf LONG_BIT)
  kern=$(uname -r)
  date=$(date)
  disk_size1=($(LANG=C df -hPl | grep -wvE '\-|none|tmpfs|devtmpfs|by-uuid|chroot|Filesystem' | awk '{print $2}'))
  disk_size2=($(LANG=C df -hPl | grep -wvE '\-|none|tmpfs|devtmpfs|by-uuid|chroot|Filesystem' | awk '{print $3}'))
  disk_total_size=$(calc_disk ${disk_size1[@]})
  disk_used_size=$(calc_disk ${disk_size2[@]})

  echo "System Info"
  next
  echo "CPU model            : $cname"
  echo "Number of cores      : $cores"
  echo "CPU frequency        : $freq MHz"
  echo "Total size of Disk   : $disk_total_size GB ($disk_used_size GB Used)"
  echo "Total amount of Mem  : $tram MB ($uram MB Used)"
  echo "Total amount of Swap : $swap MB ($uswap MB Used)"
  echo "System uptime        : $up"
  echo "Load average         : $load"
  echo "OS                   : $opsy"
  echo "Arch                 : $arch ($lbit Bit)"
  echo "Kernel               : $kern"
  echo "Date                 : $date"
  echo ""
  echo "Speedtest"
  next
  printf "%-40s%-16s%-14s\n" "Node Name" "IPv4 address" "Download Speed"
  speed && next
}
clear
tmp=$(mktemp)
test | tee $tmp
