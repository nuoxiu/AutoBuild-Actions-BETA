#!/bin/bash
# AutoBuild Module - 优化版 by nuoxiu
# 适配 Newifi D2 + 2023-06-09 分支

Firmware_Diy_Core() {
	Author=AUTO
	Author_URL=AUTO
	Default_Flag=AUTO
	Default_IP="192.168.1.1"
	Default_Title="Powered by AutoBuild-Actions"
	Short_Fw_Date=true
	x86_Full_Images=false
	Fw_MFormat=AUTO
	Regex_Skip="packages|buildinfo|sha256sums|manifest|kernel|rootfs|factory|itb|profile|ext4|json"
	AutoBuild_Features=true
	AutoBuild_Features_Patch=true
	AutoBuild_Features_Kconfig=false
}

Firmware_Diy() {
	# 使用 20230609 分支
	case "${OP_AUTHOR}/${OP_REPO}:${OP_BRANCH}" in
	coolsnowwolf/lede:20230609)
		cat >> ${Version_File} <<EOF
sed -i '/check_signature/d' /etc/opkg.conf
if [ -z "\$(grep "REDIRECT --to-ports 53" /etc/firewall.user 2> /dev/null)" ]
then
	echo '# iptables -t nat -A PREROUTING -p udp --dport 53 -j REDIRECT --to-ports 53' >> /etc/firewall.user
	echo '# iptables -t nat -A PREROUTING -p tcp --dport 53 -j REDIRECT --to-ports 53' >> /etc/firewall.user
	echo '# [ -n "\$(command -v ip6tables)" ] && ip6tables -t nat -A PREROUTING -p udp --dport 53 -j REDIRECT --to-ports 53' >> /etc/firewall.user
	echo '# [ -n "\$(command -v ip6tables)" ] && ip6tables -t nat -A PREROUTING -p tcp --dport 53 -j REDIRECT --to-ports 53' >> /etc/firewall.user
	echo 'iptables -t mangle -A PREROUTING -i pppoe -p icmp --icmp-type destination-unreachable -j DROP' >> /etc/firewall.user
	echo 'iptables -t mangle -A PREROUTING -i pppoe -p tcp -m tcp --tcp-flags ACK,RST RST -j DROP' >> /etc/firewall.user
	echo 'iptables -t mangle -A PREROUTING -i pppoe -p tcp -m tcp --tcp-flags PSH,FIN PSH,FIN -j DROP' >> /etc/firewall.user
	echo '[ -n "\$(command -v ip6tables)" ] && ip6tables -t mangle -A PREROUTING -i pppoe -p tcp -m tcp --tcp-flags PSH,FIN PSH,FIN -j DROP' >> /etc/firewall.user
	echo '[ -n "\$(command -v ip6tables)" ] && ip6tables -t mangle -A PREROUTING -i pppoe -p ipv6-icmp --icmpv6-type destination-unreachable -j DROP' >> /etc/firewall.user
	echo '[ -n "\$(command -v ip6tables)" ] && ip6tables -t mangle -A PREROUTING -i pppoe -p tcp -m tcp --tcp-flags ACK,RST RST -j DROP' >> /etc/firewall.user
