# Update Pixi and Mojo for all projects in the current directory and subdirectories
# Usage: bash update-mojo.sh

shopt -s globstar

echo "Updating Pixi"
pixi self-update

echo "Updating Mojo"
pixi update

for d in **/; do
  if [ -d "$d" ] && [ -n "$(find "$d" -maxdepth 1 -name '*.lock')" ]; then
    echo "Updating $d"
    ( cd "$d" && pixi update )
  fi
done
