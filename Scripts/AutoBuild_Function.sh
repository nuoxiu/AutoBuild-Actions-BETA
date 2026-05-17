#!/bin/bash

# ============================================================
# 注意：Firmware_Diy_Core 应该在 AutoBuild_DiyScript.sh 中定义
# 这里不重复定义，只保留调用
# ============================================================

Firmware_Diy_Start() {
	ECHO "[Firmware_Diy_Start] Starting ..."
	WORK="${GITHUB_WORKSPACE}/openwrt"
	CONFIG_TEMP="${WORK}/.config"
	CD ${WORK}
	OP_REPO="$(basename $(cut -d ':' -f1 <<< ${DEFAULT_SOURCE}))"
	OP_AUTHOR="$(cut -d '/' -f1 <<< ${DEFAULT_SOURCE})"
	OP_BRANCH="$(cut -d ':' -f2 <<< ${DEFAULT_SOURCE})"
	Firmware_Diy_Core
	[[ ${Short_Fw_Date} == true ]] && Compile_Date="$(cut -c1-8 <<< ${Compile_Date})"
	Github="$(egrep -o 'https://github.com/.+' ${GITHUB_WORKSPACE}/.git/config | awk 'NR==1')"
	[[ -z ${Author} || ${Author} == AUTO ]] && Author="$(cut -d "/" -f4 <<< ${Github} | awk 'NR==1')"
	if [[ ${OP_BRANCH} =~ (master|main) ]]; then
		OP_VERSION_HEAD="R$(date +%y.%m)-"
	else
		OP_VERSION_HEAD="R$(egrep -o "[0-9]+.[0-9]+" <<< ${OP_BRANCH} | awk 'NR==1')-"
	fi
	case "${OP_AUTHOR}/${OP_REPO}" in
	coolsnowwolf/lede)
		Version_File=package/lean/default-settings/files/zzz-default-settings
		zzz_Default_Version="$(egrep -o "R[0-9]+\.[0-9]+\.[0-9]+" ${Version_File})"
		OP_VERSION="${zzz_Default_Version}-${Compile_Date}"
	;;
	immortalwrt/immortalwrt | padavanonly/immortalwrtARM | hanwckf/immortalwrt-mt798x)
		Version_File=package/base-files/files/etc/openwrt_release
		OP_VERSION="${OP_VERSION_HEAD}${Compile_Date}"
	;;
	*)
		OP_VERSION="${OP_VERSION_HEAD}${Compile_Date}"
	;;
	esac
	while [[ -z ${x86_Test} ]]; do
		x86_Test="$(egrep -o "CONFIG_TARGET.*DEVICE.*=y" ${CONFIG_TEMP} | sed -r 's/CONFIG_TARGET_(.*)_DEVICE_(.*)=y/\1/')"
		[[ -n ${x86_Test} ]] && break
		x86_Test="$(egrep -o "CONFIG_TARGET.*Generic=y" ${CONFIG_TEMP} | sed -r 's/CONFIG_TARGET_(.*)_Generic=y/\1/')"
		[[ -z ${x86_Test} ]] && break
	done
	if [[ ${x86_Test} == x86_64 ]]; then
		TARGET_PROFILE=x86_64
	else
		TARGET_PROFILE="$(egrep -o "CONFIG_TARGET.*DEVICE.*=y" ${CONFIG_TEMP} | sed -r 's/.*DEVICE_(.*)=y/\1/')"
	fi
	TARGET_BOARD="$(awk -F '[="]+' '/TARGET_BOARD/{print $2}' ${CONFIG_TEMP})"
	TARGET_SUBTARGET="$(awk -F '[="]+' '/TARGET_SUBTARGET/{print $2}' ${CONFIG_TEMP})"
	if [[ -z ${Fw_MFormat} || ${Fw_MFormat} == AUTO ]]; then
		case "${TARGET_BOARD}" in
		ramips | reltek | ath* | ipq* | bcm47xx | bmips | kirkwood | mediatek)
			Fw_MFormat=bin ;;
		rockchip | x86 | bcm27xx | mxs | sunxi | zynq)
			Fw_MFormat="$(gz_Check)" ;;
		mvebu)
			case "${TARGET_SUBTARGET}" in
			cortexa53 | cortexa72) Fw_MFormat="$(gz_Check)" ;;
			esac ;;
		octeon | oxnas | pistachio) Fw_MFormat=tar ;;
		esac
	fi
	[[ ${Author_URL} != false && ${Author_URL} == AUTO ]] && Author_URL="${Github}"
	[[ ${Author_URL} == false ]] && unset Author_URL
	if [[ ${Default_Flag} == AUTO ]]; then
		TARGET_FLAG=${CONFIG_FILE/${TARGET_PROFILE}-/}
		[[ ${TARGET_FLAG} =~ ${TARGET_PROFILE} || -z ${TARGET_FLAG} || ${TARGET_FLAG} == ${CONFIG_FILE} ]] && TARGET_FLAG=Full
	else
		if [[ ! ${Default_Flag} =~ (\"|=|-|_|\.|\#|\|) && ${Default_Flag} =~ [a-zA-Z0-9] ]]; then
			TARGET_FLAG="${Default_Flag}"
		fi
	fi
	if [[ ! ${Tempoary_FLAG} =~ (\"|=|-|_|\.|\#|\|) && ${Tempoary_FLAG} =~ [a-zA-Z0-9] && ${Tempoary_FLAG} != AUTO ]]; then
		TARGET_FLAG="${Tempoary_FLAG}"
	fi

	# 不再写入 GITHUB_ENV，仅打印
	echo -e "### VARIABLE LIST (shell variables) ###"
	echo "WORK=${WORK}"
	echo "CONFIG_TEMP=${CONFIG_TEMP}"
	echo "CONFIG_FILE=${CONFIG_FILE}"
	echo "AutoBuild_Features=${AutoBuild_Features}"
	echo "x86_Full_Images=${x86_Full_Images}"
	echo "CustomFiles=${GITHUB_WORKSPACE}/CustomFiles"
	echo "Scripts=${GITHUB_WORKSPACE}/Scripts"
	echo "BASE_FILES=${GITHUB_WORKSPACE}/openwrt/package/base-files/files"
	echo "FEEDS_LUCI=${GITHUB_WORKSPACE}/openwrt/package/feeds/luci"
	echo "FEEDS_PKG=${GITHUB_WORKSPACE}/openwrt/package/feeds/packages"
	echo "Default_Title=${Default_Title}"
	echo "Regex_Skip=${Regex_Skip}"
	echo "Version_File=${Version_File}"
	echo "Fw_MFormat=${Fw_MFormat}"
	echo "FEEDS_CONF=${WORK}/feeds.conf.default"
	echo "Author_URL=${Author_URL}"
	echo "Compile_Date=${Compile_Date}"
	echo "Author=${Author}"
	echo "Github=${Github}"
	echo "TARGET_PROFILE=${TARGET_PROFILE}"
	echo "TARGET_BOARD=${TARGET_BOARD}"
	echo "TARGET_SUBTARGET=${TARGET_SUBTARGET}"
	echo "TARGET_FLAG=${TARGET_FLAG}"
	echo "OP_VERSION=${OP_VERSION}"
	echo "OP_AUTHOR=${OP_AUTHOR}"
	echo "OP_REPO=${OP_REPO}"
	echo "OP_BRANCH=${OP_BRANCH}"
	echo ""

	ECHO "[Firmware_Diy_Start] Done"
}

Firmware_Diy_Main() {
	ECHO "[Firmware_Diy_Main] Starting ..."
	CD ${WORK}
	
	# 强制重新定义所有路径变量
	Scripts="${GITHUB_WORKSPACE}/Scripts"
	CustomFiles="${GITHUB_WORKSPACE}/CustomFiles"
	BASE_FILES="${GITHUB_WORKSPACE}/openwrt/package/base-files/files"
	FEEDS_LUCI="${GITHUB_WORKSPACE}/openwrt/package/feeds/luci"
	FEEDS_PKG="${GITHUB_WORKSPACE}/openwrt/package/feeds/packages"
	Version_File="package/lean/default-settings/files/zzz-default-settings"
	Display_Date="${Compile_Date:0:4}/${Compile_Date:4:2}/${Compile_Date:6:2}"
	# 其他变量默认值
	AutoBuild_Features="${AutoBuild_Features:-true}"
	x86_Full_Images="${x86_Full_Images:-false}"
	Author="${Author:-nuoxiu}"
	Github="${Github:-https://github.com/nuoxiu/AutoBuild-Actions-BETA}"
	TARGET_PROFILE="${TARGET_PROFILE:-d-team_newifi-d2}"
	TARGET_BOARD="${TARGET_BOARD:-ramips}"
	TARGET_SUBTARGET="${TARGET_SUBTARGET:-mt7621}"
	TARGET_FLAG="${TARGET_FLAG:-Clash}"
	OP_VERSION="${OP_VERSION:-R26.02.20}"
	OP_AUTHOR="${OP_AUTHOR:-coolsnowwolf}"
	OP_REPO="${OP_REPO:-lede}"
	OP_BRANCH="${OP_BRANCH:-master}"
	Default_Title="${Default_Title:-Powered by AutoBuild-Actions}"
	Regex_Skip="${Regex_Skip:-packages|buildinfo|sha256sums|manifest|kernel|rootfs|factory|itb|profile|ext4|json}"
	Fw_MFormat="${Fw_MFormat:-bin}"
	FEEDS_CONF="${FEEDS_CONF:-${WORK}/feeds.conf.default}"
	Author_URL="${Author_URL:-https://github.com/nuoxiu/AutoBuild-Actions-BETA}"
	Compile_Date="${Compile_Date:-$(date +%Y%m%d)}"
	if [[ -z ${zzz_Default_Version} ]]; then
		zzz_Default_Version="$(egrep -o "R[0-9]+\.[0-9]+\.[0-9]+" ${Version_File} 2>/dev/null || echo "R26.02.20")"
	fi
	
	chmod 777 -R ${Scripts} ${CustomFiles}
	
	if [[ ${AutoBuild_Features} == true ]]
	then
		AddPackage other Hyy2001X AutoBuild-Packages master
		echo -e "\nCONFIG_PACKAGE_luci-app-autoupdate=y" >> ${CONFIG_FILE}
		AutoUpdate_Version=$(awk -F '=' '/Version/{print $2}' $(PKG_Finder d package AutoBuild-Packages)/autoupdate/files/bin/autoupdate | awk 'NR==1')
		cat >> $(PKG_Finder d package AutoBuild-Packages)/autoupdate/files/etc/autoupdate/default <<EOF
Author=${Author}
Github=${Github}
TARGET_PROFILE=${TARGET_PROFILE}
TARGET_BOARD=${TARGET_BOARD}
TARGET_SUBTARGET=${TARGET_SUBTARGET}
TARGET_FLAG=${TARGET_FLAG}
OP_VERSION=${OP_VERSION}
OP_AUTHOR=${OP_AUTHOR}
OP_REPO=${OP_REPO}
OP_BRANCH=${OP_BRANCH}

EOF
		Copy ${CustomFiles}/Depends/tools ${BASE_FILES}/bin
		Copy ${CustomFiles}/Depends/profile ${BASE_FILES}/etc
		Copy ${CustomFiles}/Depends/base-files-essential ${BASE_FILES}/lib/upgrade/keep.d
		case "${OP_AUTHOR}/${OP_REPO}" in
		coolsnowwolf/lede)
			Copy ${CustomFiles}/Depends/coremark.sh $(PKG_Finder d "package feeds" coremark)
			# 跳过 sed 修改，避免出错
			ECHO "Skipped sed modifications for Version_File and banner (coolsnowwolf/lede)"
		;;
		immortalwrt/immortalwrt | padavanonly/immortalwrtARM | hanwckf/immortalwrt-mt798x)
			Copy ${CustomFiles}/Depends/openwrt_release_immortalwrt ${BASE_FILES}/etc openwrt_release
			Copy ${CustomFiles}/Depends/os-release_immortalwrt ${BASE_FILES}/usr/lib os-release
			ECHO "Skipped sed modifications for ImmortalWrt files"
		;;
		esac
		# 跳过 banner 相关的 sed 修改
		# sed -i ... (已注释)
		case "${OP_AUTHOR}/${OP_REPO}" in
		*)
			Copy ${CustomFiles}/Depends/banner ${BASE_FILES}/etc
		;;
		esac
	fi
	if [[ -n ${Tempoary_IP} ]]; then
		ECHO "Using Tempoary IP Address: ${Tempoary_IP} ..."
		Default_IP="${Tempoary_IP}"
	fi
	if [[ -n ${Default_IP} && ${Default_IP} =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
		Old_IP=$(awk -F '[="]+' '/ipaddr:-/{print $3}' ${BASE_FILES}/bin/config_generate | awk 'NR==1')
		if [[ ! ${Default_IP} == ${Old_IP} ]]; then
			ECHO "Setting default IP Address to ${Default_IP} ..."
			sed -i "s/${Old_IP}/${Default_IP}/g" ${BASE_FILES}/bin/config_generate
		fi
	fi
 	echo -e "### VARIABLE LIST (after Firmware_Diy_Main) ###"
 	echo "WORK=${WORK}"
 	echo "CONFIG_FILE=${CONFIG_FILE}"
 	echo "TARGET_PROFILE=${TARGET_PROFILE}"
 	echo "TARGET_BOARD=${TARGET_BOARD}"
 	echo "TARGET_FLAG=${TARGET_FLAG}"
	ECHO "[Firmware_Diy_Main] Done"
}

Firmware_Diy_Other() {
	ECHO "[Firmware_Diy_Other] Starting ..."
	CD ${WORK}
	if [[ ${AutoBuild_Features} == true ]]
	then
		if [[ -n ${Author_URL} ]]
		then
			cat >> ${CONFIG_TEMP} <<EOF

CONFIG_KERNEL_BUILD_USER="${Author}"
CONFIG_KERNEL_BUILD_DOMAIN="${Author_URL}"
EOF
		fi
		if [[ ${AutoBuild_Features_Patch} == true ]]
		then
			case "${OP_AUTHOR}/${OP_REPO}:${OP_BRANCH}" in
			coolsnowwolf/lede:master)
				Patch_Path=${CustomFiles}/Patches/coolsnowwolf-lede
			;;
			immortalwrt/immortalwrt*)
				Patch_Path=${CustomFiles}/Patches/immortalwrt-immortalwrt
			;;
			lienol/openwrt*)
				Patch_Path=${CustomFiles}/Patches/lienol-openwrt
			;;
			openwrt/openwrt*)
				Patch_Path=${CustomFiles}/Patches/openwrt-openwrt
			;;
			padavanonly/immortalwrtARM*)
				Patch_Path=${CustomFiles}/Patches/padavanonly-immortalwrtARM
			;;
			hanwckf/immortalwrt-mt798x*)
				Patch_Path=${CustomFiles}/Patches/immortalwrt-mt798x
			;;
			esac
			if [[ -d ${Patch_Path} ]]
			then
				for i in $(du -ah ${Patch_Path} | awk '{print $2}' | sort | uniq)
				do
					if [[ -f $i ]]
					then
						if [[ $i =~ "-generic.patch" ]]
						then
							ECHO "Found generic patch file: $i"
							patch < $i -p1 -d ${WORK}
						elif [[ $i =~ "-${TARGET_BOARD}.patch" ]]
						then
							ECHO "Found board ${TARGET_BOARD} patch file: $i"
							patch < $i -p1 -d ${WORK}
						elif [[ $i =~ "-${TARGET_PROFILE}.patch" ]]
						then
							ECHO "Found profile ${TARGET_PROFILE} patch file: $i"
							patch < $i -p1 -d ${WORK}
						fi
					fi
				done ; unset i
			fi
		fi
		if [[ ${AutoBuild_Features_Kconfig} == true ]]
		then
			Kconfig_Path=${CustomFiles}/Kconfig
			Tree=${WORK}/target/linux
			if [[ -d ${Kconfig_Path} ]]
			then
				cd ${Kconfig_Path}
				for i in $(du -a | awk '{print $2}' | busybox sed -r 's/.\//\1/' | grep -wv '^.' | sort | uniq)
				do
					if [[ -d $i && $(ls -1 $i 2> /dev/null) ]]
					then
						:
					elif [[ -e $i ]]
					then
						_Kconfig=$(dirname $i)
						__Kconfig=$(basename $i)
						ECHO " - Found Kconfig_file: ${__Kconfig} at ${_Kconfig}"
						if [[ -e ${Tree}/$i && ${__Kconfig} != config-generic ]]
						then
							ECHO " -- Found Tree: ${Tree}/$i, refreshing ${Tree}/$i ..."
							echo >> ${Tree}/$i
							if [[ $? == 0 ]]
							then
								cat $i >> ${Tree}/$i
								ECHO " --- Done"
							else
								ECHO " --- Failed to write new content ..."
							fi
						elif [[ ${__Kconfig} == config-generic ]]
						then
							for j in $(ls -1 ${Tree}/${_Kconfig} | egrep "config-[0-9]+")
							do
								ECHO " -- Generic Kconfig_file, refreshing ${Tree}/${_Kconfig}/$j ..."
								echo >> ${Tree}/${_Kconfig}/$j
								if [[ $? == 0 ]]
								then
									cat $i >> ${Tree}/${_Kconfig}/$j
									ECHO " --- Done"
								else
									ECHO " --- Failed to write new content ..."
								fi
							done
						fi
					fi
				done ; unset i
			fi
		fi
	fi
	CD ${WORK}
	ECHO "[Firmware_Diy_Other] Done"
}

