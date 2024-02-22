#URL of the HTML file
html_url="http://192.168.1.254/DCIM/Movie"

# Extract JPG file names from HTML
jpg_files=$(wget -qO- "$html_url" | grep -oE 'href="/DCIM/Movie/[0-9]+_[0-9]+_[0-9]+_[RF]\.MP4"' | sed -E 's/href="\/DCIM\/Movie\/([0-9]+_[0-9]+_[0-9]+_[RF]\.MP4)"/\1/')

# Print the value of jpg_files
echo "JPG files: $jpg_files"

# Directory to download files to
download_dir="/mnt/sda1/DCIM/Movie"

# Loop through each JPG file and download if not existing
for jpg_file in $jpg_files; do
    if [ ! -e "$download_dir/$jpg_file" ]; then
        wget -P "$download_dir" "http://192.168.1.254/DCIM/Movie/$jpg_file"
    else
        echo "File $jpg_file already exists, skipping download."
    fi
done
