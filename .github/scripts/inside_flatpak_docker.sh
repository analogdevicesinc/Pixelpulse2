#!/bin/sh -xe

if [ -n "$BRANCH" ]; then
	ARTIFACT_LOCATION=/pixelpulse2
else
	ARTIFACT_LOCATION=$GITHUB_WORKSPACE
fi

apt-get install -y jq

pwd
ls
cd "$REPO_JSON_FLATPAK_LOCATION"
echo "===="
cat org.adi.Pixelpulse2.json
echo "===="
pwd
ls

# check the number of elements in the json file in order to get the last element
cnt=$( echo `jq '.modules | length' org.adi.Pixelpulse2.json` )
cnt=$(($cnt-1))

if [ -n "$BRANCH" ]; then
	REPO_URL=https://github.com/"$REPO"
	# We are building in Appveyor and we have access to the current branch on a CACHED Docker image
	# use jq to replace the branch + the repo url used for building
	# we want to build the branch and repo we're currently on
	cat org.adi.Pixelpulse2.json | jq --tab '.modules['$cnt'].sources[0].branch = "'$BRANCH'"' > tmp.json
	cp tmp.json org.adi.Pixelpulse2.json
	cat org.adi.Pixelpulse2.json | jq --tab '.modules['$cnt'].sources[0].url = "'$REPO_URL'"' > tmp.json
else
	# We are building in Github Actions and we use the current directory folder on a CLEAN Docker image
	cat org.adi.Pixelpulse2.json | jq --tab '.modules['$cnt'].sources[0].type = "dir"' > tmp.json
	cp tmp.json org.adi.Pixelpulse2.json
	cat org.adi.Pixelpulse2.json | jq --tab '.modules['$cnt'].sources[0].path = "'$GITHUB_WORKSPACE'"' > tmp.json
	cp tmp.json org.adi.Pixelpulse2.json
	cat org.adi.Pixelpulse2.json | jq --tab 'del(.modules['$cnt'].sources[0].url)' > tmp.json
	cp tmp.json org.adi.Pixelpulse2.json
	cat org.adi.Pixelpulse2.json | jq --tab 'del(.modules['$cnt'].sources[0].branch)' > tmp.json
fi
cp tmp.json org.adi.Pixelpulse2.json
rm tmp.json

echo "===="
cat org.adi.Pixelpulse2.json
echo "===="
make clean
make -j4

# Copy the Pixelpulse2.flatpak file in $GITHUB_WORKSPACE (which is the external location, mount when docker starts)
cp Pixelpulse2.flatpak $ARTIFACT_LOCATION/
