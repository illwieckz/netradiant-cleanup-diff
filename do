#! /bin/sh

is_help=false
is_clean=false
is_debug=false
is_translate=false

for arg in ${@}
do
	case "${arg}" in
		'-c'|'--clean')
			is_clean=true
		;;
		'-d'|'--debug')
			is_debug=true
		;;
		'-t'|'--translate')
			is_translate=true
		;;
		'-h'|'--help'|*)
			is_help=true
		;;
	esac
done

if [ "x${@}" = 'x' ]
then
	is_help=true
fi

if "${is_help}"
then
	tab="$(printf '\t')"
	cat <<-EOF
	${0} <args>

	args:

	${tab}-h --help
	${tab}${tab}print this help

	${tab}-c --clean
	${tab}${tab}clean-up everything

	${tab}-d --debug
	${tab}${tab}translate debug build of release build

	${tab}-t --translate
	${tab}${tab}translate build

	example:

	Translate a release build:

	${0} -t

	Clean-up everything and translate a debug build:

	${0} -c -d -t

	EOF
	exit
fi

if "${is_clean}"
then
	rm -rf 'repo' 'build' 'preproc'
fi

if "${is_debug}"
then
	BUILD_TYPE='-DCMAKE_BUILD_TYPE=Debug'
else
	BUILD_TYPE='-DCMAKE_BUILD_TYPE=Release'
fi

if ! "${is_translate}"
then
	exit
fi

mkdir -pv 'repo'
mkdir -pv 'build'
mkdir -pv 'preproc'

rootdir="$(realpath "$(dirname "${0}")")"

[ -d 'repo/netradiant' ] || git clone 'https://gitlab.com/xonotic/netradiant.git' 'repo/netradiant'

for step in before after
do
	repodir="repo/${step}"
	builddir="build/${step}"
	preprocdir="preproc/${step}"

	if ! [ -d "${repodir}" ]
	then
		git clone 'repo/netradiant' "${repodir}"

		cd "${repodir}"
		git remote remove 'origin'
		git remote add 'origin' 'https://gitlab.com/xonotic/netradiant.git'
		git remote add 'illwieckz' 'https://gitlab.com/illwieckz/netradiant.git'
		git fetch 'illwieckz' 'save-temps'

		case "${step}" in
			'before')
				ref='daa584ca'
			;;
			'after')
				ref='Melanosuchus/cleanup'
				git fetch 'origin' 'Melanosuchus/cleanup'
			;;
		esac

		git checkout "${ref}"
		git checkout -b "${step}"
		git cherry-pick '72382fba'
		cd "${rootdir}"

	fi

	cd "${repodir}"
	gitref="$(git rev-parse HEAD | cut -c1-8)"
	cd "${rootdir}"

	mkdir -pv "${builddir}"
	cd "${builddir}"

	cmake -DDOWNLOAD_GAMEPACKS=OFF -DSAVE_TEMPORARY_FILES=ON "${BUILD_TYPE}" "${rootdir}/${repodir}"
	make -j"$(nproc)"

	counter=0
	find . -name '*.ii' -o -name '*.i' \
	| while read filename
	do
		dirname="$(dirname "${filename}")";
		mkdir -pv "${rootdir}/${preprocdir}/${dirname}"
		(
			echo "'${filename}' -> '${rootdir}/${preprocdir}/${filename}'"
			sed -e "s|${rootdir}/${repodir}||;
					s|${rootdir}/${builddir}||;
					s|^# [0-9]* \".*$||;s/[0-9n.]*-git-${gitref}/git/;
					s/\"[0-9][0-9]:[0-9][0-9]:[0-9][0-9]\"/00:00:00/" \
			< "${filename}" \
			| grep -v 'printParseError(\|globalDebugMessageHandler(\|debug_[a-z]*(\|^$' \
			> "${rootdir}/${preprocdir}/${filename}"
			touch -r "${filename}" "${rootdir}/${preprocdir}/${filename}"
		)&

		counter="$((${counter} + 1))"

		if [ ${counter} -eq $(nproc) ]
		then
			wait
			counter=0
		fi
	done

	cd "${rootdir}"
done

cat <<\EOF

you can now diff the two preprocessed sources, for example:

	diff -r 'preproc/before' 'preproc/after'

or:

	meld 'preproc/before' 'preproc/after'
EOF

#EOF
