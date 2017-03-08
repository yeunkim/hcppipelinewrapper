#!/bin/bash

SCRIPT_NAME=$(basename ${0})
usage()
{
	cat << EOF

Run HCP minimal processing pipeline for the Depression Connectome Project. 

Usage:  ${SCRIPT_NAME} --subj=<subject folder name> --odir=<output directory>

PARAMETERs ( [] = optional ): 

[--help]				Displays usage and parameter options

--subj=<subject-folder-name>	REQUIRED. Subject folder name (assumes that the 
					parent directory is located /ifs/faculty/narr/schizo/CONNECTOME. 
					If this is not the case, please use --pathtodir)

--odir=<output-dir>              REQUIRED. Output directory (full path is recommended). 
					**TO BE DEPRECATED AFTER SERVER SETUP**

[--pathtodir=<path-to-dir>]		Path to subject folder (do not include subject 
					folder in the path)

[--stages=<stages>]			Stages/Processes to be run. 
					Separated by commas (no space!). 
					Options: PreFreeSurfer, FreeSurfer, 
					PostFreeSurfer, fMRIVolume, fMRISurface, 
					DiffusionPreprocessing, TaskfMRIAnalysis.
					Default: ALL

EOF
}

get_options()
{
	local arguments=($@)

	local index=0
	local numArgs=${#arguments[@]}
	local argument
	while [ ${index} -lt ${numArgs} ] ; do 
		argument=${arguments[index]}
		
		case ${argument} in
			--help)
				usage
				exit 1
				;;
			--subj=*)
				subjfolder=${argument#*=}
				index=$(( index + 1))
				;;
			--pathtodir=*)
				pathtodir=${argument#*=}
				index=$(( index + 1))
				;;
			--odir=*)
				outputdir=${argument#*=}
				index=$(( index + 1))
				;;
			--stages=*)
				stages=${argument#*=}
				index=$(( index + 1))
				;;
			*)
				usage
				echo "ERROR: ${argument} is unrecognizable"
				exit 1
				;;
		esac
	done
	local error_msgs=""
	
	# STAGES=`echo $stages | tr ',' ' '`
	# echo $STAGES
	declare -a arr=("PreFreeSurfer" "FreeSurfer" "PostFreeSurfer" "fMRIVolume" "fMRISurface" "DiffusionPreprocessing" "TaskfMRIAnalysis")	

	if [ -z ${subjfolder} ]; then
		error_msgs+="\nERROR: <subject-folder-name> not specified"
	fi
	if [ -z ${outputdir} ]; then
		error_msgs+="\nERROR: <output-dir> not specified"
	fi
	if ! [ -z ${stages} ]; then
		STAGES=`echo $stages | tr ',' ' '`
		for i in $(echo ${stages} | sed "s/,/ /g"); do
			if ! [[ " ${arr[*]} " == *"$i"* ]]; then
				error_msgs+="\nERROR: Stage does not belong in list"
			fi
		done
	fi
	if [ -z ${stages} ]; then
		STAGES='PreFreeSurfer FreeSurfer PostFreeSurfer fMRIVolume fMRISurface DiffusionPreprocessing TaskfMRIAnalysis'
	fi

	#if ! [ -d ${outputdir} ]; then 
	#	echo "Directory ${outputdir} not found"
	#	exit 1
	#fi

	if [ ! -z "${error_msgs}" ] ; then
		usage
		echo -e ${error_msgs}
		echo ""
		exit 1
	fi
	
	echo ""
	echo "  Subject folder name: ${subjfolder}"
	echo "  Path to subject folder: ${pathtodir}/"
	echo "  Running: ${STAGES}"
	echo ""
}
	
if [ -z ${pathtodir} ]; then
	pathtodir=/ifs/faculty/narr/schizo/CONNECTOME/
fi


main()
{
	get_options $@
	
	#get actual study folder
	DIR="${pathtodir}/${subjfolder}/"

	[[ -z `find $DIR -type d -name "*KNARR*" ` ]]

	StudyFolder=`find $DIR -type d -name "*KNARR*" `
	echo "  Study folder with DICOM files: ${StudyFolder}"

	LICENSE="CindOjuhSN1s"
	
	SUBJ=`echo "${subjfolder}" | tr _ T`
	echo "  BIDS-compliant subject ID: $SUBJ"
	
	if [[ -d ${outputdir} ]]; then
		echo "${outputdir} directory already exists. Please choose another directory name or delete previous folder."
		exit 1;
	fi

	mkdir $outputdir
	
	# run docker
	docker run -ti --rm -v ${StudyFolder}:/dataset -v ${outputdir}:/output yeunkim/hcppipelines_v1.1 /dataset /output -subjID ${SUBJ} -dataset DEPRESSION --license_key ${LICENSE} --n_cpus 4 --stages ${STAGES}
	
	cp -R ${outputdir}/${SUBJ}_output /ifs/faculty/narr/schizo/CONNECTOME/HCP_OUTPUT/
	# rm -rf ${outputdir} 
}

main $@


