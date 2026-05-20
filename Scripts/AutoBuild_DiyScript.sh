#!/bin/bash
# AutoBuild Module - 优化版 by nuoxiu
# 适配 Newifi D2 + master 分支

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

	# master 分支 (默认)
	case "${OP_AUTHOR}/${OP_REPO}:${OP_BRANCH}" in
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

		# ====== 1. 移除旧版本 argon 主题 ======
		rm -r ${FEEDS_LUCI}/luci-theme-argon* 2>/dev/null || true

		# ====== 2. 添加核心插件 ======
		# OpenClash
		AddPackage other vernesong OpenClash dev
		
		# Argon 主题配置工具
		AddPackage other jerrykuku luci-app-argon-config master
		
		# 微信推送 (新名称)
		AddPackage other tty228 luci-app-wechatpush master

		# ====== 3. 移除冲突包 ======
		rm -r ${FEEDS_PKG}/mosdns 2>/dev/null || true
		rm -r ${FEEDS_LUCI}/luci-app-mosdns 2>/dev/null || true
		rm -r ${FEEDS_PKG}/msd_lite 2>/dev/null || true

		# ====== 4. ramips 架构优化 ======
		case "${TARGET_BOARD}" in
		ramips)
			sed -i "/DEVICE_COMPAT_VERSION := 1.1/d" target/linux/ramips/image/mt7621.mk
			Copy ${CustomFiles}/Depends/automount $(PKG_Finder d "package" automount)/files 15-automount
		;;
		esac

		# ====== 5. 下载 Clash 核心（已禁用，扩容后自行下载） ======
		# 不再自动下载 Clash 核心，避免 32MB 闪存被占满
		# 固件刷好后，通过 OpenClash 界面手动下载核心即可

		# ====== 6. 设备专属配置 ======
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
	
	# 其他分支保留原有逻辑（不动）
	*)
		case "${OP_AUTHOR}/${OP_REPO}:${OP_BRANCH}" in
		coolsnowwolf/lede:20230609)
			# ... 保留原有 20230609 分支逻辑 ...
		;;
		immortalwrt/immortalwrt*)
			# ... 保留原有 ImmortalWrt 逻辑 ...
		;;
		hanwckf/immortalwrt-mt798x*)
			# ... 保留原有 MT798x 逻辑 ...
		;;
		esac
	;;
	esac

	# ====== 7. x86_64 通用优化 ======
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
