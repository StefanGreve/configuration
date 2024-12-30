pushd ~/Downloads

bew update

# script prerequisite
brew install wget

# required for .NET applications that use System.Drawing.Common
brew install mono-libgdiplus

if [ ! -e "dotnet-install.sh" ]; then
    wget https://dot.net/v1/dotnet-install.sh
    chmod +x dotnet-install.sh
fi

# install the SDK
sudo ./dotnet-install.sh --install-dir /usr/local/share/dotnet \
    --architecture arm64 \
    --os macos \
    --channel LTS

echo "Set the following two environment variables in your shell profile:"
echo "export DOTNET_ROOT=\$HOME/.dotnet"
echo "export PATH=\$PATH:\$DOTNET_ROOT:\$DOTNET_ROOT/tools"

popd
