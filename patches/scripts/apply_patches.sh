#!/bin/sh

if [ -z "$1" ]; then
    echo ">>> Error: No patch directory argument supplied!"
    exit 1
fi

for PATCH in $1/*.patch; do
	if [ ! -f $PATCH ]; then
		echo ">>> NOTE: There are no patches to apply."
		exit 0
	fi

	echo Applying $PATCH

	if git am --no-gpg-sign $PATCH; then
		echo ">>> Success: Applied the following patch: \`$PATCH\`."
	elif git apply $PATCH -R --check; then
		echo ">>> Success: Already applied the following patch: \`$PATCH\`."
	else
		echo ">>> ERROR: Failed to apply the following patch: \`$PATCH\`!"
		exit 1
	fi
done
