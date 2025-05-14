#! /bin/bash

set -euo pipefail

# dependencies
# dpkg-deb
# jq
# sha512sum
# squashfs-tools
# wget

snap_api_url="https://search.apps.ubuntu.com/api/v1/package/skype"
snap_file="skype.snap"
unsquash_dir="unsquashed"
package_dir="to_package"
base_package_dir="base_package"

tmpdir="$(mktemp -d)"
trap 'rm -fr -- "${tmpdir}"' EXIT
cp -a "${base_package_dir}" "${tmpdir}/${package_dir}" 
pushd "${tmpdir}"

echo "Downloading latest Skype snap package metadata..."
wget --quiet "${snap_api_url}"
download_url=$(cat skype | jq '.download_url' | tr -d '"')
download_sha512=$(cat skype | jq '.download_sha512' | tr -d '"')
snap_id=$(cat skype | jq '.snap_id' | tr -d '"')
version=$(cat skype | jq '.version' | tr -d '"')

echo "Downloading version ${version}..."
wget --output-document="${snap_file}" "${download_url}"

echo "Verifing SHA..."
echo "${download_sha512}  ${snap_file}" > sha512
sha512sum --check sha512

echo "Unsquashing filesystem from snap..."
unsquashfs -force -dest "${unsquash_dir}" "${snap_file}"

echo "Copying files from snap to package directory..."
(cd ${unsquash_dir}; find usr -name "*skype*") | while read file
do
	if [ -d "${unsquash_dir}/$file" ]
	then
		# it's a dir
		mkdir --parents "${package_dir}/$file"
		cp -a "${unsquash_dir}/$file/"* "${package_dir}/$file"
	else
		# it's a file
		mkdir --parents "${package_dir}/$(dirname "$file")"
		cp -a "${unsquash_dir}/$file" "${package_dir}/$file"
	fi
done

echo "Updating version in control file..."
sed --in-place "s/Version: [0-9.]\+/Version: ${version}/g" "${package_dir}/DEBIAN/control"

echo "Recalculating md5sum of package content..."
pushd "${package_dir}"
md5sum $(find -type f -not -path 'DEBIAN/*') > "DEBIAN/md5sums"
popd

echo "Creating .deb package..."
dpkg-deb --build "${package_dir}" "skypeforlinux_${version}_amd64-sv.deb"

popd
mv "${tmpdir}/skypeforlinux_${version}_amd64-sv.deb" .

