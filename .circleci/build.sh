#!/usr/bin/env bash
echo "Cloning dependencies"
git clone --depth=1 https://github.com/KazuDante89/msm-4.4.r44-rel -b  Genshin-gcc_test kernel
cd kernel
git clone --depth=1 https://github.com/mvaisakh/gcc-arm64 -b gcc-master gcc64
git clone --depth=1 https://github.com/mvaisakh/gcc-arm -b gcc-master gcc32
git clone --depth=1 https://github.com/KazuDante89/AnyKernel3-EAS -b lavender2 AnyKerne
git clone --depth=1 https://android.googlesource.com/platform/system/libufdt libufdt
echo "Done"
IMAGE=$(pwd)/out/arch/arm64/boot/Image.gz-dtb
TANGGAL=$(date +"%F-%S")
LOG=$(echo *.log)
START=$(date +"%s")
export CONFIG_PATH=$PWD/arch/arm64/configs/lavender-perf_defconfig
TC_DIR=${PWD}
GCC64_DIR="${PWD}/gcc64"
GCC32_DIR="${PWD}/gcc32"
PATH="$TC_DIR/bin/:$GCC64_DIR/bin/:$GCC32_DIR/bin/:/usr/bin:$PATH"
export ARCH=arm64
export KBUILD_BUILD_HOST="CircleCI"
export KBUILD_BUILD_USER="kazudante89"
# Send info plox channel
function sendinfo() {
    curl -s -X POST "https://api.telegram.org/bot$token/sendMessage" \
        -d chat_id="$chat_id" \
        -d "disable_web_page_preview=true" \
        -d "parse_mode=html" \
        -d text="<b>• 4.4 Genshin Kernel Project •</b>%0ABuild started on <code>Circle CI</code>%0AFor device <b>Xiaomi Redmi Note7/7S</b> (lavender)%0Abranch <code>$(git rev-parse --abbrev-ref HEAD)</code>(master)%0AUnder commit <code>$(git log --pretty=format:'"%h : %s"' -1)</code>%0AUsing compiler: <code>${KBUILD_COMPILER_STRING}</code>%0AStarted on <code>$(date)</code>%0A<b>Build Status:</b>#Stable"
}
# Push kernel to channel
function push() {
    cd AnyKernel
    ZIP=$(echo *.zip)
    curl -F document=@$ZIP "https://api.telegram.org/bot$token/sendDocument" \
        -F chat_id="$chat_id" \
        -F "disable_web_page_preview=true" \
        -F "parse_mode=html" \
        -F caption="Build took $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) second(s). | For <b>Xiaomi Redmi Note 7/7s (lavender)</b> | <b>$(${GCC}gcc --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g')</b>"
}
# Fin Error
function finerr() {
    curl -s -X POST "https://api.telegram.org/bot$token/sendMessage" \
        -d chat_id="$chat_id" \
        -d "disable_web_page_preview=true" \
        -d "parse_mode=markdown" \
        -d text="Build failed, check the circleci logs"
    exit 1
}
# Compile plox
function compile() {
   make O=out ARCH=arm64 lavender-perf_defconfig
       make -j$(nproc --all) O=out \
                             ARCH=arm64 \
			     CROSS_COMPILE_ARM32=arm-eabi- \
			     CROSS_COMPILE=aarch64-elf- \
			     AR=aarch64-elf-ar \
			     OBJDUMP=aarch64-elf-objdump \
			     STRIP=aarch64-elf-strip 2>&1 | tee error.log
   cp out/arch/arm64/boot/Image.gz-dtb AnyKernel
   python2 "libufdt/utils/src/mkdtboimg.py" \
					create "out/arch/arm64/boot/dtbo.img" --page_size=4096 out/arch/arm64/boot/dts/qcom/*.dtbo
   cp out/arch/arm64/boot/dtbo.img AnyKernel
}
# Zipping
function zipping() {
    cd AnyKernel || exit 1
    zip -r9 [R1]-GenshinKernel_v.0.0.zip *
    cd ..
}
sendinfo
compile
zipping
END=$(date +"%s")
DIFF=$(($END - $START))
finerr
push
