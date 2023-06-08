#!/bin/sh
# Version: 22

# https://techbase.kde.org/Development/Tutorials/Localization/i18n_Build_Systems
# https://techbase.kde.org/Development/Tutorials/Localization/i18n_Build_Systems/Outside_KDE_repositories
# https://invent.kde.org/sysadmin/l10n-scripty/-/blob/master/extract-messages.sh

DIR=`cd "$( dirname "$0" )" && pwd`
plasmoidName=`kreadconfig5 --file="$DIR/package/metadata.desktop" --group="Desktop Entry" --key="X-KDE-PluginInfo-Name"`
widgetName="${plasmoidName##*.}" # Strip namespace
website=`kreadconfig5 --file="$DIR/package/metadata.desktop" --group="Desktop Entry" --key="X-KDE-PluginInfo-Website"`
bugAddress="$website"
packageRoot="${DIR}/package" # Root of translatable sources
projectName="plasma_applet_${plasmoidName}" # project name

#---
if [ -z "$plasmoidName" ]; then
	echo "[merge] Error: Couldn't read plasmoidName."
	exit
fi

if [ -z "$(which xgettext)" ]; then
	echo "[merge] Error: xgettext command not found. Need to install gettext"
	echo "[merge] Running 'sudo apt install gettext'"
	sudo apt install gettext
	echo "[merge] gettext installation should be finished. Going back to merging translations."
fi

#---
echo "[merge] Extracting messages"
potArgs="--from-code=UTF-8 --width=200 --add-location=file"

# Note: xgettext v0.20.1 (Kubuntu 20.04) and below will attempt to translate Icon,
# so we need to specify Name, GenericName, Comment, and Keywords.
# https://github.com/Zren/plasma-applet-lib/issues/1
# https://savannah.gnu.org/support/?108887
find "${packageRoot}" -name '*.desktop' | sort > "${DIR}/po/infiles.list"
xgettext \
	${potArgs} \
	--files-from="${DIR}/po/infiles.list" \
	--language=Desktop \
	-k -kName -kGenericName -kComment -kKeywords \
	-D "${packageRoot}" \
	-D "${DIR}/po" \
	-o "${DIR}/po/template.pot.new" \
	|| \
	{ echo "[merge] error while calling xgettext. aborting."; exit 1; }

sed -i 's/"Content-Type: text\/plain; charset=CHARSET\\n"/"Content-Type: text\/plain; charset=UTF-8\\n"/' "${DIR}/po/template.pot.new"

# See Ki18n's extract-messages.sh for a full example:
# https://invent.kde.org/sysadmin/l10n-scripty/-/blob/master/extract-messages.sh#L25
# The -kN_ and -kaliasLocale keywords are mentioned in the Outside_KDE_repositories wiki.
# We don't need -kN_ since we don't use intltool-extract but might as well keep it.
# I have no idea what -kaliasLocale is used for. Googling aliasLocale found only listed kde1 code.
# We don't need to parse -ki18nd since that'll extract messages from other domains.
find "${packageRoot}" -name '*.cpp' -o -name '*.h' -o -name '*.c' -o -name '*.qml' -o -name '*.js' | sort > "${DIR}/po/infiles.list"
xgettext \
	${potArgs} \
	--files-from="${DIR}/po/infiles.list" \
	-C -kde \
	-ci18n \
	-ki18n:1 -ki18nc:1c,2 -ki18np:1,2 -ki18ncp:1c,2,3 \
	-kki18n:1 -kki18nc:1c,2 -kki18np:1,2 -kki18ncp:1c,2,3 \
	-kxi18n:1 -kxi18nc:1c,2 -kxi18np:1,2 -kxi18ncp:1c,2,3 \
	-kkxi18n:1 -kkxi18nc:1c,2 -kkxi18np:1,2 -kkxi18ncp:1c,2,3 \
	-kI18N_NOOP:1 -kI18NC_NOOP:1c,2 \
	-kI18N_NOOP2:1c,2 -kI18N_NOOP2_NOSTRIP:1c,2 \
	-ktr2i18n:1 -ktr2xi18n:1 \
	-kN_:1 \
	-kaliasLocale \
	--package-name="${widgetName}" \
	--msgid-bugs-address="${bugAddress}" \
	-D "${packageRoot}" \
	-D "${DIR}/po" \
	--join-existing \
	-o "${DIR}/po/template.pot.new" \
	|| \
	{ echo "[merge] error while calling xgettext. aborting."; exit 1; }

sed -i 's/# SOME DESCRIPTIVE TITLE./'"# Translation of ${widgetName} in LANGUAGE"'/' "${DIR}/po/template.pot.new"
sed -i 's/# Copyright (C) YEAR THE PACKAGE'"'"'S COPYRIGHT HOLDER/'"# Copyright (C) $(date +%Y)"'/' "${DIR}/po/template.pot.new"

if [ -f "${DIR}/po/template.pot" ]; then
	newPotDate=`grep "POT-Creation-Date:" "${DIR}/po/template.pot.new" | sed 's/.\{3\}$//'`
	oldPotDate=`grep "POT-Creation-Date:" "${DIR}/po/template.pot" | sed 's/.\{3\}$//'`
	sed -i 's/'"${newPotDate}"'/'"${oldPotDate}"'/' "${DIR}/po/template.pot.new"
	changes=`diff "${DIR}/po/template.pot" "${DIR}/po/template.pot.new"`
	if [ ! -z "$changes" ]; then
		# There's been changes
		sed -i 's/'"${oldPotDate}"'/'"${newPotDate}"'/' "${DIR}/po/template.pot.new"
		mv "${DIR}/po/template.pot.new" "${DIR}/po/template.pot"

		addedKeys=`echo "$changes" | grep "> msgid" | cut -c 9- | sort`
		removedKeys=`echo "$changes" | grep "< msgid" | cut -c 9- | sort`
		echo ""
		echo "Added Keys:"
		echo "$addedKeys"
		echo ""
		echo "Removed Keys:"
		echo "$removedKeys"
		echo ""

	else
		# No changes
		rm "${DIR}/po/template.pot.new"
	fi