Firmware_Diy_End() {
    ECHO "[Firmware_Diy_End] Starting ..."
    # 确保 WORK 变量已定义
    WORK="${GITHUB_WORKSPACE}/openwrt"
    if [ ! -d "${WORK}" ]; then
        echo "##[error] WORK directory ${WORK} does not exist!"
        exit 1
    fi
    cd ${WORK}

    ECHO "[$(date "+%H:%M:%S")] Actions Avaliable: $(df -h | grep "/dev/root" | awk '{printf $4}')"

    # 1. 检查 bin/targets 是否存在
    if [ ! -d "bin/targets" ]; then
        echo "##[error] bin/targets directory not found! Compilation may have failed."
        ls -l bin/ 2>/dev/null || echo "bin/ not found"
        exit 1
    fi

    echo -e "### FIRMWARE OUTPUT ###"
    du -ah bin/targets | grep -v 'ipk' || true

    # 2. 创建输出目录
    MKDIR ${WORK}/bin/Firmware

    # 3. 直接复制所有可能的固件文件到 bin/Firmware
    #    不再依赖变量推断和重命名
    echo "Copying all firmware files to bin/Firmware ..."
    find ${WORK}/bin/targets -type f \( \
        -name "*.bin" \
        -o -name "*.img" \
        -o -name "*.img.gz" \
        -o -name "*.tar.gz" \
        -o -name "*.vmdk" \
        -o -name "*.iso" \
        -o -name "*.squashfs" \
        -o -name "*.ubi" \
        -o -name "*.itb" \
        -o -name "*-sysupgrade*" \
        -o -name "*-factory*" \
    \) -exec cp -a {} ${WORK}/bin/Firmware/ \; 2>/dev/null || true

    # 4. 验证结果
    if [ -z "$(ls -A ${WORK}/bin/Firmware 2>/dev/null)" ]; then
        echo "##[error] No firmware files found! Please check compilation logs."
        echo "Directory structure of bin/targets:"
        find ${WORK}/bin/targets -type f | head -50
        exit 1
    else
        echo -e "### FINAL FIRMWARE FILES ###"
        ls -lh ${WORK}/bin/Firmware/
    fi

    ECHO "[Firmware_Diy_End] Done"
}

