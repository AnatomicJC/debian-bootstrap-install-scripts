
DISKS=( 
  /dev/disk/by-id/ata-Crucial_CT250MX200SSD6_1550120021F4
  /dev/disk/by-id/ata-Crucial_CT250MX200SSD6_155012002471
  )

COUNT=0
for DISK in "${DISKS[@]}"
do
    #ls -alh ${DISK}
    echo "${DISK}_${COUNT}"
    APPEND=""
    if [ ${COUNT} -gt 0 ]
    then
      APPEND=${COUNT}
    fi
    echo "APPEND=${APPEND}"
    ((COUNT++))
done

echo $COUNT