else
	# template.pot didn't already exist
	mv "${DIR}/po/template.pot.new" "${DIR}/po/template.pot"
fi

rm "${DIR}/po/infiles.list"
echo "[merge] Done extracting messages"

#---
echo "[merge] Merging messages"
catalogs=`find ${DIR}/po -name '*.po' | sort`
for cat in $catalogs; do
	echo "[merge] $cat"
	catLocale=`basename ${cat%.*}`

	widthArg=""
	catUsesGenerator=`grep "X-Generator:" "$cat"`
	if [ -z "$catUsesGenerator" ]; then
		widthArg="--width=400"
	fi

	compendiumArg=""
	if [ ! -z "$COMPENDIUM_DIR" ]; then
		langCode=`basename "${cat%.*}"`
		compendiumPath=`realpath "$COMPENDIUM_DIR/compendium-${langCode}.po"`
		if [ -f "$compendiumPath" ]; then
			echo "compendiumPath=$compendiumPath"
			compendiumArg="--compendium=$compendiumPath"
		fi
	fi

	cp "$cat" "$cat.new"
	sed -i 's/"Content-Type: text\/plain; charset=CHARSET\\n"/"Content-Type: text\/plain; charset=UTF-8\\n"/' "$cat.new"

	msgmerge \
		${widthArg} \
		--add-location=file \
		--no-fuzzy-matching \
		${compendiumArg} \
		-o "$cat.new" \
		"$cat.new" "${DIR}/po/template.pot"

	sed -i 's/# SOME DESCRIPTIVE TITLE./'"# Translation of ${widgetName} in ${catLocale}"'/' "$cat.new"
	sed -i 's/# Translation of '"${widgetName}"' in LANGUAGE/'"# Translation of ${widgetName} in ${catLocale}"'/' "$cat.new"
	sed -i 's/# Copyright (C) YEAR THE PACKAGE'"'"'S COPYRIGHT HOLDER/'"# Copyright (C) $(date +%Y)"'/' "$cat.new"

	# mv "$cat" "$cat.old"
	mv "$cat.new" "$cat"
done
echo "[merge] Done merging messages"

#---
echo "[merge] Updating .desktop file"

# Generate LINGUAS for msgfmt
if [ -f "$DIR/po/LINGUAS" ]; then
	rm "$DIR/po/LINGUAS"
fi
touch "$DIR/po/LINGUAS"
for cat in $catalogs; do
	catLocale=`basename ${cat%.*}`
	echo "${catLocale}" >> "$DIR/po/LINGUAS"
done

cp -f "$DIR/package/metadata.desktop" "$DIR/po/template.desktop"
sed -i '/^Name\[/ d; /^GenericName\[/ d; /^Comment\[/ d; /^Keywords\[/ d' "$DIR/po/template.desktop"

msgfmt \
	--desktop \
	--template="$DIR/po/template.desktop" \
	-d "$DIR/po/" \
	-o "$DIR/po/new.desktop"

# Delete empty msgid messages that used the po header
if [ ! -z "$(grep '^Name=$' "$DIR/po/new.desktop")" ]; then
	echo "[merge] Name in metadata.desktop is empty!"
	sed -i '/^Name\[/ d' "$DIR/po/new.desktop"
fi
if [ ! -z "$(grep '^GenericName=$' "$DIR/po/new.desktop")" ]; then
	echo "[merge] GenericName in metadata.desktop is empty!"
	sed -i '/^GenericName\[/ d' "$DIR/po/new.desktop"
fi
if [ ! -z "$(grep '^Comment=$' "$DIR/po/new.desktop")" ]; then
	echo "[merge] Comment in metadata.desktop is empty!"
	sed -i '/^Comment\[/ d' "$DIR/po/new.desktop"
fi
if [ ! -z "$(grep '^Keywords=$' "$DIR/po/new.desktop")" ]; then
	echo "[merge] Keywords in metadata.desktop is empty!"
	sed -i '/^Keywords\[/ d' "$DIR/po/new.desktop"
fi

# Place translations at the bottom of the desktop file.
translatedLines=`cat "$DIR/po/new.desktop" | grep "]="`
if [ ! -z "${translatedLines}" ]; then
	sed -i '/^Name\[/ d; /^GenericName\[/ d; /^Comment\[/ d; /^Keywords\[/ d' "$DIR/po/new.desktop"
	if [ "$(tail -c 2 "$DIR/po/new.desktop" | wc -l)" != "2" ]; then
		# Does not end with 2 empty lines, so add an empty line.
		echo "" >> "$DIR/po/new.desktop"
	fi
	echo "${translatedLines}" >> "$DIR/po/new.desktop"
fi

# Cleanup
mv "$DIR/po/new.desktop" "$DIR/package/metadata.desktop"
rm "$DIR/po/template.desktop"
rm "$DIR/po/LINGUAS"

echo "[merge] Done"
