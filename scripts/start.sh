#!/bin/sh
# Copyright (C) Juewuy

#脚本内部工具
getconfig(){
	#加载配置文件
	[ -d "/etc/storage/clash" ] && clashdir=/etc/storage/clash
	[ -d "/jffs/clash" ] && clashdir=/jffs/clash
	[ -z "$clashdir" ] && clashdir=$(cat /etc/profile | grep clashdir | awk -F "\"" '{print $2}')
	[ -z "$clashdir" ] && clashdir=$(cat ~/.bashrc | grep clashdir | awk -F "\"" '{print $2}')
	ccfg=$clashdir/mark
	[ -f $ccfg ] && source $ccfg
	#默认设置
	[ -z "$bindir" ] && bindir=$clashdir
	[ -z "$redir_mod" ] && [ "$USER" = "root" -o "$USER" = "admin" ] && redir_mod=Redir模式
	[ -z "$redir_mod" ] && redir_mod=纯净模式
	[ -z "$skip_cert" ] && skip_cert=已开启
	[ -z "$common_ports" ] && common_ports=已开启
	[ -z "$dns_mod" ] && dns_mod=redir_host
	[ -z "$ipv6_support" ] && ipv6_support=未开启
	[ -z "$ipv6_dns" ] && ipv6_dns=$ipv6_support
	[ -z "$mix_port" ] && mix_port=7890
	[ -z "$redir_port" ] && redir_port=7892
	[ -z "$db_port" ] && db_port=9999
	[ -z "$dns_port" ] && dns_port=1053
	[ -z "$stearming_int" ] && stearming_int=24
	[ -z "$dns_nameserver" ] && dns_nameserver='114.114.114.114, 223.5.5.5'
	[ -z "$dns_fallback" ] && dns_fallback='1.0.0.1, 8.8.4.4'
	[ -z "$multiport" ] && multiport='22,53,587,465,995,993,143,80,443,8080'
	#获取本机host地址
	[ -z "$host" ] && host=$(ubus call network.interface.lan status 2>&1 | grep \"address\" | grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}';)
	[ -z "$host" ] && host=$(ip a 2>&1 | grep -w 'inet' | grep 'global' | grep -E '\ 1(92|0|72)\.' | sed 's/.*inet.//g' | sed 's/\/[0-9][0-9].*$//g' | head -n 1)
	[ -z "$host" ] && host=127.0.0.1
	#是否代理常用端口
	[ "$common_ports" = "已开启" ] && ports="-m multiport --dports $multiport"
	}
setconfig(){
	#参数1代表变量名，参数2代表变量值,参数3即文件路径
	[ -z "$3" ] && configpath=$clashdir/mark || configpath=$3
	[ -n "$(grep ${1} $configpath)" ] && sed -i "s#${1}=.*#${1}=${2}#g" $configpath || echo "${1}=${2}" >> $configpath
}
compare(){
	if [ ! -f $1 -o ! -f $2 ];then
		return 1
	elif command -v cmp >/dev/null 2>&1;then
		cmp -s $1 $2
	else
		[ "$(cat $1)" = "$(cat $2)" ] && return 0 || return 1
	fi
}
logger(){
	[ -n "$2" ] && echo -e "\033[$2m$1\033[0m"
	echo `date "+%G-%m-%d %H:%M:%S"` $1 >> $clashdir/log
	[ "$(wc -l $clashdir/log | awk '{print $1}')" -gt 30 ] && sed -i '1,5d' $clashdir/log
}
croncmd(){
	if [ -n "$(crontab -h 2>&1 | grep '\-l')" ];then
		crontab $1
	else
		crondir="$(crond -h 2>&1 | grep -oE 'Default:.*' | awk -F ":" '{print $2}')"
		[ ! -w "$crondir" ] && crondir="/etc/storage/cron/crontabs"
		[ ! -w "$crondir" ] && crondir="/var/spool/cron/crontabs"
		[ ! -w "$crondir" ] && crondir="/var/spool/cron"
		[ ! -w "$crondir" ] && echo "你的设备不支持定时任务配置，脚本大量功能无法启用，请前往 https://t.me/clashfm 申请适配！"
		[ "$1" = "-l" ] && cat $crondir/$USER 2>/dev/null
		[ -f "$1" ] && cat $1 > $crondir/$USER
	fi
}
cronset(){
	# 参数1代表要移除的关键字,参数2代表要添加的任务语句
	tmpcron=/tmp/cron_$USER
	croncmd -l > $tmpcron 
	sed -i "/$1/d" $tmpcron
	sed -i '/^$/d' $tmpcron
	echo "$2" >> $tmpcron
	croncmd $tmpcron
	rm -f $tmpcron
}
mark_time(){
	start_time=`date +%s`
	sed -i '/start_time*/'d $clashdir/mark
	echo start_time=$start_time >> $clashdir/mark
}
#配置文件相关
getyaml(){
	[ -z "$rule_link" ] && rule_link=1
	[ -z "$server_link" ] && server_link=1
	#前后端订阅服务器地址索引，可在此处添加！
	Server=`sed -n ""$server_link"p"<<EOF
https://api.dler.io
http://sub.shellclash.ga
https://api.wcc.best
https://sub.id9.cc
https://sub.maoxiongnet.com
EOF`
	Config=`sed -n ""$rule_link"p"<<EOF
https://github.com/juewuy/ShellClash/raw/master/rules/ShellClash.ini
https://github.com/juewuy/ShellClash/raw/master/rules/ShellClash_Mini.ini
https://github.com/juewuy/ShellClash/raw/master/rules/ShellClash_Block.ini
https://github.com/juewuy/ShellClash/raw/master/rules/ShellClash_Nano.ini
https://github.com/juewuy/ShellClash/raw/master/rules/ShellClash_Full.ini
https://github.com/juewuy/ShellClash/raw/master/rules/ShellClash_Full_Block.ini
https://gist.githubusercontent.com/tindy2013/1fa08640a9088ac8652dbd40c5d2715b/raw/lhie1_clash.ini
https://gist.githubusercontent.com/tindy2013/1fa08640a9088ac8652dbd40c5d2715b/raw/lhie1_dler.ini
https://gist.githubusercontent.com/tindy2013/1fa08640a9088ac8652dbd40c5d2715b/raw/connershua_pro.ini
https://gist.githubusercontent.com/tindy2013/1fa08640a9088ac8652dbd40c5d2715b/raw/connershua_backtocn.ini
https://gist.githubusercontent.com/tindy2013/1fa08640a9088ac8652dbd40c5d2715b/raw/dlercloud_lige_platinum.ini
https://subconverter.oss-ap-southeast-1.aliyuncs.com/Rules/RemoteConfig/special/basic.ini
https://subconverter.oss-ap-southeast-1.aliyuncs.com/Rules/RemoteConfig/special/netease.ini
https://raw.githubusercontent.com/ACL4SSR/ACL4SSR/master/Clash/config/ACL4SSR_Online_Full_Google.ini
https://github.com/juewuy/ShellClash/raw/master/rules/ACL4SSR_Online_Games.ini
https://github.com/juewuy/ShellClash/raw/master/rules/ACL4SSR_Online_Mini_Games.ini
https://github.com/juewuy/ShellClash/raw/master/rules/ACL4SSR_Online_Full_Games.ini
EOF`
	Https=$(echo ${Https//\%26/\&})   #将%26替换回&
	#如果传来的是Url链接则合成Https链接，否则直接使用Https链接
	if [ -z "$Https" ];then
		[ -n "$(echo $Url | grep -o 'vless')" ] && Server='http://sub.shellclash.ga'
		Https="$Server/sub?target=clash&insert=true&new_name=true&scv=true&udp=true&exclude=$exclude&include=$include&url=$Url&config=$Config"
		markhttp=1
	fi
	#输出
	echo -----------------------------------------------
	echo 正在连接服务器获取配置文件…………链接地址为：
	echo -e "\033[4;32m$Https\033[0m"
	echo 可以手动复制该链接到浏览器打开并查看数据是否正常！
	#获取在线yaml文件
	yaml=$clashdir/config.yaml
	yamlnew=/tmp/clash_config_$USER.yaml
	rm -rf $yamlnew
	$0 webget $yamlnew $Https
	if [ "$?" = "1" ];then
		if [ -z "$markhttp" ];then
			echo -----------------------------------------------
			logger "配置文件获取失败！" 31
			echo -e "\033[31m请尝试使用【在线生成配置文件】功能！\033[0m"
			echo -----------------------------------------------
			exit 1
		else
			if [ "$retry" -ge 5 ];then
				logger "无法获取配置文件，请检查链接格式以及网络连接状态！" 31
				exit 1
			else
				retry=$((retry+1))
				logger "配置文件获取失败！" 31
				echo -e "\033[32m尝试使用其他服务器获取配置！\033[0m"
				logger "正在重试第$retry次/共5次！" 33
				sed -i '/server_link=*/'d $ccfg
				if [ "$server_link" -ge 5 ]; then
					server_link=0
				fi
				server_link=$((server_link+1))
				echo server_link=$server_link >> $ccfg
				Https=""
				getyaml
			fi
		fi
	else
		Https=""
		#检测节点或providers
		if [ -z "$(cat $yamlnew | grep -E 'server|proxy-providers' | grep -v 'nameserver' | head -n 1)" ];then
			echo -----------------------------------------------
			logger "获取到了配置文件，但似乎并不包含正确的节点信息！" 31
			echo -----------------------------------------------
			sed -n '1,30p' $yamlnew
			echo -----------------------------------------------
			echo -e "\033[33m请检查如上配置文件信息:\033[0m"
			echo -----------------------------------------------
			exit 1
		fi
		#检测旧格式
		if cat $yamlnew | grep 'Proxy Group:' >/dev/null;then
			echo -----------------------------------------------
			logger "已经停止对旧格式配置文件的支持！！！" 31
			echo -e "请使用新格式或者使用【在线生成配置文件】功能！"
			echo -----------------------------------------------
			exit 1
		fi
		#检测不支持的加密协议
		if cat $yamlnew | grep 'cipher: chacha20,' >/dev/null;then
			echo -----------------------------------------------
			logger "已停止支持chacha20加密，请更换更安全的节点加密协议！" 31
			echo -----------------------------------------------
			exit 1
		fi
		#检测vless协议
		if [ -n "$(cat $yamlnew | grep -E 'vless')" ] && [ "$clashcore" = "clash" -o "$clashcore" = "clashpre" ];then
			echo -----------------------------------------------
			logger "检测到vless协议！将改为使用clash.meta核心启动！" 33
			rm -rf $bindir/clash
			setconfig clashcore clash.meta
			echo -----------------------------------------------
		fi
		#检测是否存在高级版规则
		if [ "$clashcore" = "clash" -a -n "$(cat $yamlnew | grep -E '^script:|proxy-providers|rule-providers')" ];then
			echo -----------------------------------------------
			logger "检测到高级版核心专属规则！将改为使用clash.net核心启动！" 33
			rm -rf $bindir/clash
			setconfig clashcore clash.net
			echo -----------------------------------------------
		fi
		#使用核心内置test功能检测
		if [ -x $bindir/clash ];then
			$bindir/clash -t -d $bindir -f $yamlnew >/dev/null
			if [ "$?" != "0" ];then
				logger "配置文件加载失败！请查看报错信息！" 31
				$bindir/clash -t -d $bindir -f $yamlnew
				echo "$($bindir/clash -t -d $bindir -f $yamlnew)" >> $clashdir/log
				exit 1
			fi
		fi
		#如果不同则备份并替换文件
		if [ -f $yaml ];then
			compare $yamlnew $yaml
			[ "$?" = 0 ] || mv -f $yaml $yaml.bak && mv -f $yamlnew $yaml
		else
			mv -f $yamlnew $yaml
		fi
		echo -e "\033[32m已成功获取配置文件！\033[0m"
		rm -rf $yamlnew
		exit 0
	fi
}
modify_yaml(){
##########需要变更的配置###########
	lan='allow-lan: true'
	#mode='mode: Rule'
	log='log-level: info'
	[ "$ipv6_support" = "已开启" ] && ipv6='ipv6: true' || ipv6='ipv6: false'
	[ "$ipv6_dns" = "已开启" ] && dns_v6='ipv6: true' || dns_v6=$ipv6
	external="external-controller: 0.0.0.0:$db_port"
	[ -d $clashdir/ui ] && db_ui=ui
	if [ "$redir_mod" = "混合模式" -o "$redir_mod" = "Tun模式" ];then
		[ "$clashcore" = "clash.meta" ] && stack=gvisor || stack=system
		tun="tun: {enable: true, stack: $stack}"
	else
		tun='tun: {enable: false}'
	fi
	exper='experimental: {ignore-resolve-fail: true, interface-name: en0}'
	#dns配置
	dns_default='114.114.114.114, 223.5.5.5'
	if [ "$dns_mod" = "fake-ip" ];then
		dns='dns: {enable: true, listen: 0.0.0.0:'$dns_port', use-hosts: true, fake-ip-range: 198.18.0.1/16, enhanced-mode: fake-ip, fake-ip-filter: ["*.lan", "time.windows.com", "time.nist.gov", "time.apple.com", "time.asia.apple.com", "*.*.*.ntp.org", "*.*.ntp.org", "*.ntp.org", "*.ntp.org.cn", "*.openwrt.pool.ntp.org", "time1.cloud.tencent.com", "time.ustc.edu.cn", "pool.ntp.org", "ntp.ubuntu.com", "ntp.aliyun.com", "ntp1.aliyun.com", "ntp2.aliyun.com", "ntp3.aliyun.com", "ntp4.aliyun.com", "ntp5.aliyun.com", "ntp6.aliyun.com", "ntp7.aliyun.com", "time1.aliyun.com", "time2.aliyun.com", "time3.aliyun.com", "time4.aliyun.com", "time5.aliyun.com", "time6.aliyun.com", "time7.aliyun.com", "*.time.edu.cn", "time1.apple.com", "time2.apple.com", "time3.apple.com", "time4.apple.com", "time5.apple.com", "time6.apple.com", "time7.apple.com", "time1.google.com", "time2.google.com", "time3.google.com", "time4.google.com", "music.163.com", "*.music.163.com", "*.126.net", "musicapi.taihe.com", "music.taihe.com", "songsearch.kugou.com", "trackercdn.kugou.com", "*.kuwo.cn", "api-jooxtt.sanook.com", "api.joox.com", "joox.com", "y.qq.com", "*.y.qq.com", "streamoc.music.tc.qq.com", "mobileoc.music.tc.qq.com", "isure.stream.qqmusic.qq.com", "dl.stream.qqmusic.qq.com", "aqqmusic.tc.qq.com", "amobile.music.tc.qq.com", "*.xiami.com", "*.music.migu.cn", "music.migu.cn", "*.msftconnecttest.com", "*.msftncsi.com", "localhost.ptlogin2.qq.com", "*.*.*.srv.nintendo.net", "*.*.stun.playstation.net", "xbox.*.*.microsoft.com", "*.*.xboxlive.com", "proxy.golang.org","*.sgcc.com.cn","*.alicdn.com","*.aliyuncs.com"], default-nameserver: ['$dns_default', 127.0.0.1:53], nameserver: ['$dns_nameserver', 127.0.0.1:53], fallback: ['$dns_fallback'], fallback-filter: {geoip: true}}'
	else
		dns='dns: {enable: true, '$dns_v6', listen: 0.0.0.0:'$dns_port', use-hosts: true, enhanced-mode: redir-host, default-nameserver: ['$dns_default', 127.0.0.1:53], nameserver: ['$dns_nameserver$dns_local'], fallback: ['$dns_fallback'], fallback-filter: {geoip: true}}'
	fi
	#设置目录
	yaml=$clashdir/config.yaml
	tmpdir=/tmp/clash_$USER
	#预读取变量
	mode=$(grep "^mode" $yaml | head -1 | awk '{print $2}')
	[ -z "$mode" ] && mode='Rule'
	#预删除需要添加的项目
	a=$(grep -n "port:" $yaml | head -1 | cut -d ":" -f 1)
	b=$(grep -n "^prox" $yaml | head -1 | cut -d ":" -f 1)
	b=$((b-1))
	mkdir -p $tmpdir > /dev/null
	[ "$b" != "0" ] && sed "${a},${b}d" $yaml > $tmpdir/proxy.yaml
	#跳过本地tls证书验证
	[ "$skip_cert" = "已开启" ] && sed -i '1,99s/skip-cert-verify: false/skip-cert-verify: true/' $tmpdir/proxy.yaml
	#添加配置
###################################
	cat > $tmpdir/set.yaml <<EOF
mixed-port: $mix_port
redir-port: $redir_port
authentication: ["$authentication"]
$lan
mode: $mode
$log
$ipv6
external-controller: :$db_port
external-ui: $db_ui
secret: $secret
$tun
$exper
$dns
store-selected: $restore
hosts:
EOF
###################################
	[ -f $clashdir/user.yaml ] && yaml_user=$clashdir/user.yaml
	#读取本机hosts并生成配置文件
	hosts_dir=/etc/hosts
	if [ "$redir_mod" != "纯净模式" ] && [ "$dns_no" != "已禁用" ] && [ -f $hosts_dir ];then
		while read line;do
			[ -n "$(echo "$line")" ] && \
			[ -z "$(echo "$line" | grep '#')" ] && \
			hosts_ip=$(echo $line | awk '{print $1}')  && \
			hosts_domain=$(echo $line | awk '{print $2}') && \
			echo "   '$hosts_domain': $hosts_ip" >> $tmpdir/hosts.yaml
		done < $hosts_dir
	fi
	#合并文件
	[ -f $clashdir/user.yaml ] && yaml_user=$clashdir/user.yaml
	[ -f $clashdir/hosts.yaml ] && yaml_hosts=$clashdir/hosts.yaml
	cut -c 1- $tmpdir/set.yaml $yaml_hosts $yaml_user $tmpdir/proxy.yaml > $tmpdir/config.yaml
	#插入自定义规则
	sed -i "/#自定义规则/d" $tmpdir/config.yaml
	space=$(sed -n '/^rules/{n;p}' $tmpdir/proxy.yaml | grep -oE '^\ *') #获取空格数
	if [ -f $clashdir/rules.yaml ];then
		sed -i '/^$/d' $clashdir/rules.yaml && echo >> $clashdir/rules.yaml #处理换行
		while read line;do
			[ -z "$(echo "$line" | grep '#')" ] && \
			[ -n "$(echo "$line" | grep '\-\ ')" ] && \
			line=$(echo "$line" | sed 's#/#\\/#') && \
			sed -i "/^rules:/a\\$space$line #自定义规则" $tmpdir/config.yaml
		done < $clashdir/rules.yaml
	fi
	#tun/fake-ip防止流量回环
	if [ "$redir_mod" = "混合模式" -o "$redir_mod" = "Tun模式" -o "$dns_mod" = "fake-ip" ];then
		sed -i "/^rules:/a\\$space- SRC-IP-CIDR,198.18.0.0/16,REJECT #自定义规则(防止回环)" $tmpdir/config.yaml
	fi
	#如果没有使用小闪存模式
	if [ "$tmpdir" != "$bindir" ];then
		cmp -s $tmpdir/config.yaml $yaml >/dev/null 2>&1
		[ "$?" != 0 ] && mv -f $tmpdir/config.yaml $yaml || rm -f $tmpdir/config.yaml
	fi
	rm -f $tmpdir/set.yaml
	rm -f $tmpdir/proxy.yaml
	rm -f $tmpdir/hosts.yaml
}
#设置路由规则
cn_ip_route(){	
	if [ ! -f $bindir/cn_ip.txt ];then
		if [ -f $clashdir/cn_ip.txt ];then
			mv $clashdir/cn_ip.txt $bindir/cn_ip.txt
		else
			logger "未找到cn_ip列表，正在下载！" 33
			$0 webget $bindir/cn_ip.txt "$update_url/bin/china_ip_list.txt"
			[ "$?" = "1" ] && rm -rf $bindir/cn_ip.txt && logger "列表下载失败，已退出！" 31 && exit 1
		fi
	fi
	if [ -f $bindir/cn_ip.txt ];then
	echo "create cn_ip hash:net family inet hashsize 1024 maxelem 65536" > /tmp/cn_$USER.ipset
	awk '!/^$/&&!/^#/{printf("add cn_ip %s'" "'\n",$0)}' $bindir/cn_ip.txt >> /tmp/cn_$USER.ipset
	ipset -! flush cn_ip 2>/dev/null
	ipset -! restore < /tmp/cn_$USER.ipset
	rm -rf cn_$USER.ipset
	fi
}
start_redir(){
	#允许tun网卡接受流量
	if [ "$redir_mod" = "Tun模式" -o "$redir_mod" = "混合模式" ];then
		iptables -I FORWARD -o utun -j ACCEPT
		[ "$ipv6_support" = "已开启" ] && ip6tables -I FORWARD -o utun -j ACCEPT > /dev/null 2>&1
	fi
	#流量过滤规则
	iptables -t nat -N clash
	iptables -t nat -A clash -d 0.0.0.0/8 -j RETURN
	iptables -t nat -A clash -d 10.0.0.0/8 -j RETURN
	iptables -t nat -A clash -d 127.0.0.0/8 -j RETURN
	iptables -t nat -A clash -d 169.254.0.0/16 -j RETURN
	iptables -t nat -A clash -d 172.16.0.0/12 -j RETURN
	iptables -t nat -A clash -d 192.168.0.0/16 -j RETURN
	iptables -t nat -A clash -d 224.0.0.0/4 -j RETURN
	iptables -t nat -A clash -d 240.0.0.0/4 -j RETURN
	[ "$dns_mod" = "redir_host" -a "$cn_ip_route" = "已开启" ] && iptables -t nat -A clash -m set --match-set cn_ip dst -j RETURN >/dev/null 2>&1 #绕过大陆IP
	if [ "$macfilter_type" = "白名单" -a -n "$(cat $clashdir/mac)" ];then
		#mac白名单
		for mac in $(cat $clashdir/mac); do
			iptables -t nat -A clash -p tcp $ports -m mac --mac-source $mac -j REDIRECT --to-ports $redir_port
		done
	else
		#mac黑名单
		for mac in $(cat $clashdir/mac); do
			iptables -t nat -A clash -m mac --mac-source $mac -j RETURN
		done
		iptables -t nat -A clash -p tcp $ports -j REDIRECT --to-ports $redir_port
	fi
	iptables -t nat -A PREROUTING -p tcp -j clash
	if [ "$public_support" = "已开启" ];then
		iptables -I INPUT -p tcp --dport $mix_port -j ACCEPT
		iptables -I INPUT -p tcp --dport $db_port -j ACCEPT
		[ -n "$(command -v ip6tables)" ] && ip6tables -I INPUT -p tcp --dport $mix_port -j ACCEPT
		[ -n "$(command -v ip6tables)" ] && ip6tables -I INPUT -p tcp --dport $db_port -j ACCEPT
	fi
	#Google home DNS特殊处理
	iptables -t nat -I PREROUTING -p tcp -d 8.8.8.8 -j clash
	iptables -t nat -I PREROUTING -p tcp -d 8.8.4.4 -j clash
	#Docker特殊处理
	[ "$local_proxy" = "已开启" ] && iptables -t nat -I PREROUTING -s 172.16.0.0/12  -j clash
	#设置ipv6转发
	ip6_nat=$(ip6tables -t nat -L 2>&1 | grep -o 'Chain')
	if [ -n "$ip6_nat" -a "$ipv6_support" = "已开启" ];then
		ip6tables -t nat -N clashv6
		if [ "$macfilter_type" = "白名单" -a -n "$(cat $clashdir/mac)" ];then
			#mac白名单
			for mac in $(cat $clashdir/mac); do
				ip6tables -t nat -A clashv6 -p tcp $ports -m mac --mac-source $mac -j REDIRECT --to-ports $redir_port
			done
		else
			#mac黑名单
			for mac in $(cat $clashdir/mac); do
				ip6tables -t nat -A clashv6 -m mac --mac-source $mac -j RETURN
			done
			ip6tables -t nat -A clashv6 -p tcp $ports -j REDIRECT --to-ports $redir_port
		fi
		ip6tables -t nat -A PREROUTING -p tcp -j clashv6
	fi
}
start_dns(){
	#设置dns转发
	iptables -t nat -N clash_dns
	if [ "$macfilter_type" = "白名单" -a -n "$(cat $clashdir/mac)" ];then
		#mac白名单
		for mac in $(cat $clashdir/mac); do
			iptables -t nat -A clash_dns -p udp --dport 53 -m mac --mac-source $mac -j REDIRECT --to $dns_port
			iptables -t nat -A clash_dns -p tcp --dport 53 -m mac --mac-source $mac -j REDIRECT --to $dns_port
		done
	else
		#mac黑名单
		for mac in $(cat $clashdir/mac); do
			iptables -t nat -A clash_dns -m mac --mac-source $mac -j RETURN
		done	
		iptables -t nat -A clash_dns -p udp --dport 53 -j REDIRECT --to $dns_port
		iptables -t nat -A clash_dns -p tcp --dport 53 -j REDIRECT --to $dns_port
	fi
	iptables -t nat -A PREROUTING -p udp -j clash_dns
	#ipv6DNS
	ip6_nat=$(ip6tables -t nat -L 2>&1 | grep -o 'Chain')
	if [ -n "$ip6_nat" ];then
		ip6tables -t nat -N clashv6_dns > /dev/null 2>&1
		if [ "$macfilter_type" = "白名单" -a -n "$(cat $clashdir/mac)" ];then
			#mac白名单
			for mac in $(cat $clashdir/mac); do
				ip6tables -t nat -A clashv6_dns -p udp --dport 53 -m mac --mac-source $mac -j REDIRECT --to $dns_port
				ip6tables -t nat -A clashv6_dns -p tcp --dport 53 -m mac --mac-source $mac -j REDIRECT --to $dns_port
			done
		else
			#mac黑名单
			for mac in $(cat $clashdir/mac); do
				ip6tables -t nat -A clashv6_dns -m mac --mac-source $mac -j RETURN
			done	
			ip6tables -t nat -A clashv6_dns -p udp --dport 53 -j REDIRECT --to $dns_port
			ip6tables -t nat -A clashv6_dns -p tcp --dport 53 -j REDIRECT --to $dns_port
		fi
		ip6tables -t nat -A PREROUTING -p udp -j clashv6_dns
	else
		ip6tables -I INPUT -p tcp --dport 53 -j REJECT > /dev/null 2>&1
		ip6tables -I INPUT -p udp --dport 53 -j REJECT > /dev/null 2>&1
	fi
	#屏蔽OpenWrt内置53端口转发
	iptables -t nat -D PREROUTING -p udp --dport 53 -j REDIRECT --to-ports 53 2> /dev/null
	iptables -t nat -D PREROUTING -p tcp --dport 53 -j REDIRECT --to-ports 53 2> /dev/null
	ip6tables -t nat -D PREROUTING -p udp --dport 53 -j REDIRECT --to-ports 53 2> /dev/null
	ip6tables -t nat -D PREROUTING -p tcp --dport 53 -j REDIRECT --to-ports 53 2> /dev/null	
}
start_udp(){
	ip rule add fwmark 1 table 100
	ip route add local default dev lo table 100
	iptables -t mangle -N clash
	iptables -t mangle -A clash -d 0.0.0.0/8 -j RETURN
	iptables -t mangle -A clash -d 10.0.0.0/8 -j RETURN
	iptables -t mangle -A clash -d 127.0.0.0/8 -j RETURN
	iptables -t mangle -A clash -d 169.254.0.0/16 -j RETURN
	iptables -t mangle -A clash -d 172.16.0.0/12 -j RETURN
	iptables -t mangle -A clash -d 192.168.0.0/16 -j RETURN
	iptables -t mangle -A clash -d 224.0.0.0/4 -j RETURN
	iptables -t mangle -A clash -d 240.0.0.0/4 -j RETURN
	[ "$dns_mod" = "redir_host" -a "$cn_ip_route" = "已开启" ] && iptables -t mangle -A clash -m set --match-set cn_ip dst -j RETURN >/dev/null 2>&1 #绕过大陆IP
	if [ "$macfilter_type" = "白名单" -a -n "$(cat $clashdir/mac)" ];then
		#mac白名单
		for mac in $(cat $clashdir/mac); do
			iptables -t mangle -A clash -p udp -m mac --mac-source $mac -j TPROXY --on-port $redir_port --tproxy-mark 1
		done
	else
		#mac黑名单
		for mac in $(cat $clashdir/mac); do
			iptables -t mangle -A clash -m mac --mac-source $mac -j RETURN
		done
		iptables -t mangle -A clash -p udp -j TPROXY --on-port $redir_port --tproxy-mark 1
	fi
	iptables -t mangle -A PREROUTING -p udp -j clash
}
start_output(){
	#流量过滤规则
	iptables -t nat -N clash_out
	iptables -t nat -A clash_out -m owner --gid-owner 7890 -j RETURN
	iptables -t nat -A clash_out -d 0.0.0.0/8 -j RETURN
	iptables -t nat -A clash_out -d 10.0.0.0/8 -j RETURN
	iptables -t nat -A clash_out -d 127.0.0.0/8 -j RETURN
	iptables -t nat -A clash_out -d 169.254.0.0/16 -j RETURN
	iptables -t nat -A clash_out -d 172.16.0.0/12 -j RETURN
	iptables -t nat -A clash_out -d 192.168.0.0/16 -j RETURN
	iptables -t nat -A clash_out -d 224.0.0.0/4 -j RETURN
	iptables -t nat -A clash_out -d 240.0.0.0/4 -j RETURN
	[ "$dns_mod" = "redir_host" -a "$cn_ip_route" = "已开启" ] && iptables -t nat -A clash_out -m set --match-set cn_ip dst -j RETURN >/dev/null 2>&1 #绕过大陆IP
	if [ "$macfilter_type" = "白名单" -a -n "$(cat $clashdir/mac)" ];then
		#mac白名单
		for mac in $(cat $clashdir/mac); do
			iptables -t nat -A clash_out -p tcp $ports -m mac --mac-source $mac -j REDIRECT --to-ports $redir_port
		done
	else
		#mac黑名单
		for mac in $(cat $clashdir/mac); do
			iptables -t nat -A clash_out -m mac --mac-source $mac -j RETURN
		done
		iptables -t nat -A clash_out -p tcp $ports -j REDIRECT --to-ports $redir_port
	fi
	iptables -t nat -A OUTPUT -p tcp -j clash_out
	#设置dns转发
	iptables -t nat -N clash_dns_out
	iptables -t nat -A clash_dns_out -m owner --gid-owner 7890 -j RETURN
	if [ "$macfilter_type" = "白名单" -a -n "$(cat $clashdir/mac)" ];then
		#mac白名单
		for mac in $(cat $clashdir/mac); do
			iptables -t nat -A clash_dns_out -p udp --dport 53 -m mac --mac-source $mac -j REDIRECT --to $dns_port
			iptables -t nat -A clash_dns_out -p tcp --dport 53 -m mac --mac-source $mac -j REDIRECT --to $dns_port
		done
	else
		#mac黑名单
		for mac in $(cat $clashdir/mac); do
			iptables -t nat -A clash_dns_out -m mac --mac-source $mac -j RETURN
		done	
		iptables -t nat -A clash_dns_out -p udp --dport 53 -j REDIRECT --to $dns_port
		iptables -t nat -A clash_dns_out -p tcp --dport 53 -j REDIRECT --to $dns_port
	fi
	iptables -t nat -A OUTPUT -p udp -j clash_dns_out
}
stop_iptables(){
    #重置iptables规则
	ip rule del fwmark 1 table 100  2> /dev/null
	ip route del local default dev lo table 100 2> /dev/null
	iptables -t nat -D PREROUTING -p tcp -j clash 2> /dev/null
	iptables -D INPUT -p tcp --dport $mix_port -j ACCEPT 2> /dev/null
	iptables -D INPUT -p tcp --dport $db_port -j ACCEPT 2> /dev/null
	iptables -t nat -D PREROUTING -p udp -j clash_dns 2> /dev/null
	iptables -t nat -D PREROUTING -p tcp -d 8.8.8.8 -j clash 2> /dev/null
	iptables -t nat -D PREROUTING -p tcp -d 8.8.4.4 -j clash 2> /dev/null
	iptables -t nat -D PREROUTING -s 172.16.0.0/12  -j clash 2> /dev/null
	iptables -t nat -F clash 2> /dev/null
	iptables -t nat -X clash 2> /dev/null
	iptables -t nat -F clash_dns 2> /dev/null
	iptables -t nat -X clash_dns 2> /dev/null
	iptables -D FORWARD -o utun -j ACCEPT 2> /dev/null
	#重置output规则
	iptables -t nat -D OUTPUT -p tcp -j clash_out 2> /dev/null
	iptables -t nat -F clash_out 2> /dev/null
	iptables -t nat -X clash_out 2> /dev/null	
	iptables -t nat -D OUTPUT -p udp -j clash_dns_out 2> /dev/null
	iptables -t nat -F clash_dns_out 2> /dev/null
	iptables -t nat -X clash_dns_out 2> /dev/null
	#重置udp规则
	iptables -t mangle -D PREROUTING -p udp -j clash 2> /dev/null
	iptables -t mangle -F clash 2> /dev/null
	iptables -t mangle -X clash 2> /dev/null
	#重置ipv6规则
	ip6tables -D INPUT -p tcp --dport $mix_port -j ACCEPT 2> /dev/null
	ip6tables -D INPUT -p tcp --dport $db_port -j ACCEPT 2> /dev/null
	ip6tables -t nat -D PREROUTING -p tcp -j clashv6 2> /dev/null
	ip6tables -t nat -D PREROUTING -p udp -j clashv6_dns 2> /dev/null
	ip6tables -t nat -F clashv6 2> /dev/null
	ip6tables -t nat -X clashv6 2> /dev/null
	ip6tables -t nat -F clashv6_dns 2> /dev/null
	ip6tables -t nat -X clashv6_dns 2> /dev/null
	ip6tables -D FORWARD -o utun -j ACCEPT 2> /dev/null
	#清理ipset规则
	ipset destroy cn_ip >/dev/null 2>&1
	#移除dnsmasq转发规则
	uci del dhcp.@dnsmasq[-1].server >/dev/null 2>&1
	uci delete dhcp.@dnsmasq[0].cachesize >/dev/null 2>&1
	/etc/init.d/dnsmasq restart >/dev/null 2>&1
}
#面板配置保存相关
web_save(){
	get_save(){
		if curl --version > /dev/null 2>&1;then
			curl -s -H "Authorization: Bearer ${secret}" -H "Content-Type:application/json" "$1"
		elif [ -n "$(wget --help 2>&1|grep '\-\-method')" ];then
			wget -q --header="Authorization: Bearer ${secret}" --header="Content-Type:application/json" -O - "$1"
		fi
	}
	#使用get_save获取面板节点设置
	get_save http://localhost:${db_port}/proxies | awk -F "{" '{for(i=1;i<=NF;i++) print $i}' | grep -E '^"all".*"Selector"' > /tmp/clash_web_check_$USER
	while read line ;do
		def=$(echo $line | awk -F "[[,]" '{print $2}')
		now=$(echo $line | grep -oE '"now".*",' | sed 's/"now"://g'| sed 's/,//g')
		[ "$def" != "$now" ] && echo $line | grep -oE '"name".*"now".*",' | sed 's/"name"://g' | sed 's/"now"://g'| sed 's/"//g' >> /tmp/clash_web_save_$USER
	done < /tmp/clash_web_check_$USER
	rm -rf /tmp/clash_web_check_$USER
	#对比文件，如果有变动且不为空则写入磁盘，否则清除缓存
	if [ -s /tmp/clash_web_save_$USER ];then
		compare /tmp/clash_web_save_$USER $clashdir/web_save
		[ "$?" = 0 ] && rm -rf /tmp/clash_web_save_$USER || mv -f /tmp/clash_web_save_$USER $clashdir/web_save
	fi
}
web_restore(){
	put_save(){
		if curl --version > /dev/null 2>&1;then
			curl -sS -X PUT -H "Authorization: Bearer ${secret}" -H "Content-Type:application/json" "$1" -d "$2" >/dev/null
		elif wget --version > /dev/null 2>&1;then
			wget -q --method=PUT --header="Authorization: Bearer ${secret}" --header="Content-Type:application/json" --body-data="$2" "$1" >/dev/null
		fi
	}
	#设置循环检测clash面板端口
	i=1
	while [ $i -lt 10 ];do
		sleep 1
		if curl --version > /dev/null 2>&1;then
			test=$(curl -s http://localhost:${db_port})
		else
			test=$(wget -q -O - http://localhost:${db_port})
		fi
		[ -n "$test" ] && i=10
	done
	#发送数据
	num=$(cat $clashdir/web_save | wc -l)
	for i in `seq $num`;
	do
		group_name=$(awk -F ',' 'NR=="'${i}'" {print $1}' $clashdir/web_save | sed 's/ /%20/g')
		now_name=$(awk -F ',' 'NR=="'${i}'" {print $2}' $clashdir/web_save)
		put_save http://localhost:${db_port}/proxies/${group_name} "{\"name\":\"${now_name}\"}"
	done
}
#启动相关
catpac(){
	cat > /tmp/clash_pac <<EOF
function FindProxyForURL(url, host) {
	if (
		isInNet(host, "0.0.0.0", "255.0.0.0")||
		isInNet(host, "10.0.0.0", "255.0.0.0")||
		isInNet(host, "127.0.0.0", "255.0.0.0")||
		isInNet(host, "224.0.0.0", "224.0.0.0")||
		isInNet(host, "240.0.0.0", "240.0.0.0")||
		isInNet(host, "172.16.0.0",  "255.240.0.0")||
		isInNet(host, "192.168.0.0", "255.255.0.0")||
		isInNet(host, "169.254.0.0", "255.255.0.0")
	)
		return "DIRECT";
	else
		return "PROXY $host:$mix_port; DIRECT; SOCKS5 $host:$mix_port"
}
EOF
	compare /tmp/clash_pac $bindir/ui/pac
	[ "$?" = 0 ] && rm -rf /tmp/clash_pac || mv -f /tmp/clash_pac $bindir/ui/pac
}
bfstart(){
	#读取配置文件
	getconfig
	[ ! -d $bindir/ui ] && mkdir -p $bindir/ui
	[ -z "$update_url" ] || [ -n "$(echo $update_url | grep 'github')" ] && update_url=https://cdn.jsdelivr.net/gh/juewuy/ShellClash@master
	#检查clash核心
	if [ ! -f $bindir/clash ];then
		if [ -f $clashdir/clash ];then
			mv $clashdir/clash $bindir/clash && chmod +x $bindir/clash
		else
			logger "未找到clash核心，正在下载！" 33
			if [ -z "$clashcore" ];then
				[ "$redir_mod" = "混合模式" -o "$redir_mod" = "Tun模式" ] && clashcore=clash.net || clashcore=clash
			fi
			[ -z "$cpucore" ] && source $clashdir/getdate.sh && getcpucore
			[ -z "$cpucore" ] && logger 找不到设备的CPU信息，请手动指定处理器架构类型！ 31 && setcpucore
			$0 webget $bindir/clash "$update_url/bin/$clashcore/clash-linux-$cpucore"
			[ "$?" = "1" ] && rm -rf $bindir/clash && logger "核心下载失败，已退出！" 31 && exit 1
			[ ! -x $bindir/clash ] && chmod +x $bindir/clash 	#检测可执行权限
			clashv=$($bindir/clash -v | awk '{print $2}')
			setconfig clashv $clashv
		fi
	fi
	#检查数据库文件
	if [ ! -f $bindir/Country.mmdb ];then
		if [ -f $clashdir/Country.mmdb ];then
			mv $clashdir/Country.mmdb $bindir/Country.mmdb
		else
			logger "未找到GeoIP数据库，正在下载！" 33
			[ -z "$geotype" ] && geotype=cn_mini.mmdb
			$0 webget $bindir/Country.mmdb $update_url/bin/$geotype
			[ "$?" = "1" ] && rm -rf $bindir/Country.mmdb && logger "数据库下载失败，已退出！" 31 && exit 1
			Geo_v=$(date +"%Y%m%d")
			setconfig Geo_v $Geo_v
		fi
	fi
	#检查dashboard文件
	if [ -f $clashdir/ui/index.html -a ! -f $bindir/ui/index.html ];then
		cp -rf $clashdir/ui $bindir
	fi
	#检查curl或wget支持
	curl --version > /dev/null 2>&1
	[ "$?" = 1 ] && wget --version > /dev/null 2>&1
	[ "$?" = 1 ] && restore=true || restore=false
	#生成pac文件
	catpac
	#检查yaml配置文件
	if [ ! -f $clashdir/config.yaml ];then
		if [ -n "$Url" -o -n "$Https" ];then
			logger "未找到配置文件，正在下载！" 33
			getyaml
			exit 0
		else
			logger "未找到配置文件链接，请先导入配置文件！" 31
			exit 1
		fi
	fi
	#预下载Geosite数据库
	if [ "$clashcore" = "clash.meta" ] && [ ! -f $bindir/geosite.dat ] && [ -n "$(cat $clashdir/config.yaml|grep -Ei 'geosite')" ];then
		if [ -f $clashdir/geosite.dat ];then
			mv $clashdir/geosite.dat $bindir/geosite.dat
		else
			logger "未找到geosite数据库，正在下载！" 33
			$0 webget $bindir/geosite.dat $update_url/bin/geosite.dat
			[ "$?" = "1" ] && rm -rf $bindir/geosite.dat && logger "数据库下载失败，已退出！" 31 && exit 1
		fi
	fi
	#本机代理准备
	if [ "$local_proxy" = "已开启" -a "$local_type" = "iptables增强模式" ];then
		if [ -z "$(id shellclash 2>/dev/null | grep 'root')" ];then
			userdel shellclash 2>/dev/null
			useradd shellclash -u 7890
			groupmod shellclash -g 7890
			sed -Ei s/7890:7890/0:7890/g /etc/passwd
		fi
		if [ "$start_old" != "已开启" ];then
			[ -w /etc/systemd/system/clash.service ] && servdir=/etc/systemd/system/clash.service
			[ -w /usr/lib/systemd/system/clash.service ] && servdir=/usr/lib/systemd/system/clash.service
			setconfig ExecStart "/bin/su\ shellclash\ -c\ \"$bindir/clash\ -d\ $bindir\"" $servdir
			systemctl daemon-reload >/dev/null
		fi
	fi
}
afstart(){

	#读取配置文件
	getconfig
	$bindir/clash -t -d $bindir >/dev/null
	if [ "$?" = 0 ];then
		#设置iptables转发规则
		[ "$dns_mod" = "redir_host" ] && [ "$cn_ip_route" = "已开启" ] && cn_ip_route
		if [ "$redir_mod" != "纯净模式" ] && [ "$dns_no" != "已禁用" ];then
			if [ "$dns_redir" != "已开启" ];then
				start_dns
			else
				#openwrt使用dnsmasq转发
				uci del dhcp.@dnsmasq[-1].server >/dev/null 2>&1
				uci delete dhcp.@dnsmasq[0].resolvfile 2>/dev/null
				uci add_list dhcp.@dnsmasq[0].server=127.0.0.1#$dns_port > /dev/null 2>&1
				/etc/init.d/dnsmasq restart >/dev/null 2>&1
			fi
		fi
		[ "$redir_mod" != "纯净模式" ] && [ "$redir_mod" != "Tun模式" ] && start_redir
		[ "$redir_mod" = "Redir模式" ] && [ "$tproxy_mod" = "已开启" ] && start_udp
		[ "$local_proxy" = "已开启" ] && [ "$local_type" = "iptables增强模式" ] && start_output
		#标记启动时间
		mark_time
		#设置本机代理
		[ "$local_proxy" = "已开启" ] && $0 set_proxy $mix_port $db_port
		#加载定时任务
		[ -f $clashdir/cron ] && croncmd $clashdir/cron
		#流媒体预解析
		if [ "$netflix_pre" = "已开启" -o "$disneyp_pre" = "已开启" ];then
			cronset '#ShellClash流媒体预解析' "* */$stearming_int * * * $clashdir/start.sh steaming #ShellClash流媒体预解析"
			$0 steaming & #后台执行流媒体预解析进程
		fi		
		#启用面板配置自动保存
		if [ "$restore" = false ];then
			cronset '#每10分钟保存节点配置' "*/10 * * * * test -n \"\$(pidof clash)\" && $clashdir/start.sh web_save #每10分钟保存节点配置"
			[ -f $clashdir/web_save ] && web_restore & #后台还原面板配置
		fi
	else
		logger "clash服务启动失败！请查看报错信息！" 31
		$bindir/clash -t -d $bindir
		echo "$($bindir/clash -t -d $bindir)" >> $clashdir/log
		$0 stop
		exit 1
	fi
}
start_old(){
	#使用传统后台执行二进制文件的方式执行
	if [ "$local_proxy" = "已开启" -a "$local_type" = "iptables增强模式" ];then
		su shellclash -c "$bindir/clash -d $bindir >/dev/null" &
	else
		[ -n "$(command -v nohup)" ] && nohup=nohup
		$nohup $bindir/clash -d $bindir >/dev/null 2>&1 &
	fi
	afstart
	$0 daemon
}

case "$1" in

bfstart)
		bfstart
	;;
afstart)
		afstart
	;;
start)		
		[ -n "$(pidof clash)" ] && $0 stop #禁止多实例
		getconfig
		#检测必须文件并下载
		bfstart
		stop_iptables #清理iptables
		#使用内置规则强行覆盖config配置文件
		[ "$modify_yaml" != "已开启" ] && modify_yaml
		#使用不同方式启动clash服务
		if [ "$start_old" = "已开启" ];then
			start_old
		elif [ -f /etc/rc.common ];then
			/etc/init.d/clash start
		elif [ "$USER" = "root" ];then
			systemctl start clash.service
		else
			start_old
		fi
	;;
stop)	
		getconfig
		[ -n "$(pidof clash)" ] && [ "$restore" = false ] && web_save #保存面板配置
		#删除守护进程&面板配置自动保存
		cronset "clash保守模式守护进程"
		cronset "保存节点配置"
		cronset "流媒体预解析"
		#多种方式结束进程
		if [ -f /etc/rc.common ];then
			/etc/init.d/clash stop >/dev/null 2>&1
		elif [ "$USER" = "root" ];then
			systemctl stop clash.service >/dev/null 2>&1
		fi
		PID=$(pidof clash) && [ -n "$PID" ] &&  kill -9 $PID >/dev/null 2>&1
		stop_iptables #清理iptables
		$0 unset_proxy #禁用本机代理
        ;;
restart)
        $0 stop
        $0 start
        ;;
