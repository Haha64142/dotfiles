#
# ~/.bash_logout
#

if [ -d "$PWD" ] && [ -f "$DIR_FILE" ]; then
    last_logged=$(tail -n 1 "$DIR_FILE")
    [ "$last_logged" != "$PWD" ] && echo "$PWD" >> "$DIR_FILE"
fi

# Keep only last 20 unique entries (optional cleanup)
awk 'NR == 1 || $0 != prev { print; prev = $0 }' "$DIR_FILE" | tail -n 20 > "${DIR_FILE}.tmp"
mv "${DIR_FILE}.tmp" "$DIR_FILE"