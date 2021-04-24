# MSBuild Offline Packaging

This is a new iteration for MSBuild offline packaging. To initialize the offline package, follow these steps:

1. Clone this repository
2. Fetch the submodules by running `git submodule update --init`
3. Run initializeoffline.sh

To build MSBuild offline, use `./eng/cibuild_bootstrapped_msbuild.sh --host_type mono --configuration Release --skip_tests /p:DisableNerdbankVersioning=true` from the linux-packaging-msbuild directory.
