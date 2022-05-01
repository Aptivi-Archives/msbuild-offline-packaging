#!/bin/bash
# Run from root directory of linux-offline-packaging-msbuild

# Script variables
generate_essentials_tar_xz=false

# Check if user needs to generate Essentials.tar.xz
if [ "$1" == "--generate-essentials-archive" ]; then
	generate_essentials_tar_xz=true
	echo "--generate-essentials-archive invoked"
fi

# Source ./eng/common/tools.sh
echo "- Sourcing ./msbuild/eng/common/tools.sh..."
echo "  - . ./msbuild/eng/common/tools.sh"
. ./msbuild/eng/common/tools.sh

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

# Check for required files
echo "- Determining what files to download..."

# .dotnet/dep/Sdk/${dotnet_sdk_version}/dotnet-sdk-${dotnet_sdk_version}-linux-x64.tar.gz
echo "  - .dotnet/dep/Sdk/${dotnet_sdk_version}/dotnet-sdk-${dotnet_sdk_version}-linux-x64.tar.gz..."
if [ ! -e "./offline/.dotnet/dep/Sdk/${dotnet_sdk_version}/dotnet-sdk-${dotnet_sdk_version}-linux-x64.tar.gz" ]; then
        echo "  - dotnet-sdk-${dotnet_sdk_version}-linux-x64.tar.gz not found. downloading..."
        wget --continue --output-document="./offline/.dotnet/dep/Sdk/${dotnet_sdk_version}/dotnet-sdk-${dotnet_sdk_version}-linux-x64.tar.gz" "https://dotnetcli.azureedge.net/dotnet/Sdk/${dotnet_sdk_version}/dotnet-sdk-${dotnet_sdk_version}-linux-x64.tar.gz"
fi

# Copy required files from offline to msbuild
echo "- Copying .dotnet..."
echo "  - cp -R offline/.dotnet msbuild/"
cp -R offline/.dotnet msbuild/

# Patch tools.sh to use "--azure-feed "$root/dep" --uncached-feed "$root/dep""
echo "- Patching tools.sh..."
echo "  - patch -i offline/offline.patch msbuild/eng/common/tools.sh"
patch -i offline/offline.patch msbuild/eng/common/tools.sh

# Restore packages
echo "- Restoring packages..."
echo "  - cd msbuild"
cd msbuild
echo "  - HOME=`pwd`/nuget ./eng/cibuild_bootstrapped_msbuild.sh --host_type mono --configuration Release --skip_tests /p:DisableNerdbankVersioning=true"
HOME=`pwd`/nuget ./eng/cibuild_bootstrapped_msbuild.sh --host_type mono --configuration Release --skip_tests /p:DisableNerdbankVersioning=true
if [ "$?" -ne 0 ]; then
	exit $?
fi

# Copy dependencies to msbuild/deps
echo "- Copying dependencies to msbuild/deps..."
echo "  - mkdir deps"
mkdir deps
echo "  - cp -R ./nuget/.nuget/packages/* ./deps/"
cp -R ./nuget/.nuget/packages/* ./deps/
echo "  - cp -R ./.packages/* ./deps/"
cp -R ./.packages/* ./deps/

# Compressing essential packages
if [ ${generate_essentials_tar_xz} == true ]; then
	echo "- Compressing essential packages to Essentials.tar..."
	echo "  - tar cfv ../Essentials.tar deps"
	tar cfv ../Essentials.tar deps
	echo "  - xz -9 ../Essentials.tar"
	xz -9 ../Essentials.tar
fi

# Patch NuGet.config and get_sdk_files.sh for offline use
echo "- Patching NuGet.config..."
echo "  - patch -i ../offline/nuget.patch NuGet.config"
patch -i ../offline/nuget.patch NuGet.config
echo "- Patching get_sdk_files.sh..."
echo "  - patch -i ../offline/offline2.patch mono/build/get_sdk_files.sh"
patch -i ../offline/offline2.patch mono/build/get_sdk_files.sh

# Cleaning up
echo "- Cleaning up..."
echo "  - rm -R artifacts"
rm -R artifacts
echo "  - rm -R nuget"
rm -R nuget
echo "  - rm -R stage1"
rm -R stage1
echo "  - rm -R .packages"
rm -R .packages
echo "  - rm -R mono/dotnet-overlay"
rm -R mono/dotnet-overlay
echo "  - mkdir artifacts"
mkdir artifacts
echo "  - wget --continue --output-document=artifacts/mono_msbuild_6.12.0.137.zip https://github.com/mono/msbuild/releases/download/v16.9.0/mono_msbuild_6.12.0.137.zip"
wget --continue --output-document="artifacts/mono_msbuild_6.12.0.137.zip" "https://github.com/mono/msbuild/releases/download/v16.9.0/mono_msbuild_6.12.0.137.zip"

# Extract bootstrapped MSBuild
echo "- Extracting bootstrapped MSBuild..."
echo "  - unzip -q artifacts/mono_msbuild_6.12.0.137.zip -d artifacts"
unzip -q artifacts/mono_msbuild_6.12.0.137.zip -d artifacts
echo "  - mv artifacts/msbuild artifacts/mono-msbuild"
mv artifacts/msbuild artifacts/mono-msbuild
echo "  - chmod +x artifacts/mono-msbuild/MSBuild.dll"
chmod +x artifacts/mono-msbuild/MSBuild.dll
echo "  - rm -Rf artifacts/mono-msbuild/SdkResolvers/Microsoft.DotNet.MSBuildSdkResolver"
rm -Rf artifacts/mono-msbuild/SdkResolvers/Microsoft.DotNet.MSBuildSdkResolver

echo "- Build using \"./eng/cibuild_bootstrapped_msbuild.sh --host_type mono --configuration Release --skip_tests /p:DisableNerdbankVersioning=true\" from the \"msbuild\" directory."
echo "- For Launchpad PPAs and general Ubuntu package builds, change \"preview\" in \"debian/changelog\" to \"focal\" or any Ubuntu codename."
echo "- You may want to run \"dch -U\" to sign your custom msbuild package changelog."
echo "- Use \"debuild -S -sa\" to build source package for \"sbuild\"."
echo "- Undo patches once done."

