#!/bin/bash

#--------------------[ Banner for Nandi ]--------------------#
cat << 'EOF'
==========================================================
         .=     ,        =.
  _  _   /'/    )\,/,/(_   \ \
   `//-.|  (  ,\\)\/\\/\\)\/ _  ) |
   //___\   `\\\/\\\/\\/\\///'  /
,-"~`-._ `"--'_   `"""`  _ \`'"~-,_
\       `-.  '_`.      .'_' \ ,-"~`/
 `.__.-'/   (-\        /-) |-.__,'
   ||   |     \O)  /^\ (O/  |
   `\\  |         /   `\    /
     \\  \       /      `\ /
      `\\ `-.  /' .---.--.\
        `\\/`~(, '()      ('
         /(O) \\   _,.-.,_)
        //  \\ `\'`      /
  jgs  / |  ||   `""""~"`
     /'  |__||
           `o]
       URL Parameter Finder – Nandi
==========================================================
        By: KaliyugH4cker-Ashwatthama 
EOF

#--------------------[ Input Domain ]--------------------#
if [ -z "$1" ]; then
    echo "Usage: $0 <domain>"
    exit 1
fi

domain="$1"
result_dir="param_results/$domain"
mkdir -p "$result_dir"/{gau,paramspider,final}

#--------------------[ Check & Install Go ]--------------------#
if ! command -v go &>/dev/null; then
    echo "[!] Go not found. Installing..."
    wget https://go.dev/dl/go1.22.3.linux-amd64.tar.gz -O /tmp/go.tar.gz
    sudo rm -rf /usr/local/go
    sudo tar -C /usr/local -xzf /tmp/go.tar.gz
    echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >> ~/.bashrc
    export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin
    source ~/.bashrc
else
    echo "[✓] Go is already installed."
fi

#--------------------[ Function to Install Go Tools If Missing ]--------------------#
install_go_tool() {
    local name=$1
    local repo=$2
    if ! command -v "$name" &>/dev/null; then
        echo "[+] Installing $name..."
        go install "$repo"@latest
        sudo cp ~/go/bin/$name /usr/local/bin/
    else
        echo "[✓] $name already installed."
    fi
}

#--------------------[ Install Required Tools ]--------------------#
install_go_tool gau github.com/lc/gau

#--------------------[ Install pipx and paramspider ]--------------------#
if ! command -v paramspider &>/dev/null; then
    echo "[+] paramspider not found. Installing using pipx..."
    
    if ! command -v pipx &>/dev/null; then
        echo "[+] Installing pipx..."
        sudo apt install -y pipx
        pipx ensurepath
        source ~/.bashrc
    fi

    pipx install git+https://github.com/devanshbatham/ParamSpider.git
else
    echo "[✓] paramspider already installed."
fi

#--------------------[ Recon Collection ]--------------------#
echo -e "\n[*] Running recon for: $domain"

echo "[→] Running gau..."
gau "$domain" --threads 5 --o "$result_dir/gau/output.txt"

echo "[→] Running paramspider..."
if command -v paramspider &>/dev/null; then
    paramspider -d "$domain" --quiet > "$result_dir/paramspider/output.txt"
else
    echo "[!] paramspider failed to run. Skipping..."
fi

#--------------------[ Merge & Deduplicate ]--------------------#
echo "[→] Merging and deduplicating..."
cat "$result_dir"/gau/output.txt "$result_dir"/paramspider/output.txt 2>/dev/null | sort -u > "$result_dir/final/unique_params.txt"

#--------------------[ Done ]--------------------#
echo -e "\n[✓] Done for $domain → $result_dir/final/unique_params.txt"
