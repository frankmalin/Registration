#!/bin/bash
#
# Copy over the csv
#
set -x

source=~/Downloads
survey="2022 Player Registration V2.csv"
signed="2022 Med City FC player interest - Current Signings.csv"
part="Participant.*.csv"
p=$(sed 's/\.\*//g' <<< $part)

surveyzip=$(ls -1tr $source | egrep "$(sed 's/.csv//g' <<< $survey)" | tail -n1)
signeddown=$(ls -1tr $source | egrep "$(sed 's/.csv//g' <<< $signed)" | tail -n1)
partdown=$(ls -1tr $source | egrep "$part" | tail -n1)
unzip -o "$source"/"$surveyzip"

cat $source/"$signeddown"  | rev | cut -f2- -d',' | rev  | xargs -I{} echo "\"{}\"" | cut -f1-8 -d',' |  sed 's/,/","/g; s/com "/com"/g'  > "$signed"
# cp $source/"$signeddown" "$signed"

cp $source/"$partdown" $p
sed -i.bak 's/\,\,/,"",/g; s/\,\,/,"",/; s/\,\,/,"",/; s/\,\,/,"",/' $p


