#!/bin/bash
# Run from root directory of linux-offline-packaging-msbuild

# Source ./eng/common/tools.sh
echo "- Sourcing ./linux-packaging-msbuild/eng/common/tools.sh..."
echo "  - . ./linux-packaging-msbuild/eng/common/tools.sh"
. ./linux-packaging-msbuild/eng/common/tools.sh

# Check for components inside ./offline folder
echo "- Checking ./offline/ folder to see if required components exist..."

# .dotnet
echo "  - .dotnet/..."
if [ ! -e "./offline/.dotnet" ]; then
	echo "  - .dotnet/ not found. creating..."
	mkdir "./offline/.dotnet"
fi
# .dotnet/dotnet-install.sh
echo "  - .dotnet/dotnet-install.sh"
if [ ! -e "./offline/.dotnet/dotnet-install.sh" ]; then
        echo "  - .dotnet/dotnet-install.sh not found. downloading..."
        wget --continue --output-document="./offline/.dotnet/dotnet-install.sh" "https://dot.net/v1/dotnet-install.sh"
fi
# .dotnet/dep/
echo "  - .dotnet/dep/..."
if [ ! -e "./offline/.dotnet/dep/" ]; then
        echo "  - .dotnet/dep/ not found. creating..."
        mkdir "./offline/.dotnet/dep"
fi
# .dotnet/dep/Sdk
echo "  - .dotnet/dep/Sdk/..."
if [ ! -e "./offline/.dotnet/dep/Sdk/" ]; then
        echo "  - .dotnet/dep/Sdk/ not found. creating..."
        mkdir "./offline/.dotnet/dep/Sdk"
fi
# .dotnet/dep/Sdk/${dotnet_sdk_version}
ReadGlobalVersion "dotnet"
dotnet_sdk_version=$_ReadGlobalVersion
echo "  - .dotnet/dep/Sdk/${dotnet_sdk_version}..."
if [ ! -e "./offline/.dotnet/dep/Sdk/${dotnet_sdk_version}/" ]; then
        echo "  - .dotnet/dep/Sdk/${dotnet_sdk_version} not found. creating..."
        mkdir "./offline/.dotnet/dep/Sdk/${dotnet_sdk_version}"
fi
# .dotnet/dep/Runtime
echo "  - .dotnet/dep/Runtime/..."
if [ ! -e "./offline/.dotnet/dep/Runtime/" ]; then
        echo "  - .dotnet/dep/Runtime/ not found. creating..."
        mkdir "./offline/.dotnet/dep/Runtime"
fi
# .dotnet/dep/Runtime/2.1.7
echo "  - .dotnet/dep/Runtime/2.1.7..."
if [ ! -e "./offline/.dotnet/dep/Runtime/2.1.7/" ]; then
        echo "  - .dotnet/dep/Runtime/2.1.7 not found. creating..."
        mkdir "./offline/.dotnet/dep/Runtime/2.1.7"
fi

# Check for required files
echo "- Determining what files to download..."

# .dotnet/dep/Sdk/${dotnet_sdk_version}/dotnet-sdk-${dotnet_sdk_version}-linux-x64.tar.gz
echo "  - .dotnet/dep/Sdk/${dotnet_sdk_version}/dotnet-sdk-${dotnet_sdk_version}-linux-x64.tar.gz..."
if [ ! -e "./offline/.dotnet/dep/Sdk/${dotnet_sdk_version}/dotnet-sdk-${dotnet_sdk_version}-linux-x64.tar.gz" ]; then
        echo "  - dotnet-sdk-${dotnet_sdk_version}-linux-x64.tar.gz not found. downloading..."
        wget --continue --output-document="./offline/.dotnet/dep/Sdk/${dotnet_sdk_version}/dotnet-sdk-${dotnet_sdk_version}-linux-x64.tar.gz" "https://dotnetcli.azureedge.net/dotnet/Sdk/${dotnet_sdk_version}/dotnet-sdk-${dotnet_sdk_version}-linux-x64.tar.gz"
fi
# .dotnet/dep/Runtime/2.1.7/dotnet-runtime-2.1.7-linux-x64.tar.gz
echo "  - .dotnet/dep/Runtime/2.1.7/dotnet-runtime-2.1.7-linux-x64.tar.gz..."
if [ ! -e "./offline/.dotnet/dep/Runtime/2.1.7/dotnet-runtime-2.1.7-linux-x64.tar.gz" ]; then
	echo "  - dotnet-runtime-2.1.7-linux-x64.tar.gz not found. downloading..."
	wget --continue --output-document="./offline/.dotnet/dep/Runtime/2.1.7/dotnet-runtime-2.1.7-linux-x64.tar.gz" "https://dotnetcli.azureedge.net/dotnet/Runtime/2.1.7/dotnet-runtime-2.1.7-linux-x64.tar.gz"
fi

# Some fixups
echo "- Removing stray debian folder from linux-packaging-msbuild..."
echo "  - rm -R linux-packaging-msbuild/debian"
rm -R linux-packaging-msbuild/debian
echo "- Fixing \"bashisms\"..."
echo "  - patch -d linux-packaging-msbuild -i `pwd`/offline/fix_bashisms.patch -p 1"
patch -d linux-packaging-msbuild -i `pwd`/offline/fix_bashisms.patch -p 1

# Copy required files from offline to linux-packaging-msbuild
echo "- Copying .dotnet..."
echo "  - cp -R offline/.dotnet linux-packaging-msbuild/"
cp -R offline/.dotnet linux-packaging-msbuild/

echo "- Build using \"./eng/cibuild_bootstrapped_msbuild.sh --host_type mono --configuration Release --skip_tests /p:DisableNerdbankVersioning=true\" from the \"msbuild\" directory."
echo "- For Launchpad PPAs and general Ubuntu package builds, change \"preview\" in \"debian/changelog\" to \"focal\" or any Ubuntu codename."
echo "- You may want to run \"dch -U\" to sign your custom msbuild package changelog."
echo "- Use \"debuild -S -sa\" to build source package for \"sbuild\"."
echo "- Undo patches once done."

