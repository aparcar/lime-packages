#!/bin/bash
#
# MIT Alexander Couzens <lynxis@fe80.eu>

set -e

SDK_URL="https://downloads.openwrt.org/snapshots/targets/"
SDK_TARGET="${SDK_TARGET:-ar71xx/generic}"
SDK_PATH="$SDK_URL$SDK_TARGET"
SDK=openwrt-sdk
SDK_HOME="$HOME/sdk/$SDK_TARGET"
PACKAGES_DIR="$PWD"
REPO_NAME="libremesh"
CHECK_SIG=1

echo_red()   { printf "\033[1;31m$*\033[m\n"; }
echo_green() { printf "\033[1;32m$*\033[m\n"; }
echo_blue()  { printf "\033[1;34m$*\033[m\n"; }

exec_status() {
	PATTERN="$1"
	shift
	while :;do sleep 590;echo "still running (please don't kill me Travis)";done &
	("$@" 2>&1) | tee logoutput
	R=${PIPESTATUS[0]}
	kill $! && wait $! 2>/dev/null
	if [ $R -ne 0 ]; then
		echo_red   "=> '$*' failed (return code $R)"
		return 1
	fi
	if grep -qE "$PATTERN" logoutput; then
		echo_red   "=> '$*' failed (log matched '$PATTERN')"
		return 1
	fi

	echo_green "=> '$*' successful"
	return 0
}

get_sdk_file() {
	if [ -e "$SDK_HOME/sha256sums" ] ; then
		grep -- "$SDK" "$SDK_HOME/sha256sums" | awk '{print $2}' | sed 's/*//g'
	else
		false
	fi
}

# download will run on the `before_script` step
# The travis cache will be used (all files under $HOME/sdk/). Meaning
# We don't have to download the file again
setup_sdk() {
	mkdir -p "$SDK_HOME/sdk"
	cd "$SDK_HOME"

	echo_blue "=== download SDK"
	wget "$SDK_PATH/sha256sums" -O sha256sums
	wget "$SDK_PATH/sha256sums.gpg" -O sha256sums.asc

    if [[ "$CHECK_SIG" == 1 ]]; then
        # LEDE Build System (LEDE GnuPG key for unattended build jobs)
        gpg --import $PACKAGES_DIR/.keys/626471F1.asc
        echo '54CC74307A2C6DC9CE618269CD84BCED626471F1:6:' | gpg --import-ownertrust
        # LEDE Release Builder (17.01 "Reboot" Signing Key)
        gpg --import $PACKAGES_DIR/.keys/D52BBB6B.asc
        echo 'B09BE781AE8A0CD4702FDCD3833C6010D52BBB6B:6:' | gpg --import-ownertrust

        echo_blue "=== Verifying sha256sums signature"
        gpg --verify sha256sums.asc
        echo_blue "=== Verified sha256sums signature"
    else
        echo_red "=== Not checking SDK signature"""
    fi
	if ! grep -- "$SDK" sha256sums > sha256sums.small ; then
		echo_red "=== Can not find $SDK file in sha256sums."
		echo_red "=== Is \$SDK out of date?"
		false
	fi

	# if missing, outdated or invalid, download again
	if ! sha256sum -c ./sha256sums.small ; then
		sdk_file="$(get_sdk_file)"
		echo_blue "=== sha256 doesn't match or SDK file wasn't downloaded yet."
		echo_blue "=== Downloading a fresh version"
		wget "$SDK_PATH/$sdk_file" -O "$sdk_file"
		echo_blue "=== Removing old SDK directory"
        rm -rf "./sdk/" && mkdir "./sdk"

        echo_blue "=== Setting up SDK"
        tar Jxf "$sdk_file" --strip=1 -C "./sdk"

        # use github mirrors to spare lede servers
        cat > ./sdk/feeds.conf <<EOF
src-git base https://github.com/openwrt/openwrt.git;master
src-git packages https://github.com/openwrt/packages.git;master
src-git luci https://github.com/openwrt/luci.git;master
src-git libremesh https://github.com/libremesh/lime-packages.git;develop
src-git libremap https://github.com/libremap/libremap-agent-openwrt.git;master
src-git limeui https://github.com/libremesh/lime-packages-ui.git;master
EOF

        cat > ./sdk/key-build <<EOF
untrusted comment: private key 7546f62c3d9f56b1
$KEY_BUILD
EOF
	fi

	# check again and fail here if the file is still bad
	echo_blue "Checking sha256sum a second time"
	if ! sha256sum -c ./sha256sums.small ; then
		echo_red "=== SDK can not be verified!"
		false
	fi
	echo_blue "=== SDK is up-to-date"
}

# test_package will run on the `script` step.
# test_package call make download check for very new/modified package
build_packages() {
	cd "$SDK_HOME/sdk"

	./scripts/feeds update -a > /dev/null
	./scripts/feeds uninstall -a > /dev/null
	./scripts/feeds install -p $REPO_NAME -a > /dev/null
	make defconfig > /dev/null

    exec_status '^ERROR' make -j$(($(nproc)+1)) || return 1
}

upload_packages() {
    rsync -L -r -v -e "sshpass -p $SSH_PASS ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 22100" \
        --exclude '*/base/' \
        --exclude '*/packages/' \
        --exclude '*/luci/' \
        $SDK_HOME/sdk/bin/packages/ ci@srv02.planetexpress.cc:ci/snapshots/packages/
}

if [ $# -ne 1 ] ; then
	cat <<EOF
Usage: $0 (setup_sdk|build_packages|upload_packages)

setup_sdk - download the SDK to $HOME/sdk.tar.xz
build_packages- do a make check on the package
upload_packages - upload packages to ci server
EOF
	exit 1
fi

$@
