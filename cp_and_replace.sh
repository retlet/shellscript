#!/bin/bash -eu

PROGNAME=$(basename "${0}")
VERSION='0.4'
SOURCE=''
DESTINATION=''
FINDOPTS='-mtime +30'
FINDMUSTOPTS='! -name .DS_Store ! -name ._*'

function usage(){
	cat <<EOF
Description:
	source 以下の検索条件に一致するファイルを destination に階層ごとコピーして元ファイルはシンボリックリンクに置き換える

Usage:
	${PROGNAME} SOURCE-DIR DESTINATION-DIR [option] [-find <find-options>]

Options:
	-h, --help
	-v, --version
	-d, --debug            bash set -x
	-find <find-options>   find command options (Defult: ${FINDOPTS[@]})
EOF
}

for OPTS in "${@}"
do
	case "${OPTS}" in
		'-d'|'--debug')
			shift 1
			set -x
			;;
		'-h'|'--help')
			usage
			exit 0
			;;
		'-v'|'--version')
			echo ${VERSION}
			exit 0
			;;
		'-find')
			if [ "${2-UNDEF}" = 'UNDEF' ]; then
				FINDOPTS=''
			else
				FINDOPTS="${@:2}"
			fi
			break
			;;
		-*)
			echo "[ERORR]: ${1}: Invalid option" 1>&2
			exit 1
			;;
		*)
			if [ ! "${1-UNDEF}" = 'UNDEF' ] && [ -d "${1}" ]; then
				if [ -z "${SOURCE}" ]; then
					SOURCE=$(cd "${1}" && pwd)
				elif [ -z "${DESTINATION}" ]; then
					DESTINATION=$(cd "${1}" && pwd)
				fi
			fi
			shift 1
			;;
	esac
done

[ -z "${SOURCE}" ] && echo '[ERORR]: source dir: No such directory' 1>&2 && exit 1
[ -z "${DESTINATION}" ] && echo '[ERORR]: destination dir: No such directory' 1>&2 && exit 1

function cp_and_replace(){
	TARGET="${1}"

	echo "${TARGET}" | cpio -pdumv "${DESTINATION}"

	if [ $? -eq 0 ]; then
		ln -fs "${DESTINATION}/${TARGET}" "${TARGET}"
	else
		echo "Failed to copy file: ${TARGET}" 1>&2
		exit 1
	fi
}

cd "${SOURCE}"

FILES=()
while read f; do
	FILES+=("${f}")
done < <(find * -type f ${FINDMUSTOPTS[@]} ${FINDOPTS[@]})

[ "${FILES-UNDEF}" = 'UNDEF' ] || [ -z "${FILES}" ] && exit 1
echo 'Timestamp	Filepath'

for f in "${FILES[@]}"
do
	echo $(stat -f %Sm -t %Y%m%d "${f}")"	${f}"
done

cat<<EOF
----
find command:   find * -type f ${FINDMUSTOPTS[@]} ${FINDOPTS[@]}
source:         ${SOURCE}
destination:    ${DESTINATION}
----
copying and replacing files ? [y/n]
EOF

read ANS

if [ "${ANS}" = 'y' -o "${ANS}" = 'yes' ]; then
	echo 'start'
	for f in "${FILES[@]}"
	do
		cp_and_replace "${f}"
	done
else
	echo 'nya-n'
fi

exit 0