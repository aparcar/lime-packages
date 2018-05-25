#!/bin/bash

install() {
    git clone https://github.com/libremesh/lime-sdk.git sdk || true
    cd sdk
    git checkout develop && git pull
    sed 's|https://github.com/libremesh/lime-packages.git.*|'$TRAVIS_BUILD_DIR'|g' feeds.conf.ci > feeds.conf.default.local
    sed -i 's|sdk_compile_repos.*|sdk_compile_repos="libremesh"|g' options.conf
    ./cooker -d "$TARGET" --sdk "$IB_DOWNLOAD"
}
build() {
    env
    cd sdk
    export J=$(($(nproc)+1))
    if [ "${TRAVIS_PULL_REQUEST}" == "false" -a "$TRAVIS_BRANCH" == "master" ]; then
        ./cooker -b "$TARGET"
        ./snippets/create_repository.sh
    else
        if [ ! -z "$DOWNLOAD_IB" ]; then
            ./cooker --flavor=lime_default -c "$TARGET" --profile=Generic
            ./cooker --flavor=lime_mini -c "$TARGET" --profile=Generic
            ./cooker --flavor=lime_zero -c "$TARGET" --profile=Generic
        fi
    fi
}

upload() {
    if [ "${TRAVIS_PULL_REQUEST}" == "false" -a "$TRAVIS_BRANCH" == "master" ]; then
        rsync -L -r -v -e "sshpass -p $SSH_PASS ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 22100" \
            --exclude '*/base/' \
            --exclude '*/packages/' \
            --exclude '*/luci/' \
            "./sdk/repository/$ARCH" "${CI_USER}@${CI_SERVER}:${CI_STORE_PATH}/snapshots/packages/"
    else
        if [ ! -z "$DOWNLOAD_IB" ]; then
            mv "$TRAVIS_BUILD_DIR/sdk/output/" "/tmp/$TRAVIS_PULL_REQUEST"
            rsync -r -v -e "sshpass -p $SSH_PASS ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 22100" \
                "/tmp/$TRAVIS_PULL_REQUEST" "${CI_USER}@${CI_SERVER}:${CI_STORE_PATH}/pull_requests/"
#            curl -H "Authorization: token $COMMENT_BOT_KEY" \
#                "https://api.github.com/repos/libremesh/lime-packages/issues/$TRAVIS_PULL_REQUEST/comments" \
#                -d '{"body": "You can download the image from <http://ci.libremesh.org/'"$TRAVIS_PULL_REQUEST"'>"}'
        fi
    fi
}

$@