init)
        if [ -d "/etc/storage/clash" ];then
			clashdir=/etc/storage/clash
			if [ -w "/opt/etc/profile" ];then
				profile=/opt/etc/profile
			else
				profile=/etc/profile
				sed -i '' $profile #将软链接转化为一般文件
			fi
		fi
		[ -d "/jffs/clash" ] && clashdir=/jffs/clash && profile=/jffs/configs/profile.add
		echo "alias clash=\"$clashdir/clash.sh\"" >> $profile 
		echo "export clashdir=\"$clashdir\"" >> $profile 
		$0 start
        ;;
getyaml)	
		getconfig
		getyaml
		;;
updateyaml)	
		$0 getyaml
		$0 restart
		;;
webget)
		#设置临时http代理 
		[ -n "$(pidof clash)" ] && getconfig && export all_proxy="http://$authentication@127.0.0.1:$mix_port"
		#参数【$2】代表下载目录，【$3】代表在线地址
		#参数【$4】代表输出显示，【$4】不启用重定向
		#参数【$6】代表验证证书，【$7】使用clash文件头
		if curl --version > /dev/null 2>&1;then
			[ "$4" = "echooff" ] && progress='-s' || progress='-#'
			[ "$5" = "rediroff" ] && redirect='' || redirect='-L'
			[ "$6" = "skipceroff" ] && certificate='' || certificate='-k'
			#[ -n "$7" ] && agent='-A "clash"'
			result=$(curl $agent -w %{http_code} --connect-timeout 3 $progress $redirect $certificate -o "$2" "$3")
			[ "$result" != "200" ] && export all_proxy="" && result=$(curl $agent -w %{http_code} --connect-timeout 3 $progress $redirect $certificate -o "$2" "$3")
		else
			if wget --version > /dev/null 2>&1;then
				[ "$4" = "echooff" ] && progress='-q' || progress='-q --show-progress'
				[ "$5" = "rediroff" ] && redirect='--max-redirect=0' || redirect=''
				[ "$6" = "skipceroff" ] && certificate='' || certificate='--no-check-certificate'
				timeout='--timeout=3 -t 2'
				#[ -n "$7" ] && agent='--user-agent="clash"'
			fi
			[ "$4" = "echoon" ] && progress=''
			[ "$4" = "echooff" ] && progress='-q'
			wget -Y on $agent $progress $redirect $certificate $timeout -O "$2" "$3"
			if [ "$?" != "0" ];then
				wget -Y off $agent $progress $redirect $certificate $timeout -O "$2" "$3"
				[ "$?" = "0" ] && result="200"
			else
				result="200"
			fi
		fi
		[ "$result" = "200" ] && exit 0 || exit 1
		;;
