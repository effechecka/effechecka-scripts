#!/bin/bash
# generates checklist_status.sh using wkt_string.tsv
# the generated checklist_status.sh produces checklist_status.tsv
# checklist_status.tsv contains a status overview of all checklists associated with wkt_string.tsv
# for examples, see https://github.com/diatomsRcool/checklists and https://github.com/diatomsRcool/water_body_checklists and associated jenkins jobs at http://archive.guoda.bio/view/Effechecka%20Jobs/

generate_status_script() {
  if [ -f checklist_status.tsv ]
  then
    # only check geonames_id without prior 200 status code
    cat checklist_status.tsv > checklist_status_previous.tsv
    cat checklist_status.tsv | tail -n +2 | grep -v "200$" | cut -f1 | sort -n > geonames_id_non_200.tsv
    cat wkt_string.tsv | sort -n > wkt_string_sorted.tsv
    join --nocheck-order wkt_string_sorted.tsv geonames_id_non_200.tsv -t $'\t'> wkt_string_to_be_checked.tsv 
    cat checklist_status_previous.tsv | head -n1 > checklist_status.tsv
    cat checklist_status_previous.tsv | tail -n +2 | grep "200$" >> checklist_status.tsv
  else
    cat wkt_string.tsv > wkt_string_to_be_checked.tsv
    echo "echo \"geonames_id\\\tchecked_at\\\thttp_status_code\" > checklist_status.tsv" > checklist_status.sh
  fi
  cat wkt_string_to_be_checked.tsv | awk -F '\t'  '{ print "curl -s -o /dev/null -w \"%{http_code}\" \"http://api.effechecka.org/checklist.tsv?limit=1&wktString=" $2 "\"| xargs echo " $1 "\\\t$(date -Is)\\\t >> checklist_status.tsv"; }' >> checklist_status.sh
}

generate_download_script() {
  script_name="checklist_download.sh"
  echo "mkdir -p checklist" > $script_name
  cat wkt_string.tsv | awk -F '\t'  '{ print "curl -o checklist/" $1 ".tsv \"http://api.effechecka.org/checklist.tsv?wktString=" $2 "\""; }' >> $script_name
  echo "tar czf checklist.tar.gz wkt_string.tsv checklist_* checklist/*" >> $script_name
}

generate_status_script
generate_download_script
