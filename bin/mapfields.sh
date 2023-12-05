#!/usr/bin/env bash
# Simple change
set -o errexit
set -o nounset
set -o pipefail

shellscript=$(readlink -f "${0}")
mapping="$shellscript/../mapping/"

echo ${DEBUG:-} | grep  true  && set -x

survey="2022 Player Registration V2.csv"
surveyfields="survey.fields"
signed="2022 Med City FC player interest - Current Signings.csv"
signedfields="signed.fields"
part=Participant.csv
partfields="part.fields"

function header()
{
	local a="$1"
	local file="$2"
	local val="$(cat $file)"

	arrayname=( $(cat $file | tr ',' ' ' ) ) # | xargs -I{} echo {} | xargs echo) )

	echo ${arrayname[0]}

	eval "$a=("${arrayname[@]}")"
}

function writecsv()
{
	# Write the csv file according to the header
	local file=$1
	local output=$file.csv
	local fieldfile=$mapping/$file.fields
	local buildline=""
	# Does the file exist, then assume it contains the header
	[[ ! -f $output ]] && cat $fieldfile > $output

	set dummy $(cat $fieldfile | tr ',' '\n' | tr -d '"'); shift

	while test $# -gt 0
	do
		# echo "value of [${1}] "
		# " is: [${!1}]"
		buildline=$(echo "$buildline,\"${!1}\"")
		shift
	done
	echo $(cut -c2- <<< $buildline) >> $output
}

function readcsv()
{
	local csv="$1"; shift
	local match=$1; shift;
	local map=("$@")
	local mapname=""


	local count=0


	for mapname in ${map[@]}; do
		eval "$mapname=\"\""
	done

	# Find the line which matches
	line=$(egrep "$match" "$csv" | head -n1) || { echo "Failed to find match: $match in $csv" ; return 1; }
	# read the line
	count=0
	set dummy $(sed "s/\",\"/\"\n\"/g" <<< $line | tr ' ' '{'); shift

	while test $# -gt 0
		do
			field="$(tr '{' ' ' <<< $1)"; shift
			# echo map: $count ${map[$count]} : $count
			mapname=${map[$count]}
			eval "$mapname=$field"
			let "count=count+1"

		done

	# assign the values
}

FifaState=""
IDDownload=""

function checkFIFA()
{
	# check to see if the form is submitted
	ls ../ID/$FirstName-$LastName.ID.pdf && IDDownload=Found || IDDownload=Missing
	ls ../submitted/$FirstName-$LastName.pdf && { FifaState=Submitted; return; } || true
	ls ../returned/$FirstName-$LastName.pdf && { FifaState=Returned; return; } || true
	ls ../USCitizen/$FirstName-$LastName.pdf && { FifaState=US-Previous; IDDownload=NotNeeded; return; } || true
	ls ../blank/$FirstName-$LastName.pdf && { FifaState=NewFormWaitingOnFrank; return; } || true
	cp ../forms/ITC.pdf ../blank/$FirstName-$LastName.pdf
echo Agreement: $Agreement
	[[ -z "$Agreement" ]] && { FifaState=Unsigned; return; }
	FifaState=NewFormWaitingOnFrank
}


header signedf $mapping/$signedfields
header surveyf $mapping/$surveyfields
header partf $mapping/$partfields

rm itc.csv missing missing.emails housing.csv missing.csv 2>/dev/null || true

echo "Begin Processing player record"

while read line
do
	s=""
	m1=""
	m2=""
	m3="" ; x=""
	GoogleForm="No"
	NPSLRegister="No"
	FifaState="WaitingOnPlayerInfo"
	IDDownload="NotReady"
	s=$(cut -f5 -d',' <<< $line )
	position=$(cut -f2 -d',' <<< $line)
	# [[ $s =~ X|x ]] || continue
	[[ -z $position ]] && continue 
	e="$(cut -f4 -d',' <<< $line)"
	[[ $e =~ @ ]] && echo "Email: $e" || { echo "Missing, or incorrect email: $line";  continue; }
	echo "Looking for : $e"
	readcsv "$signed" "$e" ${signedf[@]} || { echo "ERROR" ; break; }
	readcsv "$survey" "$e"  ${surveyf[@]} && GoogleForm="Yes"|| { GoogleForm="No" ; }
	readcsv "$part" "$e" ${partf[@]} && NPSLRegister="Yes" || { NPSLRegister="No"; }
        [[ ${BirthCertificateDocumentIDUploaded:-} =~ Yes ]] || BirthCertificateDocumentIDUploaded=No

	# [[ -n "$m1" || -n "$m2" || -n "$m3" ]] && { echo "$Name is: $m1, $m2, $m3"  >> missing; echo "$Name <$(tr -d '"' <<< $e)>" >> missing.emails ; set +x; continue; }
	# Need to generate the housing information
	# [[ ${GoogleForm:-} ~= Yes ]] && i
condition=$( echo "Condition${GoogleForm:-}${NPSLRegister:-}${BirthCertificateDocumentIDUploaded:-}" )
	# egrep YesYes <<< $condition && writecsv "housing" || true
writecsv "housing" || true
echo $condition
        [[ -z "$Agreement" ]] && { FifaState=Unsigned; }
	egrep YesYesYes <<< $condition && checkFIFA || true
	writecsv "missing" || true
	egrep YesYes <<< $condition && writecsv "itc" || true
done < "$signed"

echo "End processing record"
