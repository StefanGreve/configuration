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

# Unlike the .pkg, dotnet-install.sh never touches PATH, so register the SDK with path_helper here;
# macos/usr/.zshenv exports the matching DOTNET_ROOT and macos/usr/.profile adds the global tool directory
echo "/usr/local/share/dotnet" | sudo tee /etc/paths.d/dotnet > /dev/null

echo "Restart your shell to pick up dotnet (DOTNET_ROOT is exported by macos/usr/.zshenv)."

popd