Process_Fw() {
	while [[ $1 ]];do
		Process_Fw_Core $1 $(List_Fw $1 | Regex)
		shift
	done
}

Process_Fw_Core() {
	Fw_Format=$1
	shift
	while [[ $1 ]];do
		case "${TARGET_BOARD}" in
		x86)
			if [[ $1 =~ efi ]]
			then
				Fw=${AutoBuild_Fw/SHA256/$(Get_sha256 $1)}
				Fw=${Fw/FORMAT/${Fw_Format}}
				if [[ -f $1 ]]
				then
					ECHO "Move x86 image [$1] to [${Fw}] ..."
					mv -f $1 ${Fw}
				fi
			fi
		;;
		*)
			Fw=${AutoBuild_Fw/SHA256/$(Get_sha256 $1)}
			Fw=${Fw/FORMAT/${Fw_Format}}
			if [[ -f $1 ]]
			then
				ECHO "Move generic firmware [$1] to [${Fw}] ..."
				mv -f $1 ${Fw}
			fi
		;;
		esac
		shift
	done
}

List_Fw() {
	if [[ -z $* ]]
	then
		for X in $(List_sha256);do
			cut -d "*" -f2 <<< "${X}"
		done
	else
		while [[ $1 ]];do
			for X in $(List_sha256);do
				[[ ${X} == *$1 ]] && cut -d "*" -f2 <<< "${X}"
			done
			shift
		done
	fi
}