fi
exit 0
EOF
		# 移除无用的主题
		rm -r ${FEEDS_LUCI}/luci-theme-argon* 2>/dev/null || true
		
		# 添加 OpenClash
		AddPackage other vernesong OpenClash dev
		
		# 添加 argon 主题 (新版本)
		AddPackage other jerrykuku luci-app-argon-config master
		AddPackage themes jerrykuku luci-theme-argon 18.06
		
		# 添加 mosdns (v5)
		AddPackage other sbwml luci-app-mosdns v5-lua
		
		# 添加 msd_lite (多播代理)
		AddPackage msd_lite ximiTech luci-app-msd_lite main
		AddPackage msd_lite ximiTech msd_lite main
		
		# 添加 SmartDNS (使用正确的仓库)
		AddPackage other pymumu luci-app-smartdns master
		
		# 微信推送 (ServerChan)
		AddPackage other tty228 luci-app-serverchan master
		
		# 移除冲突的包
		rm -r ${FEEDS_PKG}/mosdns 2>/dev/null || true
		rm -r ${FEEDS_LUCI}/luci-app-mosdns 2>/dev/null || true
		rm -r ${FEEDS_PKG}/curl 2>/dev/null || true
		rm -r ${FEEDS_PKG}/msd_lite 2>/dev/null || true
		
		# 复制自定义 curl
		Copy ${CustomFiles}/curl ${FEEDS_PKG}
		
		# 针对 ramips 架构的优化
		case "${TARGET_BOARD}" in
		ramips)
			sed -i "/DEVICE_COMPAT_VERSION := 1.1/d" target/linux/ramips/image/mt7621.mk
			Copy ${CustomFiles}/Depends/automount $(PKG_Finder d "package" automount)/files 15-automount
		;;
		esac

		# 针对特定配置下载 Clash 核心
		case "${CONFIG_FILE}" in
		d-team_newifi-d2-Clash | xiaoyu_xy-c5-Clash)
			ClashDL mipsle-hardfloat tun
		;;
		esac
		
		# 针对特定设备复制配置
		case "${TARGET_PROFILE}" in
		d-team_newifi-d2)
			Copy ${CustomFiles}/${TARGET_PROFILE}_system ${BASE_FILES}/etc/config system
		;;
		xiaomi_redmi-router-ax6s)
			AddPackage passwall-depends Openwrt-Passwall openwrt-passwall-packages main
			AddPackage passwall-luci Openwrt-Passwall openwrt-passwall main
		;;
		esac
	;;
	
	# master 分支 (默认)
	coolsnowwolf/lede:master)
		cat >> ${Version_File} <<EOF
sed -i '/check_signature/d' /etc/opkg.conf
if [ -z "\$(grep "REDIRECT --to-ports 53" /etc/firewall.user 2> /dev/null)" ]
then
	echo '# iptables -t nat -A PREROUTING -p udp --dport 53 -j REDIRECT --to-ports 53' >> /etc/firewall.user
	echo '# iptables -t nat -A PREROUTING -p tcp --dport 53 -j REDIRECT --to-ports 53' >> /etc/firewall.user
	echo '# [ -n "\$(command -v ip6tables)" ] && ip6tables -t nat -A PREROUTING -p udp --dport 53 -j REDIRECT --to-ports 53' >> /etc/firewall.user
	echo '# [ -n "\$(command -v ip6tables)" ] && ip6tables -t nat -A PREROUTING -p tcp --dport 53 -j REDIRECT --to-ports 53' >> /etc/firewall.user
	echo 'iptables -t mangle -A PREROUTING -i pppoe -p icmp --icmp-type destination-unreachable -j DROP' >> /etc/firewall.user
	echo 'iptables -t mangle -A PREROUTING -i pppoe -p tcp -m tcp --tcp-flags ACK,RST RST -j DROP' >> /etc/firewall.user
	echo 'iptables -t mangle -A PREROUTING -i pppoe -p tcp -m tcp --tcp-flags PSH,FIN PSH,FIN -j DROP' >> /etc/firewall.user
	echo '[ -n "\$(command -v ip6tables)" ] && ip6tables -t mangle -A PREROUTING -i pppoe -p tcp -m tcp --tcp-flags PSH,FIN PSH,FIN -j DROP' >> /etc/firewall.user
	echo '[ -n "\$(command -v ip6tables)" ] && ip6tables -t mangle -A PREROUTING -i pppoe -p ipv6-icmp --icmpv6-type destination-unreachable -j DROP' >> /etc/firewall.user
	echo '[ -n "\$(command -v ip6tables)" ] && ip6tables -t mangle -A PREROUTING -i pppoe -p tcp -m tcp --tcp-flags ACK,RST RST -j DROP' >> /etc/firewall.user
