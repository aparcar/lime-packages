#!/bin/bash
build() {
    export J=$(($(nproc)+1))
    ./cooker -b $TARGET
    cd $TRAVIS_BUILD_DIR/sdk
    if [ -z "${TRAVIS_PULL_REQUEST}" -a "$TRAVIS_BRANCH" == "develop" ]; then
        travis_wait ./cooker -b "$TARGET"
        ./snippets/create_repository.sh
    else
        if [ ! -z "$DOWNLOAD_IB" ]; then
            travis_wait ./cooker --flavor=lime_default -c "$TARGET" --profile=Generic
            travis_wait ./cooker --flavor=lime_mini -c "$TARGET" --profile=Generic
            travis_wait ./cooker --flavor=lime_zero -c "$TARGET" --profile=Generic
        fi
    fi
}

upload() {
    if [ -z "${TRAVIS_PULL_REQUEST}" -a "$TRAVIS_BRANCH" == "develop" ]; then
        rsync -L -r -v -e "sshpass -p $SSH_PASS ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 22100" \
            --exclude '*/base/' \
            --exclude '*/packages/' \
            --exclude '*/luci/' \
            "$SDK_HOME/sdk/bin/packages/" ci@srv02.planetexpress.cc:ci/snapshots/packages/
    else
        if [ ! -z "$DOWNLOAD_IB" ]; then
            chmod +x $TRAVIS_BUILD_DIR/.ci/after_success.sh
            $TRAVIS_BUILD_DIR/.ci/after_success.sh
        fi
    fi
}

$@