Regex() {
	egrep -v "${Regex_Skip}"
}

List_sha256() {
	cat ${Fw_Path}/sha256sums 2> /dev/null | Regex | tr -s '\n'
}

List_MFormat() {
	List_sha256 | cut -d "*" -f2 | cut -d "." -f2-3 | sort | uniq
}

Get_sha256() {
	List_sha256 | grep $1 | awk '{print $1}' | cut -c1-5
}

gz_Check() {
	[[ $(cat ${CONFIG_TEMP}) =~ CONFIG_TARGET_IMAGES_GZIP=y ]] && {
		echo img.gz
	} || echo img
}

ECHO() {
	echo "[$(date "+%H:%M:%S")] $*"
}

PKG_Finder() {
	local Result
	if [[ $# -ne 3 ]]
	then
		ECHO "Syntax error: [$#] [$*]"
		return 0
	fi
	Result=$(find $2 -name $3 -type $1 -exec echo {} \; 2> /dev/null)
	[[ -n ${Result} ]] && echo "${Result}"
}

CD() {
	cd $1
	[[ ! $? == 0 ]] && ECHO "Unable to enter target directory $1 ..." || ECHO "Entering directory: $(pwd) ..."
}

MKDIR() {
	while [[ $1 ]]
	do
		if [[ ! -d $(dirname $1) ]]
		then
			mkdir -p $(dirname $1)
			if [[ $? != 0 ]]
			then
				ECHO "Failed to create parent directory: [$(dirname $1)] ..."
				return 0
			fi
		fi
		if [[ ! -d $1 ]]
		then
			mkdir -p $1 || ECHO "Failed to create sub directory: [$1] ..."
		else
			ECHO "Create directory: [$(dirname $1)] ..."
		fi
		shift
	done
}

AddPackage() {
	if [[ $# -lt 4 ]]
	then
		ECHO "Syntax error: [$#] [$*]"
		return 0
	fi
	PKG_DIR=$1
	[[ ! ${PKG_DIR} =~ ${GITHUB_WORKSPACE} ]] && PKG_DIR=package/${PKG_DIR}
	REPO_URL="https://github.com/$2/$3"
	PKG_NAME=$3
	REPO_BRANCH=$4

	MKDIR ${PKG_DIR}
	if [[ -d ${PKG_DIR}/${PKG_NAME} ]]
	then
		ECHO "Removing old package: [${PKG_NAME}] ..."
		rm -rf "${PKG_DIR}/${PKG_NAME}"
	fi

	if [[ -z ${REPO_BRANCH} ]]
	then
		REPO_BRANCH=main
	fi
	ECHO "Downloading package [${PKG_NAME}] to ${PKG_DIR} ..."
	git clone --depth 1 -b ${REPO_BRANCH} ${REPO_URL} ${PKG_DIR}/${PKG_NAME}/ > /dev/null 2>&1
}

Copy() {
	if [[ ! $# =~ [23] ]]
	then
		ECHO "Syntax error: [$#] [$*]"
		return 0
	fi
	if [[ ! -f $1 && ! -d $1 ]]
	then
		ECHO "$1: No such file or directory ..."
		return 0
	fi
	MKDIR $2
	if [[ -z $3 ]]
	then
		ECHO "[C] Copying $(basename $1) to $2 ..."
		cp -a $1 $2
	else
		ECHO "[R] Copying $(basename $1) to $2 [$3] ..."
		cp -a $1 $2/$3
	fi
	[[ $? == 0 ]] && ECHO "Done"
}

ReleaseDL() {
	if [[ $# -lt 3 ]]
	then
		ECHO "Syntax error: [$#] [$*]"
		return 0
	fi
	
	API_URL=$1
	FILE_NAME=$2
	TARGET_FILE_PATH=$3
	TARGET_FILE_RENAME=$4
	API_FILE=/tmp/API.json
	
	if [[ ! -d ${TARGET_FILE_PATH} ]]
	then
		MKDIR "${TARGET_FILE_PATH}"
	fi
	
	rm -f ${API_FILE}
	wget --quiet --no-check-certificate --tries 5 --timeout 20 $1 -O ${API_FILE}
	if [[ $? != 0 || ! -f ${API_FILE} ]]
	then
		ECHO "Failed to download API ${PKG_NAME} ..."
	fi
	for i in $(seq 0 $(cat ${API_FILE} | jq ".assets | length" 2> /dev/null))
	do
		eval name=$(cat ${API_FILE} | jq ".assets[${i}].name" 2> /dev/null)
		[[ ${name} == null ]] && continue
		case "$name" in
		"${FILE_NAME}")
			eval browser_download_url=$(cat ${API_FILE} | jq ".assets[${i}].browser_download_url" 2> /dev/null)
			if [[ ${browser_download_url} || ${browser_download_url} != null ]]
			then
				# echo $browser_download_url
				[[ ${TARGET_FILE_RENAME} ]] && _FILE=${TARGET_FILE_RENAME} || _FILE=${FILE_NAME}
    				ECHO "Downloading link ${browser_download_url} ..."
				wget --quiet --no-check-certificate \
					--tries 5 --timeout 20 \
					${browser_download_url} \
					-O ${TARGET_FILE_PATH}/${_FILE}
				if [[ $? != 0 || ! -f ${TARGET_FILE_PATH}/${_FILE} ]]
				then
					ECHO "Failed to download ${PKG_NAME} ..."
				else
					ECHO "API: ${API_URL} ; ${FILE_NAME} ; ${_FILE} ; $(du -h ${TARGET_FILE_PATH}/${_FILE})"
					chmod 777 ${TARGET_FILE_PATH}/${_FILE}
				fi
			fi
		;;
		esac
	done
	rm -f ${API_FILE}
}

# ============================================================
# 容错版 ClashDL 函数
# ============================================================
ClashDL() {
	TMP_PATH=/opt/OpenClash
	
	PLATFORM=$1
	CORE_TYPE=$2
	
	if [[ ! -d ${TMP_PATH} ]]; then
		ECHO "Cloning OpenClash core repository..."
		git clone -b core --depth=1 https://github.com/vernesong/OpenClash ${TMP_PATH} || {
			ECHO "Failed to clone OpenClash core repository. OpenClash core may not be available."
			return 0
		}
	fi
	
	case $CORE_TYPE in
	dev | meta)
		CORE_PATH=${TMP_PATH}/dev/${CORE_TYPE}
	;;
	premium | tun)
		CORE_PATH=${TMP_PATH}/dev/premium
	;;
	*)
		ECHO "Unknown core type: $CORE_TYPE"
		return 0
	;;
	esac
	
	if [[ ! -d ${CORE_PATH} ]]; then
		ECHO "Core path ${CORE_PATH} does not exist. Skipping ${CORE_TYPE} core download."
		return 0
	fi
	
	# 查找匹配的核心文件
	local core_file=""
	case $CORE_TYPE in
	dev | meta)
		core_file=$(ls -1 ${CORE_PATH}/clash-linux-${PLATFORM}.tar.gz 2>/dev/null)
	;;
	premium | tun)
		core_file=$(ls -1 ${CORE_PATH}/clash-linux-${PLATFORM}-*.gz 2>/dev/null | head -1)
	;;
	esac
	
	if [[ -z ${core_file} ]]; then
		ECHO "No core file found for platform ${PLATFORM} and type ${CORE_TYPE} in ${CORE_PATH}"
		return 0
	fi
	
	ECHO "Found core file: $(basename ${core_file})"
	
	MKDIR ${BASE_FILES}/etc/openclash/core 2>/dev/null
	
	case $CORE_TYPE in
	dev | meta)
		tar -xvzf ${core_file} -C ${TMP_PATH} || {
			ECHO "Failed to extract core"
			return 0
		}
		if [[ $CORE_TYPE == dev ]]; then
			chmod 777 ${TMP_PATH}/clash
			mv -f ${TMP_PATH}/clash ${BASE_FILES}/etc/openclash/core/clash
			ECHO "CORE Size: $(du -h ${BASE_FILES}/etc/openclash/core/clash)"
		elif [[ $CORE_TYPE == meta ]]; then
			chmod 777 ${TMP_PATH}/clash
			mv -f ${TMP_PATH}/clash ${BASE_FILES}/etc/openclash/core/clash_meta
			ECHO "CORE Size: $(du -h ${BASE_FILES}/etc/openclash/core/clash_meta)"
		fi
	;;
	premium | tun)
		gzip -dk -c ${core_file} > ${TMP_PATH}/clash_tun || {
			ECHO "Failed to extract premium core"
			return 0
		}
		chmod 777 ${TMP_PATH}/clash_tun
		mv -f ${TMP_PATH}/clash_tun ${BASE_FILES}/etc/openclash/core/clash_tun
		ECHO "CORE Size: $(du -h ${BASE_FILES}/etc/openclash/core/clash_tun)"
	;;
	esac
}