web_save)
		getconfig
		web_save
	;;
web_restore)
		getconfig
		web_restore
	;;
daemon)
		getconfig
		cronset '#clash保守模式守护进程' "*/1 * * * * test -z \"\$(pidof clash)\" && $clashdir/start.sh restart #clash保守模式守护进程"
	;;
cronset)
		cronset $2 $3
	;;
set_proxy)
		getconfig
		if  [ "$local_type" = "环境变量" ];then
			[ -w ~/.bashrc ] && profile=~/.bashrc
			[ -w /etc/profile ] && profile=/etc/profile
			echo 'export all_proxy=http://127.0.0.1:'"$mix_port" >> $profile
			echo 'export ALL_PROXY=$all_proxy' >>  $profile
		fi
	;;
unset_proxy)	
		[ -w ~/.bashrc ] && profile=~/.bashrc
		[ -w /etc/profile ] && profile=/etc/profile
		sed -i '/all_proxy/'d  $profile
		sed -i '/ALL_PROXY/'d  $profile
	;;
steaming)	
		#设置循环检测clashDNS端口
		i=1
		while [ $i -lt 10 ];do
			sleep 1
			nslookup baidu.com 127.0.0.1:${dns_port} > /dev/null 2>&1
			[ "$?" = 0 ] && i=10
		done
		getconfig
		steaming_dns(){
			steaming_dir=$clashdir/steaming/${steaming_type}_Domains.list
			if [ ! -f "$steaming_dir" ];then
				echo 未找到$steaming_type域名数据库，正在下载！
				mkdir -p $clashdir/steaming
				$0 webget "$steaming_dir" "$update_url/bin/${steaming_type}_Domains.list"
				[ "$?" = "1" ] && logger "$steaming_type数据库文件下载失败"
			fi
			if [ -f "$steaming_dir" ];then
				for line in $(cat $steaming_dir);do
					[ -n "$line" ] && nslookup "$line" 127.0.0.1:${dns_port}
				done >/dev/null 2>&1
				echo "$steaming_type域名预解析完成！"
			fi
		}
		echo
		echo "正在后台进行流媒体预解析服务，请耐心等待！"
		[ "$netflix_pre" = "已开启" ] && steaming_type=Netflix && steaming_dns
		[ "$disneyP_pre" = "已开启" ] && steaming_type=Disney_Plus && steaming_dns
		echo "请输入回车继续！"
	;;
esac

exit 0