fi
exit 0
EOF
		git reset --hard 1627fd2c745e496134834a8fb8145ba0aa458ae9
		
		# 移除argon主题（如果存在）
		rm -r ${FEEDS_LUCI}/luci-theme-argon* 2>/dev/null || true
		
		# 添加核心插件
		AddPackage other vernesong OpenClash dev
		AddPackage other jerrykuku luci-app-argon-config master
		AddPackage other sbwml luci-app-mosdns v5-lua
		AddPackage themes jerrykuku luci-theme-argon 18.06
		AddPackage themes thinktip luci-theme-neobird main
		AddPackage msd_lite ximiTech luci-app-msd_lite main
		AddPackage msd_lite ximiTech msd_lite main
		AddPackage iptvhelper riverscn openwrt-iptvhelper master
		
		# 移除冲突包
		rm -r ${FEEDS_PKG}/mosdns 2>/dev/null || true
		rm -r ${FEEDS_LUCI}/luci-app-mosdns 2>/dev/null || true
		rm -r ${FEEDS_PKG}/curl 2>/dev/null || true
		rm -r ${FEEDS_PKG}/msd_lite 2>/dev/null || true
		Copy ${CustomFiles}/curl ${FEEDS_PKG}
		
		# ramips 优化
		case "${TARGET_BOARD}" in
		ramips)
			sed -i "/DEVICE_COMPAT_VERSION := 1.1/d" target/linux/ramips/image/mt7621.mk
			Copy ${CustomFiles}/Depends/automount $(PKG_Finder d "package" automount)/files 15-automount
		;;
		esac

		case "${CONFIG_FILE}" in
		d-team_newifi-d2-Clash | xiaoyu_xy-c5-Clash)
			ClashDL mipsle-hardfloat tun
		;;
		esac
		
		case "${TARGET_PROFILE}" in
		d-team_newifi-d2)
			Copy ${CustomFiles}/${TARGET_PROFILE}_system ${BASE_FILES}/etc/config system
		;;
		xiaomi_redmi-router-ax6s)
			AddPackage passwall-depends Openwrt-Passwall openwrt-passwall-packages main
			AddPackage passwall-luci Openwrt-Passwall openwrt-passwall main
		;;
		esac
	;;
	
	# ImmortalWrt 分支
	immortalwrt/immortalwrt*)
		case "${TARGET_PROFILE}" in
		x86_64)
			sed -i -- 's:/bin/ash:'/bin/bash':g' ${BASE_FILES}/etc/passwd
			case "${CONFIG_FILE}" in
			x86_64)
				AddPackage qosmate hudra0 qosmate main
				AddPackage qosmate hudra0 luci-app-qosmate main
				AddPackage bandix timsaya luci-app-bandix main
				AddPackage bandix timsaya openwrt-bandix main
				AddPackage fakehttp yingziwu luci-app-fakehttp main
				AddPackage fakehttp yingziwu openwrt-fakehttp main
				AddPackage passwall Openwrt-Passwall openwrt-passwall main
			    AddPackage passwall Openwrt-Passwall openwrt-passwall-packages main
				
				git clone https://github.com/immortalwrt/packages /tmp/packages
				git clone https://github.com/immortalwrt/luci /tmp/luci
				rm -rf feeds/packages/net/daed
				rm -rf feeds/luci/applications/luci-app-daed
				cp -a /tmp/packages/net/daed feeds/packages/net/daed
				cp -a /tmp/luci/applications/luci-app-daed feeds/luci/applications/luci-app-daed
				
				sed -i 's/^local excluded_domain = {.*/local excluded_domain = {}/' package/passwall/openwrt-passwall/luci-app-passwall/root/usr/share/passwall/rule_update.lua
				
				rm -rf feeds/packages/lang/golang
				git clone https://github.com/sbwml/packages_lang_golang -b 26.x feeds/packages/lang/golang
				
				rm -r ${FEEDS_LUCI}/luci-app-passwall
				rm -rf ${FEEDS_PKG}/{xray-core,v2ray-geodata,sing-box,chinadns-ng,dns2socks,hysteria,ipt2socks,microsocks,naiveproxy,shadowsocks-libev,shadowsocks-rust,shadowsocksr-libev,simple-obfs,tcping,trojan-plus,tuic-client,v2ray-plugin,xray-plugin,geoview,shadow-tls}

				Copy ${CustomFiles}/speedtest ${BASE_FILES}/usr/bin
				chmod +x ${BASE_FILES}/usr/bin/speedtest
			;;
			esac
		;;
		esac
	;;
	
	# MT798x 设备
	hanwckf/immortalwrt-mt798x*)
		case "${TARGET_PROFILE}" in
		cmcc_rax3000m | jcg_q30)
			AddPackage fakehttp yingziwu luci-app-fakehttp main
			AddPackage fakehttp yingziwu openwrt-fakehttp main
				
			rm -r ${FEEDS_LUCI}/luci-app-passwall
			rm -rf ${FEEDS_PKG}/{xray-core,v2ray-geodata,sing-box,chinadns-ng,dns2socks,hysteria,ipt2socks,microsocks,naiveproxy,shadowsocks-libev,shadowsocks-rust,shadowsocksr-libev,simple-obfs,tcping,trojan-plus,tuic-client,v2ray-plugin,xray-plugin,geoview,shadow-tls}

			AddPackage passwall Openwrt-Passwall openwrt-passwall main
			AddPackage passwall Openwrt-Passwall openwrt-passwall-packages main
			sed -i 's/^local excluded_domain = {.*/local excluded_domain = {}/' package/passwall/openwrt-passwall/luci-app-passwall/root/usr/share/passwall/rule_update.lua
				
			patch < ${CustomFiles}/mt7981/0001-Add-iptables-socket.patch -p1 -d ${WORK}

			rm -rf ${WORK}/package/network/services/dnsmasq
			Copy ${CustomFiles}/dnsmasq ${WORK}/package/network/services

			find ${WORK}/package/ | grep Makefile | grep mosdns | xargs rm -f
			
			rm -rf feeds/packages/lang/golang
			git clone https://github.com/sbwml/packages_lang_golang -b 25.x feeds/packages/lang/golang
				
			AddPackage other sbwml luci-app-mosdns v5
		;;
		esac
	;;
	esac
	
	# x86_64 通用优化
	case "${TARGET_PROFILE}" in
	x86_64)
		Copy ${CustomFiles}/Depends/cpuset ${BASE_FILES}/bin
		ReleaseDL https://api.github.com/repos/nxtrace/NTrace-core/releases/latest nexttrace_linux_amd64 ${BASE_FILES}/bin nexttrace

		hysteria_version="2.7.0"
		wstunnel_version="9.2.3"
		wget --quiet --no-check-certificate -P /tmp \
			https://github.com/apernet/hysteria/releases/download/app%2Fv${hysteria_version}/hysteria-linux-amd64
		wget --quiet --no-check-certificate -P /tmp \
			https://github.com/erebe/wstunnel/releases/download/v${wstunnel_version}/wstunnel_${wstunnel_version}_linux_amd64.tar.gz
		tar -xvzf /tmp/wstunnel_${wstunnel_version}_linux_amd64.tar.gz -C /tmp
		Copy /tmp/wstunnel ${BASE_FILES}/usr/bin
		Copy /tmp/hysteria-linux-amd64 ${BASE_FILES}/usr/bin hysteria
		chmod +x ${BASE_FILES}/usr/bin/hysteria ${BASE_FILES}/usr/bin/wstunnel
	;;
	esac
}
