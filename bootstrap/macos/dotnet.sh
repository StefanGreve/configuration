pushd ~/Downloads

brew update

# script prerequisite
brew install --yes wget

# required for .NET applications that use System.Drawing.Common
brew install --yes mono-libgdiplus

if [ ! -e "dotnet-install.sh" ]; then
    wget https://dot.net/v1/dotnet-install.sh
    chmod +x dotnet-install.sh
fi

# install the SDK
sudo ./dotnet-install.sh --install-dir /usr/local/share/dotnet \
    --architecture arm64 \
    --os macos \
    --channel LTS

# The installer drops /etc/paths.d/dotnet, so path_helper puts the SDK on PATH; macos/usr/.zshenv exports
# the matching DOTNET_ROOT and macos/usr/.profile adds the global tool directory
echo "Restart your shell to pick up dotnet (DOTNET_ROOT is exported by macos/usr/.zshenv)."

popd
